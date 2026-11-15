import 'package:flutter/material.dart';

import '../state/inventory_store.dart';
import '../utils/text.dart';
import '../widgets/empty_state.dart';
import 'inventory/inventory_filters_drawer.dart';
import 'inventory/item_tile.dart';
import 'item_form_screen.dart';
import 'item_screen.dart';
import 'barcode_scanner_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.store,
    required this.onCustomize,
  });

  final InventoryStore store;
  final VoidCallback onCustomize;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  bool archived = false;
  String stock = 'Todos';
  int? minimum, maximum;
  bool restoring = false;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool get filtered => archived || stock != 'Todos';
  void clearStockFilter() => setState(() {
    stock = 'Todos';
    minimum = null;
    maximum = null;
  });
  Future<void> restore(int id) async {
    if (restoring) return;
    setState(() => restoring = true);
    try {
      await widget.store.setArchived(id, false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo restaurar el artículo.')),
        );
      }
    } finally {
      if (mounted) setState(() => restoring = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addItem() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ItemFormScreen(store: widget.store),
    ),
  );

  bool _isScanning = false;

  Future<void> _findByCode() async {
    if (_isScanning) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isScanning = true);
    try {
      final code = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(builder: (_) => const BarcodeScannerScreen()),
      );
      if (!mounted || code == null) {
        return;
      }
      final item = widget.store.itemByBarcode(code);
      if (item?.archived == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Artículo archivado. Podés restaurarlo en Filtros → Archivados.',
            ),
          ),
        );
        return;
      }
      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay un artículo con este código.')),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ItemScreen(store: widget.store, itemId: item.id),
        ),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final items = archived ? widget.store.archivedItems : widget.store.items;
    final query = searchKey(_searchController.text);
    final filteredItems = items.where((item) {
      final matchesText = searchKey(
        '${item.name} ${item.description} ${item.barcode ?? ''}',
      ).contains(query);
      return matchesText &&
          switch (stock) {
            'Sin stock' => item.quantity == 0,
            'Stock bajo' => item.hasLowStock,
            'Rango' =>
              (minimum == null || item.quantity >= minimum!) &&
                  (maximum == null || item.quantity <= maximum!),
            _ => true,
          };
    }).toList();

    return Scaffold(
      key: scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: InventoryFiltersDrawer(
        key: ValueKey((archived, stock, minimum, maximum)),
        archived: archived,
        stock: stock,
        minimum: minimum,
        maximum: maximum,
        onApply: (state, mode, min, max) {
          setState(() {
            archived = state;
            stock = mode;
            minimum = min;
            maximum = max;
          });
          scaffoldKey.currentState?.closeEndDrawer();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar artículos',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(_searchController.clear),
                            ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Escanear código',
                  onPressed: _isScanning ? null : _findByCode,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
                IconButton(
                  tooltip: filtered ? 'Filtros activos' : 'Filtros',
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    scaffoldKey.currentState?.openEndDrawer();
                  },
                  icon: Badge(
                    isLabelVisible: filtered,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
          ),
          if (filtered)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (archived)
                      InputChip(
                        label: const Text('Archivados'),
                        deleteButtonTooltipMessage:
                            'Quitar filtro de archivados',
                        onDeleted: () => setState(() => archived = false),
                      ),
                    if (stock != 'Todos')
                      InputChip(
                        label: Text(
                          stock == 'Rango'
                              ? '${minimum ?? 0}–${maximum ?? "∞"} unidades'
                              : stock,
                        ),
                        deleteButtonTooltipMessage: 'Quitar filtro de stock',
                        onDeleted: clearStockFilter,
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: filteredItems.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: archived && items.isEmpty
                        ? 'No hay artículos archivados'
                        : !archived && items.isEmpty && !filtered
                        ? 'Tu inventario empieza acá'
                        : 'Sin resultados',
                    message: items.isEmpty && !filtered
                        ? 'Agregá tu primer artículo.'
                        : 'Probá otra búsqueda o cambiá los filtros.',
                    action: items.isEmpty && !filtered
                        ? FilledButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar primer artículo'),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ItemTile(
                        item: item,
                        archived: archived,
                        onRestore: restoring ? null : () => restore(item.id),
                        onTap: archived
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ItemScreen(
                                    store: widget.store,
                                    itemId: item.id,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: archived || items.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _addItem,
              tooltip: 'Agregar artículo',
              child: const Icon(Icons.add),
            ),
    );
  }
}
