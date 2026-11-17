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
      if (files.length > remaining) _message('Hanya $remaining foto pertama yang ditambahkan.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Retur')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(widget.order.nomorPesanan, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Pilih produk dan jumlah yang ingin diretur.'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Produk yang diretur', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...widget.order.items.map((item) {
              final selected = _quantities[item.idDetailPesanan] ?? 0;
              final maxQuantity = widget.maxQuantities[item.idDetailPesanan] ?? item.jumlah;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.namaProduk, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${item.namaVarian} • Dibeli ${item.jumlah}'),
                      Text(
                        'Sisa yang dapat diajukan: $maxQuantity',
                        style: TextStyle(
                          color: maxQuantity > 0 ? Colors.green : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(child: Text('Jumlah retur')),
                          SizedBox(
                            width: 130,
                            child: DropdownButtonFormField<int>(
                              initialValue: selected <= maxQuantity ? selected : 0,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(
                                maxQuantity + 1,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(i == 0 ? 'Tidak dipilih' : '$i'),
                                ),
                              ),
                              onChanged: maxQuantity == 0 || _submitting
                                  ? null
                                  : (value) => setState(
                                        () => _quantities[item.idDetailPesanan] = value ?? 0,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text('Alasan retur', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              minLines: 3,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Jelaskan alasan pengajuan retur...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) => (value == null || value.trim().length < 5) ? 'Alasan minimal 5 karakter.' : null,
            ),
            const SizedBox(height: 12),
            const Text('Bukti foto/video', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Wajib melampirkan 1–5 file. Maksimal 20 MB per file dan 50 MB total.'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(onPressed: _submitting ? null : _pickImages, icon: const Icon(Icons.photo_library_outlined), label: const Text('Pilih foto')),
                OutlinedButton.icon(onPressed: _submitting ? null : _pickVideo, icon: const Icon(Icons.video_library_outlined), label: const Text('Pilih video')),
              ],
            ),
            if (_proofs.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...List.generate(_proofs.length, (index) {
                final file = _proofs[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(file.name.toLowerCase().endsWith('.mp4') || file.name.toLowerCase().endsWith('.mov') ? Icons.videocam_outlined : Icons.image_outlined),
                  title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: _submitting ? null : () => _removeProof(index)),
                );
              }),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_outlined),
                label: Text(_submitting ? 'Mengirim pengajuan...' : 'Kirim Pengajuan Retur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
