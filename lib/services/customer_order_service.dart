import 'dart:convert';

import '../models/order.dart';
import 'api_service.dart';

class CustomerOrderException implements Exception {
  final String message;
  final int? statusCode;
  const CustomerOrderException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class CustomerOrderPage {
  final List<CustomerOrder> orders;
  final int currentPage;
  final int lastPage;
  final int total;
  const CustomerOrderPage({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
  bool get hasNextPage => currentPage < lastPage;
}

class CustomerOrderService {
  CustomerOrderService._();

  static Future<CustomerOrderPage> getHistory({int page = 1}) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    final response = await ApiService.getAuthenticated('/pesanan?page=$page');
    final decoded = _decode(response.body);
    if (response.statusCode != 200) {
      throw CustomerOrderException(
        _message(decoded, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final outer = decoded?['data'];
    if (outer is! Map) {
      throw const CustomerOrderException('Format riwayat pesanan tidak valid.');
    }
    final data = Map<String, dynamic>.from(outer);
    final rawOrders = data['data'];
    if (rawOrders is! List) {
      throw const CustomerOrderException(
        'Daftar pesanan tidak ditemukan pada respons API.',
      );
    }
    return CustomerOrderPage(
      orders: rawOrders
          .whereType<Map>()
          .map((e) => CustomerOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      currentPage: _int(data['current_page'], page),
      lastPage: _int(data['last_page'], 1),
      total: _int(data['total'], rawOrders.length),
    );
  }

  static Future<CustomerOrder> getDetail(int idPesanan) async {
    if (idPesanan <= 0) throw ArgumentError.value(idPesanan, 'idPesanan');
    final response = await ApiService.getAuthenticated('/pesanan/$idPesanan');
    final decoded = _decode(response.body);
    if (response.statusCode != 200) {
      throw CustomerOrderException(
        _message(decoded, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    final data = decoded?['data'];
    if (data is! Map) {
      throw const CustomerOrderException('Format detail pesanan tidak valid.');
    }
    return CustomerOrder.fromJson(Map<String, dynamic>.from(data));
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } on FormatException {
      return null;
    }
  }

  static int _int(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _message(Map<String, dynamic>? data, int status) {
    if (status == 401) return 'Sesi login berakhir. Silakan login kembali.';
    if (status == 403 || status == 404) {
      return data?['message']?.toString() ??
          'Pesanan tidak ditemukan atau bukan milik akun ini.';
    }
    return data?['message']?.toString() ??
        'Gagal memuat pesanan (HTTP $status).';
  }
}
