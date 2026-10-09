import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/services/outlet_service.dart';

void main() {
  test(
    'OutletService dapat mengambil daftar outlet dari Laravel',
    () async {
      final outlets = await OutletService.getOutlets();

      expect(outlets, isA<List>());
      expect(outlets, isNotEmpty);

      for (final outlet in outlets) {
        expect(
          outlet.idOutlet,
          greaterThan(0),
        );

        expect(
          outlet.namaOutlet,
          isNotEmpty,
        );

        for (final jam in outlet.jamOperasional) {
          expect(
            jam.idJamOperasional,
            greaterThan(0),
          );

          expect(
            jam.idOutlet,
            outlet.idOutlet,
          );

          expect(
            jam.hari,
            isNotEmpty,
          );
        }
      }
    },
  );
}