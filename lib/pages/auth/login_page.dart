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

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final response = await AuthService.login(
        email: _emailController.text.trim(),
        kataSandi: _passwordController.text,
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      // ========================================================
      // LOGIN BERHASIL
      // ========================================================

      if (response.statusCode == 200) {
        final userData = data['data'];

        final peran = userData['peran'];
        final token = userData['token'];

        // Pastikan token tersedia.
        if (token is! String || token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Login berhasil, tetapi token tidak ditemukan.',
              ),
            ),
          );
          return;
        }

        // Simpan token autentikasi.
        await TokenStorage.saveToken(token);

        if (!mounted) return;

        debugPrint('Role pengguna: $peran');
        debugPrint('Token berhasil disimpan.');

        // ======================================================
        // ROLE PELANGGAN
        // ======================================================

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

            // Ambil ID pengguna dari response /me.
            final rawUserId =
                meData['data']['id_pengguna'];

            final userId = rawUserId is int
                ? rawUserId
                : int.tryParse(
                    rawUserId?.toString() ?? '',
                  );

            if (userId == null || userId <= 0) {
              throw const FormatException(
                'ID pengguna tidak valid.',
              );
            }

            // Muat keranjang milik pengguna yang login.
            await CartService.initializeForUser(userId);
          } catch (e) {
            // Batalkan persiapan sesi jika gagal.
            CartService.resetSession();
            await TokenStorage.deleteToken();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gagal menyiapkan sesi pelanggan: $e',
                ),
              ),
            );
            return;
          }

          if (!mounted) return;

          // Masuk ke halaman utama setelah keranjang dimuat.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePelangganPage(),
            ),
          );

          return;
        }

        // ======================================================
        // ROLE MITRA
        // ======================================================

        if (peran == 'mitra') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Login Mitra berhasil. '
                'Halaman Mitra akan dibuat pada Fase 5.',
              ),
            ),
          );
          return;
        }

        // ======================================================
        // ROLE TIDAK DIKENAL
        // ======================================================

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role pengguna tidak dikenali: $peran',
            ),
          ),
        );

        return;
      }

      // ========================================================
      // EMAIL / PASSWORD SALAH
      // ========================================================

      if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email atau password salah.'),
          ),
        );
        return;
      }

      // ========================================================
      // AKUN TIDAK AKTIF
      // ========================================================

      if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun tidak aktif.'),
          ),
        );
        return;
      }

      // ========================================================
      // ERROR LAINNYA
      // ========================================================

      String message = 'Login gagal.';

      if (data is Map<String, dynamic> &&
          data['message'] != null) {
        message = data['message'].toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat terhubung ke server: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // NAVIGASI KE REGISTER
  // ============================================================

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  // ============================================================
  // TAMPILAN LOGIN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login TWFOOD'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                const Icon(
                  Icons.fastfood_outlined,
                  size: 70,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Selamat Datang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Login ke akun TWFOOD Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
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
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Email wajib diisi.';
                    }

                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    );

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
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
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
                    onPressed: _submitForm,
                    child: const Text(
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
