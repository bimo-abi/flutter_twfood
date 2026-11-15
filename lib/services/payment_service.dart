import 'dart:convert';
import 'dart:math';

import 'api_service.dart';

class PaymentApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool statusUncertain;

  const PaymentApiException(
    this.message, {
    this.statusCode,
    this.statusUncertain = false,
  });

  @override
  String toString() => message;
}

class PaymentService {
  PaymentService._();

  static Map<String, dynamic> buildPayload({required String jenisPembayaran}) {
    if (!['penuh', 'dp', 'pelunasan'].contains(jenisPembayaran)) {
      throw ArgumentError('Jenis pembayaran tidak valid.');
    }

    return {'jenis_pembayaran': jenisPembayaran};
  }

  static String _newIdempotencyKey() {
    final random = Random.secure();
    final chars = List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return '${chars.substring(0, 8)}-${chars.substring(8, 12)}-'
        '${chars.substring(12, 16)}-${chars.substring(16, 20)}-'
        '${chars.substring(20)}';
  }

  static Future<Map<String, dynamic>> createPayment({
    required int idPesanan,
    required String jenisPembayaran,
  }) async {
    if (idPesanan <= 0) {
      throw ArgumentError('ID pesanan tidak valid.');
    }

    final response = await ApiService.postAuthenticated(
      '/pesanan/$idPesanan/pembayaran',
      body: buildPayload(jenisPembayaran: jenisPembayaran),
      extraHeaders: {'Idempotency-Key': _newIdempotencyKey()},
    );

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = decoded?['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      throw PaymentApiException(
        'Respons pembayaran dari Laravel tidak memiliki data transaksi yang valid.',
        statusCode: response.statusCode,
      );
    }

    final message = decoded?['message']?.toString();
    if (response.statusCode == 503) {
      throw PaymentApiException(
        message ??
            'Status pembuatan transaksi belum dapat dipastikan. '
                'Periksa detail pesanan sebelum mencoba kembali.',
        statusCode: 503,
        statusUncertain: true,
      );
    }

    if (response.statusCode == 401) {
      throw const PaymentApiException(
        'Sesi login berakhir. Pesanan sudah dibuat; silakan login kembali dan periksa detail pesanan.',
        statusCode: 401,
      );
    }

    throw PaymentApiException(
      message ??
          'Gagal membuat transaksi pembayaran (HTTP ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}
