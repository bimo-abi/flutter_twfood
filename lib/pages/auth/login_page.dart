import 'dart:convert';

import 'package:flutter/material.dart';

import 'register_page.dart';
import '../../pages/pelanggan/home_pelanggan_page.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/token_storage.dart';

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

        if (peran != 'pelanggan') {
          await TokenStorage.deleteToken();
          CartService.resetSession();

          if (!mounted) return;

          final message = peran == 'mitra'
              ? 'Login Mitra berhasil, tetapi aplikasi Mitra belum tersedia.'
              : 'Role pengguna tidak dikenali: $peran';

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
      appBar: AppBar(title: const Text('Login TWFOOD')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                const Icon(Icons.fastfood_outlined, size: 70),

                const SizedBox(height: 20),

                const Text(
                  'Selamat Datang',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Login ke akun TWFOOD Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 35),

                // EMAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Masukkan email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email wajib diisi.';
                    }

                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // TOMBOL LOGIN
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // NAVIGASI REGISTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? '),
                    TextButton(
                      onPressed: _goToRegister,
                      child: const Text('Daftar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
