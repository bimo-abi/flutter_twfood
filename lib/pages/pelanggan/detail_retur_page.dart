import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/retur.dart';
import '../../services/retur_service.dart';

class DetailReturPage extends StatefulWidget {
  final int idRetur;
  const DetailReturPage({super.key, required this.idRetur});

  @override
  State<DetailReturPage> createState() => _DetailReturPageState();
}

class _DetailReturPageState extends State<DetailReturPage> {
  late Future<ReturnRequest> _future;

  @override
  void initState() {
    super.initState();
    _future = ReturnService.getDetail(widget.idRetur);
  }

  void _reload() => setState(() => _future = ReturnService.getDetail(widget.idRetur));

  Future<void> _viewProof(ReturnProof proof) async {
    try {
      final Uint8List bytes = await ReturnService.getProof(proof.idBuktiRetur);
      if (!mounted) return;

      final isVideo = proof.jenisMedia.toLowerCase().contains('video');
      if (isVideo) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bukti video'),
            content: const Text(
              'Bukti video berhasil diambil dari penyimpanan privat. '
              'Pemutaran video belum tersedia pada aplikasi ini.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka bukti retur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Retur')),
      body: FutureBuilder<ReturnRequest>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(snapshot.error.toString(), textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _reload, child: const Text('Coba lagi'))])));
          final item = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _section('Informasi Retur', [
                  _line('Nomor retur', item.nomorRetur),
                  _line('Nomor pesanan', item.nomorPesanan ?? item.idPesanan.toString()),
                  _line('Status retur', _status(item.statusRetur)),
                  _line('Diajukan pada', _date(item.diajukanPada)),
                  _line('Status pengembalian dana', _status(item.statusPengembalianDana)),
                  _line('Nominal pengembalian', _money(item.nominalPengembalian)),
                ]),
                const SizedBox(height: 12),
                _section('Alasan Pengajuan', [Text(item.alasanRetur)]),
                if (item.alasanPenolakan != null && item.alasanPenolakan!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _section('Alasan Penolakan', [Text(item.alasanPenolakan!)]),
                ],
                if (item.catatanMitra != null && item.catatanMitra!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _section('Catatan Mitra', [Text(item.catatanMitra!)]),
                ],
                const SizedBox(height: 12),
                _section('Produk Diretur', item.items.isEmpty
                    ? [const Text('Rincian produk belum tersedia.')]
                    : item.items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${e.namaProduk ?? 'Detail produk #${e.idDetailPesanan}'}${e.namaVarian == null ? '' : ' • ${e.namaVarian}'}\nDiminta: ${e.jumlahDiminta} • Disetujui: ${e.jumlahDisetujui?.toString() ?? 'Menunggu'}'))).toList()),
                const SizedBox(height: 12),
                _section('Bukti Terlampir', [
                  if (item.proofs.isEmpty)
                    const Text('Tidak ada bukti yang tercatat.')
                  else ...[
                    Text('${item.proofs.length} file bukti telah dikirim.'),
                    const SizedBox(height: 8),
                    ...item.proofs.map(
                      (proof) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          proof.jenisMedia.toLowerCase().contains('video')
                              ? Icons.videocam_outlined
                              : Icons.image_outlined,
                        ),
                        title: Text('Bukti ${proof.idBuktiRetur}'),
                        subtitle: Text(proof.jenisMedia),
                        trailing: IconButton(
                          tooltip: 'Lihat bukti',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () => _viewProof(proof),
                        ),
                      ),
                    ),
                  ],
                ]),
                if ((item.metodePengembalian ?? '').isNotEmpty ||
                    (item.instruksiPengembalian ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _section('Instruksi Pengembalian Barang', [
                    if ((item.metodePengembalian ?? '').isNotEmpty)
                      _line('Metode', _status(item.metodePengembalian!)),
                    if ((item.instruksiPengembalian ?? '').isNotEmpty)
                      Text(item.instruksiPengembalian!),
                  ]),
                ],
                const SizedBox(height: 12),
                _section('Tahapan Proses', [
                  _line('Disetujui pada', _date(item.disetujuiPada)),
                  _line('Barang diterima pada', _date(item.barangDiterimaPada)),
                  _line('Diperiksa pada', _date(item.diperiksaPada)),
                  _line('Selesai pada', _date(item.selesaiPada)),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(color: AppColors.surface, elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 12), ...children])));
  Widget _line(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))), const SizedBox(width: 12), Expanded(child: Text(value, textAlign: TextAlign.end))]));
}

String _status(String value) => value.replaceAll('_', ' ');
String _money(int value) => 'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
String _date(DateTime? value) { if (value == null) return '-'; final d = value.toLocal(); return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; }
