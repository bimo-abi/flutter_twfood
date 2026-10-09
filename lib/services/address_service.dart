import 'dart:convert';

import '../models/address.dart';
import 'api_service.dart';

class AddressService {
  static Future<List<Address>> getAddresses() async {
    final response = await ApiService.getAuthenticated('/alamat');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil daftar alamat. '
        'Status: ${response.statusCode}',
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

  static Future<Address> addAddress({
    required String label,
    required String namaPenerima,
    required String nomorTelepon,
    required String alamatLengkap,
    required String kota,
    required String provinsi,
    required String kodePos,
    double? latitude,
    double? longitude,
    bool alamatUtama = false,
  }) async {
    final response = await ApiService.postAuthenticated(
      '/alamat',
      body: {
        'label': label,
        'nama_penerima': namaPenerima,
        'nomor_telepon': nomorTelepon,
        'alamat_lengkap': alamatLengkap,
        'kota': kota,
        'provinsi': provinsi,
        'kode_pos': kodePos,
        'latitude': latitude,
        'longitude': longitude,
        'alamat_utama': alamatUtama,
      },
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Gagal menambahkan alamat. '
        'Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format response tambah alamat tidak valid.');
    }

    final rawData = responseData['data'];

    if (rawData is! Map<String, dynamic>) {
      throw Exception('Data alamat yang dibuat tidak valid.');
    }

    return Address.fromJson(rawData);
  }

  static Future<Address> updateAddress({
    required int idAlamat,
    required String label,
    required String namaPenerima,
    required String nomorTelepon,
    required String alamatLengkap,
    required String kota,
    required String provinsi,
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
        'kota': kota,
        'provinsi': provinsi,
        'kode_pos': kodePos,
        'latitude': latitude,
        'longitude': longitude,
        'alamat_utama': alamatUtama,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengubah alamat. '
        'Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format response ubah alamat tidak valid.');
    }

    final rawData = responseData['data'];

    if (rawData is! Map<String, dynamic>) {
      throw Exception('Data alamat yang diubah tidak valid.');
    }

    return Address.fromJson(rawData);
  }

  static Future<void> deleteAddress({required int idAlamat}) async {
    final response = await ApiService.deleteAuthenticated('/alamat/$idAlamat');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghapus alamat. '
        'Status: ${response.statusCode}',
      );
    }
  }
}
