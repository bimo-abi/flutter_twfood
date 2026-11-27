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
    Map<String, String> dokumen = const {},
  }) {
    final Map<String, String> fields = {
      'nama': nama,
      'email': email,
      'nomor_telepon': nomorTelepon,
      'kata_sandi': kataSandi,
      'kata_sandi_confirmation': kataSandiConfirmation,
      'jenis_pelanggan': jenisPelanggan,
    };

    if (profilBisnis != null) {
      for (final entry in profilBisnis.entries) {
        if (entry.value != null) {
          fields['profil_bisnis[${entry.key}]'] = entry.value.toString();
        }
      }
    }

    if (jenisPelanggan == 'umum') {
      return ApiService.post('/register', body: {
        'nama': nama,
        'email': email,
        'nomor_telepon': nomorTelepon,
        'kata_sandi': kataSandi,
        'kata_sandi_confirmation': kataSandiConfirmation,
        'jenis_pelanggan': jenisPelanggan,
      });
    }

    return ApiService.multipartPublic(
      '/register',
      fields: fields,
      filePaths: dokumen,
    );
  }

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

  // MEMPERBARUI PROFIL PELANGGAN
  static Future<http.Response> updateProfile({
    required String nama,
    required String email,
    required String nomorTelepon,
  }) {
    return ApiService.patchAuthenticated(
      '/profile',
      body: {
        'nama': nama,
        'email': email,
        'nomor_telepon': nomorTelepon,
      },
    );
  }

  // Mengunggah foto profil pengguna yang sedang login.
  static Future<http.Response> uploadProfilePhoto(String filePath) {
    return ApiService.multipartAuthenticated(
      '/profile/photo',
      fields: {},
      fileField: 'foto_profil',
      filePath: filePath,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<http.Response> logout() {
    return ApiService.postAuthenticated('/logout');
  }
}
