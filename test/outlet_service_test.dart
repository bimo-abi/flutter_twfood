import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:tw_food/services/api_service.dart';
import 'package:tw_food/services/outlet_service.dart';

const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void _initializeSecureStorageMock() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (call) async => null);
}


void main() {
  _initializeSecureStorageMock();

  setUp(() {
    ApiService.setClientForTesting(
      MockClient((request) async {
        expect(request.url.path, endsWith('/outlet'));
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id_outlet': 1,
                'nama_outlet': 'Outlet TWFOOD',
                'jam_operasional': [
                  {
                    'id_jam_operasional': 10,
                    'id_outlet': 1,
                    'hari': 'Senin',
                    'jam_buka': '09:00',
                    'jam_tutup': '21:00',
                    'tutup': false,
                  }
                ],
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  tearDown(() {
    ApiService.resetClientForTesting();
  });

  test('OutletService mem-parsing daftar outlet dari respons API', () async {
    final outlets = await OutletService.getOutlets();

    expect(outlets, isA<List>());
    expect(outlets, isNotEmpty);
    expect(outlets.first.idOutlet, 1);
    expect(outlets.first.namaOutlet, 'Outlet TWFOOD');
    expect(outlets.first.jamOperasional, isNotEmpty);
    expect(outlets.first.jamOperasional.first.idJamOperasional, 10);
    expect(outlets.first.jamOperasional.first.idOutlet, 1);
    expect(outlets.first.jamOperasional.first.hari, 'Senin');
  });
}
