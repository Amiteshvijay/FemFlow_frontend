import 'package:flutter/material.dart';
import 'package:femlyra/core/network/api_client.dart';

class LabCartProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  LabCartProvider() {
    fetchCart();
  }

  List<Map<String, dynamic>> get items => _items;
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item['sellingPrice'] as num).toDouble());
  }

  double get collectionFee => itemCount > 0 ? 150.0 : 0.0;

  double get totalAmount => subtotal + collectionFee;

  bool isPackageInCart(Map<String, dynamic> package) {
    return _items.any((item) => item['name'] == package['name']);
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    try {
      final response = await _apiClient.get('/labs/cart/');
      if (response is List) {
        _items = response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch cart from production DB: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(Map<String, dynamic> package) async {
    if (!isPackageInCart(package)) {
      _items.add(package);
      notifyListeners();
      try {
        await _apiClient.post('/labs/cart/', body: package);
      } catch (e) {
        debugPrint('Failed to add item to production DB cart: $e');
      }
    }
  }

  Future<void> removeItem(Map<String, dynamic> package) async {
    _items.removeWhere((item) => item['name'] == package['name']);
    notifyListeners();
    try {
      await _apiClient.delete('/labs/cart/', body: {'name': package['name']});
    } catch (e) {
      debugPrint('Failed to remove item from production DB cart: $e');
    }
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    try {
      await _apiClient.delete('/labs/cart/', body: {'action': 'clear'});
    } catch (e) {
      debugPrint('Failed to clear production DB cart: $e');
    }
  }
}
