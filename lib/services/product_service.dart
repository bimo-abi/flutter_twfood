import 'dart:convert';

import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  static Future<List<Product>> getProducts() async {
    final response = await ApiService.get('/produk');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil produk. '
        'Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format response produk tidak valid.');
    }

    final rawData = responseData['data'];

    if (rawData is! List) {
      throw Exception('Data produk tidak valid.');
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map((item) => Product.fromJson(item))
        .toList();
  }

  static Future<Product> getProductById(int id) async {
    final response = await ApiService.get('/produk/$id');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil detail produk. '
        'Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format response detail produk tidak valid.');
    }

    final rawData = responseData['data'];

    if (rawData is! Map<String, dynamic>) {
      throw Exception('Data detail produk tidak valid.');
    }

    return Product.fromJson(rawData);
  }
}
