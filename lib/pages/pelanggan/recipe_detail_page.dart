import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import '../../services/recipe_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeDetailPage> createState() =>
      _RecipeDetailPageState();
}

class _RecipeDetailPageState
    extends State<RecipeDetailPage> {
  late Future<Recipe> _recipeFuture;

  @override
  void initState() {
    super.initState();

    _recipeFuture =
        RecipeService.getRecipeById(widget.recipeId);
  }

  Future<void> _refreshRecipe() async {
    setState(() {
      _recipeFuture =
          RecipeService.getRecipeById(widget.recipeId);
    });

    await _recipeFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Resep'),
      ),
      body: FutureBuilder<Recipe>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil detail resep.',
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
                      onPressed: _refreshRecipe,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final recipe = snapshot.data;

          if (recipe == null) {
            return const Center(
              child: Text(
                'Data resep tidak ditemukan.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshRecipe,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildRecipeImage(recipe),

                const SizedBox(height: 20),

                Text(
                  recipe.judul,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (recipe.deskripsi != null &&
                    recipe.deskripsi!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    recipe.deskripsi!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],

                if (recipe.waktuMemasak != null &&
                    recipe.waktuMemasak!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.timer_outlined,
                    'Waktu Memasak',
                    recipe.waktuMemasak!,
                  ),
                ],

                const SizedBox(height: 28),

                _buildSectionTitle('Produk yang Digunakan'),

                const SizedBox(height: 12),

                if (recipe.produk.isEmpty)
                  const Text(
                    'Belum ada produk yang tercatat.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  )
                else
                  ...recipe.produk.map(
                    (recipeProduct) {
                      final namaProduk =
                          recipeProduct.produk
                                  ?.namaProduk ??
                              'Produk #${recipeProduct.idProduk}';

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.shopping_bag_outlined,
                          ),
                          title: Text(
                            namaProduk,
                          ),
                          subtitle: Text(
                            'Jumlah: ${recipeProduct.jumlah}',
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                _buildSectionTitle('Bahan'),

                const SizedBox(height: 12),

                _buildTextContent(
                  recipe.bahan,
                  'Belum ada informasi bahan.',
                ),

                const SizedBox(height: 20),

                _buildSectionTitle('Langkah Pembuatan'),

                const SizedBox(height: 12),

                _buildTextContent(
                  recipe.langkahPembuatan,
                  'Belum ada informasi langkah pembuatan.',
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeImage(Recipe recipe) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: recipe.foto != null &&
              recipe.foto!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                recipe.foto!,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 70,
                  );
                },
              ),
            )
          : const Icon(
              Icons.menu_book_outlined,
              size: 70,
            ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextContent(
    String? content,
    String emptyMessage,
  ) {
    if (content == null || content.isEmpty) {
      return Text(
        emptyMessage,
        style: const TextStyle(
          color: Colors.grey,
        ),
      );
    }

    return Text(
      content,
      style: const TextStyle(
        fontSize: 15,
        height: 1.6,
      ),
    );
  }
}