import 'package:flutter/material.dart';

class LabCartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;
  int get itemCount => _items.length;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item['sellingPrice'] as num).toDouble());
  }

  double get collectionFee => itemCount > 0 ? 150.0 : 0.0;

  double get totalAmount => subtotal + collectionFee;

  bool isPackageInCart(Map<String, dynamic> package) {
    return _items.any((item) => item['name'] == package['name']);
  }

  void addItem(Map<String, dynamic> package) {
    if (!isPackageInCart(package)) {
      _items.add(package);
      notifyListeners();
    }
  }

  void removeItem(Map<String, dynamic> package) {
    _items.removeWhere((item) => item['name'] == package['name']);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
