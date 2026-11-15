import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../widgets/item_photo.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.archived,
    this.onRestore,
    this.onTap,
  });

  final Item item;
  final bool archived;
  final VoidCallback? onRestore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 44,
        height: 44,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ItemPhoto(photoName: item.photoName, cacheWidth: 160),
        ),
      ),
      title: Text(item.name),
      subtitle: item.quantity == 0
          ? Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    'Sin stock',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          : Text(
              [
                '${item.quantity} ${item.quantity == 1 ? "unidad" : "unidades"}',
                if (item.quantity == 0 || item.hasLowStock) item.stockStatus,
              ].join(' · '),
            ),
      trailing: archived
          ? TextButton(onPressed: onRestore, child: const Text('Restaurar'))
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
