import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../utils/product_image_url.dart';

class RecipeDetailPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late Future<Recipe> _recipeFuture;

  @override
  void initState() {
    super.initState();

    _recipeFuture = RecipeService.getRecipeById(widget.recipeId);
  }

  Future<void> _refreshRecipe() async {
    setState(() {
      _recipeFuture = RecipeService.getRecipeById(widget.recipeId);
    });

    await _recipeFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: const Color(0x33000000),
              child: IconButton(
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Recipe>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil detail resep.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
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
            return const Center(child: Text('Data resep tidak ditemukan.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshRecipe,
            edgeOffset: 90,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHero(recipe),

                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow(recipe),

                        if (_plainText(recipe.deskripsi).isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            _plainText(recipe.deskripsi),
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 15,
                              height: 1.55,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],

                        const SizedBox(height: 26),

                        _buildSectionTitle(
                          'Produk yang Digunakan',
                          Icons.shopping_bag_outlined,
                        ),

                        const SizedBox(height: 12),

                        if (recipe.produk.isEmpty)
                          const Text(
                            'Belum ada produk yang tercatat.',
                            style: TextStyle(color: AppColors.textSecondary),
                          )
                        else
                          ...recipe.produk.map((recipeProduct) {
                            final namaProduk =
                                recipeProduct.produk?.namaProduk ??
                                'Produk #${recipeProduct.idProduk}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondarySoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      namaProduk,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${recipeProduct.jumlah}',
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 22),

                        _buildSectionTitle('Bahan', Icons.eco_outlined),

                        const SizedBox(height: 12),

                        _buildListCard(
                          _plainText(recipe.bahan),
                          'Belum ada informasi bahan.',
                          numbered: false,
                        ),

                        const SizedBox(height: 22),

                        _buildSectionTitle(
                          'Langkah Pembuatan',
                          Icons.soup_kitchen_outlined,
                        ),

                        const SizedBox(height: 12),

                        _buildListCard(
                          _plainText(recipe.langkahPembuatan),
                          'Belum ada informasi langkah pembuatan.',
                          numbered: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Foto besar dengan judul di atas foto.
  Widget _buildHero(Recipe recipe) {
    return SizedBox(
      width: double.infinity,
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildRecipeImage(recipe),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.28, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RESEP TWFOOD',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  recipe.judul,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage(Recipe recipe) {
    final foto = recipe.foto;

    if (foto == null || foto.trim().isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      ProductImageUrl.resolve(foto),
      fit: BoxFit.cover,
      // Di Chrome (web), foto dari server lain bisa gagal karena aturan CORS.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => _imagePlaceholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.secondarySoft,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.secondary,
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD79A), Color(0xFFFFE9C9)],
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 150),
        child: Image.asset(
        'assets/images/jamur_hias.png',
        fit: BoxFit.fitWidth,
        errorBuilder: (_, _, _) => const Padding(
          padding: EdgeInsets.only(bottom: 120),
          child: Icon(
            Icons.restaurant_menu_rounded,
            size: 80,
            color: AppColors.secondary,
          ),
        ),
      ),
      ),
    );
  }

  // Tiga kotak ringkas: waktu memasak, jumlah produk, jumlah langkah.
  Widget _buildStatRow(Recipe recipe) {
    final langkah = _plainText(recipe.langkahPembuatan)
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
    final waktu = (recipe.waktuMemasak != null &&
            recipe.waktuMemasak!.isNotEmpty)
        ? recipe.waktuMemasak!
        : '-';

    return Row(
      children: [
        Expanded(child: _statBox(Icons.timer_outlined, waktu, 'Waktu')),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            Icons.shopping_bag_outlined,
            '${recipe.produk.length}',
            'Produk',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            Icons.format_list_numbered_rounded,
            '$langkah',
            'Langkah',
          ),
        ),
      ],
    );
  }

  Widget _statBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.secondary),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.secondarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: AppColors.secondary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Isi teks ditampilkan dalam kartu; jika berisi beberapa baris,
  // tiap baris tampil sebagai poin (atau nomor untuk langkah).
  Widget _buildListCard(
    String? content,
    String emptyMessage, {
    required bool numbered,
  }) {
    if (content == null || content.isEmpty) {
      return Text(
        emptyMessage,
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }

    final lines = content
        .split('\n')
        .map(
          (line) => line
              .trim()
              .replaceFirst(RegExp(r'^(\d+[\.\)]\s*|[-•*]\s*)'), ''),
        )
        .where((line) => line.isNotEmpty)
        .toList();

    const textStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 15,
      height: 1.55,
      color: AppColors.textPrimary,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: lines.length <= 1
          ? Text(content, style: textStyle)
          : Column(
              children: [
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == lines.length - 1 ? 0 : 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        numbered
                            ? Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(lines[i], style: textStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// Membersihkan teks dari editor admin (tag HTML seperti <p>, <li>, <br>)
// supaya tampil sebagai teks biasa. Hanya untuk tampilan.
String _plainText(String? html) {
  if (html == null) return '';

  return html
      .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</\s*(p|li|div|h[1-6])\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\n\s*\n+'), '\n')
      .trim();
}