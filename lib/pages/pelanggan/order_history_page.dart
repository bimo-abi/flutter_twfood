import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/customer_order_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // Kepala halaman: banner gradasi berisi judul, jumlah pesanan, tombol muat ulang.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.bannerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(top: -40, right: -30, child: _decorCircle(150, 0.10)),
          Positioned(bottom: -50, left: -40, child: _decorCircle(120, 0.08)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pesanan Saya',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pantau pesanan dan pembayaranmu di sini.',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!_loading) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_total pesanan',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: 'Muat ulang',
                      onPressed:
                          _refreshing ? null : () => _load(refresh: true),
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null && _orders.isEmpty) return _errorView();
    if (_orders.isEmpty) return _emptyView();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: _orders.length + 1 + (_error != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (_error != null && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Pembaruan gagal: $_error',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }
          final offset = _error != null ? 1 : 0;
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
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
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
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.secondarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 46,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text('Belum ada pesanan',
                style: AppTextStyles.headingSmall),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Pesanan yang kamu buat akan muncul di sini.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
          style: AppTextStyles.bodySmall,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.nomorPesanan,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDate(order.createdAt),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(text: _statusLabel(order.statusPesanan)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (firstItem != null) ...[
                        Text(
                          firstItem.namaProduk,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${firstItem.namaVarian} · ${firstItem.jumlah} item',
                          style: AppTextStyles.bodySmall,
                        ),
                      ] else
                        const Text('Rincian produk tidak tersedia',
                            style: AppTextStyles.bodySmall),
                      if (otherCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '+ $otherCount produk lainnya',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status pembayaran',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                          const SizedBox(height: 3),
                          Text(
                            _statusLabel(order.statusPembayaran),
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total pesanan',
                            style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                        const SizedBox(height: 3),
                        Text(
                          _rupiah(order.totalPesanan),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat detail',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
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
    final normalized = text.toLowerCase();
    final Color background;
    final Color foreground;

    if (normalized.contains('batal') ||
        normalized.contains('gagal') ||
        normalized.contains('kedaluwarsa')) {
      background = AppColors.primarySoft;
      foreground = AppColors.primary;
    } else if (normalized.contains('selesai') ||
        normalized.contains('diterima') ||
        normalized.contains('lunas')) {
      background = const Color(0xFFE3F4EA);
      foreground = AppColors.success;
    } else if (normalized.contains('menunggu') ||
        normalized.contains('belum')) {
      background = AppColors.accentSoft;
      foreground = const Color(0xFFB07A00);
    } else {
      background = AppColors.secondarySoft;
      foreground = const Color(0xFFD9780A);
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
          fontFamily: AppTextStyles.fontFamily,
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
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