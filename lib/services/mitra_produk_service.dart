import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'api_service.dart';

class MitraProdukService {
  static Map<String, dynamic> _decode(http.Response httpResponse) {
    final decoded = jsonDecode(httpResponse.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Format respons server tidak valid.');
  }

  static String _message(Map<String, dynamic> data, String fallback) {
    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) return message;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return fallback;
  }

  static Future<List<Product>> getProducts({String status = 'semua'}) async {
    final suffix = status == 'semua' ? '' : '?status=$status';
    final response = await ApiService.getAuthenticated('/mitra/produk$suffix');
    final data = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_message(data, 'Gagal mengambil daftar produk.'));
    }
    final raw = data['data'];
    if (raw is! List) throw Exception('Data produk dari server tidak valid.');
    return raw
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<Product> getProduct(int id) async {
    final response = await ApiService.getAuthenticated('/mitra/produk/$id');
    final data = _decode(response);
    if (response.statusCode != 200 || data['data'] is! Map) {
      throw Exception(_message(data, 'Gagal mengambil detail produk.'));
    }
    return Product.fromJson(Map<String, dynamic>.from(data['data'] as Map));
  }

  static Future<Product> saveProduct({
    int? id,
    required String namaProduk,
    String? deskripsi,
    File? foto,
  }) async {
    final fields = <String, String>{
      'nama_produk': namaProduk.trim(),
      'deskripsi': deskripsi?.trim() ?? '',
    };
    if (id != null) fields['_method'] = 'PUT';

    final response = await ApiService.multipartAuthenticated(
      id == null ? '/mitra/produk' : '/mitra/produk/$id',
      fields: fields,
      fileField: 'foto_produk',
      filePath: foto?.path,
    );
    final data = _decode(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(data, 'Produk gagal disimpan.'));
    }
    return Product.fromJson(Map<String, dynamic>.from(data['data'] as Map));
  }

  static Future<void> toggleStatus(int id) async {
    final response = await ApiService.patchAuthenticated('/mitra/produk/$id/status');
    final data = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_message(data, 'Status produk gagal diperbarui.'));
    }
  }
}
