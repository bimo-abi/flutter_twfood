import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/address.dart';
import '../../models/cart_item.dart';
import '../../models/outlet.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/outlet_service.dart';
import 'address_selection_page.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final Address? initialAddress;

  const CheckoutPage({super.key, this.initialAddress});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const String _delivery = 'delivery';
  static const String _pickup = 'pickup';
  static const String _regular = 'reguler';
  static const String _preOrder = 'pre_order';

  final TextEditingController _noteController = TextEditingController();

  String _fulfillmentMethod = _delivery;
  String _orderType = _regular;
  Address? _selectedAddress;
  Outlet? _selectedOutlet;
  late Future<List<Outlet>> _outletsFuture;
  late Future<bool> _preOrderEligibilityFuture;
  late Future<bool> _dpEligibilityFuture;
  String _paymentType = 'penuh';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress;
    _outletsFuture = OutletService.getOutlets();
    _preOrderEligibilityFuture = _checkPreOrderEligibility();
    _dpEligibilityFuture = _checkDpEligibility();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<bool> _checkPreOrderEligibility() async {
    try {
      final response = await AuthService.me();
      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['data'] is! Map<String, dynamic>) {
        return false;
      }

      final user = decoded['data'] as Map<String, dynamic>;
      final customerType = user['jenis_pelanggan']?.toString();
      final verificationStatus = user['status_verifikasi']?.toString();

      if (!['toko', 'horeca'].contains(customerType) ||
          verificationStatus != 'disetujui') {
        return false;
      }

      final items = CartService.items;
      if (items.isEmpty) return false;

      return items.every(
        (item) => item.variant.tersediaPreOrder && _isPreOrderPeriodOpen(item),
      );
    } catch (_) {
      // Kegagalan pemeriksaan hanya menyembunyikan pilihan pre-order.
      // Pembuatan pesanan reguler tetap dapat dilanjutkan.
      return false;
    }
  }

  Future<bool> _checkDpEligibility() async {
    try {
      final response = await AuthService.me();
      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['data'] is! Map<String, dynamic>) {
        return false;
      }

      final user = decoded['data'] as Map<String, dynamic>;
      return ['toko', 'horeca'].contains(user['jenis_pelanggan']?.toString()) &&
          user['status_verifikasi']?.toString() == 'disetujui';
    } catch (_) {
      return false;
    }
  }

  bool _isPreOrderPeriodOpen(CartItem item) {
    final start = item.variant.tanggalMulaiPreOrder;
    final end = item.variant.tanggalSelesaiPreOrder;
    if (start == null || end == null) return false;

    final localStart = start.toLocal();
    final localEnd = end.toLocal();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final startDate = DateTime(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    final endDate = DateTime(localEnd.year, localEnd.month, localEnd.day);

    return !todayDate.isBefore(startDate) && !todayDate.isAfter(endDate);
  }

  Future<void> _chooseAddress() async {
    final address = await Navigator.push<Address>(
      context,
      MaterialPageRoute(builder: (_) => const AddressSelectionPage()),
    );

    if (address != null && mounted) {
      setState(() => _selectedAddress = address);
    }
  }

  Future<void> _refreshOutlets() async {
    setState(() => _outletsFuture = OutletService.getOutlets());
    await _outletsFuture;
  }

  bool get _canSubmit {
    if (_isSubmitting || CartService.items.isEmpty) return false;
    if (_fulfillmentMethod == _delivery) return _selectedAddress != null;
    return _selectedOutlet != null;
  }

  Future<void> _submitOrder() async {
    if (!_canSubmit || _isSubmitting) return;

    final items = CartService.items;
    if (items.length > 50) {
      _showMessage('Maksimal 50 baris item dalam satu pesanan.');
      return;
    }

    // API Laravel mensyaratkan id_varian yang berbeda pada setiap baris.
    final variantIds = items.map((item) => item.variant.idVarian).toSet();
    if (variantIds.length != items.length) {
      _showMessage(
        'Varian yang sama tidak dapat dikirim dalam dua jenis harga pada satu pesanan. '
        'Silakan sisakan satu jenis harga untuk setiap varian.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final order = await OrderService.createOrder(
        jenisPemenuhan: _orderType,
        jenisPesanan: _fulfillmentMethod,
        idAlamat: _fulfillmentMethod == _delivery
            ? _selectedAddress!.idAlamat
            : null,
        idOutlet: _fulfillmentMethod == _pickup
            ? _selectedOutlet!.idOutlet
            : null,
        catatan: _noteController.text,
        items: items,
      );

      // Pesanan sudah tercatat. Kosongkan keranjang sebelum membuat transaksi
      // pembayaran agar kegagalan gateway tidak menyebabkan pesanan dibuat ulang.
      CartService.clear();

      if (!mounted) return;

      Map<String, dynamic>? payment;
      String? paymentError;
      final rawOrderId = order['id_pesanan'];
      final orderId = rawOrderId is int
          ? rawOrderId
          : int.tryParse(rawOrderId?.toString() ?? '');

      if (orderId == null || orderId <= 0) {
        paymentError =
            'Pesanan berhasil dibuat, tetapi ID pesanan tidak tersedia untuk memulai pembayaran. '
            'Jangan membuat pesanan baru. Periksa riwayat pesanan.';
      } else {
        try {
          payment = await PaymentService.createPayment(
            idPesanan: orderId,
            jenisPembayaran: _paymentType,
          );
        } on PaymentApiException catch (error) {
          paymentError = error.message;
        } catch (_) {
          paymentError =
              'Pesanan berhasil dibuat, tetapi status pembuatan pembayaran belum dapat dipastikan. '
              'Periksa detail pesanan sebelum mencoba kembali.';
        }
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            order: order,
            payment: payment,
            paymentError: paymentError,
          ),
        ),
      );
    } on OrderApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Respons server tidak dapat dipastikan. Periksa riwayat pesanan '
          'sebelum mengirim ulang agar tidak membuat pesanan ganda. ($error)',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: items.isEmpty
          ? const Center(child: Text('Keranjang masih kosong.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOrderTypeCard(),
                const SizedBox(height: 12),
                _buildFulfillmentMethodCard(),
                const SizedBox(height: 12),
                _buildPaymentSelectionCard(),
                const SizedBox(height: 12),
                if (_fulfillmentMethod == _delivery)
                  _buildDeliveryAddressCard()
                else
                  _buildOutletSelectionCard(),
                const SizedBox(height: 12),
                _buildOrderSummary(items),
                const SizedBox(height: 12),
                _buildNoteField(),
                if (_fulfillmentMethod == _delivery) ...[
                  const SizedBox(height: 12),
                  _buildShippingInformation(),
                ],
                const SizedBox(height: 20),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _canSubmit ? _submitOrder : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Buat Pesanan'),
              ),
            ),
    );
  }

  Widget _buildOrderTypeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jenis Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _orderType,
              onChanged: (value) {
                if (value != null) setState(() => _orderType = value);
              },
              child: const RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: _regular,
                title: Text('Reguler'),
                subtitle: Text('Mengikuti ketersediaan stok reguler.'),
              ),
            ),
            FutureBuilder<bool>(
              future: _preOrderEligibilityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }

                if (snapshot.data != true) return const SizedBox.shrink();

                return RadioGroup<String>(
                  groupValue: _orderType,
                  onChanged: (value) {
                    if (value != null) setState(() => _orderType = value);
                  },
                  child: const RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: _preOrder,
                    title: Text('Pre-order'),
                    subtitle: Text(
                      'Tersedia untuk akun Toko/Horeca terverifikasi '
                      'dan seluruh varian dalam keranjang memenuhi periode pre-order.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFulfillmentMethodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RadioGroup<String>(
          groupValue: _fulfillmentMethod,
          onChanged: (value) {
            if (value != null) setState(() => _fulfillmentMethod = value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Metode Pemenuhan Pesanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: _delivery,
                title: Text('Pengiriman'),
                subtitle: Text('Pesanan dikirim ke alamat pelanggan.'),
              ),
              const RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: _pickup,
                title: Text('Ambil di Outlet'),
                subtitle: Text(
                  'Pelanggan mengambil pesanan langsung di outlet.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pembayaran digital diproses melalui Midtrans. Nominal final '
              'ditentukan dan divalidasi oleh Laravel.',
              style: TextStyle(color: Colors.black54),
            ),
            RadioGroup<String>(
              groupValue: _paymentType,
              onChanged: (value) {
                if (value != null) setState(() => _paymentType = value);
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'penuh',
                    title: Text('Bayar penuh'),
                    subtitle: Text('Membayar seluruh tagihan produk.'),
                  ),
                ],
              ),
            ),
            FutureBuilder<bool>(
              future: _dpEligibilityFuture,
              builder: (context, snapshot) {
                if (snapshot.data != true) {
                  if (_paymentType == 'dp') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _paymentType == 'dp') {
                        setState(() => _paymentType = 'penuh');
                      }
                    });
                  }
                  return const SizedBox.shrink();
                }

                return RadioGroup<String>(
                  groupValue: _paymentType,
                  onChanged: (value) {
                    if (value != null) setState(() => _paymentType = value);
                  },
                  child: const RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'dp',
                    title: Text('DP 50%'),
                    subtitle: Text(
                      'Khusus Toko/Horeca terverifikasi. '
                      'Tetap bergantung pada minimum nominal dan pengaturan DP mitra.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            const Text(
              'DP dapat dipilih untuk pesanan reguler maupun pre-order. '
              'Jika tidak memenuhi ketentuan, Laravel akan meminta pembayaran penuh.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (_fulfillmentMethod == _pickup)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pembayaran tunai di outlet belum tersedia melalui endpoint aplikasi saat ini. '
                  'Untuk checkout tahap ini, gunakan Midtrans.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    final address = _selectedAddress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Alamat Pengiriman',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _chooseAddress,
                  child: Text(address == null ? 'Pilih Alamat' : 'Ubah'),
                ),
              ],
            ),
            if (address == null)
              const Text('Alamat wajib dipilih untuk metode pengiriman.')
            else ...[
              Text('${address.namaPenerima} • ${address.nomorTelepon}'),
              const SizedBox(height: 4),
              Text(
                '${address.label}: ${address.alamatLengkap}, ${address.kota}, '
                '${address.provinsi} ${address.kodePos}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutletSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Outlet>>(
          future: _outletsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daftar outlet gagal dimuat.'),
                  TextButton(
                    onPressed: _refreshOutlets,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              );
            }

            final outlets = snapshot.data ?? [];
            if (outlets.isEmpty) {
              return const Text(
                'Belum ada outlet yang tersedia untuk pengambilan.',
              );
            }

            if (_selectedOutlet == null ||
                !outlets.any(
                  (outlet) => outlet.idOutlet == _selectedOutlet!.idOutlet,
                )) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedOutlet == null) {
                  setState(() => _selectedOutlet = outlets.first);
                }
              });
            }

            return RadioGroup<int>(
              groupValue: _selectedOutlet?.idOutlet,
              onChanged: (value) {
                if (value == null) return;
                final selected = outlets.where(
                  (item) => item.idOutlet == value,
                );
                if (selected.isNotEmpty) {
                  setState(() => _selectedOutlet = selected.first);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Outlet Pengambilan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...outlets.map(
                    (outlet) => RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      value: outlet.idOutlet,
                      title: Text(outlet.namaOutlet),
                      subtitle: outlet.alamat == null
                          ? null
                          : Text(outlet.alamat!),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderSummary(List<CartItem> items) {
    final subtotal = items.fold<int>(0, (total, item) => total + item.subtotal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product.namaProduk}\n'
                        '${item.variant.namaVarian} • ${item.quantity} x '
                        'Rp ${item.price.harga}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Rp ${item.subtotal}'),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal sementara',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp $subtotal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Nominal final dihitung ulang oleh Laravel saat pesanan dibuat.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Catatan pesanan (opsional)',
            hintText: 'Tambahkan catatan untuk pesanan...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }

  Widget _buildShippingInformation() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Biaya pengiriman dibayarkan penerima kepada kurir saat pesanan diterima. '
          'Biaya pengiriman tidak termasuk subtotal produk TWFOOD.',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
