import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../utils/product_image_url.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'product_detail_page.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late Future<List<Product>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService.getProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    final future = ProductService.getProducts();
    setState(() => _productsFuture = future);
    await future;
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _searchQuery.trim().toLowerCase();
    final activeProducts = products.where((product) => product.statusAktif);

    if (query.isEmpty) return activeProducts.toList();

    return activeProducts.where((product) {
      final name = product.namaProduk.toLowerCase();
      final description = (product.deskripsi ?? '').toLowerCase();
      final variantMatch = product.varian.any(
        (variant) => variant.statusAktif &&
            variant.namaVarian.toLowerCase().contains(query),
      );
      return name.contains(query) ||
          description.contains(query) ||
          variantMatch;
    }).toList();
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final result = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      result.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) result.write('.');
    }
    return 'Rp $result';
  }

  int? _startingPrice(Product product) {
    final prices = product.varian
        .where((variant) => variant.statusAktif)
        .expand((variant) => variant.daftarHarga)
        .where((price) => price.statusAktif)
        .map((price) => price.harga)
        .toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first;
  }

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: product.idProduk),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Jelajahi Produk'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final allProducts = snapshot.data ?? <Product>[];
          final products = _filterProducts(allProducts);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temukan Produk Favoritmu',
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pilih produk dan varian sesuai kebutuhanmu.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari produk atau varian...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${products.length} produk tersedia',
                          style: AppTextStyles.bodySmall,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.tune_rounded,
                          size: 17,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text('Katalog', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refreshProducts,
                  child: products.isEmpty
                      ? _buildEmptyState(allProducts.isEmpty)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 650 ? 3 : 2;
                            return GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: products.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.68,
                              ),
                              itemBuilder: (context, index) =>
                                  _buildProductCard(products[index]),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final variants = product.varian.where((item) => item.statusAktif).toList();
    final startingPrice = _startingPrice(product);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openProduct(product),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _productImage(product.fotoProduk),
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${variants.length} varian',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.namaProduk,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      if (startingPrice != null) ...[
                        const Text(
                          'Mulai dari',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRupiah(startingPrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ] else
                        const Text(
                          'Lihat pilihan varian',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      ProductImageUrl.resolve(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.border.withValues(alpha: 0.45),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondary,
            ),
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.border.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_outlined,
        size: 42,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildEmptyState(bool noProductsAtAll) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(
          noProductsAtAll ? Icons.inventory_2_outlined : Icons.search_off,
          size: 54,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            noProductsAtAll
                ? 'Belum ada produk yang tersedia.'
                : 'Produk tidak ditemukan.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 54,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text('Produk belum dapat dimuat', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet lalu coba kembali.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _refreshProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
            const SizedBox(height: 8),
            if (error.isNotEmpty)
              Text(
                error,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
