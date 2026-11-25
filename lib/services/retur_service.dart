import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/order.dart';
import '../models/retur.dart';
import 'token_storage.dart';

class ReturnServiceException implements Exception {
  final String message;
  final int? statusCode;
  const ReturnServiceException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ReturnService {
  ReturnService._();

  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'avi'};

  static Future<ReturnRequestPage> getHistory({
    int page = 1,
    int perPage = 10,
  }) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    if (perPage < 1 || perPage > 50) {
      throw ArgumentError.value(perPage, 'perPage');
    }
    final response = await _get('/retur?page=$page&per_page=$perPage');
    final decoded = _decode(response.body);
    if (response.statusCode != 200) _throwApi(decoded, response.statusCode);

    final data = decoded?['data'];
    if (data is! Map || data['data'] is! List) {
      throw const ReturnServiceException('Format riwayat retur tidak valid.');
    }
    final rows = data['data'] as List;
    return ReturnRequestPage(
      returns: rows.whereType<Map>().map((e) => ReturnRequest.fromJson(Map<String, dynamic>.from(e))).toList(),
      currentPage: _toInt(data['current_page'], page),
      lastPage: _toInt(data['last_page'], 1),
      total: _toInt(data['total'], rows.length),
    );
  }


  /// Menghitung kuota retur berdasarkan riwayat yang dikirim Laravel.
  /// Laravel tetap menjadi validasi final saat pengajuan disimpan.
  static Future<ReturnEligibilitySummary> getEligibilityForOrder(
    int idPesanan,
  ) async {
    if (idPesanan <= 0) throw ArgumentError.value(idPesanan, 'idPesanan');

    const activeStatuses = {
      'diajukan',
      'diproses',
      'menunggu_persetujuan',
      'disetujui',
      'menunggu_pengembalian_barang',
      'barang_diterima',
      'sedang_diperiksa',
    };
    const pendingStatuses = {
      'diajukan',
      'diproses',
      'menunggu_persetujuan',
    };
    const approvedStatuses = {
      'disetujui',
      'menunggu_pengembalian_barang',
      'barang_diterima',
      'sedang_diperiksa',
      'selesai',
    };

    final usedQuantities = <int, int>{};
    var hasActiveRequest = false;
    String? activeReturnNumber;
    String? activeReturnStatus;

    var page = 1;
    var lastPage = 1;
    do {
      final result = await getHistory(page: page, perPage: 50);
      lastPage = result.lastPage;

      for (final request in result.returns) {
        if (request.idPesanan != idPesanan) continue;

        final status = request.statusRetur;
        if (activeStatuses.contains(status)) {
          hasActiveRequest = true;
          activeReturnNumber ??= request.nomorRetur;
          activeReturnStatus ??= status;
        }

        if (!pendingStatuses.contains(status) &&
            !approvedStatuses.contains(status)) {
          continue;
        }

        for (final item in request.items) {
          final quantity = pendingStatuses.contains(status)
              ? item.jumlahDiminta
              : (item.jumlahDisetujui ?? item.jumlahDiminta);
          if (quantity <= 0) continue;
          usedQuantities.update(
            item.idDetailPesanan,
            (current) => current + quantity,
            ifAbsent: () => quantity,
          );
        }
      }

      page++;
    } while (page <= lastPage);

    return ReturnEligibilitySummary(
      hasActiveRequest: hasActiveRequest,
      usedQuantities: usedQuantities,
      activeReturnNumber: activeReturnNumber,
      activeReturnStatus: activeReturnStatus,
    );
  }

  static Future<ReturnRequest> getDetail(int idRetur) async {
    if (idRetur <= 0) throw ArgumentError.value(idRetur, 'idRetur');
    final response = await _get('/retur/$idRetur');
    final decoded = _decode(response.body);
    if (response.statusCode != 200) _throwApi(decoded, response.statusCode);
    final data = decoded?['data'];
    if (data is! Map) throw const ReturnServiceException('Format detail retur tidak valid.');
    return ReturnRequest.fromJson(Map<String, dynamic>.from(data));
  }


  /// Mengambil bukti retur privat melalui endpoint yang memerlukan Sanctum token.
  /// File tidak diakses melalui URL publik.
  static Future<Uint8List> getProof(int idBuktiRetur) async {
    if (idBuktiRetur <= 0) {
      throw ArgumentError.value(idBuktiRetur, 'idBuktiRetur');
    }

    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ReturnServiceException(
        'Token autentikasi tidak ditemukan. Silakan login.',
      );
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/retur/bukti/$idBuktiRetur'),
      headers: {
        'Accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final decoded = _decode(utf8.decode(response.bodyBytes, allowMalformed: true));
      _throwApi(decoded, response.statusCode);
    }

    return response.bodyBytes;
  }

  /// Mengambil bukti refund dari endpoint privat khusus pemilik pesanan.
  static Future<Uint8List> getRefundProof(int idPercobaanRefund) async {
    if (idPercobaanRefund <= 0) {
      throw ArgumentError.value(idPercobaanRefund, 'idPercobaanRefund');
    }
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw const ReturnServiceException('Token autentikasi tidak ditemukan. Silakan login.');
    }
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/retur/refund/percobaan/$idPercobaanRefund/bukti/preview'),
      headers: {'Accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final decoded = _decode(utf8.decode(response.bodyBytes, allowMalformed: true));
      _throwApi(decoded, response.statusCode);
    }
    return response.bodyBytes;
  }

  static Future<ReturnRequest> submit({
    required CustomerOrder order,
    required String reason,
    required Map<int, int> quantities,
    required List<XFile> proofs,
  }) async {
    final selected = order.items.where((item) => (quantities[item.idDetailPesanan] ?? 0) > 0).toList();
    if (selected.isEmpty) throw const ReturnServiceException('Pilih minimal satu produk yang akan diretur.');
    if (reason.trim().length < 5) throw const ReturnServiceException('Alasan retur minimal 5 karakter.');
    if (proofs.isEmpty || proofs.length > 5) throw const ReturnServiceException('Lampirkan 1 sampai 5 bukti foto/video.');

    var totalBytes = 0;
    for (final proof in proofs) {
      final extension = proof.name.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(extension)) {
        throw ReturnServiceException('Format file ${proof.name} tidak didukung.');
      }
      final size = await File(proof.path).length();
      if (size > 20 * 1024 * 1024) throw ReturnServiceException('Ukuran ${proof.name} melebihi 20 MB.');
      totalBytes += size;
    }
    if (totalBytes > 50 * 1024 * 1024) throw const ReturnServiceException('Total ukuran bukti melebihi 50 MB.');

    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) throw const ReturnServiceException('Token autentikasi tidak ditemukan. Silakan login.');

    final uri = Uri.parse('${ApiConfig.baseUrl}/pesanan/${order.idPesanan}/retur');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $token'})
      ..fields['alasan_retur'] = reason.trim();

    for (var i = 0; i < selected.length; i++) {
      final item = selected[i];
      request.fields['detail_retur[$i][id_detail_pesanan]'] = item.idDetailPesanan.toString();
      request.fields['detail_retur[$i][jumlah_diminta]'] = (quantities[item.idDetailPesanan] ?? 0).toString();
    }
    for (final proof in proofs) {
      request.files.add(await http.MultipartFile.fromPath('bukti[]', proof.path, filename: proof.name));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response.body);
    if (response.statusCode != 201) _throwApi(decoded, response.statusCode);
    final data = decoded?['data'];
    if (data is! Map) throw const ReturnServiceException('Pengajuan berhasil dikirim, tetapi respons data retur tidak valid.');
    return ReturnRequest.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<http.Response> _get(String endpoint) async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) throw const ReturnServiceException('Token autentikasi tidak ditemukan. Silakan login.');
    return http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } on FormatException {
      return null;
    }
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static Never _throwApi(Map<String, dynamic>? decoded, int status) {
    final message = decoded?['message']?.toString() ??
        (status == 401 ? 'Sesi login berakhir. Silakan login kembali.' : 'Permintaan retur gagal (HTTP $status).');
    throw ReturnServiceException(message, statusCode: status);
  }
}


class ReturnEligibilitySummary {
  final bool hasActiveRequest;
  final Map<int, int> usedQuantities;
  final String? activeReturnNumber;
  final String? activeReturnStatus;

  const ReturnEligibilitySummary({
    required this.hasActiveRequest,
    required this.usedQuantities,
    required this.activeReturnNumber,
    required this.activeReturnStatus,
  });

  int remainingFor(OrderItem item) {
    final remaining = item.jumlah - (usedQuantities[item.idDetailPesanan] ?? 0);
    return remaining > 0 ? remaining : 0;
  }
}
