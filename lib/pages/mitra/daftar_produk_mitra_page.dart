import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../models/product.dart';
import '../../services/mitra_produk_service.dart';
import '../../theme/app_colors.dart';
import 'detail_produk_mitra_page.dart';
import 'form_produk_mitra_page.dart';

class DaftarProdukMitraPage extends StatefulWidget {
  const DaftarProdukMitraPage({super.key});

  @override
  State<DaftarProdukMitraPage> createState() => _DaftarProdukMitraPageState();
}

class _DaftarProdukMitraPageState extends State<DaftarProdukMitraPage> {
  String _filter = 'semua';
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = MitraProdukService.getProducts(status: _filter);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _openForm([Product? product]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormProdukMitraPage(product: product)),
    );
    if (changed == true && mounted) setState(_load);
  }

  Future<void> _openDetail(Product product) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DetailProdukMitraPage(productId: product.idProduk)),
    );
    if (changed == true && mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Produk')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'semua', label: Text('Semua')),
                ButtonSegment(value: 'aktif', label: Text('Aktif')),
                ButtonSegment(value: 'nonaktif', label: Text('Nonaktif')),
              ],
              selected: {_filter},
              onSelectionChanged: (value) => setState(() {
                _filter = value.first;
                _load();
              }),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageState(
                    message: snapshot.error.toString(),
                    buttonText: 'Coba Lagi',
                    onPressed: () => setState(_load),
                  );
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const _MessageState(message: 'Belum ada produk pada kategori ini.');
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 0,
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: _ProductThumbnail(path: product.fotoProduk),
                          title: Text(product.namaProduk, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text('${product.varian.length} varian • ${product.statusAktif ? 'Aktif' : 'Nonaktif'}'),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openDetail(product),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _productImageUrl(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 62,
        height: 62,
        color: AppColors.background,
        child: imageUrl == null
            ? const Icon(Icons.fastfood_outlined, color: AppColors.textSecondary)
            : Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.fastfood_outlined)),
      ),
    );
  }
}

String? _productImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return '$base/storage/${path.replaceFirst(RegExp(r'^/'), '')}';
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.buttonText, this.onPressed});
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inventory_2_outlined, size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onPressed, child: Text(buttonText!)),
            ],
          ]),
        ),
      );
}
