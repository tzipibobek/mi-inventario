import 'package:flutter/material.dart';

import '../models/stock_movement.dart';
import '../utils/dates.dart';

class MovementTile extends StatelessWidget {
  const MovementTile({
    super.key,
    required this.movement,
    this.showItemName = true,
  });

  final bool showItemName;
  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final IconData movementIcon;
    switch (movement.type) {
      case MovementType.initial:
        movementIcon = Icons.add_box_outlined;
        break;
      case MovementType.entry:
        movementIcon = Icons.south_west_rounded;
        break;
      case MovementType.exit:
        movementIcon = Icons.north_east_rounded;
        break;
      case MovementType.adjustment:
        movementIcon = Icons.tune_rounded;
        break;
    }
    final change = movement.quantityChange > 0
        ? '+${movement.quantityChange}'
        : '${movement.quantityChange}';
    final typeLabel = movement.type == MovementType.initial
        ? 'Stock inicial'
        : movementTypeLabel(movement.type);
    final note = movement.reason.trim();
    final action = '$typeLabel · $change u.';
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(movementIcon),
      title: Text(showItemName ? movement.itemName : action),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showItemName) Text(action, style: theme.textTheme.labelLarge),
          Text('Stock: ${movement.quantityBefore} → ${movement.quantityAfter}'),
          if (note.isNotEmpty) Text('Nota: $note'),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              dateAndTime(movement.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
