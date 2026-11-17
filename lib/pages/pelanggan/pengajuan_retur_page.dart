import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/order.dart';
import '../../services/retur_service.dart';
import 'riwayat_retur_page.dart';

class PengajuanReturPage extends StatefulWidget {
  final CustomerOrder order;
  final Map<int, int> maxQuantities;

  const PengajuanReturPage({
    super.key,
    required this.order,
    required this.maxQuantities,
  });

  @override
  State<PengajuanReturPage> createState() => _PengajuanReturPageState();
}

class _PengajuanReturPageState extends State<PengajuanReturPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _picker = ImagePicker();
  final Map<int, int> _quantities = {};
  final List<XFile> _proofs = [];
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final remaining = 5 - _proofs.length;
      if (remaining <= 0) {
        _message('Maksimal 5 file bukti.');
        return;
      }
      final files = await _picker.pickMultiImage();
      if (!mounted || files.isEmpty) return;
      setState(() => _proofs.addAll(files.take(remaining)));
      if (files.length > remaining) {
        _message('Hanya $remaining foto pertama yang ditambahkan.');
      }
    } catch (e) {
      _message('Tidak dapat memilih foto: $e');
    }
  }

  Future<void> _pickVideo() async {
    if (_proofs.length >= 5) {
      _message('Maksimal 5 file bukti.');
      return;
    }
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (!mounted || file == null) return;
      setState(() => _proofs.add(file));
    } catch (e) {
      _message('Tidak dapat memilih video: $e');
    }
  }

  void _removeProof(int index) => setState(() => _proofs.removeAt(index));

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final selected = _quantities.values.any((value) => value > 0);
    if (!selected) {
      _message('Pilih jumlah minimal satu produk yang akan diretur.');
      return;
    }
    if (_proofs.isEmpty) {
      _message('Lampirkan minimal satu bukti foto atau video.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ReturnService.submit(
        order: widget.order,
        reason: _reasonController.text,
        quantities: _quantities,
        proofs: List<XFile>.unmodifiable(_proofs),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan retur berhasil dikirim.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RiwayatReturPage()),
      );
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  bool _isVideo(XFile file) {
    final name = file.name.toLowerCase();
    return name.endsWith('.mp4') || name.endsWith('.mov') || name.endsWith('.m4v') || name.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Retur')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _sectionCard(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nomor Pesanan', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 3),
                        Text(widget.order.nomorPesanan, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('Pilih produk dan jumlah yang ingin diajukan.', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Produk yang diretur', subtitle: 'Pilih jumlah untuk setiap produk.'),
                  const SizedBox(height: 12),
                  ...widget.order.items.map((item) {
                    final selected = _quantities[item.idDetailPesanan] ?? 0;
                    final maxQuantity = widget.maxQuantities[item.idDetailPesanan] ?? item.jumlah;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.namaProduk, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('${item.namaVarian} • Dibeli ${item.jumlah}', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Maksimal dapat diretur: $maxQuantity',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: maxQuantity > 0 ? theme.colorScheme.secondary : theme.disabledColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 142,
                                child: DropdownButtonFormField<int>(
                                  initialValue: selected <= maxQuantity ? selected : 0,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  items: List.generate(
                                    maxQuantity + 1,
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(i == 0 ? 'Tidak dipilih' : '$i unit'),
                                    ),
                                  ),
                                  onChanged: maxQuantity == 0 || _submitting
                                      ? null
                                      : (value) => setState(() => _quantities[item.idDetailPesanan] = value ?? 0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Alasan retur', subtitle: 'Jelaskan kendala atau kondisi produk yang diterima.'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Produk rusak saat diterima...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => (value == null || value.trim().length < 5) ? 'Alasan minimal 5 karakter.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Bukti foto atau video', subtitle: 'Wajib melampirkan 1–5 file bukti.'),
                  const SizedBox(height: 8),
                  Text('Maksimal 20 MB per file dan 50 MB total.', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _submitting ? null : _pickImages,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pilih foto'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _submitting ? null : _pickVideo,
                        icon: const Icon(Icons.video_library_outlined),
                        label: const Text('Pilih video'),
                      ),
                    ],
                  ),
                  if (_proofs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...List.generate(_proofs.length, (index) {
                      final file = _proofs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(_isVideo(file) ? Icons.videocam_outlined : Icons.image_outlined, color: theme.colorScheme.secondary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            IconButton(
                              tooltip: 'Hapus bukti',
                              icon: const Icon(Icons.close),
                              onPressed: _submitting ? null : () => _removeProof(index),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 4),
                  Text('${_proofs.length}/5 file dipilih', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                label: Text(_submitting ? 'Mengirim pengajuan...' : 'Kirim Pengajuan Retur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
