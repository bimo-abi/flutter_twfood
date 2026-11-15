import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/services/payment_service.dart';

void main() {
  group('PaymentService.buildPayload', () {
    test('membuat payload pembayaran penuh', () {
      expect(
        PaymentService.buildPayload(jenisPembayaran: 'penuh'),
        {'jenis_pembayaran': 'penuh'},
      );
    });

    test('membuat payload DP', () {
      expect(
        PaymentService.buildPayload(jenisPembayaran: 'dp'),
        {'jenis_pembayaran': 'dp'},
      );
    });

    test('menolak jenis pembayaran yang tidak dikenal', () {
      expect(
        () => PaymentService.buildPayload(jenisPembayaran: 'tunai'),
        throwsArgumentError,
      );
    });
  });
}
