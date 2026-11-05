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

  void insertProduct(int index, Product product) {
    final safeIndex = index > _items.length ? _items.length : index;
    _items.insert(safeIndex, product);
    _save();
  }

  void updateProduct(int index, Product updatedProduct) {
    _items[index] = updatedProduct;
    _save();
  }

  double get total => _items
      .where((item) => item.isBought)
      .fold(0.0, (sum, item) => sum + item.subtotal);

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

  Future<void> archiveCurrentList() async {
    if (_items.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('buylist_history') ?? [];

    final archiveData = {
      'date': DateTime.now().toIso8601String(),
      'total': total,
      'items': _items.map((item) => item.toMap()).toList(),
    };

    history.insert(0, jsonEncode(archiveData));
    await prefs.setStringList('buylist_history', history);

    _items.clear();
    await _save();
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? history = prefs.getStringList('buylist_history');
    if (history == null) return [];
    return history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> deleteHistoryList(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('buylist_history') ?? [];
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      await prefs.setStringList('buylist_history', history);
    }
  }

  Future<void> updateHistoryListItems(
    int historyIndex,
    List<Product> updatedProducts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('buylist_history') ?? [];
    if (historyIndex >= 0 && historyIndex < history.length) {
      final Map<String, dynamic> listData = jsonDecode(history[historyIndex]);
      listData['items'] = updatedProducts.map((item) => item.toMap()).toList();
      listData['total'] = updatedProducts
          .where((item) => item.isBought)
          .fold(0.0, (sum, item) => sum + item.subtotal);
      history[historyIndex] = jsonEncode(listData);
      await prefs.setStringList('buylist_history', history);
    }
  }
}
