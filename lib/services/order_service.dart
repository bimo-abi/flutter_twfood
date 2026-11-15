import 'dart:convert';

import '../models/cart_item.dart';
import 'api_service.dart';

class OrderApiException implements Exception {
  final String message;
  final int? statusCode;

  const OrderApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class OrderService {
  OrderService._();

  static Map<String, dynamic> buildPayload({
    required String jenisPemenuhan,
    required String jenisPesanan,
    int? idAlamat,
    int? idOutlet,
    String? catatan,
    required List<CartItem> items,
  }) {
    if (!['reguler', 'pre_order'].contains(jenisPemenuhan)) {
      throw ArgumentError('Jenis pemenuhan tidak valid.');
    }
    if (!['pickup', 'delivery'].contains(jenisPesanan)) {
      throw ArgumentError('Jenis pesanan tidak valid.');
    }
    if (jenisPesanan == 'delivery' && (idAlamat == null || idAlamat <= 0)) {
      throw ArgumentError('Alamat pengiriman wajib dipilih.');
    }
    if (jenisPesanan == 'pickup' && (idOutlet == null || idOutlet <= 0)) {
      throw ArgumentError('Outlet pengambilan wajib dipilih.');
    }
    if (items.isEmpty || items.length > 50) {
      throw ArgumentError('Pesanan harus berisi 1 sampai 50 baris item.');
    }

    final variantIds = <int>{};
    for (final item in items) {
      if (!variantIds.add(item.variant.idVarian)) {
        throw ArgumentError(
          'Satu varian tidak boleh dikirim dalam dua baris jenis harga.',
        );
      }
      if (item.quantity < 1 || item.quantity > 65535) {
        throw ArgumentError('Jumlah pembelian tidak valid.');
      }
    }

    final normalizedNote = catatan?.trim();

    return {
      'jenis_pemenuhan': jenisPemenuhan,
      'jenis_pesanan': jenisPesanan,
      'id_alamat': jenisPesanan == 'delivery' ? idAlamat : null,
      'id_outlet': jenisPesanan == 'pickup' ? idOutlet : null,
      'catatan': normalizedNote == null || normalizedNote.isEmpty
          ? null
          : normalizedNote,
      'items': items
          .map(
            (item) => {
              'id_varian': item.variant.idVarian,
              'id_daftar_harga': item.price.idDaftarHarga,
              'jumlah': item.quantity,
            },
          )
          .toList(),
    };
  }

  static Future<Map<String, dynamic>> createOrder({
    required String jenisPemenuhan,
    required String jenisPesanan,
    int? idAlamat,
    int? idOutlet,
    String? catatan,
    required List<CartItem> items,
  }) async {
    final payload = buildPayload(
      jenisPemenuhan: jenisPemenuhan,
      jenisPesanan: jenisPesanan,
      idAlamat: idAlamat,
      idOutlet: idOutlet,
      catatan: catatan,
      items: items,
    );

    final response = await ApiService.postAuthenticated(
      '/pesanan',
      body: payload,
    );

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode == 201) {
      final data = decoded?['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      throw const OrderApiException(
        'Laravel menyatakan pesanan berhasil, tetapi data pesanan tidak valid.',
        statusCode: 201,
      );
    }

    throw OrderApiException(
      _extractErrorMessage(decoded, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  static String _extractErrorMessage(
    Map<String, dynamic>? response,
    int statusCode,
  ) {
    if (statusCode == 401) {
      return 'Sesi login tidak valid atau telah berakhir. Silakan login kembali.';
    }
    if (statusCode == 403) {
      return response?['message']?.toString() ??
          'Akun tidak memiliki izin untuk membuat pesanan.';
    }

    final errors = response?['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.isNotEmpty) return value;
      }
    }

    final message = response?['message']?.toString();
    if (message != null && message.isNotEmpty) return message;

    return 'Gagal membuat pesanan (HTTP $statusCode). Silakan coba kembali.';
  }
}
