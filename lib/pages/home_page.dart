import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../repositories/buylist_repository.dart';

final NumberFormat _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String _money(double value) => _brl.format(value);

Color _accent(ColorScheme cs) =>
    cs.brightness == Brightness.dark ? const Color(0xFF90A4AE) : cs.primary;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BuylistRepository _repository = BuylistRepository();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      await _repository.load();
    } catch (_) {}
    if (!mounted) return;
    setState(() {});
  }

  void _addItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _repository.addProduct(Product(name: name));
    });
    _nameController.clear();
  }

  void _showFillDetailsDialog(int index, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductSheet(
        title: product.name,
        confirmLabel: "Confirmar no carrinho",
        product: product,
        onConfirm: (price, quantity) async {
          setState(() {
            _repository.updateProduct(
              index,
              product.copyWith(
                price: price,
                quantity: quantity,
                isBought: true,
              ),
            );
          });
        },
      ),
    );
  }

  void _toggleItem(int index, Product item) {
    if (item.isBought) {
      HapticFeedback.selectionClick();
      setState(() {
        _repository.updateProduct(index, item.copyWith(isBought: false));
      });
    } else {
      _showFillDetailsDialog(index, item);
    }
  }

  void _removeItem(int index, Product item) {
    setState(() {
      _repository.removeProduct(index);
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "\"${item.name}\" removido",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "Desfazer",
          onPressed: () {
            setState(() {
              _repository.insertProduct(index, item);
            });
          },
        ),
      ),
    );
  }

  void _archiveList() {
    if (_repository.items.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Salvar compra?"),
        content: const Text(
          "A lista vai para o histórico e esta tela será limpa.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: TextStyle(color: _accent(Theme.of(context).colorScheme)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repository.archiveCurrentList();
              if (!mounted) return;
              setState(() {});
            },
            child: Text(
              "Salvar",
              style: TextStyle(
                color: _accent(Theme.of(context).colorScheme),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(
    String dateLabel,
    List items,
    double total,
    int historyIndex,
  ) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailsPage(
          dateLabel: dateLabel,
          productsJson: items,
          total: total,
          historyIndex: historyIndex,
          repository: _repository,
          onRefresh: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  void _confirmDeleteHistory(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir compra?"),
        content: const Text(
          "Esta compra será apagada do histórico para sempre.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: TextStyle(color: _accent(Theme.of(context).colorScheme)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _repository.deleteHistoryList(index);
              if (!mounted) return;
              setState(() {});
            },
            child: const Text(
              "Excluir",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 72,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Sua pré-lista está vazia.\nAdicione os itens acima!",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.outline, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(ColorScheme colorScheme) {
    final items = _repository.items;
    final bought = items.where((e) => e.isBought).length;
    final total = items.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$bought de $total no carrinho",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : bought / total,
              minHeight: 6,
              color: _accent(colorScheme),
              backgroundColor: colorScheme.outlineVariant.withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lista de compras",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 28,
              ),
              tooltip: "Salvar compra",
              onPressed: _archiveList,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _repository.getHistory(),
          builder: (context, snapshot) {
            final history = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: colorScheme.primary),
                  child: const Text(
                    "Histórico de compras",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: history.isEmpty
                      ? const Center(child: Text("Nenhuma compra salva."))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final listData = history[index];
                            final date = DateTime.parse(listData['date']);
                            final formattedDate = DateFormat(
                              'dd/MM/yyyy',
                            ).format(date);
                            final total = (listData['total'] as num).toDouble();
                            final itemsList = listData['items'] as List;

                            return ListTile(
                              leading: const Icon(Icons.receipt_long),
                              title: Text("Compra de $formattedDate"),
                              subtitle: Text("${itemsList.length} itens"),
                              trailing: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _money(total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () => _navigateToDetails(
                                formattedDate,
                                itemsList,
                                total,
                                index,
                              ),
                              onLongPress: () => _confirmDeleteHistory(index),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Nome do produto",
                        hintText: "Ex: Arroz, Feijão...",
                        prefixIcon: const Icon(Icons.shopping_basket_outlined),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addItem,
                      child: const Icon(
                        Icons.add,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_repository.items.isNotEmpty) _buildProgress(colorScheme),
              Expanded(
                child: _repository.items.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : ListView.builder(
                        itemCount: _repository.items.length,
                        itemBuilder: (context, index) {
                          final item = _repository.items[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 0,
                            color: item.isBought
                                ? colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3)
                                : cardColor,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: item.isBought
                                    ? Colors.transparent
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: Dismissible(
                              key: ObjectKey(item),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _removeItem(index, item),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                ),
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: item.isBought,
                                  activeColor: _accent(colorScheme),
                                  onChanged: (_) => _toggleItem(index, item),
                                ),
                                title: Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: item.isBought
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: item.isBought
                                    ? Text(
                                        "${_money(item.price)} x ${item.quantity}",
                                      )
                                    : Text(
                                        "Toque para informar o preço",
                                        style: TextStyle(
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                trailing: item.isBought
                                    ? ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 110,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _money(item.subtotal),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: _accent(colorScheme),
                                            ),
                                          ),
                                        ),
                                      )
                                    : null,
                                onTap: () =>
                                    _showFillDetailsDialog(index, item),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black45,
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _money(_repository.total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryDetailsPage extends StatefulWidget {
  final String dateLabel;
  final List productsJson;
  final double total;
  final int historyIndex;
  final BuylistRepository repository;
  final VoidCallback onRefresh;

  const HistoryDetailsPage({
    super.key,
    required this.dateLabel,
    required this.productsJson,
    required this.total,
    required this.historyIndex,
    required this.repository,
    required this.onRefresh,
  });

  @override
  State<HistoryDetailsPage> createState() => _HistoryDetailsPageState();
}

class _HistoryDetailsPageState extends State<HistoryDetailsPage> {
  late List<Product> _localProducts;

  @override
  void initState() {
    super.initState();
    _localProducts = widget.productsJson
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  double get _localTotal => _localProducts
      .where((item) => item.isBought)
      .fold(0.0, (sum, item) => sum + item.subtotal);

  Future<void> _removeHistoryItem(int index) async {
    final removed = _localProducts[index];
    setState(() {
      _localProducts.removeAt(index);
    });
    await widget.repository.updateHistoryListItems(
      widget.historyIndex,
      _localProducts,
    );
    widget.onRefresh();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "\"${removed.name}\" removido",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "Desfazer",
          onPressed: () async {
            final safeIndex = index > _localProducts.length
                ? _localProducts.length
                : index;
            _localProducts.insert(safeIndex, removed);
            if (mounted) setState(() {});
            await widget.repository.updateHistoryListItems(
              widget.historyIndex,
              _localProducts,
            );
            widget.onRefresh();
          },
        ),
      ),
    );
  }

  void _editProductDetails(int index, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductSheet(
        title: product.name,
        confirmLabel: "Salvar alteração",
        product: product,
        onConfirm: (price, quantity) async {
          setState(() {
            _localProducts[index] = product.copyWith(
              price: price,
              quantity: quantity,
              isBought: true,
            );
          });
          await widget.repository.updateHistoryListItems(
            widget.historyIndex,
            _localProducts,
          );
          widget.onRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Compra - ${widget.dateLabel}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _localProducts.length,
          itemBuilder: (context, index) {
            final item = _localProducts[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Dismissible(
                key: ObjectKey(item),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _removeHistoryItem(index),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: item.isBought
                      ? Text("${_money(item.price)} x ${item.quantity}")
                      : Text(
                          "Toque para informar o preço",
                          style: TextStyle(color: colorScheme.outline),
                        ),
                  trailing: item.isBought
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _money(item.subtotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _accent(colorScheme),
                              ),
                            ),
                          ),
                        )
                      : null,
                  onTap: () => _editProductDetails(index, item),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: colorScheme.primary,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                const Text(
                  "Total da compra:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _money(_localTotal),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductSheet extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final Product product;
  final Future<void> Function(double price, int quantity) onConfirm;

  const _ProductSheet({
    required this.title,
    required this.confirmLabel,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  late final TextEditingController _priceController;
  late int _quantity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final price = widget.product.price;
    _priceController = TextEditingController(
      text: price > 0 ? price.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _quantity = widget.product.quantity > 0 ? widget.product.quantity : 1;
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    _saving = true;

    final price =
        double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ??
        0.0;

    HapticFeedback.lightImpact();
    try {
      await widget.onConfirm(price, _quantity);
    } catch (_) {
      _saving = false;
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Preço unitário (R\$)",
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Quantidade:",
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: Icon(Icons.remove_circle_outline, color: textColor),
                    ),
                    Text(
                      "$_quantity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: Icon(Icons.add_circle_outline, color: textColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _confirm,
              child: Text(
                widget.confirmLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
