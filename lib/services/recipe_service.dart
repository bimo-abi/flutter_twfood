import 'dart:convert';

import '../models/recipe.dart';
import 'api_service.dart';

class RecipeService {
  static Future<List<Recipe>> getRecipes() async {
    final response = await ApiService.get('/resep');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil resep. '
        'Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format response resep tidak valid.');
    }

    final rawData = responseData['data'];

    if (rawData is! List) {
      throw Exception('Data resep tidak valid.');
    }

    return rawData
        .whereType<Map<String, dynamic>>()
        .map((item) => Recipe.fromJson(item))
        .toList();
  }

  static Future<Recipe> getRecipeById(int id) async {
    final response = await ApiService.get('/resep/$id');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil detail resep. '
        'Status: ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format response detail resep tidak valid.');
    }

    final rawData = responseData['data'];

    if (rawData is! Map<String, dynamic>) {
      throw Exception('Data detail resep tidak valid.');
    }

    return Recipe.fromJson(rawData);
  }
}
