import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tw_food/models/address.dart';
import 'package:tw_food/services/address_service.dart';
import 'package:tw_food/services/api_service.dart';

const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async {
      if (call.method == 'read') return 'test-token';
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
    ApiService.resetClientForTesting();
  });

  test('AddressService mengambil dan memetakan daftar alamat dari API', () async {
    ApiService.setClientForTesting(
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/alamat'));
        expect(request.headers['authorization'], 'Bearer test-token');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id_alamat': 10,
                'id_pengguna': 5,
                'label': 'Rumah',
                'nama_penerima': 'Bimo',
                'nomor_telepon': '081234567890',
                'alamat_lengkap': 'Jalan Melati No. 10',
                'kota': 'Jember',
                'provinsi': 'Jawa Timur',
                'kode_pos': '68121',
                'latitude': null,
                'longitude': null,
                'alamat_utama': true,
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final addresses = await AddressService.getAddresses();

    expect(addresses, isA<List<Address>>());
    expect(addresses, hasLength(1));
    expect(addresses.single.idAlamat, 10);
    expect(addresses.single.idPengguna, 5);
    expect(addresses.single.label, 'Rumah');
    expect(addresses.single.namaPenerima, 'Bimo');
    expect(addresses.single.nomorTelepon, '081234567890');
    expect(addresses.single.alamatLengkap, 'Jalan Melati No. 10');
  });
}
