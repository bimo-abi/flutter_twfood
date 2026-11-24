import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/mitra_retur.dart';
import 'api_service.dart';

class MitraReturService {
  /// Mengambil bukti retur dari penyimpanan privat melalui token Sanctum.
  static Future<http.Response> getProof(int idBuktiRetur) async {
    if (idBuktiRetur <= 0) {
      throw ArgumentError.value(idBuktiRetur, 'idBuktiRetur');
    }

    final response = await ApiService.getAuthenticated(
      '/retur/bukti/$idBuktiRetur',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
      final message = decoded is Map
          ? decoded['message']?.toString()
          : null;
      throw Exception(
        message ?? 'Gagal mengambil bukti retur (${response.statusCode}).',
      );
    }

    return response;
  }

  static Future<List<MitraRetur>> fetchRetur({String? status}) async {
    final query = <String, String>{'per_page': '50'};
    if (status != null && status.isNotEmpty) {
      query['status_retur'] = status;
    }

    final uri = Uri(path: '/mitra/retur', queryParameters: query);
    final response = await ApiService.getAuthenticated(uri.toString());

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(
        message ?? 'Gagal mengambil daftar retur (${response.statusCode}).',
      );
    }

    if (decoded is! Map || decoded['data'] is! Map) {
      throw Exception('Format data retur dari server tidak sesuai.');
    }

    final pageData = decoded['data'] as Map;
    final rows = pageData['data'];
    if (rows is! List) return [];

    return rows
        .whereType<Map>()
        .map((item) => MitraRetur.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<MitraRetur> fetchDetail(int idRetur) async {
    final response = await ApiService.getAuthenticated('/mitra/retur/$idRetur');

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(
        message ?? 'Gagal mengambil detail retur (${response.statusCode}).',
      );
    }

    if (decoded is! Map || decoded['data'] is! Map) {
      throw Exception('Format detail retur dari server tidak sesuai.');
    }

    return MitraRetur.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  static Future<void> submitDecision({
    required int idRetur,
    required String keputusan,
    String? catatanMitra,
    String? alasanPenolakan,
    List<Map<String, dynamic>>? detailRetur,
  }) async {
    final body = <String, dynamic>{
      'keputusan': keputusan,
      'catatan_mitra': catatanMitra,
    };

    if (keputusan == 'ditolak') {
      body['alasan_penolakan'] = alasanPenolakan;
    }

    if (keputusan == 'disetujui') {
      body['detail_retur'] = detailRetur;
    }

    final response = await ApiService.patchAuthenticated(
      '/mitra/retur/$idRetur/keputusan',
      body: body,
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Gagal menyimpan keputusan retur.';

      if (decoded is Map) {
        message = decoded['message']?.toString() ?? message;

        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      }

      throw Exception(message);
    }
  }

  static Future<void> submitReturnInstruction({
    required int idRetur,
    required String metodePengembalian,
    required String instruksiPengembalian,
  }) async {
    final response = await ApiService.patchAuthenticated(
      '/mitra/retur/$idRetur/instruksi-pengembalian',
      body: {
        'metode_pengembalian': metodePengembalian,
        'instruksi_pengembalian': instruksiPengembalian,
      },
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Gagal menyimpan instruksi pengembalian.';

      if (decoded is Map) {
        message = decoded['message']?.toString() ?? message;

        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      }

      throw Exception(message);
    }
  }

  static Future<void> confirmReturnReceived({
    required int idRetur,
    String? catatanPenerimaan,
  }) async {
    final response = await ApiService.patchAuthenticated(
      '/mitra/retur/$idRetur/barang-diterima',
      body: {'catatan_penerimaan': catatanPenerimaan},
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Gagal mengonfirmasi penerimaan barang retur.';

      if (decoded is Map) {
        message = decoded['message']?.toString() ?? message;

        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      }

      throw Exception(message);
    }
  }


  static Future<void> inspectReturnedGoods({
    required int idRetur,
    String? catatanPemeriksaan,
    required List<Map<String, dynamic>> detailInspeksi,
  }) async {
    final response = await ApiService.patchAuthenticated(
      '/mitra/retur/$idRetur/pemeriksaan',
      body: {
        'catatan_pemeriksaan': catatanPemeriksaan,
        'detail_inspeksi': detailInspeksi,
      },
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Gagal menyimpan hasil pemeriksaan barang retur.';

      if (decoded is Map) {
        message = decoded['message']?.toString() ?? message;
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      }

      throw Exception(message);
    }
  }

}
