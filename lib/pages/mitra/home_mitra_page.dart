import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/mitra_dashboard_service.dart';
import '../../services/token_storage.dart';
import '../../theme/app_colors.dart';
import '../auth/login_page.dart';
import 'daftar_pesanan_mitra_page.dart';
import 'daftar_produk_mitra_page.dart';
import 'daftar_retur_mitra_page.dart';

class HomeMitraPage extends StatefulWidget {
  const HomeMitraPage({super.key});

  @override
  State<HomeMitraPage> createState() => _HomeMitraPageState();
}

class _HomeMitraPageState extends State<HomeMitraPage> {
  late Future<MitraDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    _dashboardFuture = MitraDashboardService.fetchDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(_loadDashboard);
    await _dashboardFuture;
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
    } catch (e) {
      debugPrint('Logout API gagal: $e');
    } finally {
      await TokenStorage.deleteToken();
      CartService.resetSession();
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  String _formatRupiah(dynamic value) {
    final number = int.tryParse(value?.toString() ?? '') ?? 0;
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return 'Menunggu pembayaran';
      case 'sedang_diproses':
        return 'Sedang diproses';
      case 'siap_dikirim':
        return 'Siap dikirim';
      case 'siap_diambil':
        return 'Siap diambil';
      case 'dalam_pengiriman':
        return 'Dalam pengiriman';
      case 'diterima':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status?.replaceAll('_', ' ') ?? 'Tidak diketahui';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'sedang_diproses':
        return AppColors.warning;
      case 'siap_dikirim':
      case 'siap_diambil':
        return AppColors.secondary;
      case 'dalam_pengiriman':
        return Colors.blue;
      case 'diterima':
        return AppColors.success;
      case 'dibatalkan':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildMetricCard(String title, int value, IconData icon, Color color) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 14),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrder(Map<String, dynamic> order) {
    final customer = order['pengguna'];
    final customerName = customer is Map
        ? customer['nama']?.toString() ?? 'Pelanggan'
        : 'Pelanggan';

    final number =
        order['nomor_pesanan']?.toString() ?? '#${order['id_pesanan'] ?? '-'}';

    final status = order['status_pesanan']?.toString();

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(number, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    customerName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(order['total_pesanan']),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(MitraDashboardData data) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Selamat datang, Mitra!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Pantau dan kelola aktivitas operasional TWFOOD.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          Text(
            'Ringkasan Pesanan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricCard(
                'Total Pesanan',
                data.totalPesanan,
                Icons.shopping_bag_outlined,
                AppColors.primary,
              ),
              _buildMetricCard(
                'Sedang Diproses',
                data.perluDiproses,
                Icons.pending_actions,
                AppColors.warning,
              ),
              _buildMetricCard(
                'Siap Diserahkan',
                data.siapDiserahkan,
                Icons.inventory_2_outlined,
                AppColors.secondary,
              ),
              _buildMetricCard(
                'Dalam Pengiriman',
                data.dalamPengiriman,
                Icons.local_shipping_outlined,
                Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pesanan Terbaru',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: () {
                  setState(_loadDashboard);
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DaftarPesananMitraPage(),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Lihat Semua Pesanan'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DaftarProdukMitraPage(),
                  ),
                );
              },
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Manajemen Produk'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DaftarReturMitraPage(),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Kelola Retur'),
            ),
          ),

          if (data.pesananTerbaru.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 42,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 10),
                  Text('Belum ada pesanan.'),
                ],
              ),
            )
          else
            ...data.pesananTerbaru.map(_buildRecentOrder),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TWFOOD Mitra'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<MitraDashboardData>(
        future: _dashboardFuture,
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
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Data Dashboard belum dapat dimuat.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(_loadDashboard);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildDashboard(snapshot.data!);
        },
      ),
    );
  }
}
