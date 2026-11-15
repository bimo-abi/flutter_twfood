import 'package:flutter_test/flutter_test.dart';

import 'package:tw_food/models/cart_item.dart';
import 'package:tw_food/models/product.dart';
import 'package:tw_food/services/order_service.dart';

CartItem _item({
  int variantId = 10,
  int priceId = 20,
  int quantity = 2,
}) {
  return CartItem(
    product: const Product(
      idProduk: 1,
      namaProduk: 'Produk Uji',
      statusAktif: true,
      varian: [],
    ),
    variant: ProductVariant(
      idVarian: variantId,
      idProduk: 1,
      namaVarian: 'Reguler',
      stok: 10,
      tersediaPreOrder: false,
      statusAktif: true,
      daftarHarga: [],
    ),
    price: ProductPrice(
      idDaftarHarga: priceId,
      idVarian: variantId,
      jenisHarga: 'ecer',
      harga: 10000,
      statusAktif: true,
    ),
    quantity: quantity,
  );
}

void main() {
  group('OrderService.buildPayload', () {
    test('membentuk payload delivery sesuai kontrak Laravel', () {
      final payload = OrderService.buildPayload(
        jenisPemenuhan: 'reguler',
        jenisPesanan: 'delivery',
        idAlamat: 7,
        catatan: '  Tolong dikemas rapi  ',
        items: [_item()],
      );

      expect(payload['jenis_pemenuhan'], 'reguler');
      expect(payload['jenis_pesanan'], 'delivery');
      expect(payload['id_alamat'], 7);
      expect(payload['id_outlet'], isNull);
      expect(payload['catatan'], 'Tolong dikemas rapi');
      expect(payload['items'], [
        {'id_varian': 10, 'id_daftar_harga': 20, 'jumlah': 2},
      ]);
    });

    test('membentuk payload pickup sesuai kontrak Laravel', () {
      final payload = OrderService.buildPayload(
        jenisPemenuhan: 'pre_order',
        jenisPesanan: 'pickup',
        idOutlet: 3,
        items: [_item()],
      );

      expect(payload['jenis_pemenuhan'], 'pre_order');
      expect(payload['jenis_pesanan'], 'pickup');
      expect(payload['id_alamat'], isNull);
      expect(payload['id_outlet'], 3);
      expect(payload['catatan'], isNull);
    });

    test('menolak delivery tanpa alamat', () {
      expect(
        () => OrderService.buildPayload(
          jenisPemenuhan: 'reguler',
          jenisPesanan: 'delivery',
          items: [_item()],
        ),
        throwsArgumentError,
      );
    });

    test('menolak pickup tanpa outlet', () {
      expect(
        () => OrderService.buildPayload(
          jenisPemenuhan: 'reguler',
          jenisPesanan: 'pickup',
          items: [_item()],
        ),
        throwsArgumentError,
      );
    });

    test('menolak varian sama dalam dua baris harga', () {
      expect(
        () => OrderService.buildPayload(
          jenisPemenuhan: 'reguler',
          jenisPesanan: 'pickup',
          idOutlet: 3,
          items: [
            _item(variantId: 10, priceId: 20),
            _item(variantId: 10, priceId: 21),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
