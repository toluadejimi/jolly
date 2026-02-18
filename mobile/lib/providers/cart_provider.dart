// ignore: file_names
import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get count => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));

  void add(CartItem item) {
    final existing = _items.indexWhere((e) =>
        e.productId == item.productId && e.variantId == item.variantId);
    if (existing >= 0) {
      _items[existing].quantity += item.quantity;
    } else {
      _items.add(CartItem(
        productId: item.productId,
        variantId: item.variantId,
        name: item.name,
        price: item.price,
        imageUrl: item.imageUrl,
        currency: item.currency,
        quantity: item.quantity,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int? variantId, int quantity) {
    final i = _items.indexWhere((e) =>
        e.productId == productId && e.variantId == variantId);
    if (i < 0) return;
    if (quantity <= 0) {
      _items.removeAt(i);
    } else {
      _items[i].quantity = quantity;
    }
    notifyListeners();
  }

  void remove(int productId, {int? variantId}) {
    _items.removeWhere((e) =>
        e.productId == productId && e.variantId == variantId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
