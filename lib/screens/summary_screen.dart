import 'package:flutter/material.dart';

import '../models/stock_movement.dart';
import '../state/inventory_store.dart';
import '../utils/dates.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.store});

  final InventoryStore store;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _selectedWeek = startOfWeek(DateTime.now());

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final nextWeekStart = nextWeek(_selectedWeek);
    final movementCounts = <MovementType, int>{};
    final weekMovements = widget.store.movements
        .where(
          (movement) =>
              !movement.date.isBefore(_selectedWeek) &&
              movement.date.isBefore(nextWeekStart),
        )
        .toList();
    final exitsByItem = <int, int>{};
    final itemNames = <int, String>{};
    for (final movement in weekMovements) {
      final previousCount = movementCounts[movement.type] ?? 0;
      movementCounts[movement.type] = previousCount + 1;
      if (movement.type == MovementType.exit) {
        final previousTotal = exitsByItem[movement.itemId] ?? 0;
        final removedQuantity =
            movement.quantityBefore - movement.quantityAfter;
        exitsByItem[movement.itemId] = previousTotal + removedQuantity;
        itemNames[movement.itemId] = movement.itemName;
      }
    }
    final rankedItems = exitsByItem.entries.toList();
    rankedItems.sort((firstItem, secondItem) {
      return secondItem.value.compareTo(firstItem.value);
    });
    final lowStockItems = widget.store.items
        .where((item) => item.hasLowStock)
        .toList();
    final currentWeekStart = startOfWeek(DateTime.now());
    final lastDayOfWeek = DateTime(
      nextWeekStart.year,
      nextWeekStart.month,
      nextWeekStart.day - 1,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Resumen semanal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Semana anterior',
                onPressed: () => setState(
                  () => _selectedWeek = DateTime(
                    _selectedWeek.year,
                    _selectedWeek.month,
                    _selectedWeek.day - 7,
                  ),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${shortDate(_selectedWeek)} – ${shortDate(lastDayOfWeek)}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: 'Semana siguiente',
                onPressed: _selectedWeek.isBefore(currentWeekStart)
                    ? () => setState(() => _selectedWeek = nextWeekStart)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final metric in [
                        (
                          exitsByItem.values.fold<int>(0, (a, b) => a + b),
                          'Unidades retiradas',
                        ),
                        (
                          weekMovements
                              .where((m) => m.type == MovementType.entry)
                              .fold<int>(0, (a, m) => a + m.quantityChange),
                          'Unidades ingresadas',
                        ),
                      ])
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${metric.$1}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              Text(metric.$2),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    '${weekMovements.length} ${weekMovements.length == 1 ? "movimiento" : "movimientos"}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (weekMovements.isNotEmpty)
                    Text(
                      [
                        for (final type in MovementType.values)
                          if (movementCounts.containsKey(type))
                            _countLabel(type, movementCounts[type]!),
                      ].join(' · '),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Artículos con más salidas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (rankedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No hubo salidas en esta semana.'),
            ),
          for (final rankedItem in rankedItems.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.store.itemById(rankedItem.key)?.name ??
                    itemNames[rankedItem.key]!,
              ),
              subtitle: const Text('Cantidad retirada de este artículo'),
              trailing: Text('${rankedItem.value}'),
            ),
          if (widget.store.items.any((item) => item.trackLowStock)) ...[
            const SizedBox(height: 24),
            Text(
              'Stock bajo ahora',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Estado actual del inventario, independientemente de la semana seleccionada.',
            ),
            if (lowStockItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No hay artículos por debajo o en su mínimo.'),
              ),
            for (final item in lowStockItems)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text('Mínimo: ${item.minimumQuantity}'),
                trailing: Text('${item.quantity}'),
              ),
          ],
        ],
      ),
    );
  }
}

String _countLabel(MovementType type, int count) {
  final labels = switch (type) {
    MovementType.initial => ('carga inicial', 'cargas iniciales'),
    MovementType.entry => ('entrada', 'entradas'),
    MovementType.exit => ('salida', 'salidas'),
    MovementType.adjustment => ('ajuste', 'ajustes'),
  };
  return '$count ${count == 1 ? labels.$1 : labels.$2}';
}
