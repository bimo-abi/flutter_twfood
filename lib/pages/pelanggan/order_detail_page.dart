import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../services/customer_order_service.dart';
import 'pengajuan_retur_page.dart';
import 'riwayat_retur_page.dart';

class OrderDetailPage extends StatefulWidget {
  final int idPesanan;

  const OrderDetailPage({super.key, required this.idPesanan});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<CustomerOrder> _future;

  @override
  void initState() {
    super.initState();
    _future = CustomerOrderService.getDetail(widget.idPesanan);
  }

  void _reload() {
    setState(() {
      _future = CustomerOrderService.getDetail(widget.idPesanan);
    });
  }

  Future<void> _openTrackingLink(String link) async {
    final uri = Uri.tryParse(link.trim());

    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme.toLowerCase())) {
      _showMessage('Tautan pelacakan tidak valid.');
      return;
    }

    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        _showMessage('Tidak dapat membuka tautan pelacakan.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Terjadi kesalahan saat membuka tautan.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: FutureBuilder<CustomerOrder>(
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
                    const Icon(Icons.error_outline, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final order = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _section(
                  title: 'Informasi Pesanan',
                  children: [
                    _line('Nomor pesanan', order.nomorPesanan),
                    _line('Tanggal', _date(order.createdAt)),
                    _line('Jenis pemenuhan', _label(order.jenisPemenuhan)),
                    _line('Metode penerimaan', _label(order.jenisPesanan)),
                    _line('Status pesanan', _label(order.statusPesanan)),
                    _line('Status pembayaran', _label(order.statusPembayaran)),
                  ],
                ),
                if (_canSubmitReturn(order)) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PengajuanReturPage(order: order),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Ajukan Retur'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiwayatReturPage(),
                      ),
                    ),
                    icon: const Icon(Icons.history),
                    label: const Text('Riwayat Retur Saya'),
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Produk',
                  children: [
                    if (order.items.isEmpty)
                      const Text('Tidak ada rincian produk.'),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.namaProduk,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.namaVarian} • ${item.jumlah} × ${_money(item.harga)}',
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(_money(item.subtotalSetelahDiskon)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    _line('Subtotal', _money(order.subtotalProduk)),
                    _line('Diskon', _money(order.diskon)),
                    _line(
                      'Total pesanan',
                      _money(order.totalPesanan),
                      bold: true,
                    ),
                    if (order.menggunakanDp && order.nominalDp != null)
                      _line(
                        'DP yang ditetapkan',
                        _money(order.nominalDp!),
                        bold: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Pembayaran',
                  children: [
                    if (order.payments.isEmpty)
                      const Text('Belum ada catatan pembayaran.'),
                    ...order.payments.map(
                      (payment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _line('Jenis', _label(payment.jenisPembayaran)),
                            _line('Penyedia', payment.penyediaPembayaran),
                            _line('Jumlah', _money(payment.jumlahPembayaran)),
                            _line(
                              'Status transaksi',
                              _label(payment.statusPembayaran),
                            ),
                            if (payment.metodePembayaran != null)
                              _line('Metode', payment.metodePembayaran!),
                            if (payment.dibayarPada != null)
                              _line('Dibayar pada', _date(payment.dibayarPada)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.jenisPesanan == 'delivery' ||
                    order.kurir != null) ...[
                  const SizedBox(height: 12),
                  _section(
                    title: 'Pengiriman',
                    children: [
                      _line('Kurir', order.kurir ?? '-'),
                      _line('Nomor resi', order.nomorResi ?? '-'),
                      _line('Estimasi selesai', _date(order.estimasiSelesai)),
                      if (order.tautanPelacakan != null &&
                          order.tautanPelacakan!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _openTrackingLink(order.tautanPelacakan!),
                            icon: const Icon(Icons.local_shipping_outlined),
                            label: const Text('Lacak Pengiriman'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (order.catatan != null &&
                    order.catatan!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _section(title: 'Catatan', children: [Text(order.catatan!)]),
                ],
                if (order.statusPesanan == 'dibatalkan' &&
                    order.alasanPembatalan != null &&
                    order.alasanPembatalan!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _section(
                    title: 'Pembatalan',
                    children: [Text(order.alasanPembatalan!)],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  bool _canSubmitReturn(CustomerOrder order) {
    final receivedAt = order.diterimaPada;
    if (order.statusPesanan != 'diterima' ||
        order.statusPembayaran != 'lunas' ||
        receivedAt == null) {
      return false;
    }
    final now = DateTime.now();
    final deadline = receivedAt.add(const Duration(hours: 24));
    return !now.isBefore(receivedAt) && now.isBefore(deadline);
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _label(String value) => value.replaceAll('_', ' ');

String _money(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

String _date(DateTime? value) {
  if (value == null) return '-';

  final v = value.toLocal();

  return '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year} ${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
}
