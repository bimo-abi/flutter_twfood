import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/customer_order_service.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final List<CustomerOrder> _orders = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _refreshing = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loadingMore || _refreshing || (_loading && !refresh)) return;

    final showInitialLoader = refresh && _orders.isEmpty;
    if (refresh) {
      setState(() {
        _refreshing = true;
        if (showInitialLoader) _loading = true;
        _error = null;
      });
    } else {
      if (_currentPage >= _lastPage) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await CustomerOrderService.getHistory(
        page: refresh ? 1 : _currentPage + 1,
      );
      if (!mounted) return;

      setState(() {
        if (refresh) {
          _orders
            ..clear()
            ..addAll(result.orders);
        } else {
          final existingIds = _orders.map((order) => order.idPesanan).toSet();
          for (final order in result.orders) {
            if (existingIds.add(order.idPesanan)) _orders.add(order);
          }
        }
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refreshing ? null : () => _load(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _orders.isEmpty
              ? _errorView()
              : _orders.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: () => _load(refresh: true),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _orders.length + 2 + (_error != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0) return _summaryHeader(colors);
                          if (_error != null && index == 1) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: colors.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    'Pembaruan gagal: $_error',
                                    style: TextStyle(color: colors.onErrorContainer),
                                  ),
                                ),
                              ),
                            );
                          }
                          final offset = _error != null ? 2 : 1;
                          final orderIndex = index - offset;
                          if (orderIndex == _orders.length) return _footer();
                          if (orderIndex < 0 || orderIndex > _orders.length) {
                            return const SizedBox.shrink();
                          }
                          final order = _orders[orderIndex];
                          return _OrderCard(
                            order: order,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailPage(
                                    idPesanan: order.idPesanan,
                                  ),
                                ),
                              );
                              if (mounted) _load(refresh: true);
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _summaryHeader(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Pantau pesanan dan pembayaranmu di sini.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_total pesanan',
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _load(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 110),
          Icon(Icons.receipt_long_outlined, size: 68, color: colors.outline),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Belum ada pesanan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Pesanan yang kamu buat akan muncul di sini.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final colors = Theme.of(context).colorScheme;
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentPage < _lastPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: OutlinedButton.icon(
          onPressed: () => _load(),
          icon: const Icon(Icons.expand_more_rounded),
          label: const Text('Muat pesanan lainnya'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Menampilkan ${_orders.length} dari $_total pesanan',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstItem = order.items.isEmpty ? null : order.items.first;
    final otherCount = order.items.length - 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.nomorPesanan,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  _StatusChip(text: _statusLabel(order.statusPesanan)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(order.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: colors.outlineVariant),
              ),
              if (firstItem != null) ...[
                Text(
                  firstItem.namaProduk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${firstItem.namaVarian} · ${firstItem.jumlah} item',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ] else
                Text('Rincian produk tidak tersedia',
                    style: TextStyle(color: colors.onSurfaceVariant)),
              if (otherCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '+ $otherCount produk lainnya',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status pembayaran',
                            style: TextStyle(
                                color: colors.onSurfaceVariant, fontSize: 11)),
                        const SizedBox(height: 3),
                        Text(
                          _statusLabel(order.statusPembayaran),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total pesanan',
                          style: TextStyle(
                              color: colors.onSurfaceVariant, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(
                        _rupiah(order.totalPesanan),
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Lihat detail  →',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalized = text.toLowerCase();
    final Color background;
    final Color foreground;

    if (normalized.contains('batal') || normalized.contains('gagal') ||
        normalized.contains('kedaluwarsa')) {
      background = colors.errorContainer;
      foreground = colors.onErrorContainer;
    } else if (normalized.contains('selesai') || normalized.contains('diterima')) {
      background = colors.secondaryContainer;
      foreground = colors.onSecondaryContainer;
    } else if (normalized.contains('menunggu') || normalized.contains('belum')) {
      background = colors.tertiaryContainer;
      foreground = colors.onTertiaryContainer;
    } else {
      background = colors.primaryContainer;
      foreground = colors.onPrimaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _statusLabel(String value) {
  const labels = {
    'menunggu_pembayaran': 'Menunggu pembayaran',
    'sedang_diproses': 'Sedang diproses',
    'diproses': 'Diproses',
    'siap_diambil': 'Siap diambil',
    'siap_dikirim': 'Siap dikirim',
    'dalam_pengiriman': 'Dalam pengiriman',
    'dikirim': 'Dikirim',
    'diterima': 'Diterima',
    'selesai': 'Selesai',
    'dibatalkan': 'Dibatalkan',
    'lunas': 'Lunas',
    'belum_dibayar': 'Belum dibayar',
    'sebagian': 'Dibayar sebagian',
    'dp_dibayar': 'DP dibayar',
    'sebagian_dibayar': 'Dibayar sebagian',
    'dikembalikan': 'Dikembalikan',
    'kadaluarsa': 'Kedaluwarsa',
    'gagal': 'Gagal',
  };
  return labels[value] ?? value.replaceAll('_', ' ');
}

String _rupiah(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
