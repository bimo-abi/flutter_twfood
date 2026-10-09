import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import 'recipe_detail_page.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();

    _recipesFuture = RecipeService.getRecipes();
  }

  Future<void> _refreshRecipes() async {
    setState(() {
      _recipesFuture = RecipeService.getRecipes();
    });

    await _recipesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resep TWFOOD')),
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil data resep.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshRecipes,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final recipes = snapshot.data ?? [];

          if (recipes.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshRecipes,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Belum ada resep yang tersedia.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshRecipes,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecipeDetailPage(recipeId: recipe.idResep),
                      ),
                    );
                  },
                  child: _buildRecipeCard(recipe),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecipeImage(recipe),

            const SizedBox(height: 16),

            Text(
              recipe.judul,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            if (recipe.deskripsi != null && recipe.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                recipe.deskripsi!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],

            if (recipe.waktuMemasak != null &&
                recipe.waktuMemasak!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    recipe.waktuMemasak!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],

            if (recipe.produk.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Produk yang digunakan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...recipe.produk.map((recipeProduct) {
                final namaProduk =
                    recipeProduct.produk?.namaProduk ??
                    'Produk #${recipeProduct.idProduk}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $namaProduk — '
                    '${recipeProduct.jumlah}',
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),

            Text(
              _buildRecipePreview(recipe),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage(Recipe recipe) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: recipe.foto != null && recipe.foto!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                recipe.foto!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 60,
                  );
                },
              ),
            )
          : const Icon(Icons.menu_book_outlined, size: 60),
    );
  }

  String _buildRecipePreview(Recipe recipe) {
    if (recipe.langkahPembuatan != null &&
        recipe.langkahPembuatan!.isNotEmpty) {
      return recipe.langkahPembuatan!;
    }

    if (recipe.bahan != null && recipe.bahan!.isNotEmpty) {
      return recipe.bahan!;
    }

    return 'Belum ada informasi bahan atau langkah pembuatan.';
  }
}
