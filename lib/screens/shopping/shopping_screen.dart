import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/room_service.dart';
import '../../models/shopping_item.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => ShoppingScreenState();
}

class ShoppingScreenState extends State<ShoppingScreen>
    with AutomaticKeepAliveClientMixin {
  List<ShoppingItem> _items = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadItems(silent: true);
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void onScreenVisible() {
    _loadItems(silent: true);
  }

  Future<void> refresh() async {
    await _loadItems();
  }

  Future<void> _loadItems({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      if (roomService.currentRoomId == null) return;

      final items =
          await apiService.getShoppingItems(roomService.currentRoomId!);

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleItem(ShoppingItem item) async {
    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      await apiService.updateShoppingItem(
        roomService.currentRoomId!,
        item.id,
        purchased: !item.purchased,
      );
      _loadItems(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      await apiService.deleteShoppingItem(roomService.currentRoomId!, item.id);
      _loadItems(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар удалён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить товар'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_basket_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Количество (необязательно)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                hintText: 'Например: 2 шт, 1 кг',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название товара')),
                );
                return;
              }

              try {
                final apiService = context.read<ApiService>();
                final roomService = context.read<RoomService>();

                await apiService.createShoppingItem(
                  roomService.currentRoomId!,
                  nameController.text.trim(),
                  quantityController.text.trim().isEmpty
                      ? null
                      : quantityController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadItems(silent: true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Товар добавлен')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final notPurchased = _items.where((i) => !i.purchased).toList();
    final purchased = _items.where((i) => i.purchased).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadItems(),
        child: _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Список покупок пуст',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите + чтобы добавить первый товар',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (notPurchased.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Нужно купить (${notPurchased.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ...notPurchased.map((item) => _buildItemCard(item)),
                  ],
                  if (purchased.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Куплено (${purchased.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ...purchased.map((item) => _buildItemCard(item)),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  Widget _buildItemCard(ShoppingItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.purchased,
          onChanged: (_) => _toggleItem(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.purchased ? TextDecoration.lineThrough : null,
            color: item.purchased
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
        ),
        subtitle: item.quantity != null && item.quantity!.isNotEmpty
            ? Text(
                item.quantity!,
                style: TextStyle(
                  decoration:
                      item.purchased ? TextDecoration.lineThrough : null,
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteItem(item),
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
