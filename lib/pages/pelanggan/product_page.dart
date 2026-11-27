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
  String _selectedCategory = 'Semua';

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

  // API belum mengirim kategori, jadi kategori ditebak dari nama produk.
  // Kalau nanti API punya kolom kategori, cukup ganti isi fungsi ini.
  String _categoryOf(Product product) {
    final name = product.namaProduk.toLowerCase();
    if (name.contains('mie')) return 'Mie Instan';
    if (name.contains('krispi') ||
        name.contains('crispy') ||
        name.contains('stik') ||
        name.contains('keripik')) {
      return 'Camilan';
    }
    return 'Bumbu';
  }

  List<String> _categoriesOf(List<Product> products) {
    const order = ['Bumbu', 'Camilan', 'Mie Instan'];
    final present = products
        .where((product) => product.statusAktif)
        .map(_categoryOf)
        .toSet();
    return ['Semua', ...order.where(present.contains)];
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _searchQuery.trim().toLowerCase();

    return products.where((product) {
      if (!product.statusAktif) return false;
      if (_selectedCategory != 'Semua' &&
          _categoryOf(product) != _selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;

      final name = product.namaProduk.toLowerCase();
      final description = (product.deskripsi ?? '').toLowerCase();
      final variantMatch = product.varian.any(
        (variant) =>
            variant.statusAktif &&
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
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<Product>>(
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
                final categories = _categoriesOf(allProducts);
                if (!categories.contains(_selectedCategory)) {
                  _selectedCategory = 'Semua';
                }
                final products = _filterProducts(allProducts);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final category in categories) ...[
                            _buildCategoryChip(category),
                            const SizedBox(width: 10),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                      child: Text(
                        '${products.length} produk tersedia',
                        style: AppTextStyles.bodySmall,
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
                                  final columns =
                                      constraints.maxWidth >= 650 ? 3 : 2;
                                  return GridView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 24),
                                    itemCount: products.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 0.7,
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
          ),
        ],
      ),
    );
  }

  // Kepala halaman: banner gradasi merah-oranye berisi judul dan kolom cari.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.bannerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _decorCircle(150, 0.10),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: _decorCircle(130, 0.08),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temukan produk\nfavoritmu',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih produk dan varian sesuai kebutuhanmu.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari produk atau varian...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final selected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF07D00) : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFFF07D00) : AppColors.border,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final variants = product.varian.where((item) => item.statusAktif).toList();
    final startingPrice = _startingPrice(product);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openProduct(product),
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
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${variants.length} varian',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
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
                  padding: const EdgeInsets.fromLTRB(12, 9, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.namaProduk,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: startingPrice != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Mulai dari',
                                        style: TextStyle(
                                          fontFamily:
                                              AppTextStyles.fontFamily,
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        _formatRupiah(startingPrice),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily:
                                              AppTextStyles.fontFamily,
                                          color: AppColors.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Lihat varian',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: AppColors.secondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppColors.bannerGradient,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
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
      // Di Chrome (web), foto dari server lain bisa gagal karena aturan CORS.
      // Opsi ini memakai tag <img> biasa sebagai cadangan sehingga foto tetap tampil.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => _imagePlaceholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.secondarySoft,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentSoft, AppColors.secondarySoft],
        ),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/logo.png',
        width: 56,
        height: 56,
        errorBuilder: (_, _, _) => const Icon(
          Icons.fastfood_rounded,
          size: 42,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noProductsAtAll) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: AppColors.secondarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              noProductsAtAll
                  ? Icons.inventory_2_outlined
                  : Icons.search_off_rounded,
              size: 40,
              color: AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            noProductsAtAll
                ? 'Belum ada produk yang tersedia.'
                : 'Produk tidak ditemukan.',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSmall,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            noProductsAtAll
                ? 'Tarik layar ke bawah untuk memuat ulang.'
                : 'Coba kata kunci lain.',
            style: AppTextStyles.bodySmall,
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
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Produk belum dapat dimuat',
                style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            const Text(
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