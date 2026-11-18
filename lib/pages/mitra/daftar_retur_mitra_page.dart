import 'package:flutter/material.dart';

import '../../models/mitra_retur.dart';
import '../../services/mitra_retur_service.dart';
import '../../theme/app_colors.dart';
import 'detail_retur_mitra_page.dart';

class DaftarReturMitraPage extends StatefulWidget {
  const DaftarReturMitraPage({super.key});

  @override
  State<DaftarReturMitraPage> createState() => _DaftarReturMitraPageState();
}

class _DaftarReturMitraPageState extends State<DaftarReturMitraPage> {
  String? _status;
  late Future<List<MitraRetur>> _future;

  static const _filters = <String, String>{
    'Semua Status': '',
    'Menunggu Persetujuan': 'menunggu_persetujuan',
    'Disetujui': 'disetujui',
    'Menunggu Barang': 'menunggu_pengembalian_barang',
    'Barang Diterima': 'barang_diterima',
    'Sedang Diperiksa': 'sedang_diperiksa',
    'Selesai': 'selesai',
    'Ditolak': 'ditolak',
    'Dibatalkan': 'dibatalkan',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = MitraReturService.fetchRetur(status: _status);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  String _customerName(MitraRetur item) {
    final pengguna = item.pesanan['pengguna'];
    if (pengguna is Map) return pengguna['nama']?.toString() ?? 'Pelanggan';
    return 'Pelanggan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengelolaan Retur')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              value: _status ?? '',
              decoration: const InputDecoration(
                labelText: 'Filter status retur',
                border: OutlineInputBorder(),
              ),
              items: _filters.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _status = value == null || value.isEmpty ? null : value;
                  _load();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MitraRetur>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageState(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(_load),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        Icon(Icons.assignment_return_outlined,
                            size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Center(child: Text('Belum ada pengajuan retur.')),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final orderNumber =
                          item.pesanan['nomor_pesanan']?.toString() ?? '-';
                      return Card(
                        elevation: 0,
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.background,
                            child: Icon(Icons.assignment_return_outlined,
                                color: AppColors.secondary),
                          ),
                          title: Text(item.nomorRetur,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pesanan: $orderNumber'),
                                Text('Pelanggan: ${_customerName(item)}'),
                                const SizedBox(height: 5),
                                Text(MitraRetur.statusLabel(item.statusRetur),
                                    style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailReturMitraPage(
                                    idRetur: item.idRetur),
                              ),
                            );
                            if (mounted) setState(_load);
                          },
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

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessageState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
