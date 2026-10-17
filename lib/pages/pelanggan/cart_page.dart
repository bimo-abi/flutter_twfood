
import 'package:flutter/material.dart';

import '../../services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final items = CartService.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Saya'),
        automaticallyImplyLeading: false,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Kosongkan keranjang',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmClearCart,
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyCart()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.namaProduk,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Varian: ${item.variant.namaVarian}'),
                          Text('Jenis harga: ${item.price.jenisHarga}'),
                          Text(
                            'Harga satuan: Rp ${item.price.harga}',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  _updateQuantity(
                                    item.variant.idVarian,
                                    item.price.idDaftarHarga,
                                    item.quantity - 1,
                                  );
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                ),
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _updateQuantity(
                                    item.variant.idVarian,
                                    item.price.idDaftarHarga,
                                    item.quantity + 1,
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Hapus item',
                                onPressed: () {
                                  _removeItem(
                                    item.variant.idVarian,
                                    item.price.idDaftarHarga,
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Subtotal: Rp ${item.subtotal}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp ${CartService.totalPrice}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              'Keranjang masih kosong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Pilih produk TWFOOD untuk mulai berbelanja.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuantity(int variantId, int priceId, int quantity) {
    setState(() {
      CartService.updateQuantity(
        variantId: variantId,
        priceId: priceId,
        quantity: quantity,
      );
    });
  }

  void _removeItem(int variantId, int priceId) {
    setState(() {
      CartService.removeItem(
        variantId: variantId,
        priceId: priceId,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item dihapus dari keranjang.')),
    );
  }

  Future<void> _confirmClearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text(
          'Semua item dalam keranjang akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(CartService.clear);
    }
  }
}
