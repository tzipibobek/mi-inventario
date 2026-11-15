import 'package:flutter/material.dart';
import '../models/item.dart';
import 'item_photo.dart';

class ItemHeader extends StatelessWidget {
  const ItemHeader({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onArchive,
  });
  final Item item;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final photo = item.photoName;
    final colors = Theme.of(context).colorScheme;
    final ink = photo == null ? colors.onPrimary : Colors.white;
    void openPhoto() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(item.name)),
            backgroundColor: Colors.black,
            body: InteractiveViewer(
              child: Center(
                child: ItemPhoto(photoName: photo, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: colors.primary,
            child: photo == null ? null : ItemPhoto(photoName: photo),
          ),
        ),
        if (photo != null)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.black38, Colors.black87],
                ),
              ),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BackButton(color: ink),
                const Spacer(),
                if (photo != null)
                  IconButton(
                    color: ink,
                    tooltip: 'Ver foto completa',
                    icon: const Icon(Icons.fullscreen),
                    onPressed: openPhoto,
                  ),
                IconButton(
                  color: ink,
                  tooltip: 'Editar artículo',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  color: ink,
                  tooltip: 'Archivar artículo',
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: onArchive,
                ),
              ],
            ),
            GestureDetector(
              onTap: photo == null ? null : openPhoto,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  photo == null ? 0 : 32,
                  20,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: ink, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${item.quantity} ${item.quantity == 1 ? "unidad" : "unidades"} en stock',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: ink),
                    ),
                    if (item.trackLowStock || item.quantity == 0)
                      Text(
                        [
                          item.stockStatus,
                          if (item.trackLowStock)
                            'Mínimo ${item.minimumQuantity}',
                        ].join(' · '),
                        style: TextStyle(color: ink),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
