import 'dart:convert';

import '../models/notifikasi.dart';
import 'api_service.dart';

class NotifikasiService {
  // Mengambil daftar notifikasi pengguna yang sedang login.
  static Future<List<Notifikasi>> getNotifikasi() async {
    const perPage = 50;
    final semuaNotifikasi = <Notifikasi>[];
    var page = 1;
    var lastPage = 1;

    do {
      final response = await ApiService.getAuthenticated(
        '/notifikasi?page=$page&per_page=$perPage',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil notifikasi (${response.statusCode}).',
        );
      }

      final responseData = jsonDecode(response.body);

      if (responseData is! Map<String, dynamic> ||
          responseData['data'] is! Map<String, dynamic>) {
        throw const FormatException(
          'Format response notifikasi tidak valid.',
        );
      }

      final pagination = responseData['data'] as Map<String, dynamic>;
      final items = pagination['data'];

      if (items is! List) {
        throw const FormatException('Daftar notifikasi tidak ditemukan.');
      }

      semuaNotifikasi.addAll(
        items
            .whereType<Map>()
            .map(
              (item) => Notifikasi.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ),
      );

      page = _asInt(pagination['current_page'], page) + 1;
      lastPage = _asInt(pagination['last_page'], page - 1);
    } while (page <= lastPage);

    return semuaNotifikasi;
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
