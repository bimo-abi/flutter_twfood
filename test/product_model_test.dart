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

    test('membaca informasi Campaign aktif pada varian', () {
      final product = Product.fromJson({
        'id_produk': 3,
        'nama_produk': 'Jamur Crispy',
        'status_aktif': true,
        'varian': [
          {
            'id_varian': 30,
            'id_produk': 3,
            'nama_varian': '100 gram',
            'stok': 10,
            'tersedia_pre_order': false,
            'status_aktif': true,
            'campaign_aktif': {
              'id_promosi': 7,
              'nama_promosi': 'Promo Akhir Tahun',
              'nilai_persen': 15,
              'tanggal_mulai': '2026-11-28',
              'tanggal_selesai': '2026-12-31',
            },
            'daftar_harga': [],
          },
        ],
      });

      expect(product.varian.single.campaignAktif?.idPromosi, 7);
      expect(product.varian.single.campaignAktif?.nilaiPersen, 15);
      expect(product.varian.single.campaignAktif?.namaPromosi, 'Promo Akhir Tahun');
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
