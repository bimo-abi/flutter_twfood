import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';
import '../models/mitra_refund.dart';

class MitraRefundService {
  static String _message(dynamic decoded, String fallback) {
    if (decoded is Map) {
      var message = decoded['message']?.toString() ?? fallback;
      final errors = decoded['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
      return message;
    }
    return fallback;
  }

  static dynamic _decode(String body) {
    try { return jsonDecode(body); } catch (_) {
      throw Exception('Respons server tidak dapat dibaca.');
    }
  }

  static Future<List<MitraRefund>> fetchRefund({String? status}) async {
    final query = <String, String>{'per_page': '50'};
    if (status != null && status.isNotEmpty) query['status_refund'] = status;
    final uri = Uri(path: '/mitra/refund', queryParameters: query);
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${uri.toString()}'),
      headers: await _headers(),
    );
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(decoded, 'Gagal mengambil daftar refund.'));
    }
    if (decoded is! Map || decoded['data'] is! Map || decoded['data']['data'] is! List) {
      throw Exception('Format daftar refund dari server tidak sesuai.');
    }
    return (decoded['data']['data'] as List)
        .whereType<Map>()
        .map((e) => MitraRefund.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<MitraRefund> fetchDetail(int idRefund) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/mitra/refund/$idRefund'),
      headers: await _headers(),
    );
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(decoded, 'Gagal mengambil detail refund.'));
    }
    if (decoded is! Map || decoded['data'] is! Map) {
      throw Exception('Format detail refund dari server tidak sesuai.');
    }
    return MitraRefund.fromJson(Map<String, dynamic>.from(decoded['data']));
  }

  static Future<void> submitManual({
    required int idRefund,
    required String hasil,
    required String metodeRefund,
    String? referensiTransaksi,
    String? catatan,
    PlatformFile? bukti,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token autentikasi tidak ditemukan. Silakan login.');
    }
    final request = http.MultipartRequest(
      'POST', Uri.parse('${ApiConfig.baseUrl}/mitra/refund/$idRefund/manual'),
    );
    request.headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    request.fields['hasil'] = hasil;
    request.fields['metode_refund'] = metodeRefund;
    if (referensiTransaksi != null && referensiTransaksi.trim().isNotEmpty) {
      request.fields['referensi_transaksi'] = referensiTransaksi.trim();
    }
    if (catatan != null && catatan.trim().isNotEmpty) request.fields['catatan'] = catatan.trim();
    if (bukti != null) {
      final bytes = await bukti.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'bukti_refund',
          bytes,
          filename: bukti.name,
        ),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(decoded, 'Gagal mencatat hasil refund manual.'));
    }
  }

  static Future<Uri?> downloadEvidence(int idPercobaan) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/mitra/refund/percobaan/$idPercobaan/bukti'),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic decoded;
      try { decoded = jsonDecode(response.body); } catch (_) {}
      throw Exception(_message(decoded, 'Gagal mengunduh bukti refund.'));
    }
    final disposition = response.headers['content-disposition'] ?? '';
    final match = RegExp(r'filename="?([^";]+)').firstMatch(disposition);
    final fileName = match?.group(1) ?? 'bukti-refund-$idPercobaan';
    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Simpan bukti refund',
      fileName: fileName,
      bytes: response.bodyBytes,
    );
    if (savedUri == null) throw Exception('Penyimpanan bukti dibatalkan.');
    return savedUri;
  }

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Token autentikasi tidak ditemukan. Silakan login.');
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }
}
