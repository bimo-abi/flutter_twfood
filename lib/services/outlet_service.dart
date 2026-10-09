import 'dart:convert';

import '../models/outlet.dart';
import 'api_service.dart';

class OutletService {
  static Future<List<Outlet>> getOutlets() async {
    final response = await ApiService.get('/outlet');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data outlet. '
        'Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception(
        'Format response outlet tidak valid.',
      );
    }

    final rawData = responseData['data'];

    if (rawData is! List) {
      throw Exception(
        'Data outlet tidak valid.',
      );
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => Outlet.fromJson(item),
        )
        .toList();
  }
}