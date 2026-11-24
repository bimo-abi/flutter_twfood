import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class MitraDashboardData {
  const MitraDashboardData({
    required this.totalPesanan,
    required this.perluDiproses,
    required this.siapDiserahkan,
    required this.dalamPengiriman,
  });

  final int totalPesanan;
  final int perluDiproses;
  final int siapDiserahkan;
  final int dalamPengiriman;
}

class MitraDashboardService {
  MitraDashboardService._();

  static Future<MitraDashboardData> fetchDashboard() async {
    final responses = await Future.wait<http.Response>([
      ApiService.getAuthenticated('/mitra/pesanan?per_page=1'),
      ApiService.getAuthenticated(
        '/mitra/pesanan?status_pesanan=sedang_diproses&per_page=1',
      ),
      ApiService.getAuthenticated(
        '/mitra/pesanan?status_pesanan=siap_dikirim&per_page=1',
      ),
      ApiService.getAuthenticated(
        '/mitra/pesanan?status_pesanan=siap_diambil&per_page=1',
      ),
      ApiService.getAuthenticated(
        '/mitra/pesanan?status_pesanan=dalam_pengiriman&per_page=1',
      ),
    ]);

    for (final response in responses) {
      if (response.statusCode != 200) {
        throw _responseException(response);
      }
    }

    final allOrders = _decodePaginator(responses[0]);
    final processing = _decodePaginator(responses[1]);
    final readyDelivery = _decodePaginator(responses[2]);
    final readyPickup = _decodePaginator(responses[3]);
    final inDelivery = _decodePaginator(responses[4]);

    return MitraDashboardData(
      totalPesanan: _readTotal(allOrders),
      perluDiproses: _readTotal(processing),
      siapDiserahkan: _readTotal(readyDelivery) + _readTotal(readyPickup),
      dalamPengiriman: _readTotal(inDelivery),
    );
  }

  static Map<String, dynamic> _decodePaginator(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Format daftar pesanan dari server tidak sesuai.',
      );
    }
    return decoded['data'] as Map<String, dynamic>;
  }

  static int _readTotal(Map<String, dynamic> paginator) {
    final value = paginator['total'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Exception _responseException(http.Response response) {
    String message = 'Gagal mengambil data Dashboard Mitra.';

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {
      // Gunakan pesan umum jika respons server bukan JSON.
    }

    return Exception('$message (HTTP ${response.statusCode})');
  }
}
