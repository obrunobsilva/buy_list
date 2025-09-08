import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:buy_list/repositories/buylist_repository.dart';
import 'package:buy_list/widgets/custom_elevated_button.dart';
import 'package:buy_list/widgets/custom_dropdown.dart';
import 'package:buy_list/widgets/custom_text_form_field.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final BuylistRepository _repository = BuylistRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  int? _selectedQuantity;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    await _repository.load();
    setState(() {});
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final quantity = _selectedQuantity ?? 0;

    if (name.isEmpty || price <= 0 || quantity <= 0) return;

    setState(() {
      _repository.addProduct(
        Product(name: name, price: price, quantity: quantity),
      );
    });

    _nameController.clear();
    _priceController.clear();
    _selectedQuantity = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lista de Compras",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextFormField(
                    controller: _nameController,
                    label: "Produto",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: CustomTextFormField(
                    controller: _priceController,
                    label: "Valor (R\$)",
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: CustomDropdownButtonFormField(
                    value: _selectedQuantity,
                    onChanged: (value) {
                      setState(() {
                        _selectedQuantity = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 60,
                  child: CustomElevatedButton(text: "+", onPressed: _addItem),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _repository.items.length,
                itemBuilder: (context, index) {
                  final item = _repository.items[index];
                  return Dismissible(
                    key: ValueKey(item.name + index.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      final removedItem = _repository.items[index];
                      setState(() {
                        _repository.removeProduct(index);
                      });
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${removedItem.name} removido"),
                          action: SnackBarAction(
                            label: "Desfazer",
                            onPressed: () {
                              setState(() {
                                _repository.addProduct(removedItem);
                              });
                            },
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        "Valor: R\$ ${item.price.toStringAsFixed(2)} x ${item.quantity}",
                      ),
                      trailing: Text("R\$ ${item.subtotal.toStringAsFixed(2)}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Text(
            "Total: R\$ ${_repository.total.toStringAsFixed(2)}",
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
