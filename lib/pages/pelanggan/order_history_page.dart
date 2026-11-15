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
    if (_loadingMore) return;
    if (refresh) {
      setState(() {
        _loading = true;
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
        if (refresh) _orders.clear();
        _orders.addAll(result.orders);
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => _load(refresh: true),
            icon: const Icon(Icons.refresh),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _orders.length + 1,
                itemBuilder: (context, index) {
                  if (index == _orders.length) return _footer();
                  return _OrderCard(
                    order: _orders[index],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(
                            idPesanan: _orders[index].idPesanan,
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

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 44),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _load(refresh: true),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );

  Widget _emptyView() => RefreshIndicator(
    onRefresh: () => _load(refresh: true),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 140),
        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Center(child: Text('Belum ada pesanan')),
        SizedBox(height: 8),
        Center(child: Text('Pesanan yang dibuat akan muncul di sini.')),
      ],
    ),
  );

  Widget _footer() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentPage < _lastPage) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: OutlinedButton(
          onPressed: () => _load(),
          child: const Text('Muat pesanan lainnya'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Menampilkan ${_orders.length} dari $_total pesanan',
          style: const TextStyle(color: Colors.grey),
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
    final firstItem = order.items.isEmpty ? null : order.items.first;
    final otherCount = order.items.length - 1;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusChip(text: _statusLabel(order.statusPesanan)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Divider(height: 22),
              if (firstItem != null)
                Text(
                  '${firstItem.namaProduk} • ${firstItem.namaVarian} × ${firstItem.jumlah}',
                ),
              if (otherCount > 0)
                Text(
                  'dan $otherCount produk lainnya',
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pembayaran: ${_statusLabel(order.statusPembayaran)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    _rupiah(order.totalPesanan),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Lihat detail  ›',
                  style: TextStyle(color: Colors.green),
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
  Widget build(BuildContext context) => Chip(
    label: Text(text, style: const TextStyle(fontSize: 11)),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
  );
}

String _statusLabel(String value) {
  const labels = {
    'menunggu_pembayaran': 'Menunggu pembayaran',
    'sedang_diproses': 'Sedang diproses',
    'diproses': 'Diproses',
    'siap_diambil': 'Siap diambil',
    'dikirim': 'Dikirim',
    'selesai': 'Selesai',
    'dibatalkan': 'Dibatalkan',
    'lunas': 'Lunas',
    'belum_dibayar': 'Belum dibayar',
    'sebagian': 'Dibayar sebagian',
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
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
