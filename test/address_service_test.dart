import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/services/address_service.dart';
import 'package:tw_food/models/address.dart';

void main() {
  test(
    'AddressService dapat mengambil daftar alamat dari Laravel',
    () async {
      final addresses =
          await AddressService.getAddresses();

      expect(addresses, isA<List<Address>>());

      for (final address in addresses) {
        expect(
          address.idAlamat,
          greaterThan(0),
        );

        expect(
          address.idPengguna,
          greaterThan(0),
        );

        expect(
          address.label,
          isNotEmpty,
        );

        expect(
          address.namaPenerima,
          isNotEmpty,
        );

        expect(
          address.nomorTelepon,
          isNotEmpty,
        );

        expect(
          address.alamatLengkap,
          isNotEmpty,
        );
      }
    },
  );
}