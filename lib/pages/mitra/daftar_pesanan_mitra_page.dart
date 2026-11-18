import 'package:flutter/material.dart';

import '../../models/mitra_pesanan.dart';
import '../../services/mitra_pesanan_service.dart';
import '../../theme/app_colors.dart';
import 'detail_pesanan_mitra_page.dart';

class DaftarPesananMitraPage extends StatefulWidget {
  const DaftarPesananMitraPage({super.key});

  @override
  State<DaftarPesananMitraPage> createState() =>
      _DaftarPesananMitraPageState();
}

class _DaftarPesananMitraPageState extends State<DaftarPesananMitraPage> {
  static const _statusFilters = <String, String>{
    'Semua status': '',
    'Menunggu pembayaran': 'menunggu_pembayaran',
    'Sedang diproses': 'sedang_diproses',
    'Siap dikirim': 'siap_dikirim',
    'Siap diambil': 'siap_diambil',
    'Dalam pengiriman': 'dalam_pengiriman',
    'Selesai': 'diterima',
  };

  String _selectedStatus = '';
  String _selectedType = '';
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  String? _error;
  final List<MitraPesanan> _orders = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadOrders(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_loadingMore &&
        _hasMore &&
        !_initialLoading) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders({bool reset = false}) async {
    if (_loadingMore || (_initialLoading && !reset)) return;

    setState(() {
      if (reset) {
        _initialLoading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        _orders.clear();
      } else {
        _loadingMore = true;
      }
    });

    try {
      final result = await MitraPesananService.fetchPesanan(
        page: _page,
        status: _selectedStatus,
        jenisPemenuhan: _selectedType,
      );

      if (!mounted) return;
      setState(() {
        _orders.addAll(result.pesanan);
        _page = result.currentPage + 1;
        _hasMore = result.currentPage < result.lastPage;
        _initialLoading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initialLoading = false;
        _loadingMore = false;
      });
    }
  }

  String _statusLabel(String status) => status.replaceAll('_', ' ');

  Color _statusColor(String status) {
    switch (status) {
      case 'diterima':
      case 'selesai':
      case 'pesanan_diambil':
        return AppColors.success;
      case 'dibatalkan':
        return AppColors.error;
      case 'sedang_diproses':
        return AppColors.warning;
      case 'siap_dikirim':
      case 'siap_diambil':
        return AppColors.secondary;
      case 'dalam_pengiriman':
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }

  String _rupiah(dynamic value) {
    final amount = int.tryParse(value?.toString() ?? '') ?? 0;
    return 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}';
  }

  Widget _orderCard(MitraPesanan order) {
    final color = _statusColor(order.status);
    final isPo = order.isPreOrder;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailPesananMitraPage(idPesanan: order.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.nomor,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _typeBadge(isPo),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.namaPelanggan,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(order.status),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    order.jenisPesanan.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    _rupiah(order.getValue('total_pesanan')),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              if (isPo && order.getValue('estimasi_selesai') != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Estimasi pemenuhan: ${order.getValue('estimasi_selesai')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBadge(bool isPo) {
    final color = isPo ? AppColors.warning : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPo ? 'PRE-ORDER' : 'REGULER',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _filterChips({
    required Map<String, String> filters,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: filters.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.key),
              selected: selected == entry.value,
              onSelected: (_) => onSelected(entry.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pesanan')),
      body: Column(
        children: [
          _filterChips(
            filters: const {
              'Semua jenis': '',
              'Reguler': 'reguler',
              'Pre-Order': 'pre_order',
            },
            selected: _selectedType,
            onSelected: (value) {
              setState(() => _selectedType = value);
              _loadOrders(reset: true);
            },
          ),
          _filterChips(
            filters: _statusFilters,
            selected: _selectedStatus,
            onSelected: (value) {
              setState(() => _selectedStatus = value);
              _loadOrders(reset: true);
            },
          ),
          Expanded(
            child: _initialLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _orders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 42),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _loadOrders(reset: true),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadOrders(reset: true),
                        child: _orders.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(child: Text('Belum ada pesanan.')),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount:
                                    _orders.length + (_loadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _orders.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return _orderCard(_orders[index]);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
