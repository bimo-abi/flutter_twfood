import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tw_food/services/region_service.dart';

void main() {
  group('RegionService', () {
    test('mengambil dan membaca daftar provinsi', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          '${RegionService.baseUrl}/provinces.json',
        );
        return http.Response(
          '{"data":[{"id":"35","name":"Jawa Timur"}],"meta":{"level":1}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RegionService(client: client);
      final result = await service.getProvinces();

      expect(result, hasLength(1));
      expect(result.first.id, '35');
      expect(result.first.name, 'Jawa Timur');
      service.close();
    });

    test('menggunakan kode induk untuk mengambil kabupaten/kota', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          '${RegionService.baseUrl}/regencies/35.json',
        );
        return http.Response(
          '{"data":[{"id":"35.09","name":"Kabupaten Jember"}]}',
          200,
        );
      });

      final service = RegionService(client: client);
      final result = await service.getRegencies('35');

      expect(result.single.id, '35.09');
      expect(result.single.name, 'Kabupaten Jember');
      service.close();
    });

    test('membaca kode pos dari data desa/kelurahan', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          '${RegionService.baseUrl}/villages/35.09.01.json',
        );
        return http.Response(
          '{"data":[{"id":"35.09.01.2001","name":"Contoh Desa","postal_code":"68111"}]}',
          200,
        );
      });

      final service = RegionService(client: client);
      final result = await service.getVillages('35.09.01');

      expect(result.single.postalCode, '68111');
      service.close();
    });

    test('menolak kode wilayah dengan format tidak aman', () {
      final service = RegionService(
        client: MockClient((_) async => http.Response('{"data":[]}', 200)),
      );

      expect(
        () => service.getRegencies('../provinces'),
        throwsArgumentError,
      );
      service.close();
    });

    test('menolak respons HTTP selain 200', () async {
      final service = RegionService(
        client: MockClient((_) async => http.Response('Not found', 404)),
      );

      expect(service.getProvinces(), throwsException);
      service.close();
    });

    test('menolak format respons yang tidak sesuai', () async {
      final service = RegionService(
        client: MockClient((_) async => http.Response('{"items":[]}', 200)),
      );

      expect(service.getProvinces(), throwsException);
      service.close();
    });
  });
}
