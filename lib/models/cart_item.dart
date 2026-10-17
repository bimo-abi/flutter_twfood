import 'product.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  final ProductPrice price;
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    required this.price,
    this.quantity = 1,
  });
//perhitungan subtotal harga berdasarkan quantity dan harga produk
  int get subtotal => price.harga * quantity;

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      product: product,
      variant: variant,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}
