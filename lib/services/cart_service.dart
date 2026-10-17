import '../models/cart_item.dart';

class CartService {
  CartService._();

  static final List<CartItem> _items = [];

  static List<CartItem> get items =>
      List.unmodifiable(_items);

  static int get totalItems =>
      _items.fold(0, (total, item) => total + item.quantity);

  static int get totalPrice =>
      _items.fold(0, (total, item) => total + item.subtotal);

  static void addItem(CartItem newItem) {
    final index = _items.indexWhere(
      (item) =>
          item.variant.idVarian == newItem.variant.idVarian &&
          item.price.idDaftarHarga == newItem.price.idDaftarHarga,
    );

    if (index != -1) {
      _items[index].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
  }

  static void updateQuantity({
    required int variantId,
    required int priceId,
    required int quantity,
  }) {
    final index = _items.indexWhere(
      (item) =>
          item.variant.idVarian == variantId &&
          item.price.idDaftarHarga == priceId,
    );

    if (index == -1) return;

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
  }

  static void removeItem({
    required int variantId,
    required int priceId,
  }) {
    _items.removeWhere(
      (item) =>
          item.variant.idVarian == variantId &&
          item.price.idDaftarHarga == priceId,
    );
  }

  static void clear() {
    _items.clear();
  }
}
