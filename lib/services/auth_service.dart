import 'package:http/http.dart' as http;

import 'api_service.dart';

class AuthService {
  // ============================================================
  // REGISTER
  // ============================================================

  static Future<http.Response> register({
    required String nama,
    required String email,
    required String nomorTelepon,
    required String kataSandi,
    required String kataSandiConfirmation,
    required String jenisPelanggan,
    Map<String, dynamic>? profilBisnis,
  }) {
    final Map<String, dynamic> body = {
      'nama': nama,
      'email': email,
      'nomor_telepon': nomorTelepon,
      'kata_sandi': kataSandi,
      'kata_sandi_confirmation': kataSandiConfirmation,
      'jenis_pelanggan': jenisPelanggan,
    };

    if (profilBisnis != null) {
      body['profil_bisnis'] = profilBisnis;
    }

    return ApiService.post('/register', body: body);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<http.Response> login({
    required String email,
    required String kataSandi,
  }) {
    return ApiService.post(
      '/login',
      body: {'email': email, 'kata_sandi': kataSandi},
    );
  }

  // ============================================================
  // DATA PENGGUNA
  // ============================================================

  static Future<http.Response> me() {
    return ApiService.getAuthenticated('/me');
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<http.Response> logout() {
    return ApiService.postAuthenticated('/logout');
  }
}
