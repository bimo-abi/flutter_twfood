import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/administrative_region.dart';

/// Mengambil data wilayah administratif Indonesia dari Emsifa API v2.
///
/// Endpoint bersifat publik dan tidak membutuhkan token autentikasi.
/// Laravel tetap menjadi sumber validasi akhir saat alamat disimpan.
class RegionService {
  static const String baseUrl =
      'https://www.emsifa.com/api-wilayah-indonesia/v2';

  final http.Client _client;
  final Duration timeout;

  RegionService({
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  Future<List<AdministrativeRegion>> getProvinces() {
    return _getList('/provinces.json');
  }

  Future<List<AdministrativeRegion>> getRegencies(String provinceId) {
    _validateRegionId(provinceId);
    return _getList('/regencies/${Uri.encodeComponent(provinceId)}.json');
  }

  Future<List<AdministrativeRegion>> getDistricts(String regencyId) {
    _validateRegionId(regencyId);
    return _getList('/districts/${Uri.encodeComponent(regencyId)}.json');
  }

  Future<List<AdministrativeRegion>> getVillages(String districtId) {
    _validateRegionId(districtId);
    return _getList('/villages/${Uri.encodeComponent(districtId)}.json');
  }

  Future<List<AdministrativeRegion>> _getList(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw Exception(
        'Permintaan data wilayah melewati batas waktu. Periksa koneksi internet.',
      );
    } on http.ClientException {
      throw Exception(
        'Data wilayah tidak dapat dihubungi. Periksa koneksi internet.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data wilayah. HTTP ${response.statusCode}.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Respons API wilayah bukan JSON yang valid.');
    }

    // Emsifa v2 umumnya mengembalikan array JSON langsung. Bentuk
    // {"data": [...]} tetap diterima untuk kompatibilitas jika provider
    // atau proxy membungkus respons.
    final List<dynamic> rawItems;
    if (decoded is List) {
      rawItems = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['data'] is List) {
      rawItems = decoded['data'] as List<dynamic>;
    } else {
      throw Exception('Format respons API wilayah tidak sesuai.');
    }
    try {
      return rawItems
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Item wilayah bukan objek JSON.');
            }
            return AdministrativeRegion.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException catch (error) {
      throw Exception('Data wilayah tidak valid: ${error.message}');
    }
  }

  void _validateRegionId(String id) {
    // Format ID v2: 2 digit provinsi, lalu segmen bertitik.
    // Hanya menerima angka dan titik agar ID tidak dapat menyisipkan path.
    if (!RegExp(r'^\d{2}(?:\.\d{2}){0,2}$').hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'Kode wilayah tidak valid.');
    }
  }

  void close() {
    _client.close();
  }
}
