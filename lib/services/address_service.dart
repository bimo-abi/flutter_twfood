import 'dart:convert';

import '../models/address.dart';
import '../models/region_selection.dart';
import 'api_service.dart';

class AddressService {
  static const int maxAddresses = 3;

  static Future<List<Address>> getAddresses() async {
    final response = await ApiService.getAuthenticated('/alamat');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil daftar alamat. Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);
    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format response alamat tidak valid.');
    }

    final rawData = responseData['data'];
    if (rawData is! List) {
      throw Exception('Data alamat tidak valid.');
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map((item) => Address.fromJson(item))
        .toList();
  }

  static Map<String, dynamic> _regionPayload(RegionSelection region) {
    return {
      'provinsi': region.province.name,
      'kota': region.regency.name,
      'kabupaten_kota': region.regency.name,
      'kecamatan': region.district.name,
      'desa_kelurahan': region.village.name,
      'kode_provinsi': region.province.id,
      'kode_kabupaten_kota': region.regency.id,
      'kode_kecamatan': region.district.id,
      'kode_desa_kelurahan': region.village.id,
    };
  }

  static Future<Address> addAddress({
    required String label,
    required String namaPenerima,
    required String nomorTelepon,
    required String alamatLengkap,
    required RegionSelection region,
    required String kodePos,
    double? latitude,
    double? longitude,
    bool alamatUtama = false,
  }) async {
    final existingAddresses = await getAddresses();
    if (existingAddresses.length >= maxAddresses) {
      throw Exception(
        'Maksimal $maxAddresses alamat dapat disimpan. '
        'Hapus alamat lama sebelum menambahkan alamat baru.',
      );
    }

    final response = await ApiService.postAuthenticated(
      '/alamat',
      body: {
        'label': label,
        'nama_penerima': namaPenerima,
        'nomor_telepon': nomorTelepon,
        'alamat_lengkap': alamatLengkap,
        ..._regionPayload(region),
        'kode_pos': kodePos,
        'latitude': latitude,
        'longitude': longitude,
        'alamat_utama': alamatUtama,
      },
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Gagal menambahkan alamat. Status: ${response.statusCode}. '
        '${_extractMessage(response.body)}',
      );
    }

    final responseData = jsonDecode(response.body);
    if (responseData is! Map<String, dynamic> ||
        responseData['data'] is! Map<String, dynamic>) {
      throw Exception('Data alamat yang dibuat tidak valid.');
    }

    return Address.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  static Future<Address> updateAddress({
    required int idAlamat,
    required String label,
    required String namaPenerima,
    required String nomorTelepon,
    required String alamatLengkap,
    required RegionSelection region,
    required String kodePos,
    double? latitude,
    double? longitude,
    bool alamatUtama = false,
  }) async {
    final response = await ApiService.putAuthenticated(
      '/alamat/$idAlamat',
      body: {
        'label': label,
        'nama_penerima': namaPenerima,
        'nomor_telepon': nomorTelepon,
        'alamat_lengkap': alamatLengkap,
        ..._regionPayload(region),
        'kode_pos': kodePos,
        'latitude': latitude,
        'longitude': longitude,
        'alamat_utama': alamatUtama,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengubah alamat. Status: ${response.statusCode}. '
        '${_extractMessage(response.body)}',
      );
    }

    final responseData = jsonDecode(response.body);
    if (responseData is! Map<String, dynamic> ||
        responseData['data'] is! Map<String, dynamic>) {
      throw Exception('Data alamat yang diubah tidak valid.');
    }

    return Address.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  static String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        return decoded['message']?.toString() ?? '';
      }
    } catch (_) {
      // Gunakan pesan generik jika respons bukan JSON.
    }
    return '';
  }

  static Future<void> deleteAddress({required int idAlamat}) async {
    final response = await ApiService.deleteAuthenticated('/alamat/$idAlamat');
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus alamat. Status: ${response.statusCode}');
    }
  }
}
