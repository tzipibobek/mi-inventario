import 'package:flutter/material.dart';

Future<bool?> confirmArchiveItem(
  BuildContext context, {
  required String name,
  required int quantity,
}) => showDialog<bool>(
  context: context,
  builder: (dialog) => AlertDialog(
    title: Text('¿Archivar $name?'),
    content: Text(
      'Stock actual: $quantity. Se conserva el historial. Podés restaurarlo desde Inventario → Filtros → Archivados.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialog, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(dialog, true),
        child: const Text('Archivar'),
      ),
    ],
  ),
);
