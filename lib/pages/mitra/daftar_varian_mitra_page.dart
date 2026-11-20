import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/mitra_varian_service.dart';
import '../../theme/app_colors.dart';

class DaftarVarianMitraPage extends StatefulWidget {
  const DaftarVarianMitraPage({super.key, required this.productId, required this.productName});
  final int productId;
  final String productName;

  @override
  State<DaftarVarianMitraPage> createState() => _DaftarVarianMitraPageState();
}

class _DaftarVarianMitraPageState extends State<DaftarVarianMitraPage> {
  late Future<List<ProductVariant>> _future;
  bool _busy = false;

  @override
  void initState() { super.initState(); _load(); }
  void _load() => _future = MitraVarianService.getVariants(widget.productId);

  Future<void> _refresh() async { setState(_load); await _future; }

  Future<void> _variantDialog({ProductVariant? variant}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: variant?.namaVarian ?? '');
    final weight = TextEditingController(text: variant?.beratGram?.toString() ?? '');
    final unit = TextEditingController(text: variant?.satuanJual ?? '');
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(variant == null ? 'Tambah Varian' : 'Ubah Varian'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama varian'), textCapitalization: TextCapitalization.words, validator: (v) => v == null || v.trim().isEmpty ? 'Nama varian wajib diisi.' : null),
        TextFormField(controller: weight, decoration: const InputDecoration(labelText: 'Berat (gram)', hintText: 'Opsional'), keyboardType: TextInputType.number, validator: (v) => v != null && v.trim().isNotEmpty && (int.tryParse(v.trim()) == null || int.parse(v.trim()) < 0 || int.parse(v.trim()) > 65535) ? 'Berat harus 0–65.535 gram.' : null),
        TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'Satuan jual', hintText: 'contoh: pcs, bungkus'), validator: (v) => v == null || v.trim().isEmpty ? 'Satuan jual wajib diisi.' : null),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Simpan'))],
    ));
    if (saved != true) return;
    setState(() => _busy = true);
    try {
      await MitraVarianService.saveVariant(id: variant?.idVarian, productId: widget.productId, name: name.text, unit: unit.text, weight: weight.text);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Varian berhasil disimpan.')));
    } catch (e) { if (mounted) _showError(e); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _priceDialog(ProductVariant variant, {ProductPrice? price}) async {
    final formKey = GlobalKey<FormState>();
    String type = price?.jenisHarga ?? (variant.daftarHarga.any((p) => p.jenisHarga == 'ecer') ? 'grosir' : 'ecer');
    final amount = TextEditingController(text: price?.harga.toString() ?? '');
    final minimum = TextEditingController(text: price?.minimalPembelian?.toString() ?? '1');
    final unit = TextEditingController(text: price?.satuanMinimal ?? variant.satuanJual ?? '');
    final availableTypes = ['ecer', 'grosir'].where((t) => price != null || !variant.daftarHarga.any((p) => p.jenisHarga == t)).toList();
    if (availableTypes.isEmpty && price == null) { _showError(Exception('Harga ecer dan grosir sudah tersedia untuk varian ini.')); return; }
    if (price != null) type = price.jenisHarga;
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(price == null ? 'Tambah Harga' : 'Ubah Harga'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Jenis harga'), items: availableTypes.map((t) => DropdownMenuItem(value: t, child: Text(t == 'ecer' ? 'Retail / Ecer' : 'Grosir'))).toList(), onChanged: (v) { if (v != null) setDialogState(() => type = v); }),
        TextFormField(controller: amount, decoration: const InputDecoration(labelText: 'Harga (Rp)'), keyboardType: TextInputType.number, validator: (v) { final n = int.tryParse(v?.trim() ?? ''); return n == null || n < 100 || n > 16777215 ? 'Harga harus Rp100–Rp16.777.215.' : null; }),
        TextFormField(controller: minimum, decoration: const InputDecoration(labelText: 'Minimal pembelian'), keyboardType: TextInputType.number, validator: (v) { final n = int.tryParse(v?.trim() ?? ''); return n == null || n < 1 || n > 65535 ? 'Minimal pembelian harus 1–65.535.' : null; }),
        TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'Satuan minimal', hintText: 'Opsional')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Simpan'))],
    )));
    if (saved != true) return;
    setState(() => _busy = true);
    try {
      await MitraVarianService.savePrice(id: price?.idDaftarHarga, variantId: variant.idVarian, type: type, price: amount.text, minimum: minimum.text, unit: unit.text);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga berhasil disimpan.')));
    } catch (e) { if (mounted) _showError(e); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _stockDialog(ProductVariant variant) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: variant.stok.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Atur Stok ${variant.namaVarian}'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Stok fisik saat ini: ${variant.stok} ${variant.satuanJual ?? ''}'),
            const SizedBox(height: 10),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stok fisik baru', helperText: 'Jumlah stok fisik, bukan stok setelah reservasi.'),
              validator: (value) {
                final number = int.tryParse(value?.trim() ?? '');
                if (number == null || number < 0 || number > 16777215) {
                  return 'Stok harus berupa angka 0–16.777.215.';
                }
                return null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Simpan')),
        ],
      ),
    );
    if (saved != true) return;
    setState(() => _busy = true);
    try {
      final stock = int.parse(controller.text.trim());
      final meta = await MitraVarianService.updateStock(variant.idVarian, stock);
      if (!mounted) return;
      setState(_load);
      final available = meta['stok_tersedia'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(available == null
            ? 'Stok berhasil diperbarui.'
            : 'Stok berhasil diperbarui. Stok tersedia: $available.'),
      ));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<void> _preOrderDialog(ProductVariant variant) async {
    bool enabled = variant.tersediaPreOrder;
    DateTime? start = variant.tanggalMulaiPreOrder;
    DateTime? end = variant.tanggalSelesaiPreOrder;
    DateTime? available = variant.estimasiTersedia;

    String formatDate(DateTime? value) {
      if (value == null) return 'Pilih tanggal';
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    }

    Future<DateTime?> chooseDate(
      BuildContext context,
      DateTime? current, {
      DateTime? firstDate,
    }) {
      final today = DateTime.now();
      final minimum = firstDate ?? DateTime(today.year, today.month, today.day);
      final initial = current != null && !current.isBefore(minimum)
          ? current
          : minimum;
      return showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: minimum,
        lastDate: DateTime(2100),
      );
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pengaturan Pre-order • ${variant.namaVarian}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktifkan Pre-order'),
                  value: enabled,
                  onChanged: (value) => setDialogState(() {
                    enabled = value;
                    if (!enabled) {
                      start = null;
                      end = null;
                      available = null;
                    }
                  }),
                ),
                if (enabled) ...[
                  const SizedBox(height: 8),
                  const Text('Tanggal mulai pre-order'),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await chooseDate(context, start);
                      if (picked != null) setDialogState(() => start = picked);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(formatDate(start)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tanggal selesai pre-order'),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final minimum = start?.add(const Duration(days: 1));
                      final picked = await chooseDate(context, end, firstDate: minimum);
                      if (picked != null) setDialogState(() => end = picked);
                    },
                    icon: const Icon(Icons.event),
                    label: Text(formatDate(end)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Estimasi produk tersedia'),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final minimum = end?.add(const Duration(days: 1));
                      final picked = await chooseDate(context, available, firstDate: minimum);
                      if (picked != null) setDialogState(() => available = picked);
                    },
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: Text(formatDate(available)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimasi tersedia harus setelah tanggal selesai pre-order.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (enabled &&
                    (start == null ||
                        end == null ||
                        available == null ||
                        !end!.isAfter(start!) ||
                        !available!.isAfter(end!))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lengkapi tanggal dengan urutan yang benar.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    await _perform(
      () => MitraVarianService.updatePreOrder(
        variantId: variant.idVarian,
        enabled: enabled,
        startDate: start,
        endDate: end,
        availableDate: available,
      ),
      enabled
          ? 'Pengaturan pre-order berhasil disimpan.'
          : 'Pre-order berhasil dinonaktifkan.',
    );
  }

  Future<void> _toggleVariant(ProductVariant variant) async {
    final ok = await _confirm('${variant.statusAktif ? 'Nonaktifkan' : 'Aktifkan'} varian ${variant.namaVarian}?');
    if (!ok) return;
    await _perform(() => MitraVarianService.toggleVariant(variant.idVarian), 'Status varian berhasil diperbarui.');
  }

  Future<void> _togglePrice(ProductPrice price) async {
    final ok = await _confirm('${price.statusAktif ? 'Nonaktifkan' : 'Aktifkan'} harga ${price.jenisHarga}?');
    if (!ok) return;
    await _perform(() => MitraVarianService.togglePrice(price.idDaftarHarga), 'Status harga berhasil diperbarui.');
  }

  Future<bool> _confirm(String message) async => await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Konfirmasi'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ya'))])) ?? false;

  Future<void> _perform(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try { await action(); if (!mounted) return; setState(_load); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success))); }
    catch (e) { if (mounted) _showError(e); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));

  String _rupiah(int value) => 'Rp${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Varian & Harga')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : () => _variantDialog(), icon: const Icon(Icons.add), label: const Text('Tambah Varian')),
    body: Stack(children: [
      FutureBuilder<List<ProductVariant>>(future: _future, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(snapshot.error.toString(), textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: () => setState(_load), child: const Text('Coba Lagi'))])));
        final variants = snapshot.data ?? [];
        if (variants.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary), const SizedBox(height: 12), const Text('Belum ada varian untuk produk ini.'), const SizedBox(height: 12), FilledButton.icon(onPressed: () => _variantDialog(), icon: const Icon(Icons.add), label: const Text('Tambah Varian'))])));
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Text(
                widget.productName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ...variants.map(_variantCard),
            ],
          ),
        );
      }),
      if (_busy) const Positioned.fill(child: ColoredBox(color: Color(0x33000000), child: Center(child: CircularProgressIndicator()))),
    ]),
  );

  Widget _variantCard(ProductVariant variant) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  variant.namaVarian,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (variant.statusAktif ? AppColors.success : AppColors.textSecondary)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  variant.statusAktif ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    color: variant.statusAktif ? AppColors.success : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${variant.beratGram == null ? '-' : '${variant.beratGram} gram'}  •  ${variant.satuanJual ?? '-'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stok fisik: ${variant.stok} ${variant.satuanJual ?? ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _stockDialog(variant),
                  child: const Text('Atur'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 18,
                      color: variant.tersediaPreOrder ? AppColors.secondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        variant.tersediaPreOrder ? 'Pre-order aktif' : 'Pre-order nonaktif',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _preOrderDialog(variant),
                      child: const Text('Atur'),
                    ),
                  ],
                ),
                if (variant.tersediaPreOrder)
                  Padding(
                    padding: const EdgeInsets.only(left: 26, bottom: 2),
                    child: Text(
                      '${variant.tanggalMulaiPreOrder?.toString().split(' ').first ?? '-'} s.d. ${variant.tanggalSelesaiPreOrder?.toString().split(' ').first ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 0,
            children: [
              TextButton.icon(
                onPressed: _busy ? null : () => _variantDialog(variant: variant),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Ubah'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _toggleVariant(variant),
                icon: Icon(
                  variant.statusAktif ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(variant.statusAktif ? 'Nonaktifkan' : 'Aktifkan'),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Daftar Harga', style: Theme.of(context).textTheme.titleSmall),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _priceDialog(variant),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
          if (variant.daftarHarga.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Belum ada harga.'),
            ),
          ...variant.daftarHarga.map((price) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.jenisHarga == 'ecer' ? 'Retail / Ecer' : 'Grosir',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_rupiah(price.harga)}  •  Minimal ${price.minimalPembelian ?? 1} ${price.satuanMinimal ?? variant.satuanJual ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        price.statusAktif ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          color: price.statusAktif ? AppColors.success : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _priceDialog(variant, price: price);
                    if (v == 'status') _togglePrice(price);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Ubah harga')),
                    PopupMenuItem(
                      value: 'status',
                      child: Text(price.statusAktif ? 'Nonaktifkan' : 'Aktifkan'),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    ),
  );
}
