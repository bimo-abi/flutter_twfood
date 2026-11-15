import 'dart:convert';

import '../models/notifikasi.dart';
import 'api_service.dart';

class NotifikasiService {
  // Mengambil daftar notifikasi pengguna yang sedang login.
  static Future<List<Notifikasi>> getNotifikasi() async {
    final response = await ApiService.getAuthenticated('/notifikasi');

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil notifikasi (${response.statusCode}).');
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic> ||
        responseData['data'] is! Map<String, dynamic>) {
      throw const FormatException('Format response notifikasi tidak valid.');
    }

    final pagination = responseData['data'] as Map<String, dynamic>;

    final items = pagination['data'];

    if (items is! List) {
      throw const FormatException('Daftar notifikasi tidak ditemukan.');
    }

    return items
        .map((item) => Notifikasi.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Menandai satu notifikasi sebagai sudah dibaca.
  static Future<void> markRead(int idNotifikasi) async {
    final response = await ApiService.patchAuthenticated(
      '/notifikasi/$idNotifikasi/baca',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menandai notifikasi sebagai dibaca '
        '(${response.statusCode}).',
      );
    }
  }

  // Menandai seluruh notifikasi aktif sebagai sudah dibaca.
  static Future<void> markAllRead() async {
    final response = await ApiService.patchAuthenticated(
      '/notifikasi/baca-semua',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menandai semua notifikasi sebagai dibaca '
        '(${response.statusCode}).',
      );
    }
  }
}
