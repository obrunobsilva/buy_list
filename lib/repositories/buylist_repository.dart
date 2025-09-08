import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class BuylistRepository {
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);

  void addProduct(Product product) {
    _items.add(product);
    _save();
  }

  void removeProduct(int index) {
    _items.removeAt(index);
    _save();
  }

  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = _items
        .map((item) => jsonEncode(item.toMap()))
        .toList();
    await prefs.setStringList('buylist_items', jsonList);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('buylist_items');
    if (jsonList != null) {
      _items.clear();
      _items.addAll(jsonList.map((item) => Product.fromMap(jsonDecode(item))));
    }
  }

  void clear() {
    _items.clear();
    _save();
  }
}
