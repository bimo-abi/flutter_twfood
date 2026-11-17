import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/notifikasi.dart';
import '../../services/notifikasi_service.dart';
import 'order_detail_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  late Future<List<Notifikasi>> _notifikasiFuture;
  final Set<int> _processingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadNotifikasi();
  }

  // Mengambil ulang notifikasi dari backend.
  void _loadNotifikasi() {
    _notifikasiFuture = NotifikasiService.getNotifikasi();
  }

  // Refresh daftar notifikasi.
  Future<void> _refreshNotifikasi() async {
    setState(_loadNotifikasi);
    await _notifikasiFuture;
  }

  // Menandai seluruh notifikasi sebagai sudah dibaca.
  Future<void> _markAllRead() async {
    try {
      await NotifikasiService.markAllRead();

      if (!mounted) return;

      setState(_loadNotifikasi);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi telah ditandai dibaca.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui notifikasi: $e')),
      );
    }
  }

  // Buka detail pesanan dari notifikasi yang memiliki referensi pesanan.
  Future<void> _openNotification(Notifikasi notifikasi) async {
    if (_processingIds.contains(notifikasi.idNotifikasi)) return;

    _processingIds.add(notifikasi.idNotifikasi);
    try {
      if (!notifikasi.sudahDibaca) {
        await NotifikasiService.markRead(notifikasi.idNotifikasi);
      }

      if (!mounted) return;

      if (notifikasi.jenisReferensi == 'pesanan' &&
          notifikasi.idReferensi != null &&
          notifikasi.idReferensi! > 0) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(
              idPesanan: notifikasi.idReferensi!,
            ),
          ),
        );
      }

      if (mounted) {
        setState(_loadNotifikasi);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notifikasi gagal diproses: $e')),
      );
    } finally {
      _processingIds.remove(notifikasi.idNotifikasi);
    }
  }

  // Menghitung jumlah notifikasi yang belum dibaca.
  int _countUnread(List<Notifikasi> items) {
    return items.where((item) => !item.sudahDibaca).length;
  }

  // Format waktu tanpa menambah dependency intl.
  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final localDate = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year} '
        '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)}';
  }

  IconData _getNotificationIcon(String jenis) {
    final value = jenis.toLowerCase();

    if (value.contains('pembayaran')) {
      return Icons.payment_outlined;
    }

    if (value.contains('pesanan')) {
      return Icons.receipt_long_outlined;
    }

    if (value.contains('pre_order') || value.contains('preorder')) {
      return Icons.inventory_2_outlined;
    }

    if (value.contains('pengiriman') || value.contains('delivery')) {
      return Icons.local_shipping_outlined;
    }

    if (value.contains('retur') || value.contains('refund')) {
      return Icons.assignment_return_outlined;
    }

    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        automaticallyImplyLeading: false,
        actions: [
          FutureBuilder<List<Notifikasi>>(
            future: _notifikasiFuture,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              final unreadCount = _countUnread(items);

              if (snapshot.connectionState == ConnectionState.waiting ||
                  unreadCount == 0) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: _markAllRead,
                child: const Text('Baca semua'),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Notifikasi>>(
        future: _notifikasiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error);
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmpty();
          }

          final unreadCount = _countUnread(items);

          return RefreshIndicator(
            onRefresh: _refreshNotifikasi,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (unreadCount > 0) ...[
                  Text(
                    '$unreadCount notifikasi belum dibaca',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ...items.map(_buildNotificationCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Notifikasi item) {
    final unread = !item.sudahDibaca;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: unread
          ? Theme.of(context).colorScheme.primaryContainer.withAlpha(90)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openNotification(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                child: Icon(_getNotificationIcon(item.jenis)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.judul,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 5, left: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.pesan, style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          unread
                              ? Icons.mark_email_unread_outlined
                              : Icons.check_circle_outline,
                          size: 14,
                          color: unread
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.secondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          unread ? 'Belum dibaca' : 'Sudah dibaca',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: unread
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    if (unread) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.jenisReferensi == 'pesanan' && item.idReferensi != null
                            ? 'Ketuk untuk melihat detail pesanan'
                            : 'Ketuk untuk menandai sudah dibaca',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _refreshNotifikasi,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Icon(Icons.notifications_none_outlined, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Belum ada notifikasi.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Gagal mengambil notifikasi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              error?.toString() ?? 'Penyebab error tidak tersedia.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(_loadNotifikasi);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
