import 'package:flutter/material.dart';
import '../models/transaction_item_model.dart';
import '../models/product_model.dart';

class TransactionProvider with ChangeNotifier {
  final List<TransaksiItem> _cart = [];
  List<TransaksiItem> get cart => List.unmodifiable(_cart);

  int get totalPrice => _cart.fold(0, (sum, item) => sum + item.subtotal);
  int get totalItems => _cart.fold(0, (sum, item) => sum + item.qty);

  void addToCart(Barang product) {
    final index = _cart.indexWhere((item) => item.barangId == product.id);
    if (index != -1) {
      if (_cart[index].qty < product.stok) {
        _cart[index].qty++;
      }
    } else {
      _cart.add(TransaksiItem(
        barangId: product.id,
        namaBarang: product.nama,
        harga: product.harga,
        qty: 1,
      ));
    }
    notifyListeners();
  }

  void updateQty(int index, int delta, int stokLimit) {
    if (index < 0 || index >= _cart.length) return;
    
    final item = _cart[index];
    if (delta > 0 && item.qty >= stokLimit) return;
    
    item.qty += delta;
    if (item.qty <= 0) {
      _cart.removeAt(index);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
