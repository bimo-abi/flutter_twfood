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
          // DATA KOSONG
          // ======================================================

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshProducts,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Belum ada produk yang tersedia.')),
                ],
              ),
            );
          }

          // ======================================================
          // DAFTAR PRODUK
          // ======================================================

          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailPage(productId: product.idProduk),
                      ),
                    );
                  },
                  child: _buildProductCard(product),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
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

            if (product.varian.isEmpty)
              const Text(
                'Tidak ada varian aktif.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...product.varian.map((variant) => _buildVariantItem(variant)),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantItem(ProductVariant variant) {
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
          if (variant.daftarHarga.isEmpty)
            const Text(
              'Harga belum tersedia.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...variant.daftarHarga.map(
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
