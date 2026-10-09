import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/services/recipe_service.dart';

void main() {
  test('RecipeService dapat mengambil daftar resep dari Laravel', () async {
    final recipes = await RecipeService.getRecipes();

    expect(recipes, isA<List>());
    expect(recipes, isNotEmpty);

    for (final recipe in recipes) {
      expect(recipe.idResep, greaterThan(0));
      expect(recipe.judul, isNotEmpty);

      for (final recipeProduct in recipe.produk) {
        expect(recipeProduct.idResepProduk, greaterThan(0));

        expect(recipeProduct.idResep, recipe.idResep);

        expect(recipeProduct.idProduk, greaterThan(0));

        expect(recipeProduct.jumlah, isNotEmpty);
      }
    }
  });
  test(
    'RecipeService dapat mengambil detail satu resep dari Laravel',
    () async {
      final recipes = await RecipeService.getRecipes();

      expect(recipes, isNotEmpty);

      final recipeId = recipes.first.idResep;

      final recipe = await RecipeService.getRecipeById(recipeId);

      expect(recipe.idResep, recipeId);
      expect(recipe.judul, isNotEmpty);

      for (final recipeProduct in recipe.produk) {
        expect(recipeProduct.idResepProduk, greaterThan(0));

        expect(recipeProduct.idResep, recipe.idResep);

        expect(recipeProduct.idProduk, greaterThan(0));
      }
    },
  );
}
