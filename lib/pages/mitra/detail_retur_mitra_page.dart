import 'package:flutter/material.dart';

import '../../models/mitra_retur.dart';
import '../../services/mitra_retur_service.dart';
import '../../theme/app_colors.dart';

class DetailReturMitraPage extends StatefulWidget {
  final int idRetur;

  const DetailReturMitraPage({super.key, required this.idRetur});

  @override
  State<DetailReturMitraPage> createState() => _DetailReturMitraPageState();
}

class _DetailReturMitraPageState extends State<DetailReturMitraPage> {
  late Future<MitraRetur> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = MitraReturService.fetchDetail(widget.idRetur);
  }

  String _rupiah(dynamic value) {
    final number = int.tryParse(value?.toString() ?? '') ?? 0;
    return 'Rp ${number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    )}';
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _line(String label, dynamic value) {
    final text = value?.toString().trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const Text(': '),
          Expanded(child: Text(text == null || text.isEmpty ? '-' : text)),
        ],
      ),
    );
  }

  Widget _buildDetail(MitraRetur retur) {
    final order = retur.pesanan;
    final customer = order['pengguna'];
    final customerName =
        customer is Map ? customer['nama']?.toString() ?? '-' : '-';
    final orderNumber = order['nomor_pesanan']?.toString() ?? '-';

    return RefreshIndicator(
      onRefresh: () async {
        setState(_load);
        await _future;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _section('Informasi Retur', [
            _line('Nomor retur', retur.nomorRetur),
            _line('Status', MitraRetur.statusLabel(retur.statusRetur)),
            _line('Nomor pesanan', orderNumber),
            _line('Pelanggan', customerName),
            _line('Tanggal pengajuan', retur.diajukanPada),
            _line('Alasan', retur.alasanRetur),
            _line('Catatan Mitra', retur.catatanMitra),
          ]),
          const SizedBox(height: 12),
          _section('Rincian Barang', [
            if (retur.detailRetur.isEmpty)
              const Text('Tidak ada rincian barang.')
            else
              ...retur.detailRetur.map((item) {
                final detail = item['detail_pesanan'];
                final detailMap =
                    detail is Map ? Map<String, dynamic>.from(detail) : {};
                final nama = detailMap['nama_produk_saat_pesan']?.toString()
                    ?? detailMap['nama_produk']?.toString()
                    ?? 'Produk';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _line('Jumlah diminta', item['jumlah_diminta'] ?? item['jumlah_diretur']),
                      _line('Jumlah disetujui', item['jumlah_disetujui']),
                      _line('Alasan item', item['alasan_item']),
                      _line('Nominal refund', _rupiah(item['nominal_refund'])),
                    ],
                  ),
                );
              }),
          ]),
          const SizedBox(height: 12),
          _section('Bukti Retur', [
            if (retur.buktiRetur.isEmpty)
              const Text('Tidak ada bukti yang dilampirkan.')
            else
              ...retur.buktiRetur.map((bukti) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      bukti['jenis_media'] == 'video'
                          ? Icons.videocam_outlined
                          : Icons.image_outlined,
                      color: AppColors.secondary,
                    ),
                    title: Text(
                      bukti['jenis_media']?.toString() == 'video'
                          ? 'Bukti video'
                          : 'Bukti foto',
                    ),
                    subtitle: const Text(
                      'Berkas tersimpan secara privat di server.',
                    ),
                  )),
          ]),
          const SizedBox(height: 12),
          _section('Informasi Pengembalian Dana', [
            _line('Status refund', retur.statusPengembalianDana),
            _line('Nominal refund', _rupiah(retur.nominalPengembalian)),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Retur')),
      body: FutureBuilder<MitraRetur>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(snapshot.error.toString(),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => setState(_load),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildDetail(snapshot.data!);
        },
      ),
    );
  }
}
