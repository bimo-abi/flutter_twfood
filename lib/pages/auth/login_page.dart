import 'dart:convert';

import 'package:flutter/material.dart';

import 'register_page.dart';
import '../../pages/pelanggan/home_pelanggan_page.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/token_storage.dart';
import '../../services/remember_me_storage.dart';
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
  bool _rememberMe = false;
  bool _rememberMeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      final credentials = await RememberMeStorage.load();
      if (!mounted) return;

      setState(() {
        _rememberMe = credentials != null;
        if (credentials != null) {
          _emailController.text = credentials.email;
          _passwordController.text = credentials.password;
        }
        _rememberMeLoaded = true;
      });
    } catch (e) {
      debugPrint('Gagal membaca Remember Me: $e');
      if (mounted) {
        setState(() => _rememberMeLoaded = true);
      }
    }
  }

  Future<void> _saveRememberedCredentials(Map<String, dynamic> userData) async {
    if (_rememberMe) {
      await RememberMeStorage.save(
        name: userData['nama']?.toString() ?? '',
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      await RememberMeStorage.clear();
    }
  }

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
            await _saveRememberedCredentials(
              meData['data'] as Map<String, dynamic>,
            );
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
            await _saveRememberedCredentials(meUser);
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

  Future<void> _goToRegister() async {
    final registrationSucceeded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );

    if (!mounted || registrationSucceeded != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrasi berhasil. Silakan masuk.')),
    );
  }

  // ============================================================
  // TAMPILAN LOGIN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                    child: Form(
                      key: _formKey,
                      child: _buildFormContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Bagian atas sederhana: dua lapis gelombang kuning lembut dan logo.
  Widget _buildHeader() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          ClipPath(
            clipper: _WaveClipper(back: true),
            child: Container(height: 300, color: AppColors.secondarySoft),
          ),
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              height: 262,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD79A), Color(0xFFFFE9C9)],
                ),
              ),
            ),
          ),
          // Ilustrasi berbagai jamur (shiitake, tiram, enoki, kancing, king oyster)
          // di kiri dan kanan logo. File: assets/images/jamur_hias.png
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/jamur_hias.png',
                fit: BoxFit.fitWidth,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                if (Navigator.of(context).canPop())
                  Positioned(
                    left: 12,
                    top: 8,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Kembali',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: const Alignment(0, -0.2),
                  child: Container(
                    width: 108,
                    height: 108,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.primary,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Masuk',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Selamat datang kembali di TWFOOD.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(
            label: 'Email',
            hint: 'Masukkan email terdaftar',
            icon: Icons.email_outlined,
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
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitForm(),
          decoration: _fieldDecoration(
            label: 'Password',
            hint: 'Masukkan password',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              tooltip: _obscurePassword
                  ? 'Tampilkan password'
                  : 'Sembunyikan password',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(
                () => _obscurePassword = !_obscurePassword,
              ),
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Password wajib diisi.' : null,
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Ingat saya',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Simpan email dan password di perangkat ini.',
            style: TextStyle(fontSize: 11.5),
          ),
          value: _rememberMe,
          onChanged: _rememberMeLoaded && !_isLoading
              ? (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                }
              : null,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
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
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Belum punya akun?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: _goToRegister,
              child: const Text(
                'Daftar sekarang',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: border(Colors.transparent, 0),
      enabledBorder: border(AppColors.border, 1),
      focusedBorder: border(AppColors.primary, 1.6),
      errorBorder: border(AppColors.error, 1),
      focusedErrorBorder: border(AppColors.error, 1.6),
    );
  }
}

// Bentuk gelombang untuk bagian atas halaman masuk/daftar.
class _WaveClipper extends CustomClipper<Path> {
  final bool back;

  _WaveClipper({this.back = false});

  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    final path = Path()..lineTo(0, h - 55);
    if (back) {
      path.quadraticBezierTo(w * 0.30, h + 5, w * 0.62, h - 35);
      path.quadraticBezierTo(w * 0.85, h - 62, w, h - 18);
    } else {
      path.quadraticBezierTo(w * 0.25, h + 8, w * 0.52, h - 28);
      path.quadraticBezierTo(w * 0.80, h - 62, w, h - 22);
    }
    path
      ..lineTo(w, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}