class Product {
  final String name;
  final double price;
  final int quantity;
  final bool isBought;

  Product({
    required this.name,
    this.price = 0.0,
    this.quantity = 0,
    this.isBought = false,
  });

  double get subtotal => price * quantity;

  Product copyWith({
    String? name,
    double? price,
    int? quantity,
    bool? isBought,
  }) {
    return Product(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isBought: isBought ?? this.isBought,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'isBought': isBought,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      isBought: map['isBought'] ?? false,
    );
  }
}
