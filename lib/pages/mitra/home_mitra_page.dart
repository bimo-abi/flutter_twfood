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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 10),
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DaftarPesananMitraPage(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined),
                  const SizedBox(width: 10),
                  const Text('Lihat Semua Pesanan'),
                  if (data.perluDiproses > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.perluDiproses > 99
                            ? '99+'
                            : '${data.perluDiproses}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
