import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() =>
      _ProductDetailPageState();
}

class _ProductDetailPageState
    extends State<ProductDetailPage> {
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();

    _productFuture =
        ProductService.getProductById(widget.productId);
  }

  Future<void> _refreshProduct() async {
    setState(() {
      _productFuture =
          ProductService.getProductById(widget.productId);
    });

    await _productFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
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
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil detail produk.',
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
                      onPressed: _refreshProduct,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = snapshot.data;

          if (product == null) {
            return const Center(
              child: Text(
                'Data produk tidak ditemukan.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshProduct,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProductImage(product),

                const SizedBox(height: 20),

                Text(
                  product.namaProduk,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (product.deskripsi != null &&
                    product.deskripsi!.isNotEmpty)
                  Text(
                    product.deskripsi!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                const SizedBox(height: 24),

                const Text(
                  'Varian Produk',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (product.varian.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada varian aktif.',
                      ),
                    ),
                  )
                else
                  ...product.varian.map(
                    (variant) =>
                        _buildVariantCard(variant),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: product.fotoProduk != null &&
              product.fotoProduk!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                product.fotoProduk!,
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
              Icons.fastfood_outlined,
              size: 70,
            ),
    );
  }

  Widget _buildVariantCard(
    ProductVariant variant,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              variant.namaVarian,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (variant.beratGram != null ||
                variant.satuanJual != null)
              Text(
                _buildVariantInfo(variant),
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

            const SizedBox(height: 10),

            Text(
              'Stok: ${variant.stok}',
              style: const TextStyle(
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 12),

            if (variant.tersediaPreOrder)
              const Text(
                'Tersedia Pre-Order',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (variant.tanggalMulaiPreOrder != null)
              Text(
                'Mulai Pre-Order: '
                '${_formatDate(variant.tanggalMulaiPreOrder!)}',
              ),

            if (variant.tanggalSelesaiPreOrder != null)
              Text(
                'Selesai Pre-Order: '
                '${_formatDate(variant.tanggalSelesaiPreOrder!)}',
              ),

            if (variant.estimasiTersedia != null)
              Text(
                'Estimasi tersedia: '
                '${_formatDate(variant.estimasiTersedia!)}',
              ),

            const SizedBox(height: 14),

            const Text(
              'Harga',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (variant.daftarHarga.isEmpty)
              const Text(
                'Harga belum tersedia.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              )
            else
              ...variant.daftarHarga.map(
                (price) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          price.jenisHarga,
                        ),
                      ),
                      Text(
                        'Rp ${price.harga}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildVariantInfo(
    ProductVariant variant,
  ) {
    final List<String> info = [];

    if (variant.beratGram != null) {
      info.add('${variant.beratGram} gram');
    }

    if (variant.satuanJual != null &&
        variant.satuanJual!.isNotEmpty) {
      info.add(variant.satuanJual!);
    }

    return info.join(' • ');
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day-$month-$year';
  }
}