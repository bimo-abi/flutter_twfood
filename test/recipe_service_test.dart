import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:tw_food/services/api_service.dart';
import 'package:tw_food/services/recipe_service.dart';

const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void _initializeSecureStorageMock() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (call) async => null);
}


Map<String, dynamic> _recipeJson() => {
  'id_resep': 3,
  'judul': 'Jamur Crispy Pedas',
  'deskripsi': 'Resep uji',
  'bahan': 'Jamur, cabai',
  'langkah_pembuatan': 'Goreng lalu sajikan',
  'waktu_memasak': '20 menit',
  'produk': [
    {
      'id_resep_produk': 8,
      'id_resep': 3,
      'id_produk': 5,
      'jumlah': '100 gram',
    }
  ],
};

void main() {
  _initializeSecureStorageMock();

  setUp(() {
    ApiService.setClientForTesting(
      MockClient((request) async {
        if (request.url.path.endsWith('/resep/3')) {
          return http.Response(
            jsonEncode({'data': _recipeJson()}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/resep')) {
          return http.Response(
            jsonEncode({'data': [_recipeJson()]}),
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

  test('RecipeService mem-parsing daftar resep', () async {
    final recipes = await RecipeService.getRecipes();

    expect(recipes, isA<List>());
    expect(recipes, isNotEmpty);
    expect(recipes.first.idResep, 3);
    expect(recipes.first.judul, 'Jamur Crispy Pedas');
    expect(recipes.first.produk, isNotEmpty);
    expect(recipes.first.produk.first.idResepProduk, 8);
    expect(recipes.first.produk.first.idResep, 3);
    expect(recipes.first.produk.first.idProduk, 5);
    expect(recipes.first.produk.first.jumlah, '100 gram');
  });

  test('RecipeService mem-parsing detail resep berdasarkan ID', () async {
    final recipe = await RecipeService.getRecipeById(3);

    expect(recipe.idResep, 3);
    expect(recipe.judul, 'Jamur Crispy Pedas');
    expect(recipe.produk, isNotEmpty);
    expect(recipe.produk.first.idProduk, 5);
  });
}
