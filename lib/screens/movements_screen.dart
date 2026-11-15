import 'package:flutter/material.dart';

import '../models/stock_movement.dart';
import '../state/inventory_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/movement_tile.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key, required this.store});

  final InventoryStore store;

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  MovementType? _selectedType;

  Widget _emptyState() {
    final (title, message) = switch (_selectedType) {
      null => (
        'Todavía no hay movimientos',
        'Cuando agregues un artículo, su stock inicial aparecerá acá.',
      ),
      MovementType.entry => (
        'Sin entradas registradas',
        'Las unidades que sumes desde Entrada aparecerán acá.',
      ),
      MovementType.exit => (
        'Sin salidas registradas',
        'Las unidades que retires desde Salida aparecerán acá.',
      ),
      MovementType.initial => (
        'Sin registros de stock inicial',
        'Acá aparece la cantidad con la que se creó cada artículo.',
      ),
      MovementType.adjustment => (
        'Sin ajustes de stock',
        'Cuando corrijas la cantidad desde Ajustar cantidad, el cambio aparecerá acá.',
      ),
    };
    return EmptyState(
      icon: Icons.swap_horiz,
      title: title,
      message: message,
      action: _selectedType != null && widget.store.movements.isNotEmpty
          ? TextButton(
              onPressed: () => setState(() => _selectedType = null),
              child: const Text('Ver todos los movimientos'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final movements = widget.store.movements
        .where(
          (movement) => _selectedType == null || movement.type == _selectedType,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Movimientos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: DropdownButtonFormField<MovementType?>(
              key: ValueKey(_selectedType),
              isExpanded: true,
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de movimiento',
              ),
              items: [
                const DropdownMenuItem<MovementType?>(
                  value: null,
                  child: Text('Todos'),
                ),
                for (final type in MovementType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(switch (type) {
                      MovementType.adjustment => 'Ajuste de stock',
                      MovementType.initial => 'Stock inicial',
                      _ => movementTypeLabel(type),
                    }),
                  ),
              ],
              hint: const Text('Todos'),
              onChanged: (type) => setState(() => _selectedType = type),
            ),
          ),
          Expanded(
            child: movements.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: movements.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (_, index) =>
                        MovementTile(movement: movements[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
