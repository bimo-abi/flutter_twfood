import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/services/product_service.dart';

void main() {
  test('ProductService dapat mengambil daftar produk dari Laravel', () async {
    final products = await ProductService.getProducts();

    expect(products, isA<List>());
    expect(products, isNotEmpty);

    for (final product in products) {
      expect(product.idProduk, greaterThan(0));
      expect(product.namaProduk, isNotEmpty);

      for (final variant in product.varian) {
        expect(variant.idVarian, greaterThan(0));
        expect(variant.namaVarian, isNotEmpty);

        for (final price in variant.daftarHarga) {
          expect(price.idDaftarHarga, greaterThan(0));
          expect(price.jenisHarga, isNotEmpty);
          expect(price.harga, greaterThan(0));
        }
      }
    }
  });

  test(
    'ProductService dapat mengambil detail satu produk dari Laravel',
    () async {
      final products = await ProductService.getProducts();

      expect(products, isNotEmpty);

      final productId = products.first.idProduk;

      final product = await ProductService.getProductById(productId);

      expect(product.idProduk, productId);
      expect(product.namaProduk, isNotEmpty);

      for (final variant in product.varian) {
        expect(variant.idVarian, greaterThan(0));

        for (final price in variant.daftarHarga) {
          expect(price.idDaftarHarga, greaterThan(0));
          expect(price.harga, greaterThan(0));
        }
      }
    },
  );
}
