import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../utils/product_image_url.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'checkout_page.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = ProductService.getProductById(widget.productId);
  }

  Future<void> _refreshProduct() async {
    final future = ProductService.getProductById(widget.productId);
    setState(() => _productFuture = future);
    await future;
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return 'Rp $buffer';
  }

  int? _startingPrice(List<ProductVariant> variants) {
    final prices = variants
        .expand((variant) => variant.daftarHarga)
        .where((price) => price.statusAktif)
        .map((price) => price.harga)
        .toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              shadowColor: Colors.black26,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final product = snapshot.data;
          if (product == null) {
            return _buildMessageState(
              icon: Icons.inventory_2_outlined,
              title: 'Produk tidak ditemukan',
              message: 'Informasi produk belum tersedia.',
            );
          }

          if (!product.statusAktif) {
            return _buildMessageState(
              icon: Icons.remove_shopping_cart_outlined,
              title: 'Produk tidak tersedia',
              message: 'Produk ini sedang tidak tersedia untuk dibeli.',
            );
          }

          final activeVariants = product.varian
              .where((variant) => variant.statusAktif)
              .toList();
          final startingPrice = _startingPrice(activeVariants);
          final hasDescription = product.deskripsi != null &&
              product.deskripsi!.trim().isNotEmpty;

          return RefreshIndicator(
            color: AppColors.primary,
            edgeOffset: 80,
            onRefresh: _refreshProduct,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _buildProductImage(product),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.namaProduk,
                          style: AppTextStyles.headingLarge),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPill(
                            Icons.layers_rounded,
                            '${activeVariants.length} varian',
                            AppColors.secondary,
                            AppColors.secondarySoft,
                          ),
                          if (startingPrice != null)
                            _buildPill(
                              Icons.sell_rounded,
                              'Mulai ${_formatRupiah(startingPrice)}',
                              AppColors.primary,
                              AppColors.primarySoft,
                            ),
                        ],
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tentang produk',
                                  style: AppTextStyles.headingSmall),
                              const SizedBox(height: 8),
                              Text(
                                product.deskripsi!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Pilih Varian',
                              style: AppTextStyles.headingMedium),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (activeVariants.isEmpty)
                        _buildEmptyVariants()
                      else
                        ...activeVariants.map(
                          (variant) => _buildVariantCard(product, variant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // Foto produk besar di bagian atas, sudut bawah membulat.
  Widget _buildProductImage(Product product) {
    final hasImage =
        product.fotoProduk != null && product.fotoProduk!.trim().isNotEmpty;

    return Container(
      height: 330,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          hasImage
              ? Image.network(
                  ProductImageUrl.resolve(product.fotoProduk),
                  fit: BoxFit.cover,
                  // Cadangan untuk Chrome (web) bila foto terhalang aturan CORS.
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (context, error, stackTrace) =>
                      _imagePlaceholder(),
                )
              : _imagePlaceholder(),
          // Bayangan tipis di atas agar tombol kembali selalu terlihat.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 110,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x40000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentSoft, AppColors.secondarySoft],
        ),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/logo.png',
        width: 96,
        height: 96,
        errorBuilder: (_, _, _) => const Icon(
          Icons.fastfood_rounded,
          size: 64,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildVariantCard(Product product, ProductVariant variant) {
    final prices = variant.daftarHarga
        .where((price) => price.statusAktif)
        .toList();

    return _VariantPurchaseCard(
      product: product,
      variant: variant,
      prices: prices,
    );
  }

  Widget _buildEmptyVariants() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 36, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text('Belum ada varian aktif', style: AppTextStyles.headingSmall),
          SizedBox(height: 4),
          Text(
            'Silakan periksa kembali nanti.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 52, color: AppColors.error),
            const SizedBox(height: 14),
            const Text('Detail produk gagal dimuat',
                style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _refreshProduct,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            Text(title, style: AppTextStyles.headingSmall),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Produk'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantPurchaseCard extends StatefulWidget {
  final Product product;
  final ProductVariant variant;
  final List<ProductPrice> prices;

  const _VariantPurchaseCard({
    required this.product,
    required this.variant,
    required this.prices,
  });

  @override
  State<_VariantPurchaseCard> createState() => _VariantPurchaseCardState();
}

class _VariantPurchaseCardState extends State<_VariantPurchaseCard> {
  ProductPrice? _selectedPrice;
  int _quantity = 1;
  late Future<bool> _preOrderCustomerEligibilityFuture;

  @override
  void initState() {
    super.initState();
    _preOrderCustomerEligibilityFuture = _checkPreOrderCustomerEligibility();

    if (widget.prices.isNotEmpty) {
      _selectedPrice = widget.prices.firstWhere(
        (price) => price.jenisHarga.toLowerCase() == 'ecer',
        orElse: () => widget.prices.first,
      );
    }
  }

  Future<bool> _checkPreOrderCustomerEligibility() async {
    try {
      final response = await AuthService.me();
      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);
      final rawUser = decoded is Map ? decoded['data'] : null;
      if (rawUser is! Map) return false;

      final user = Map<String, dynamic>.from(rawUser);
      return ['toko', 'horeca'].contains(
            user['jenis_pelanggan']?.toString().trim().toLowerCase(),
          ) &&
          user['status_verifikasi']?.toString().trim().toLowerCase() ==
              'disetujui';
    } catch (_) {
      return false;
    }
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);

      final remaining = digits.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return 'Rp $buffer';
  }

  CampaignDiscount? get _campaignAktif {
    final campaign = widget.variant.campaignAktif;
    if (campaign == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mulai = campaign.tanggalMulai == null
        ? null
        : DateTime(campaign.tanggalMulai!.year, campaign.tanggalMulai!.month, campaign.tanggalMulai!.day);
    final selesai = campaign.tanggalSelesai == null
        ? null
        : DateTime(campaign.tanggalSelesai!.year, campaign.tanggalSelesai!.month, campaign.tanggalSelesai!.day);
    if ((mulai != null && today.isBefore(mulai)) ||
        (selesai != null && today.isAfter(selesai))) return null;
    return campaign;
  }

  bool get _isWholesale => _selectedPrice?.jenisHarga.toLowerCase() == 'grosir';

  // Validasi konversi satuan dibuat konservatif.
  // Grosir hanya dapat dipilih jika satuan minimum sama
  // dengan satuan jual varian.
  bool get _canValidateWholesaleUnit {
    final price = _selectedPrice;

    if (price == null || !_isWholesale) {
      return true;
    }

    final minimumUnit = price.satuanMinimal?.trim();
    final saleUnit = widget.variant.satuanJual?.trim();

    if (minimumUnit == null ||
        minimumUnit.isEmpty ||
        saleUnit == null ||
        saleUnit.isEmpty) {
      return false;
    }

    return minimumUnit.toLowerCase() == saleUnit.toLowerCase();
  }

  bool get _meetsWholesaleMinimum {
    final price = _selectedPrice;

    if (price == null || !_isWholesale) {
      return true;
    }

    final minimum = price.minimalPembelian;

    if (minimum == null) {
      return false;
    }

    return _quantity >= minimum;
  }

  bool get _quantityWithinStock =>
      _quantity > 0 && _quantity <= widget.variant.stok;

  bool get _isPreOrderPeriodOpen {
    final start = widget.variant.tanggalMulaiPreOrder;
    final end = widget.variant.tanggalSelesaiPreOrder;
    if (!widget.variant.tersediaPreOrder || start == null || end == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localStart = start.toLocal();
    final localEnd = end.toLocal();
    final startDate = DateTime(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    final endDate = DateTime(localEnd.year, localEnd.month, localEnd.day);
    return !today.isBefore(startDate) && !today.isAfter(endDate);
  }

  bool get _canPurchasePreOrder =>
      _selectedPrice != null &&
      _isPreOrderPeriodOpen &&
      _canValidateWholesaleUnit &&
      _meetsWholesaleMinimum &&
      _quantity > 0;

  bool get _canAddToCart {
    if (_selectedPrice == null || widget.variant.stok <= 0) {
      return false;
    }

    if (!_quantityWithinStock) {
      return false;
    }

    if (!_canValidateWholesaleUnit) {
      return false;
    }

    if (!_meetsWholesaleMinimum) {
      return false;
    }

    return true;
  }

  String get _purchaseMessage {
    if (_selectedPrice == null) {
      return 'Harga belum tersedia.';
    }

    if (widget.variant.stok <= 0) {
      return _isPreOrderPeriodOpen
          ? 'Stok reguler habis. Gunakan tombol Pesan Pre-order.'
          : 'Stok reguler sedang tidak tersedia.';
    }

    if (!_canValidateWholesaleUnit) {
      return 'Satuan minimum grosir berbeda dari satuan jual. '
          'Konversi satuan perlu ditentukan terlebih dahulu.';
    }

    if (!_meetsWholesaleMinimum) {
      return 'Jumlah belum memenuhi minimum pembelian grosir.';
    }

    if (!_quantityWithinStock) {
      return _isPreOrderPeriodOpen
          ? 'Jumlah melebihi stok reguler. Gunakan tombol Pesan Pre-order.'
          : 'Jumlah pembelian melebihi stok tersedia.';
    }

    return '';
  }

  void _changeQuantity(int difference) {
    final nextQuantity = _quantity + difference;

    if (nextQuantity < 1) {
      return;
    }

    setState(() {
      _quantity = nextQuantity;
    });
  }

  Future<void> _buyNow({required bool preOrder}) async {
    final price = _selectedPrice;
    final canProceed = preOrder ? _canPurchasePreOrder : _canAddToCart;
    if (price == null || !canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            preOrder
                ? 'Pre-order tidak tersedia atau jumlah belum memenuhi minimum pembelian.'
                : (_purchaseMessage.isEmpty
                    ? 'Periksa pilihan harga dan jumlah pembelian.'
                    : _purchaseMessage),
          ),
        ),
      );
      return;
    }

    if (preOrder) {
      try {
        final response = await AuthService.me();
        if (response.statusCode != 200) {
          throw Exception('Sesi pelanggan tidak dapat diverifikasi.');
        }
        final decoded = jsonDecode(response.body);
        final user = decoded is Map && decoded['data'] is Map
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : <String, dynamic>{};
        final eligible =
            ['toko', 'horeca'].contains(user['jenis_pelanggan']?.toString()) &&
            user['status_verifikasi']?.toString() == 'disetujui';
        if (!eligible) {
          throw Exception(
            'Pre-order hanya tersedia untuk pelanggan Toko/Horeca yang sudah terverifikasi.',
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error.toString().replaceFirst('Exception: ', ''),
              ),
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    final item = CartItem(
      product: widget.product,
      variant: widget.variant,
      price: price,
      quantity: _quantity,
    );
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          initialItems: [item],
          initialOrderType: preOrder ? 'pre_order' : 'reguler',
        ),
      ),
    );
  }

  void _addToCart() {
    final price = _selectedPrice;

    if (price == null || !_canAddToCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _purchaseMessage.isEmpty
                ? 'Periksa pilihan harga dan jumlah pembelian.'
                : _purchaseMessage,
          ),
        ),
      );
      return;
    }

    final errorMessage = CartService.addItem(
      CartItem(
        product: widget.product,
        variant: widget.variant,
        price: price,
        quantity: _quantity,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage ??
              '${widget.variant.namaVarian} ditambahkan ke keranjang.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.variant;
    final isAvailable = variant.stok > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(variant.namaVarian,
                        style: AppTextStyles.headingSmall),
                    if (variant.beratGram != null ||
                        variant.satuanJual != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _buildVariantInfo(variant),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isAvailable ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAvailable ? 'Stok ${variant.stok}' : 'Stok habis',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: isAvailable ? AppColors.success : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          if (widget.prices.isEmpty)
            const Text(
              'Harga aktif belum tersedia.',
              style: AppTextStyles.bodySmall,
            )
          else ...[
            Text('Pilih harga',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.prices.map((price) {
                final selected = _selectedPrice == price;
                final label = price.jenisHarga.toLowerCase() == 'grosir'
                    ? 'Grosir'
                    : 'Ecer';
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedPrice = price),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primarySoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (price.jenisHarga == 'ecer' && _campaignAktif != null) ...[
                          Text(
                            _formatRupiah(price.harga),
                            style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            _formatRupiah(price.harga - (price.harga * _campaignAktif!.nilaiPersen / 100 + 0.5).floor()),
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 15, fontWeight: FontWeight.w800, color: selected ? AppColors.primary : AppColors.success),
                          ),
                          Text('Diskon ${_campaignAktif!.nilaiPersen.toStringAsFixed(_campaignAktif!.nilaiPersen % 1 == 0 ? 0 : 2)}%', style: const TextStyle(fontSize: 10, color: AppColors.success)),
                        ] else
                          Text(
                            _formatRupiah(price.harga),
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 15, fontWeight: FontWeight.w800, color: selected ? AppColors.primary : AppColors.textPrimary),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedPrice != null &&
                _isWholesale &&
                _selectedPrice!.minimalPembelian != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Minimal pembelian: ${_selectedPrice!.minimalPembelian} '
                    '${_selectedPrice!.satuanMinimal ?? ''}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Jumlah pembelian',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed:
                            _quantity > 1 ? () => _changeQuantity(-1) : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed:
                            (_isPreOrderPeriodOpen || _quantity < variant.stok)
                                ? () => _changeQuantity(1)
                                : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (variant.satuanJual != null && variant.satuanJual!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Satuan: ${variant.satuanJual}',
                      style: AppTextStyles.bodySmall),
                ),
              ),
            if (_purchaseMessage.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _purchaseMessage,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            if (_selectedPrice != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Subtotal', style: AppTextStyles.bodyMedium),
                  const Spacer(),
                  Text(
                    _formatRupiah((_selectedPrice!.harga - (_selectedPrice!.jenisHarga == 'ecer' && _campaignAktif != null ? (_selectedPrice!.harga * _campaignAktif!.nilaiPersen / 100 + 0.5).floor() : 0)) * _quantity),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _canAddToCart ? _addToCart : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Keranjang'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        _canAddToCart ? () => _buyNow(preOrder: false) : null,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Beli Sekarang'),
                  ),
                ),
              ],
            ),
            FutureBuilder<bool>(
              future: _preOrderCustomerEligibilityFuture,
              builder: (context, snapshot) {
                if (snapshot.data != true || !_isPreOrderPeriodOpen) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_available,
                              color: AppColors.secondary, size: 19),
                          const SizedBox(width: 7),
                          Text(
                            'Tersedia Pre-Order',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (variant.tanggalMulaiPreOrder != null)
                        Text(
                            'Mulai: ${_formatDate(variant.tanggalMulaiPreOrder!)}',
                            style: AppTextStyles.bodySmall),
                      if (variant.tanggalSelesaiPreOrder != null)
                        Text(
                            'Berakhir: ${_formatDate(variant.tanggalSelesaiPreOrder!)}',
                            style: AppTextStyles.bodySmall),
                      if (variant.estimasiTersedia != null)
                        Text(
                            'Estimasi tersedia: ${_formatDate(variant.estimasiTersedia!)}',
                            style: AppTextStyles.bodySmall),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _canPurchasePreOrder
                              ? () => _buyNow(preOrder: true)
                              : null,
                          icon: const Icon(Icons.event_available),
                          label: const Text('Pesan Pre-order'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Khusus Toko/Horeca terverifikasi. Pesanan dicatat terpisah dan tidak mengurangi stok reguler.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _buildVariantInfo(ProductVariant variant) {
    final List<String> info = [];

    if (variant.beratGram != null) {
      info.add('${variant.beratGram} gram');
    }

    if (variant.satuanJual != null && variant.satuanJual!.isNotEmpty) {
      info.add(variant.satuanJual!);
    }

    return info.join(' • ');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day-$month-$year';
  }
}