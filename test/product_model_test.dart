import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/models/product.dart';

void main() {
  group('Product status parsing', () {
    test('membaca status aktif boolean dan angka dari API', () {
      final product = Product.fromJson({
        'id_produk': 1,
        'nama_produk': 'Produk Aktif',
        'status_aktif': 1,
        'varian': [
          {
            'id_varian': 10,
            'id_produk': 1,
            'nama_varian': 'Original',
            'stok': 5,
            'tersedia_pre_order': 0,
            'status_aktif': true,
            'daftar_harga': [
              {
                'id_daftar_harga': 100,
                'id_varian': 10,
                'jenis_harga': 'ecer',
                'harga': 10000,
                'status_aktif': '1',
              },
              {
                'id_daftar_harga': 101,
                'id_varian': 10,
                'jenis_harga': 'grosir',
                'harga': 9000,
                'status_aktif': 0,
              },
            ],
          },
        ],
      });

      expect(product.statusAktif, isTrue);
      expect(product.varian.single.statusAktif, isTrue);
      expect(product.varian.single.tersediaPreOrder, isFalse);
      expect(product.varian.single.daftarHarga[0].statusAktif, isTrue);
      expect(product.varian.single.daftarHarga[1].statusAktif, isFalse);
    });

    test('status selain true atau 1 dianggap nonaktif', () {
      final product = Product.fromJson({
        'id_produk': 2,
        'nama_produk': 'Produk Nonaktif',
        'status_aktif': '0',
        'varian': [],
      });

      expect(product.statusAktif, isFalse);
    });
  });
}
