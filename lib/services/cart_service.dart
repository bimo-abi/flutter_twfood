import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  CartService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final List<CartItem> _items = [];
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static int? _userId;
  static bool _initialized = false;

  static List<CartItem> get items => List.unmodifiable(_items);
  static int get totalItems =>
      _items.fold(0, (total, item) => total + item.quantity);
  static int get totalPrice =>
      _items.fold(0, (total, item) => total + item.subtotal);
  static bool get isInitialized => _initialized && _userId != null;

  static void _notifyChanged() {
    changes.value++;
  }

  // Memuat keranjang yang terpisah untuk setiap pengguna.
  static Future<void> initializeForUser(int userId) async {
    if (userId <= 0) {
      throw ArgumentError.value(userId, 'userId', 'Harus lebih besar dari 0.');
    }
    if (_initialized && _userId == userId) return;

    _items.clear();
    _userId = userId;
    _initialized = false;
    _notifyChanged();

    try {
      final savedData = await _storage.read(key: _storageKey(userId));
      if (savedData != null && savedData.isNotEmpty) {
        final decoded = jsonDecode(savedData);
        if (decoded is List) {
          for (final rawItem in decoded) {
            if (rawItem is! Map) continue;
            try {
              final data = Map<String, dynamic>.from(rawItem);
              final productData = Map<String, dynamic>.from(
                data['product'] as Map,
              );
              final variantData = Map<String, dynamic>.from(
                data['variant'] as Map,
              );
              final priceData = Map<String, dynamic>.from(data['price'] as Map);
              final quantity = int.tryParse(data['quantity'].toString()) ?? 0;
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
      _notifyChanged();
    } catch (e) {
      _items.clear();
      _initialized = false;
      _notifyChanged();
      debugPrint('Gagal memuat keranjang: $e');
      rethrow;
    }
  }

  static String _storageKey(int userId) => 'twfood_cart_$userId';

  static Future<void> _save() async {
    if (!isInitialized) return;
    final data = _items
        .map(
          (item) => {
            'product': item.product.toJson(),
            'variant': item.variant.toJson(),
            'price': item.price.toJson(),
            'quantity': item.quantity,
          },
        )
        .toList();

    await _storage.write(key: _storageKey(_userId!), value: jsonEncode(data));
  }

  static void _saveInBackground() {
    _save().catchError((Object e) {
      debugPrint('Gagal menyimpan keranjang: $e');
    });
  }

  static int _minimumQuantity(CartItem item) {
    if (item.price.jenisHarga.toLowerCase() != 'grosir') return 1;
    return item.price.minimalPembelian ?? 1;
  }

  static bool _hasCompatibleWholesaleUnit(CartItem item) {
    if (item.price.jenisHarga.toLowerCase() != 'grosir') return true;
    final minimumUnit = item.price.satuanMinimal?.trim().toLowerCase();
    final saleUnit = item.variant.satuanJual?.trim().toLowerCase();
    return minimumUnit != null &&
        minimumUnit.isNotEmpty &&
        saleUnit != null &&
        saleUnit.isNotEmpty &&
        minimumUnit == saleUnit;
  }

  // Mengembalikan pesan error jika item tidak layak ditambahkan.
  // Null berarti item berhasil ditambahkan.
  static String? addItem(CartItem newItem) {
    if (!isInitialized) {
      return 'Sesi pelanggan belum siap. Silakan login kembali.';
    }
    if (!newItem.product.statusAktif) return 'Produk sedang tidak tersedia.';
    if (!newItem.variant.statusAktif) return 'Varian sedang tidak tersedia.';
    if (!newItem.price.statusAktif) {
      return 'Harga yang dipilih sudah tidak tersedia.';
    }
    if (newItem.quantity <= 0) return 'Jumlah pembelian tidak valid.';
    if (newItem.variant.stok <= 0) return 'Stok sedang tidak tersedia.';
    if (!_hasCompatibleWholesaleUnit(newItem)) {
      return 'Satuan minimum grosir berbeda dari satuan jual.';
    }
    if (newItem.quantity < _minimumQuantity(newItem)) {
      return 'Jumlah belum memenuhi minimum pembelian.';
    }

    final index = _items.indexWhere(
      (item) =>
          item.variant.idVarian == newItem.variant.idVarian &&
          item.price.idDaftarHarga == newItem.price.idDaftarHarga,
    );
    final resultingQuantity =
        newItem.quantity + (index == -1 ? 0 : _items[index].quantity);

    if (resultingQuantity > newItem.variant.stok) {
      return 'Jumlah di keranjang melebihi stok tersedia (${newItem.variant.stok}).';
    }

    if (index != -1) {
      _items[index].quantity = resultingQuantity;
    } else {
      _items.add(newItem);
    }

    _notifyChanged();
    _saveInBackground();
    return null;
  }

  // Quantity <= 0 berarti item dihapus. Untuk quantity positif,
  // stok dan minimum pembelian tetap diperiksa.
  static String? updateQuantity({
    required int variantId,
    required int priceId,
    required int quantity,
  }) {
    final index = _items.indexWhere(
      (item) =>
          item.variant.idVarian == variantId &&
          item.price.idDaftarHarga == priceId,
    );
    if (index == -1) return 'Item tidak ditemukan di keranjang.';

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      final item = _items[index];
      if (!item.product.statusAktif ||
          !item.variant.statusAktif ||
          !item.price.statusAktif) {
        return 'Produk, varian, atau harga sudah tidak tersedia.';
      }
      if (!_hasCompatibleWholesaleUnit(item)) {
        return 'Satuan minimum grosir berbeda dari satuan jual.';
      }
      if (quantity < _minimumQuantity(item)) {
        return 'Jumlah minimal untuk harga ini adalah ${_minimumQuantity(item)}.';
      }
      if (quantity > item.variant.stok) {
        return 'Jumlah melebihi stok tersedia (${item.variant.stok}).';
      }
      item.quantity = quantity;
    }

    _notifyChanged();
    _saveInBackground();
    return null;
  }

  static void removeItem({required int variantId, required int priceId}) {
    _items.removeWhere(
      (item) =>
          item.variant.idVarian == variantId &&
          item.price.idDaftarHarga == priceId,
    );
    _notifyChanged();
    _saveInBackground();
  }

  static void clear() {
    _items.clear();
    _notifyChanged();
    _saveInBackground();
  }

  // Membersihkan memori saat sesi berakhir; data lokal per pengguna tetap ada.
  static void resetSession() {
    _items.clear();
    _userId = null;
    _initialized = false;
    _notifyChanged();
  }
}
