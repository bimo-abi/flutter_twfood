import 'dart:convert';

import 'package:flutter/material.dart';

import 'register_page.dart';
import '../../pages/pelanggan/home_pelanggan_page.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/token_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../pages/mitra/home_mitra_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _submitForm() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.login(
        email: _emailController.text.trim(),
        kataSandi: _passwordController.text,
      );

      if (!mounted) return;
      Map<String, dynamic>? data;

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } on FormatException {
        data = null;
      }

      // ========================================================
      // LOGIN BERHASIL
      // ========================================================

      if (response.statusCode == 200) {
        if (data == null || data['data'] is! Map<String, dynamic>) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format respons login dari server tidak valid.'),
            ),
          );
          return;
        }
        final userData = data['data'] as Map<String, dynamic>;
        final peran = userData['peran'];
        final token = userData['token'];

        // ========================================================
        // VALIDASI ROLE SEBELUM MENYIMPAN TOKEN
        // ========================================================

        if (peran != 'pelanggan' && peran != 'mitra') {
          await TokenStorage.deleteToken();
          CartService.resetSession();

          if (!mounted) return;

          final message = 'Role pengguna tidak dikenali: $peran';

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));

          return;
        }

        // ========================================================
        // VALIDASI TOKEN
        // ========================================================

        if (token is! String || token.trim().isEmpty) {
          await TokenStorage.deleteToken();
          CartService.resetSession();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login gagal: token tidak valid.')),
          );

          return;
        }

        // ========================================================
        // SIMPAN TOKEN KHUSUS PELANGGAN
        // ========================================================

        await TokenStorage.saveToken(token);

        if (!mounted) return;

        debugPrint('Role pengguna: $peran');
        debugPrint('Token pelanggan berhasil disimpan.');

        if (peran == 'mitra') {
          try {
            final meResponse = await AuthService.me();

            if (meResponse.statusCode != 200) {
              throw Exception(
                'Gagal memvalidasi akun Mitra '
                '(HTTP ${meResponse.statusCode}).',
              );
            }

            final meData = jsonDecode(meResponse.body);

            if (meData is! Map<String, dynamic> ||
                meData['data'] is! Map<String, dynamic> ||
                (meData['data'] as Map<String, dynamic>)['peran'] != 'mitra') {
              throw const FormatException(
                'Akun tidak terverifikasi sebagai Mitra.',
              );
            }

            CartService.resetSession();
          } catch (e) {
            await TokenStorage.deleteToken();
            CartService.resetSession();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menyiapkan sesi Mitra: $e')),
            );

            return;
          }

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeMitraPage()),
          );

          return;
        }

        if (peran == 'pelanggan') {
          try {
            // Ambil data pengguna dari Laravel menggunakan token.
            final meResponse = await AuthService.me();

            if (meResponse.statusCode != 200) {
              throw Exception(
                'Gagal mengambil profil '
                '(HTTP ${meResponse.statusCode}).',
              );
            }

            final meData = jsonDecode(meResponse.body);

            if (meData is! Map<String, dynamic> ||
                meData['data'] is! Map<String, dynamic>) {
              throw const FormatException(
                'Format profil pengguna tidak valid.',
              );
            }

            final meUser = meData['data'] as Map<String, dynamic>;

            if (meUser['peran'] != 'pelanggan') {
              throw const FormatException(
                'Role pengguna tidak sesuai dengan aplikasi pelanggan.',
              );
            }

            // Ambil ID pengguna dari response /me.
            final rawUserId = meUser['id_pengguna'];

            final userId = rawUserId is int
                ? rawUserId
                : int.tryParse(rawUserId?.toString() ?? '');

            if (userId == null || userId <= 0) {
              throw const FormatException('ID pengguna tidak valid.');
            }

            // Muat keranjang milik pengguna yang login.
            await CartService.initializeForUser(userId);
          } catch (e) {
            // Batalkan persiapan sesi jika gagal.
            CartService.resetSession();
            await TokenStorage.deleteToken();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menyiapkan sesi pelanggan: $e')),
            );
            return;
          }

          if (!mounted) return;

          // Masuk ke halaman utama setelah keranjang dimuat.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePelangganPage()),
          );

          return;
        }
      }

      // ========================================================
      // EMAIL / PASSWORD SALAH
      // ========================================================

      if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email atau password salah.')),
        );
        return;
      }

      // ========================================================
      // AKUN TIDAK AKTIF
      // ========================================================

      if (response.statusCode == 403) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Akun tidak aktif.')));
        return;
      }

      // ========================================================
      // ERROR LAINNYA
      // ========================================================

      String message = 'Login gagal (HTTP ${response.statusCode}).';

      if (data != null && data['message'] is String) {
        message = data['message'].toString();
      }

      if (data != null && data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;

        if (errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      }

      if (data == null) {
        message =
            'Server mengembalikan respons tidak valid '
            '(HTTP ${response.statusCode}).';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Terjadi kesalahan saat login. Periksa koneksi dan coba lagi.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // NAVIGASI KE REGISTER
  // ============================================================

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  // ============================================================
  // TAMPILAN LOGIN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Masuk'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Selamat Datang',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk ke akun TWFOOD untuk melanjutkan belanja.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      color: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Login', style: AppTextStyles.headingSmall),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Masukkan email terdaftar',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'Email wajib diisi.';
                                final emailRegex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );
                                if (!emailRegex.hasMatch(value.trim()))
                                  return 'Format email tidak valid.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submitForm(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Masukkan password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Tampilkan password'
                                      : 'Sembunyikan password',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Password wajib diisi.'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('MASUK'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: _goToRegister,
                          child: const Text('Daftar sekarang'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
