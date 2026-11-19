import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'api_service.dart';

class MitraVarianService {
  static Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
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

  static Future<List<ProductVariant>> getVariants(int productId) async {
    final response = await ApiService.getAuthenticated('/mitra/produk/$productId/varian');
    final data = _decode(response);
    if (response.statusCode != 200 || data['data'] is! List) {
      throw Exception(_message(data, 'Gagal mengambil daftar varian.'));
    }
    return (data['data'] as List)
        .whereType<Map>()
        .map((item) => ProductVariant.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> saveVariant({int? id, required int productId, required String name, required String unit, String? weight}) async {
    final body = <String, dynamic>{
      'nama_varian': name.trim(),
      'satuan_jual': unit.trim(),
      'berat_gram': weight == null || weight.trim().isEmpty ? null : int.tryParse(weight.trim()),
    };
    final response = id == null
        ? await ApiService.postAuthenticated('/mitra/produk/$productId/varian', body: body)
        : await ApiService.putAuthenticated('/mitra/varian/$id', body: body);
    final data = _decode(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(data, 'Varian gagal disimpan.'));
    }
  }

  static Future<void> toggleVariant(int id) async {
    final response = await ApiService.patchAuthenticated('/mitra/varian/$id/status');
    final data = _decode(response);
    if (response.statusCode != 200) throw Exception(_message(data, 'Status varian gagal diperbarui.'));
  }

  static Future<void> savePrice({int? id, required int variantId, required String type, required String price, required String minimum, String? unit}) async {
    final body = <String, dynamic>{
      'jenis_harga': type,
      'harga': int.tryParse(price.trim()),
      'minimal_pembelian': int.tryParse(minimum.trim()),
      'satuan_minimal': unit?.trim().isEmpty == true ? null : unit?.trim(),
    };
    final response = id == null
        ? await ApiService.postAuthenticated('/mitra/varian/$variantId/harga', body: body)
        : await ApiService.putAuthenticated('/mitra/harga/$id', body: body);
    final data = _decode(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(data, 'Harga gagal disimpan.'));
    }
  }

  static Future<void> togglePrice(int id) async {
    final response = await ApiService.patchAuthenticated('/mitra/harga/$id/status');
    final data = _decode(response);
    if (response.statusCode != 200) throw Exception(_message(data, 'Status harga gagal diperbarui.'));
  }

  static Future<void> updatePreOrder({
    required int variantId,
    required bool enabled,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? availableDate,
  }) async {
    String? dateOnly(DateTime? value) {
      if (value == null) return null;
      final year = value.year.toString().padLeft(4, '0');
      final month = value.month.toString().padLeft(2, '0');
      final day = value.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }

    final response = await ApiService.patchAuthenticated(
      '/mitra/varian/$variantId/pre-order',
      body: {
        'tersedia_pre_order': enabled,
        'tanggal_mulai_pre_order': enabled ? dateOnly(startDate) : null,
        'tanggal_selesai_pre_order': enabled ? dateOnly(endDate) : null,
        'estimasi_tersedia': enabled ? dateOnly(availableDate) : null,
      },
    );
    final data = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_message(data, 'Pengaturan pre-order gagal diperbarui.'));
    }
  }

  static Future<Map<String, dynamic>> updateStock(int variantId, int stock) async {
    final response = await ApiService.patchAuthenticated(
      '/mitra/varian/$variantId/stok',
      body: {'stok': stock},
    );
    final data = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_message(data, 'Stok gagal diperbarui.'));
    }
    final meta = data['meta'];
    return meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
  }

}
