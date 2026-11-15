import 'package:flutter/material.dart';

import '../../models/notifikasi.dart';
import '../../services/notifikasi_service.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  late Future<List<Notifikasi>> _notifikasiFuture;

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

  // Menandai satu notifikasi sebagai sudah dibaca.
  Future<void> _markRead(Notifikasi notifikasi) async {
    if (notifikasi.sudahDibaca) return;

    try {
      await NotifikasiService.markRead(notifikasi.idNotifikasi);

      if (!mounted) return;

      setState(_loadNotifikasi);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi berhasil ditandai sudah dibaca.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui notifikasi: $e')),
      );
    }
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
                      color: Colors.grey,
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
      color: unread
          ? Theme.of(context).colorScheme.primaryContainer.withAlpha(90)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _markRead(item),
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
                          ?.copyWith(color: Colors.grey),
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
                              : Colors.green,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          unread ? 'Belum dibaca' : 'Sudah dibaca',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: unread
                                ? Theme.of(context).colorScheme.primary
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (unread) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ketuk untuk menandai sudah dibaca',
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
          Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Belum ada notifikasi.',
              style: TextStyle(color: Colors.grey),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Gagal mengambil notifikasi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              error?.toString() ?? 'Penyebab error tidak tersedia.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
