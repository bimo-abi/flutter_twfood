import 'dart:convert';

import '../models/mitra_retur.dart';
import 'api_service.dart';

class MitraReturService {
  static Future<List<MitraRetur>> fetchRetur({String? status}) async {
    final query = <String, String>{'per_page': '50'};
    if (status != null && status.isNotEmpty) {
      query['status_retur'] = status;
    }

    final uri = Uri(
      path: '/mitra/retur',
      queryParameters: query,
    );
    final response = await ApiService.getAuthenticated(uri.toString());

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Gagal mengambil daftar retur (${response.statusCode}).');
    }

    if (decoded is! Map || decoded['data'] is! Map) {
      throw Exception('Format data retur dari server tidak sesuai.');
    }

    final pageData = decoded['data'] as Map;
    final rows = pageData['data'];
    if (rows is! List) return [];

    return rows.whereType<Map>()
        .map((item) => MitraRetur.fromJson(
            Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<MitraRetur> fetchDetail(int idRetur) async {
    final response =
        await ApiService.getAuthenticated('/mitra/retur/$idRetur');

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Gagal mengambil detail retur (${response.statusCode}).');
    }

    if (decoded is! Map || decoded['data'] is! Map) {
      throw Exception('Format detail retur dari server tidak sesuai.');
    }

    return MitraRetur.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }
}
