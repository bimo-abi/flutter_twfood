import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _productsFuture = ProductService.getProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = ProductService.getProducts();
    });

    await _productsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk TWFOOD')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ======================================================
          // ERROR
          // ======================================================

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
                      'Gagal mengambil data produk.',
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
                      onPressed: _refreshProducts,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ======================================================
          // DATA PRODUK + PENCARIAN
          // ======================================================

          final products = (snapshot.data ?? [])
              .where((product) => product.statusAktif)
              .toList();

          final normalizedQuery = _searchQuery.trim().toLowerCase();
          final filteredProducts = normalizedQuery.isEmpty
              ? products
              : products.where((product) {
                  final name = product.namaProduk.toLowerCase();
                  final description = (product.deskripsi ?? '').toLowerCase();
                  return name.contains(normalizedQuery) ||
                      description.contains(normalizedQuery);
                }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau deskripsi produk...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshProducts,
                  child: filteredProducts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Icon(
                              products.isEmpty
                                  ? Icons.inventory_2_outlined
                                  : Icons.search_off,
                              size: 56,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                products.isEmpty
                                    ? 'Belum ada produk yang tersedia.'
                                    : 'Produk tidak ditemukan.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      productId: product.idProduk,
                                    ),
                                  ),
                                );
                              },
                              child: _buildProductCard(product),
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
    final activeVariants = product.varian
        .where((variant) => variant.statusAktif)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // FOTO PRODUK
            // ====================================================

            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child:
                  product.fotoProduk != null && product.fotoProduk!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.fotoProduk!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported_outlined,
                            size: 60,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.fastfood_outlined, size: 60),
            ),

            const SizedBox(height: 16),

            // ====================================================
            // NAMA PRODUK
            // ====================================================
            Text(
              product.namaProduk,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // DESKRIPSI
            // ====================================================
            if (product.deskripsi != null && product.deskripsi!.isNotEmpty)
              Text(
                product.deskripsi!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 14),

            // ====================================================
            // VARIAN
            // ====================================================
            const Text(
              'Varian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            if (activeVariants.isEmpty)
              const Text(
                'Belum ada varian aktif.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...activeVariants.map(_buildVariantItem),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantItem(ProductVariant variant) {
    final activePrices = variant.daftarHarga
        .where((price) => price.statusAktif)
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // NAMA VARIAN
          // ======================================================

          Text(
            variant.namaVarian,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          // ======================================================
          // BERAT + SATUAN
          // ======================================================
          if (variant.beratGram != null || variant.satuanJual != null)
            Text(
              _buildVariantInfo(variant),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),

          const SizedBox(height: 8),

          // ======================================================
          // STOK
          // ======================================================
          Text('Stok: ${variant.stok}', style: const TextStyle(fontSize: 14)),

          const SizedBox(height: 10),

          // ======================================================
          // HARGA
          // ======================================================
          if (activePrices.isEmpty)
            const Text(
              'Harga aktif belum tersedia.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...activePrices.map(
              (price) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(price.jenisHarga)),
                    Text(
                      'Rp ${price.harga}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildVariantInfo(ProductVariant variant) {
    final List<String> info = [];

    if (variant.beratGram != null) {
      info.add('${variant.beratGram} gram');
    }

    if (variant.satuanJual != null && variant.satuanJual!.isNotEmpty) {
      info.add(variant.satuanJual!);
    }

    return info.join(' • ');
  }
}
