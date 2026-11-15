import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/models/address.dart';

void main() {
  group('Address.fromJson', () {
    test('membaca alamat utama dari boolean true', () {
      final address = Address.fromJson(_addressJson(alamatUtama: true));
      expect(address.alamatUtama, isTrue);
    });

    test('membaca alamat utama dari angka 1 dan string 1', () {
      expect(
        Address.fromJson(_addressJson(alamatUtama: 1)).alamatUtama,
        isTrue,
      );
      expect(
        Address.fromJson(_addressJson(alamatUtama: '1')).alamatUtama,
        isTrue,
      );
    });

    test('membaca alamat utama false dari 0 dan null', () {
      expect(
        Address.fromJson(_addressJson(alamatUtama: 0)).alamatUtama,
        isFalse,
      );
      expect(
        Address.fromJson(_addressJson(alamatUtama: null)).alamatUtama,
        isFalse,
      );
    });

    test('membaca koordinat numerik dan string', () {
      final address = Address.fromJson(
        _addressJson(latitude: '-8.17', longitude: 113.7),
      );
      expect(address.latitude, -8.17);
      expect(address.longitude, 113.7);
    });
  });
}

Map<String, dynamic> _addressJson({
  dynamic alamatUtama = false,
  dynamic latitude,
  dynamic longitude,
}) {
  return {
    'id_alamat': 1,
    'id_pengguna': 10,
    'label': 'Rumah',
    'nama_penerima': 'Pelanggan',
    'nomor_telepon': '08123456789',
    'alamat_lengkap': 'Jl. Contoh No. 1',
    'kota': 'Jember',
    'provinsi': 'Jawa Timur',
    'kode_pos': '68100',
    'latitude': latitude,
    'longitude': longitude,
    'alamat_utama': alamatUtama,
  };
}
