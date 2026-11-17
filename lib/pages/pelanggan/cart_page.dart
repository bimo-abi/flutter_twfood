import 'package:flutter/material.dart';

import '../../models/address.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'address_selection_page.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Address? _selectedDeliveryAddress;

  @override
  void initState() {
    super.initState();
    CartService.changes.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartService.changes.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  int _minimumQuantityFor(CartItem item) {
    if (item.price.jenisHarga.toLowerCase() != 'grosir') return 1;
    return item.price.minimalPembelian ?? 1;
  }

  String _rupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        automaticallyImplyLeading: false,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Kosongkan keranjang',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmClearCart,
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildIntro(items.length),
                const SizedBox(height: 14),
                _buildDeliveryAddressCard(),
                const SizedBox(height: 8),
                ...items.map(_buildCartItem),
                const SizedBox(height: 8),
                _buildPriceSummary(),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: FilledButton.icon(
                onPressed: _openCheckout,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Lanjut ke Checkout'),
              ),
            ),
    );
  }

  Widget _buildIntro(int itemCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Siap melanjutkan belanja?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$itemCount jenis produk di keranjang',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final minimum = _minimumQuantityFor(item);
    final isWholesale = item.price.jenisHarga.toLowerCase() == 'grosir';

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fastfood_outlined,
                    color: AppColors.secondary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.namaProduk,
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.variant.namaVarian,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isWholesale
                              ? AppColors.accent.withValues(alpha: 0.18)
                              : AppColors.secondary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isWholesale ? 'Harga grosir' : 'Harga retail',
                          style: TextStyle(
                            color: isWholesale
                                ? AppColors.textPrimary
                                : AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus item',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmRemoveItem(
                    item.variant.idVarian,
                    item.price.idDaftarHarga,
                    item.product.namaProduk,
                    item.variant.namaVarian,
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_rupiah(item.price.harga)} / ${item.variant.satuanJual ?? 'unit'}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                _QuantityControl(
                  quantity: item.quantity,
                  minimum: minimum,
                  maximum: item.variant.stok,
                  onDecrease: () => _updateQuantity(
                    item.variant.idVarian,
                    item.price.idDaftarHarga,
                    item.quantity - 1,
                  ),
                  onIncrease: () => _updateQuantity(
                    item.variant.idVarian,
                    item.price.idDaftarHarga,
                    item.quantity + 1,
                  ),
                ),
              ],
            ),
            if (isWholesale && minimum > 1) ...[
              const SizedBox(height: 7),
              Text(
                'Minimum pembelian: $minimum ${item.price.satuanMinimal ?? item.variant.satuanJual ?? 'unit'}',
                style: AppTextStyles.bodySmall,
              ),
            ],
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: AppTextStyles.bodyMedium),
                Text(
                  _rupiah(item.subtotal),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    final address = _selectedDeliveryAddress;

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.background,
              child: Icon(Icons.location_on_outlined, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alamat pengiriman', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 5),
                  if (address == null)
                    Text(
                      'Belum dipilih. Alamat diperlukan jika pesanan dikirim.',
                      style: AppTextStyles.bodySmall,
                    )
                  else ...[
                    Text(
                      '${address.namaPenerima} • ${address.nomorTelepon}',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${address.label}: ${address.alamatLengkap}, ${address.kota}, ${address.provinsi} ${address.kodePos}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: _selectDeliveryAddress,
              child: Text(address == null ? 'Pilih' : 'Ubah'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total sementara', style: AppTextStyles.bodyMedium),
                Text(
                  _rupiah(CartService.totalPrice),
                  style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total akhir akan divalidasi kembali saat checkout.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 54,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 22),
            const Text('Keranjang masih kosong', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Pilih produk TWFOOD yang kamu inginkan. Produk pilihanmu akan muncul di sini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDeliveryAddress() async {
    final selectedAddress = await Navigator.push<Address>(
      context,
      MaterialPageRoute(builder: (_) => const AddressSelectionPage()),
    );

    if (selectedAddress != null && mounted) {
      setState(() => _selectedDeliveryAddress = selectedAddress);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat pengiriman berhasil dipilih.')),
      );
    }
  }

  Future<void> _openCheckout() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          initialAddress: _selectedDeliveryAddress,
          initialOrderType: 'reguler',
          clearCartOnSuccess: true,
        ),
      ),
    );
  }

  void _updateQuantity(int variantId, int priceId, int quantity) {
    final errorMessage = CartService.updateQuantity(
      variantId: variantId,
      priceId: priceId,
      quantity: quantity,
    );
    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _confirmRemoveItem(
    int variantId,
    int priceId,
    String productName,
    String variantName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus item?'),
        content: Text('Hapus $productName - $variantName dari keranjang?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      CartService.removeItem(variantId: variantId, priceId: priceId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item dihapus dari keranjang.')),
      );
    }
  }

  Future<void> _confirmClearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text('Semua item dalam keranjang akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Kosongkan')),
        ],
      ),
    );

    if (confirmed == true && mounted) CartService.clear();
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final int minimum;
  final int maximum;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.minimum,
    required this.maximum,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: quantity <= minimum ? null : onDecrease,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          Text('$quantity', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: quantity >= maximum ? null : onIncrease,
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
