import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:tw_food/services/api_service.dart';
import 'package:tw_food/services/product_service.dart';

const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void _initializeSecureStorageMock() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (call) async => null);
}


Map<String, dynamic> _productJson() => {
  'id_produk': 5,
  'nama_produk': 'Jamur Crispy',
  'deskripsi': 'Produk uji',
  'status_aktif': true,
  'varian': [
    {
      'id_varian': 12,
      'id_produk': 5,
      'nama_varian': '100g',
      'stok': 20,
      'tersedia_pre_order': false,
      'status_aktif': true,
      'daftar_harga': [
        {
          'id_daftar_harga': 30,
          'id_varian': 12,
          'jenis_harga': 'ecer',
          'harga': 15000,
          'status_aktif': true,
        }
      ],
      'campaign_aktif': {
        'id_promosi': 7,
        'nama_promosi': 'Campaign Uji',
        'nilai_persen': 10,
        'tanggal_mulai': '2026-11-28',
        'tanggal_selesai': '2026-11-30',
      },
    }
  ],
};

void main() {
  _initializeSecureStorageMock();

  setUp(() {
    ApiService.setClientForTesting(
      MockClient((request) async {
        if (request.url.path.endsWith('/produk/5')) {
          return http.Response(
            jsonEncode({'data': _productJson()}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/produk')) {
          return http.Response(
            jsonEncode({'data': [_productJson()]}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not found', 404);
      }),
    );
  });

  tearDown(() {
    ApiService.resetClientForTesting();
  });

  test('ProductService mem-parsing daftar produk dan Campaign', () async {
    final products = await ProductService.getProducts();

    expect(products, isA<List>());
    expect(products, isNotEmpty);

    final product = products.first;
    expect(product.idProduk, 5);
    expect(product.namaProduk, 'Jamur Crispy');
    expect(product.varian, isNotEmpty);

    final variant = product.varian.first;
    expect(variant.idVarian, 12);
    expect(variant.namaVarian, '100g');
    expect(variant.daftarHarga, isNotEmpty);
    expect(variant.daftarHarga.first.idDaftarHarga, 30);
    expect(variant.daftarHarga.first.jenisHarga, 'ecer');
    expect(variant.daftarHarga.first.harga, 15000);
    expect(variant.campaignAktif, isNotNull);
    expect(variant.campaignAktif!.idPromosi, 7);
    expect(variant.campaignAktif!.nilaiPersen, 10);
  });

  test('ProductService mem-parsing detail produk berdasarkan ID', () async {
    final product = await ProductService.getProductById(5);

    expect(product.idProduk, 5);
    expect(product.namaProduk, 'Jamur Crispy');
    expect(product.varian, isNotEmpty);
    expect(product.varian.first.campaignAktif?.namaPromosi, 'Campaign Uji');
  });
}
