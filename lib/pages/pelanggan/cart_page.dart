import 'package:flutter/material.dart';

import '../../models/address.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/product_image_url.dart';
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
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(items.length),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyCart()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      _buildDeliveryAddressCard(),
                      const SizedBox(height: 14),
                      ...items.map(_buildCartItem),
                      const SizedBox(height: 2),
                      _buildPriceSummary(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: items.isEmpty ? null : _buildCheckoutBar(),
    );
  }

  // Kepala halaman: judul besar yang jelas, tanpa blok warna.
  Widget _buildHeader(int itemCount) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 14, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keranjang',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          itemCount == 0
                              ? 'Belum ada produk pilihanmu.'
                              : '$itemCount jenis produk siap dipesan',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (itemCount > 0)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  tooltip: 'Kosongkan keranjang',
                  onPressed: _confirmClearCart,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tombol checkout menempel di bawah halaman.
  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total sementara', style: AppTextStyles.bodySmall),
              const SizedBox(height: 2),
              Text(
                _rupiah(CartService.totalPrice),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _openCheckout,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(Product product) {
    final url = product.fotoProduk;
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentSoft, AppColors.secondarySoft],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.secondary,
        size: 30,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 78,
        height: 78,
        child: (url == null || url.trim().isEmpty)
            ? fallback
            : Image.network(
                ProductImageUrl.resolve(url),
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final minimum = _minimumQuantityFor(item);
    final isWholesale = item.price.jenisHarga.toLowerCase() == 'grosir';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemImage(item.product),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.namaProduk,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.variant.namaVarian,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isWholesale
                            ? AppColors.accentSoft
                            : AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isWholesale ? 'Harga grosir' : 'Harga retail',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: isWholesale
                              ? const Color(0xFFB07A00)
                              : const Color(0xFFD9780A),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_rupiah(item.price.harga)} / ${item.variant.satuanJual ?? 'unit'}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isWholesale && minimum > 1) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Minimum: $minimum ${item.price.satuanMinimal ?? item.variant.satuanJual ?? 'unit'}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
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
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: AppTextStyles.bodyMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.diskonItem > 0)
                    Text(
                      _rupiah(item.subtotal),
                      style: AppTextStyles.bodySmall.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    _rupiah(item.subtotalSetelahDiskon),
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (item.diskonItem > 0)
                    Text(
                      'Campaign ${item.variant.campaignAktif!.nilaiPersen}% • Hemat ${_rupiah(item.diskonItem)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    final address = _selectedDeliveryAddress;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alamat pengiriman',
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 5),
                if (address == null)
                  const Text(
                    'Belum dipilih. Alamat diperlukan jika pesanan dikirim.',
                    style: AppTextStyles.bodySmall,
                  )
                else ...[
                  Text(
                    '${address.namaPenerima} • ${address.nomorTelepon}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
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
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentSoft, AppColors.secondarySoft],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total sementara', style: AppTextStyles.bodyMedium),
              Text(
                _rupiah(CartService.totalPrice),
                style: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.primary),
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
                color: AppColors.secondarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 54,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 22),
            const Text('Keranjang masih kosong',
                style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Pilih produk TWFOOD yang kamu inginkan. Produk pilihanmu akan muncul di sini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
          SizedBox(
            width: 26,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ),
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