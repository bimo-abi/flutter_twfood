import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  CartService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final List<CartItem> _items = [];

  static int? _userId;
  static bool _initialized = false;

  static List<CartItem> get items => List.unmodifiable(_items);

  static int get totalItems =>
      _items.fold(0, (total, item) => total + item.quantity);

  static int get totalPrice =>
      _items.fold(0, (total, item) => total + item.subtotal);

  // Memuat keranjang berdasarkan ID pengguna yang sedang login.
  static Future<void> initializeForUser(int userId) async {
    if (_initialized && _userId == userId) return;

    _items.clear();
    _userId = userId;
    _initialized = false;

    final key = _storageKey(userId);

    try {
      final savedData = await _storage.read(key: key);

      if (savedData != null && savedData.isNotEmpty) {
        final decoded = jsonDecode(savedData);

        if (decoded is List) {
          for (final rawItem in decoded) {
            if (rawItem is! Map) continue;

            try {
              final data = Map<String, dynamic>.from(rawItem);

              final productData =
                  Map<String, dynamic>.from(data['product'] as Map);
              final variantData =
                  Map<String, dynamic>.from(data['variant'] as Map);
              final priceData =
                  Map<String, dynamic>.from(data['price'] as Map);

              final quantity =
                  int.tryParse(data['quantity'].toString()) ?? 0;

              if (quantity <= 0) continue;

              _items.add(
                CartItem(
                  product: Product.fromJson(productData),
                  variant: ProductVariant.fromJson(variantData),
                  price: ProductPrice.fromJson(priceData),
                  quantity: quantity,
                ),
              );
            } catch (e) {
              debugPrint('Item keranjang tidak dapat dipulihkan: $e');
            }
          }
        }
      }

      _initialized = true;
    } catch (e) {
      _items.clear();
      _initialized = false;
      debugPrint('Gagal memuat keranjang: $e');
      rethrow;
    }
  }

  static String _storageKey(int userId) => 'twfood_cart_$userId';

  // Menyimpan seluruh item keranjang ke penyimpanan lokal.
  static Future<void> _save() async {
    if (!_initialized || _userId == null) return;

    final data = _items.map((item) {
      return {
        'product': item.product.toJson(),
        'variant': item.variant.toJson(),
        'price': item.price.toJson(),
        'quantity': item.quantity,
      };
    }).toList();

    await _storage.write(
      key: _storageKey(_userId!),
      value: jsonEncode(data),
    );
  }

  // Menangani penyimpanan untuk fungsi yang tetap sinkron.
  static void _saveInBackground() {
    _save().catchError((Object e) {
      debugPrint('Gagal menyimpan keranjang: $e');
    });
  }

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

    _saveInBackground();
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

    _saveInBackground();
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

    _saveInBackground();
  }

  static void clear() {
    _items.clear();
    _saveInBackground();
  }

  // Membersihkan data di memori ketika pengguna keluar.
  // Data tersimpan tetap tersedia saat pengguna login kembali.
  static void resetSession() {
    _items.clear();
    _userId = null;
    _initialized = false;
  }
}
