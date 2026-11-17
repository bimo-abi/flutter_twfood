import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
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

    setState(() {
      _productFuture = future;
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal mengambil detail produk.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshProduct,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = snapshot.data;

          if (product == null) {
            return const Center(child: Text('Data produk tidak ditemukan.'));
          }

          if (!product.statusAktif) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Produk ini sedang tidak tersedia.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final activeVariants = product.varian
              .where((variant) => variant.statusAktif)
              .toList();

          return RefreshIndicator(
            onRefresh: _refreshProduct,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProductImage(product),
                const SizedBox(height: 20),
                Text(
                  product.namaProduk,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (product.deskripsi != null && product.deskripsi!.isNotEmpty)
                  Text(
                    product.deskripsi!,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Varian Produk',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (activeVariants.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Belum ada varian aktif.'),
                    ),
                  )
                else
                  ...activeVariants.map(
                    (variant) => _buildVariantCard(product, variant),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: product.fotoProduk != null && product.fotoProduk!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                product.fotoProduk!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    size: 70,
                  );
                },
              ),
            )
          : const Icon(Icons.fastfood_outlined, size: 70),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              variant.namaVarian,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (variant.beratGram != null || variant.satuanJual != null)
              Text(
                _buildVariantInfo(variant),
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 10),
            Text('Stok: ${variant.stok}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            const SizedBox(height: 14),
            const Text(
              'Harga dan Pembelian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.prices.isEmpty)
              const Text(
                'Harga aktif belum tersedia.',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              DropdownButtonFormField<ProductPrice>(
                initialValue: _selectedPrice,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pilih jenis harga',
                  border: OutlineInputBorder(),
                ),
                items: widget.prices.map((price) {
                  return DropdownMenuItem<ProductPrice>(
                    value: price,
                    child: Text(
                      '${price.jenisHarga.toUpperCase()} - '
                      '${_formatRupiah(price.harga)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (price) {
                  if (price == null) return;

                  setState(() {
                    _selectedPrice = price;
                  });
                },
              ),
              if (_selectedPrice != null &&
                  _isWholesale &&
                  _selectedPrice!.minimalPembelian != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Minimal pembelian: '
                    '${_selectedPrice!.minimalPembelian} '
                    '${_selectedPrice!.satuanMinimal ?? ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Jumlah pembelian',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1 ? () => _changeQuantity(-1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: (_isPreOrderPeriodOpen || _quantity < variant.stok)
                        ? () => _changeQuantity(1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  if (variant.satuanJual != null)
                    Expanded(
                      child: Text(
                        variant.satuanJual!,
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
              if (_purchaseMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _purchaseMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canAddToCart ? () => _buyNow(preOrder: false) : null,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Beli Sekarang'),
                ),
              ),
              FutureBuilder<bool>(
                future: _preOrderCustomerEligibilityFuture,
                builder: (context, snapshot) {
                  if (snapshot.data != true || !_isPreOrderPeriodOpen) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Tersedia Pre-Order',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (variant.tanggalMulaiPreOrder != null)
                        Text(
                          'Mulai Pre-Order: '
                          '${_formatDate(variant.tanggalMulaiPreOrder!)}',
                        ),
                      if (variant.tanggalSelesaiPreOrder != null)
                        Text(
                          'Selesai Pre-Order: '
                          '${_formatDate(variant.tanggalSelesaiPreOrder!)}',
                        ),
                      if (variant.estimasiTersedia != null)
                        Text(
                          'Estimasi tersedia: '
                          '${_formatDate(variant.estimasiTersedia!)}',
                        ),
                      const SizedBox(height: 8),
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
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Khusus Toko/Horeca terverifikasi. Pesanan dicatat terpisah dan tidak mengurangi stok reguler.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _canAddToCart ? _addToCart : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Tambah ke Keranjang'),
                ),
              ),
            ],
          ],
        ),
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
