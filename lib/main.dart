import 'dart:convert';

import 'package:flutter/material.dart';

import 'pages/auth/login_page.dart';
import 'pages/pelanggan/home_pelanggan_page.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TwfoodApp());
}

class TwfoodApp extends StatelessWidget {
  const TwfoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TWFOOD',
      theme: AppTheme.lightTheme,
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  Widget? _destination;
  String? _errorMessage;
  bool _accessDenied = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _destination = null;
      _errorMessage = null;
      _accessDenied = false;
    });

    try {
      // 1. Periksa token yang tersimpan.
      final token = await TokenStorage.getToken();

      if (token == null || token.isEmpty) {
        _showDestination(const LoginPage());
        return;
      }

      // 2. Validasi token melalui backend.
      final response = await AuthService.me();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is! Map<String, dynamic> ||
            responseData['data'] is! Map<String, dynamic>) {
          throw const FormatException('Format profil pengguna tidak valid.');
        }

        final data = responseData['data'] as Map<String, dynamic>;

        // 3. Pastikan akun memiliki role pelanggan.
        final peran = data['peran'];

        if (peran != 'pelanggan') {
          await TokenStorage.deleteToken();
          CartService.resetSession();

          if (!mounted) return;

          setState(() {
            _errorMessage =
                'Akun ini tidak memiliki akses ke aplikasi pelanggan.';
            _accessDenied = true;
          });

          return;
        }

        // 4. Validasi ID pengguna.
        final rawUserId = data['id_pengguna'];

        final userId = rawUserId is int
            ? rawUserId
            : int.tryParse(rawUserId?.toString() ?? '');

        if (userId == null || userId <= 0) {
          throw const FormatException(
            'ID pengguna tidak valid dari respons API.',
          );
        }

        // 5. Muat keranjang sesuai akun yang tervalidasi.
        await CartService.initializeForUser(userId);

        // 6. Buka halaman utama pelanggan.
        _showDestination(const HomePelangganPage());
        return;
      }

      // Token ditolak oleh backend.
      if (response.statusCode == 401 || response.statusCode == 403) {
        await TokenStorage.deleteToken();
        CartService.resetSession();
        _showDestination(const LoginPage());
        return;
      }

      // Error server tidak otomatis menghapus token.
      throw Exception('Server mengembalikan status ${response.statusCode}.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Tidak dapat memeriksa sesi login. '
            'Periksa koneksi dan coba lagi.';
      });

      debugPrint('Pemulihan sesi gagal: $e');
    }
  }

  void _showDestination(Widget destination) {
    if (!mounted) return;

    setState(() {
      _destination = destination;
      _errorMessage = null;
      _accessDenied = false;
    });
  }

  void _backToLogin() {
    CartService.resetSession();
    _showDestination(const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _accessDenied ? Icons.lock_outline : Icons.wifi_off,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _accessDenied ? _backToLogin : _restoreSession,
                  child: Text(_accessDenied ? 'Kembali ke Login' : 'Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_destination == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _destination!;
  }
}
