import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../models/product.dart';
import '../../services/mitra_produk_service.dart';
import '../../theme/app_colors.dart';
import 'form_produk_mitra_page.dart';
import 'daftar_varian_mitra_page.dart';

class DetailProdukMitraPage extends StatefulWidget {
  const DetailProdukMitraPage({super.key, required this.productId});
  final int productId;

  @override
  State<DetailProdukMitraPage> createState() => _DetailProdukMitraPageState();
}

class _DetailProdukMitraPageState extends State<DetailProdukMitraPage> {
  late Future<Product> _future;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = MitraProdukService.getProduct(widget.productId);

  Future<void> _edit(Product product) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormProdukMitraPage(product: product)),
    );
    if (changed == true && mounted) {
      setState(_load);
      Navigator.pop(context, true);
    }
  }

  Future<void> _toggle(Product product) async {
    final action = product.statusAktif ? 'menonaktifkan' : 'mengaktifkan';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.statusAktif ? 'Nonaktifkan' : 'Aktifkan'} Produk?'),
        content: Text('Apakah kamu yakin ingin $action produk ${product.namaProduk}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Lanjutkan')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _updatingStatus = true);
    try {
      await MitraProdukService.toggleStatus(product.idProduk);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status produk berhasil ${product.statusAktif ? 'dinonaktifkan' : 'diaktifkan'}.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: FutureBuilder<Product>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(snapshot.error?.toString() ?? 'Produk tidak ditemukan.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => setState(_load), child: const Text('Coba Lagi')),
            ])));
          }
          final product = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(20), children: [
            _ProductImage(path: product.fotoProduk),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: Text(product.namaProduk, style: Theme.of(context).textTheme.headlineSmall)),
              _StatusPill(active: product.statusAktif),
            ]),
            const SizedBox(height: 10),
            Text(product.deskripsi?.isNotEmpty == true ? product.deskripsi! : 'Belum ada deskripsi produk.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 22),
            Text('Ringkasan Varian', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (product.varian.isEmpty)
              const Text('Belum ada varian. Pengelolaan varian akan tersedia pada Stage 7B.')
            else
              ...product.varian.map((variant) => Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                child: ListTile(
                  title: Text(variant.namaVarian),
                  subtitle: Text('Stok: ${variant.stok} ${variant.satuanJual ?? ''} • ${variant.statusAktif ? 'Aktif' : 'Nonaktif'}'),
                  trailing: Text('${variant.daftarHarga.where((p) => p.statusAktif).length} harga'),
                ),
              )),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => DaftarVarianMitraPage(productId: product.idProduk, productName: product.namaProduk)));
                if (mounted) setState(_load);
              },
              icon: const Icon(Icons.tune),
              label: const Text('Kelola Varian & Harga'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: () => _edit(product), icon: const Icon(Icons.edit_outlined), label: const Text('Ubah Informasi Produk')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _updatingStatus ? null : () => _toggle(product),
              icon: _updatingStatus ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(product.statusAktif ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              label: Text(product.statusAktif ? 'Nonaktifkan Produk' : 'Aktifkan Produk'),
              style: OutlinedButton.styleFrom(foregroundColor: product.statusAktif ? AppColors.error : AppColors.secondary),
            ),
          ]);
        },
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.path});
  final String? path;
  @override
  Widget build(BuildContext context) {
    final url = _imageUrl(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 220,
        color: AppColors.background,
        child: url == null ? const Icon(Icons.fastfood_outlined, size: 64, color: AppColors.textSecondary) : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.fastfood_outlined, size: 64)),
      ),
    );
  }
}

String? _imageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return '$base/storage/${path.replaceFirst(RegExp(r'^/'), '')}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: (active ? AppColors.success : AppColors.textSecondary).withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
    child: Text(active ? 'Aktif' : 'Nonaktif', style: TextStyle(color: active ? AppColors.success : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}
