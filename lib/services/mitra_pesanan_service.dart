import 'dart:convert';

import '../models/mitra_pesanan.dart';
import 'api_service.dart';

class MitraPesananPageData {
  final List<MitraPesanan> pesanan;
  final int currentPage;
  final int lastPage;
  final int total;

  const MitraPesananPageData({
    required this.pesanan,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class MitraPesananService {
  static Future<MitraPesananPageData> fetchPesanan({
    int page = 1,
    String? status,
    String? jenisPemenuhan,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': '20',
      if (status != null && status.isNotEmpty) 'status_pesanan': status,
      if (jenisPemenuhan != null && jenisPemenuhan.isNotEmpty)
        'jenis_pemenuhan': jenisPemenuhan,
    };

    final uri = Uri(path: '/mitra/pesanan', queryParameters: query);

    final response = await ApiService.getAuthenticated(
      '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}',
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Gagal mengambil daftar pesanan.');
    }

    if (decoded is! Map || decoded['data'] is! Map) {
      throw const FormatException('Format daftar pesanan tidak valid.');
    }

    final pagination = decoded['data'] as Map;
    final rows = pagination['data'];
    if (rows is! List) {
      throw const FormatException('Data pesanan tidak berbentuk daftar.');
    }

    return MitraPesananPageData(
      pesanan: rows
          .whereType<Map>()
          .map((item) => MitraPesanan.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      currentPage: _toInt(pagination['current_page'], 1),
      lastPage: _toInt(pagination['last_page'], 1),
      total: _toInt(pagination['total'], rows.length),
    );
  }

  static Future<MitraPesanan> fetchDetail(int id) async {
    final response = await ApiService.getAuthenticated('/mitra/pesanan/$id');
    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Gagal mengambil detail pesanan.');
    }

    if (decoded is! Map || decoded['data'] is! Map) {
      throw const FormatException('Format detail pesanan tidak valid.');
    }

    return MitraPesanan.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  static Future<void> updateStatus({
    required int idPesanan,
    required String statusPesanan,
  }) async {
    final response = await ApiService.patchAuthenticated(
      '/mitra/pesanan/$idPesanan/status',
      body: {'status_pesanan': statusPesanan},
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['errors'] is Map) {
        final errors = (decoded['errors'] as Map).values
            .expand((value) => value is List ? value : [value])
            .join('\n');

        throw Exception(errors);
      }

      final message = decoded is Map ? decoded['message']?.toString() : null;

      throw Exception(message ?? 'Gagal memperbarui status pesanan.');
    }
  }

  static Future<void> updatePengiriman({
    required int idPesanan,
    required String kurir,
    String? nomorResi,
    String? tautanPelacakan,
  }) async {
    final response = await ApiService.putAuthenticated(
      '/mitra/pesanan/$idPesanan/pengiriman',
      body: {
        'kurir': kurir,
        'nomor_resi': nomorResi,
        'tautan_pelacakan': tautanPelacakan,
      },
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map && decoded['errors'] is Map) {
        final errors = (decoded['errors'] as Map).values
            .expand((value) => value is List ? value : [value])
            .join('\n');

        throw Exception(errors);
      }

      final message = decoded is Map ? decoded['message']?.toString() : null;

      throw Exception(message ?? 'Gagal menyimpan informasi pengiriman.');
    }
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
