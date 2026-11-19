import 'package:flutter/material.dart';
import '../../models/mitra_refund.dart';
import '../../services/mitra_refund_service.dart';
import '../../theme/app_colors.dart';
import 'detail_refund_mitra_page.dart';

class DaftarRefundMitraPage extends StatefulWidget {
  const DaftarRefundMitraPage({super.key});
  @override
  State<DaftarRefundMitraPage> createState() => _DaftarRefundMitraPageState();
}

class _DaftarRefundMitraPageState extends State<DaftarRefundMitraPage> {
  String? _status;
  late Future<List<MitraRefund>> _future;
  static const _filters = <String, String>{
    'Semua Status': '', 'Belum Diajukan': 'belum_diajukan',
    'Menunggu Diproses': 'menunggu_diproses', 'Sedang Diproses': 'diproses',
    'Berhasil': 'berhasil', 'Gagal': 'gagal', 'Perlu Diproses Ulang': 'perlu_diproses_ulang',
  };
  @override
  void initState() { super.initState(); _load(); }
  void _load() { _future = MitraRefundService.fetchRefund(status: _status); }
  Future<void> _refresh() async { setState(_load); await _future; }
  String _rupiah(int value) => 'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pengelolaan Refund')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: DropdownButtonFormField<String>(
        initialValue: _status ?? '', decoration: const InputDecoration(labelText: 'Filter status refund', border: OutlineInputBorder()),
        items: _filters.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
        onChanged: (v) => setState(() { _status = v == null || v.isEmpty ? null : v; _load(); }),
      )),
      Expanded(child: FutureBuilder<List<MitraRefund>>(future: _future, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _state(snapshot.error.toString(), () => setState(_load));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return RefreshIndicator(onRefresh: _refresh, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 140), Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textSecondary), SizedBox(height: 12), Center(child: Text('Belum ada data refund.'))]));
        return RefreshIndicator(onRefresh: _refresh, child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) { final item = items[i]; return Card(
            elevation: 0, color: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
            child: ListTile(contentPadding: const EdgeInsets.all(14), leading: const CircleAvatar(backgroundColor: AppColors.background, child: Icon(Icons.currency_exchange, color: AppColors.secondary)),
              title: Text('Refund #${item.idRefund}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Retur: ${item.nomorRetur}'), Text('Pesanan: ${item.nomorPesanan}'), Text('Pelanggan: ${item.namaPelanggan}'), const SizedBox(height: 5), Text(MitraRefund.statusLabel(item.statusRefund), style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600))])),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(_rupiah(item.nominalRefund), style: const TextStyle(fontWeight: FontWeight.w700)), const Icon(Icons.chevron_right)]),
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailRefundMitraPage(idRefund: item.idRefund))); if (mounted) setState(_load); },
            ),
          ); },
        ));
      })),
    ]),
  );

  Widget _state(String message, VoidCallback retry) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 44, color: AppColors.textSecondary), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 14), ElevatedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi'))])));
}
