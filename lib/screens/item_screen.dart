import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/archive_item_dialog.dart';
import '../models/stock_movement.dart';
import '../state/inventory_store.dart';
import '../widgets/movement_tile.dart';
import '../widgets/stock_form.dart';
import '../widgets/item_header.dart';
import 'item_form_screen.dart';

class ItemScreen extends StatelessWidget {
  const ItemScreen({super.key, required this.store, required this.itemId});

  final InventoryStore store;
  final int itemId;

  void _showMovement(BuildContext context, MovementType type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => StockForm(store: store, itemId: itemId, type: type),
    );
  }

  Future<void> _archive(BuildContext context, String name, int quantity) async {
    final confirmed = await confirmArchiveItem(
      context,
      name: name,
      quantity: quantity,
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await store.setArchived(itemId, true);
      if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo archivar el artículo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, child) {
      final item = store.itemById(itemId)!;
      final history = store.movements
          .where((movement) => movement.itemId == itemId)
          .toList();
      final surface = Theme.of(context).scaffoldBackgroundColor;
      final isDark =
          ThemeData.estimateBrightnessForColor(surface) == Brightness.dark;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: surface,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ItemHeader(
                  item: item,
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ItemFormScreen(store: store, item: item),
                    ),
                  ),
                  onArchive: () => _archive(context, item.name, item.quantity),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(item.description),
                        ),
                      Text(
                        'Historial',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (history.isEmpty)
                        const Text('Todavía no hay movimientos.'),
                    ],
                  ),
                ),
                for (final movement in history)
                  MovementTile(movement: movement, showItemName: false),
              ],
            ),
          ),
          bottomNavigationBar: Material(
            elevation: 8,
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                _showMovement(context, MovementType.entry),
                            icon: const Icon(Icons.add),
                            label: const Text('Entrada'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: item.quantity == 0
                                ? null
                                : () =>
                                      _showMovement(context, MovementType.exit),
                            icon: const Icon(Icons.remove),
                            label: const Text('Salida'),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () =>
                          _showMovement(context, MovementType.adjustment),
                      child: const Text('Ajustar cantidad'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
