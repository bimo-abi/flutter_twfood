import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../services/customer_order_service.dart';
import '../../services/payment_service.dart';
import '../../services/retur_service.dart';
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
  bool _isStartingSettlement = false;
  bool _loadingReturnEligibility = true;
  ReturnEligibilitySummary? _returnEligibility;
  String? _returnEligibilityError;

  @override
  void initState() {
    super.initState();
    _future = CustomerOrderService.getDetail(widget.idPesanan);
    _loadReturnEligibility();
  }

  Future<void> _loadReturnEligibility() async {
    setState(() {
      _loadingReturnEligibility = true;
      _returnEligibilityError = null;
    });
    try {
      final summary = await ReturnService.getEligibilityForOrder(widget.idPesanan);
      if (!mounted) return;
      setState(() => _returnEligibility = summary);
    } catch (error) {
      if (!mounted) return;
      setState(() => _returnEligibilityError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingReturnEligibility = false);
    }
  }

  Future<void> _reload() async {
    final request = CustomerOrderService.getDetail(widget.idPesanan);
    setState(() => _future = request);

    // RefreshIndicator menunggu permintaan selesai, bukan hanya perubahan state.
    try {
      await request;
    } catch (_) {
      // Error tetap ditampilkan oleh FutureBuilder.
    }
    await _loadReturnEligibility();
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

  int _paidAmount(CustomerOrder order) {
    return order.payments
        .where((payment) => payment.statusPembayaran == 'paid')
        .fold(0, (total, payment) => total + payment.jumlahPembayaran);
  }

  int _remainingBalance(CustomerOrder order) {
    final remaining = order.totalPesanan - _paidAmount(order);
    return remaining > 0 ? remaining : 0;
  }

  bool _canSettle(CustomerOrder order) {
    return order.menggunakanDp &&
        ['dp_dibayar', 'sebagian_dibayar'].contains(order.statusPembayaran) &&
        _remainingBalance(order) > 0;
  }

  Future<void> _startSettlement() async {
    if (_isStartingSettlement) return;

    setState(() => _isStartingSettlement = true);
    try {
      final payment = await PaymentService.createPayment(
        idPesanan: widget.idPesanan,
        jenisPembayaran: 'pelunasan',
      );
      final rawUrl = payment['redirect_url']?.toString();
      final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);

      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        _showMessage(
          'Transaksi pelunasan dibuat, tetapi tautan Midtrans tidak valid. '
          'Muat ulang detail pesanan sebelum mencoba kembali.',
        );
        _reload();
        return;
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMessage('Tidak dapat membuka halaman pembayaran Midtrans.');
      }
      if (mounted) _reload();
    } on PaymentApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
        _reload();
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Terjadi kendala saat memulai pelunasan. Periksa detail pesanan '
          'sebelum mencoba kembali agar tidak membuat transaksi ganda.',
        );
        _reload();
      }
    } finally {
      if (mounted) setState(() => _isStartingSettlement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _OrderStatusHeader(order: order),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _canOpenReturn(order)
                        ? () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PengajuanReturPage(
                                  order: order,
                                  maxQuantities: {
                                    for (final item in order.items)
                                      item.idDetailPesanan:
                                          _returnEligibility!.remainingFor(item),
                                  },
                                ),
                              ),
                            );
                            if (mounted) await _reload();
                          }
                        : null,
                    icon: const Icon(Icons.assignment_return_outlined),
                    label: const Text('Ajukan Retur'),
                  ),
                ),
                if (!_canOpenReturn(order)) ...[
                  const SizedBox(height: 6),
                  Text(
                    _returnEligibilityMessage(order),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (_returnEligibilityError != null)
                    TextButton.icon(
                      onPressed: _loadReturnEligibility,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Periksa ulang kelayakan retur'),
                    ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RiwayatReturPage(),
                        ),
                      );
                      if (mounted) await _reload();
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Riwayat Retur Saya'),
                  ),
                ),
                if (order.menggunakanDp) ...[
                  const SizedBox(height: 12),
                  _section(
                    title: 'Ringkasan DP dan Pelunasan',
                    children: [
                      _line('Total tagihan produk', _money(order.totalPesanan)),
                      if (order.nominalDp != null)
                        _line('Nominal DP', _money(order.nominalDp!)),
                      _line('Total pembayaran berhasil', _money(_paidAmount(order))),
                      _line(
                        'Sisa tagihan (perkiraan)',
                        _money(_remainingBalance(order)),
                        bold: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nominal pelunasan final dihitung kembali oleh Laravel saat transaksi dibuat.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (_canSettle(order)) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isStartingSettlement ? null : _startSettlement,
                            icon: _isStartingSettlement
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.payment),
                            label: Text(
                              _isStartingSettlement
                                  ? 'Menyiapkan pembayaran...'
                                  : 'Lunasi Sisa Pembayaran',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
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
                      if (order.kurir == 'jnt')
                        _line(
                          'Nomor resi J&T',
                          order.nomorResi?.trim().isNotEmpty == true
                              ? order.nomorResi!
                              : 'Belum tersedia',
                        ),
                      if (order.nomorResi != null &&
                          order.nomorResi!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: order.nomorResi!.trim()),
                              );
                              if (mounted) {
                                _showMessage('Nomor resi berhasil disalin.');
                              }
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Salin nomor resi'),
                          ),
                        ),
                      ],
                      _line('Estimasi selesai', _date(order.estimasiSelesai)),
                      if (order.tautanPelacakan != null &&
                          order.tautanPelacakan!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(
                          order.tautanPelacakan!,
                          style: const TextStyle(fontSize: 12),
                        ),
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
    return !now.isBefore(receivedAt) && !now.isAfter(deadline);
  }

  bool _canOpenReturn(CustomerOrder order) {
    final summary = _returnEligibility;
    if (!_canSubmitReturn(order) ||
        _loadingReturnEligibility ||
        _returnEligibilityError != null ||
        summary == null ||
        summary.hasActiveRequest) {
      return false;
    }
    return order.items.any((item) => summary.remainingFor(item) > 0);
  }

  String _returnEligibilityMessage(CustomerOrder order) {
    if (!_canSubmitReturn(order)) return _returnUnavailableReason(order);
    if (_loadingReturnEligibility) {
      return 'Sedang memeriksa riwayat dan sisa kuota retur...';
    }
    if (_returnEligibilityError != null || _returnEligibility == null) {
      return 'Tidak dapat memeriksa riwayat retur. Muat ulang halaman sebelum mengajukan retur.';
    }
    if (_returnEligibility!.hasActiveRequest) {
      final nomor = _returnEligibility!.activeReturnNumber;
      return 'Masih ada pengajuan retur aktif${nomor == null ? '' : ' ($nomor)'}. Tunggu proses tersebut selesai.';
    }
    if (!order.items.any((item) => _returnEligibility!.remainingFor(item) > 0)) {
      return 'Seluruh jumlah produk pada pesanan ini sudah diajukan atau disetujui untuk retur.';
    }
    return 'Pengajuan retur belum dapat dilakukan.';
  }

  String _returnUnavailableReason(CustomerOrder order) {
    if (order.statusPesanan != 'diterima') {
      return 'Pengajuan retur tersedia setelah pesanan berstatus diterima.';
    }

    if (order.statusPembayaran != 'lunas') {
      return 'Pengajuan retur tersedia setelah pembayaran pesanan lunas.';
    }

    final receivedAt = order.diterimaPada;
    if (receivedAt == null) {
      return 'Waktu penerimaan pesanan belum tercatat. Hubungi admin/mitra untuk pemeriksaan.';
    }

    final now = DateTime.now();
    if (now.isBefore(receivedAt)) {
      return 'Waktu penerimaan pesanan belum valid. Hubungi admin/mitra untuk pemeriksaan.';
    }

    final deadline = receivedAt.add(const Duration(hours: 24));
    if (now.isAfter(deadline)) {
      return 'Batas pengajuan retur 1 × 24 jam setelah pesanan diterima telah berakhir.';
    }

    return 'Pengajuan retur belum dapat dilakukan.';
  }

  Widget _section({required String title, required List<Widget> children}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
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

class _OrderStatusHeader extends StatelessWidget {
  final CustomerOrder order;

  const _OrderStatusHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = _label(order.statusPesanan);
    final normalized = order.statusPesanan.toLowerCase();
    final Color background;
    final Color foreground;
    final IconData icon;

    if (normalized == 'dibatalkan') {
      background = colors.errorContainer;
      foreground = colors.onErrorContainer;
      icon = Icons.cancel_outlined;
    } else if (normalized == 'diterima' || normalized == 'selesai') {
      background = colors.secondaryContainer;
      foreground = colors.onSecondaryContainer;
      icon = Icons.check_circle_outline_rounded;
    } else if (normalized == 'menunggu_pembayaran') {
      background = colors.tertiaryContainer;
      foreground = colors.onTertiaryContainer;
      icon = Icons.hourglass_top_rounded;
    } else {
      background = colors.primaryContainer;
      foreground = colors.onPrimaryContainer;
      icon = Icons.local_shipping_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status pesanan',
                  style: TextStyle(color: foreground.withValues(alpha: 0.8), fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.nomorPesanan,
                  style: TextStyle(color: foreground, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _label(String value) {
  const labels = {
    'menunggu_pembayaran': 'Menunggu pembayaran',
    'sedang_diproses': 'Sedang diproses',
    'siap_diambil': 'Siap diambil',
    'siap_dikirim': 'Siap dikirim',
    'dalam_pengiriman': 'Dalam pengiriman',
    'diterima': 'Diterima',
    'selesai': 'Selesai',
    'dibatalkan': 'Dibatalkan',
    'belum_dibayar': 'Belum dibayar',
    'dp_dibayar': 'DP dibayar',
    'sebagian_dibayar': 'Dibayar sebagian',
    'lunas': 'Lunas',
    'kadaluarsa': 'Kedaluwarsa',
    'gagal': 'Gagal',
    'penuh': 'Pembayaran penuh',
    'pelunasan': 'Pelunasan',
    'delivery': 'Pengiriman',
    'pickup': 'Ambil di outlet',
    'reguler': 'Reguler',
    'pre_order': 'Pre-order',
  };
  return labels[value] ?? value.replaceAll('_', ' ');
}

String _money(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

String _date(DateTime? value) {
  if (value == null) return '-';

  final v = value.toLocal();

  return '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year} ${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
}
