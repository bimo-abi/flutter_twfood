import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class OrderSuccessPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? payment;
  final String? paymentError;

  const OrderSuccessPage({
    super.key,
    required this.order,
    this.payment,
    this.paymentError,
  });

  String _rupiah(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return value;
    final digits = parsed.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
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
      'pending': 'Menunggu pembayaran',
      'paid': 'Lunas',
      'lunas': 'Lunas',
      'dp_dibayar': 'DP dibayar',
    };
    return labels[value] ?? value.replaceAll('_', ' ');
  }

  Future<void> _openPayment(BuildContext context) async {
    final rawUrl = payment?['redirect_url']?.toString();
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);

    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link pembayaran tidak valid.')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka halaman Midtrans.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = order['nomor_pesanan']?.toString() ?? '-';
    final total = order['total_pesanan']?.toString() ?? '-';
    final status = order['status_pesanan']?.toString() ?? '-';
    final paymentUrl = payment?['redirect_url']?.toString();
    final paymentAmount = payment?['jumlah_pembayaran']?.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Pesanan Berhasil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pesanan berhasil dibuat!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 8),
              Text(
                paymentUrl != null
                    ? 'Pesananmu sudah tersimpan. Lanjutkan pembayaran dengan aman melalui Midtrans.'
                    : 'Pesananmu sudah tersimpan. Kamu dapat melihat perkembangannya melalui riwayat pesanan.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.softShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _OrderInfoRow(label: 'Nomor pesanan', value: orderNumber),
                      const Divider(height: 24, color: AppColors.border),
                      _OrderInfoRow(label: 'Total pesanan', value: _rupiah(total)),
                      const Divider(height: 24),
                      _OrderInfoRow(label: 'Status pesanan', value: _label(status)),
                      if (paymentAmount != null) ...[
                        const Divider(height: 24),
                        _OrderInfoRow(
                          label: 'Pembayaran awal',
                          value: _rupiah(paymentAmount),
                        ),
                      ],
                      if (payment?['status_pembayaran'] != null) ...[
                        const Divider(height: 24),
                        _OrderInfoRow(
                          label: 'Status pembayaran',
                          value: _label(payment!['status_pembayaran'].toString()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (paymentError != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    paymentError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (paymentUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openPayment(context),
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('Bayar melalui Midtrans'),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke Aplikasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _OrderInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: Text(
            value,
            textAlign: TextAlign.start,
            softWrap: true,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}