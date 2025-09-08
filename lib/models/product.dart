class Product {
  final String name;
  final double price;
  final int quantity;

  Product({required this.name, required this.price, required this.quantity});

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'quantity': quantity};
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['name'],
      price: map['price'] + 0.0,
      quantity: map['quantity'],
    );
  }
}
