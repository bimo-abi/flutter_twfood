import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _openPayment(BuildContext context) async {
    final rawUrl = payment?['redirect_url']?.toString();
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);

    if (uri == null || !['https'].contains(uri.scheme) || uri.host.isEmpty) {
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pesanan Berhasil'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 84,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Pesanan berhasil dibuat!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                paymentUrl != null
                    ? 'Pesanan tersimpan. Lanjutkan pembayaran melalui halaman Midtrans.'
                    : 'Pesanan tersimpan. Periksa detail pesanan sebelum mencoba ulang pembayaran.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _OrderInfoRow(label: 'Nomor pesanan', value: orderNumber),
                      const Divider(),
                      _OrderInfoRow(label: 'Total pesanan', value: 'Rp $total'),
                      const Divider(),
                      _OrderInfoRow(label: 'Status pesanan', value: status),
                      if (paymentAmount != null) ...[
                        const Divider(),
                        _OrderInfoRow(
                          label: 'Pembayaran awal',
                          value: 'Rp $paymentAmount',
                        ),
                      ],
                      if (payment?['status_pembayaran'] != null) ...[
                        const Divider(),
                        _OrderInfoRow(
                          label: 'Status pembayaran',
                          value: payment!['status_pembayaran'].toString(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (paymentError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paymentError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (paymentUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openPayment(context),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Bayar melalui Midtrans'),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
