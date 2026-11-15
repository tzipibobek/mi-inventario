import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ItemStockFields extends StatelessWidget {
  const ItemStockFields({
    super.key,
    required this.isNew,
    required this.enabled,
    required this.isSaving,
    required this.trackLowStock,
    required this.quantityController,
    required this.minimumController,
    required this.onTrackLowStockChanged,
  });
  final bool isNew;
  final bool enabled;
  final bool isSaving;
  final bool trackLowStock;
  final TextEditingController quantityController;
  final TextEditingController minimumController;
  final ValueChanged<bool> onTrackLowStockChanged;
  String? _validateQuantity(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) {
      return 'Ingresá un número entero desde cero.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (isNew) ...[
        TextFormField(
          controller: quantityController,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Cantidad inicial'),
          validator: _validateQuantity,
        ),
        const SizedBox(height: 20),
      ] else ...[
        const Text(
          'Para cambiar el stock, registrá una entrada, salida o ajuste desde el artículo.',
        ),
        const SizedBox(height: 20),
      ],
      ExpansionTile(
        title: const Text('Opciones de stock'),
        maintainState: true,
        initiallyExpanded: trackLowStock,
        children: [
          SwitchListTile(
            title: const Text('Marcar stock bajo'),
            subtitle: const Text('Opcional, solo para este artículo.'),
            value: trackLowStock,
            onChanged: isSaving ? null : onTrackLowStockChanged,
          ),
          if (trackLowStock)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: minimumController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Stock mínimo',
                  helperText: 'Se marca al llegar a este valor o menos.',
                  helperMaxLines: 2,
                ),
                validator: _validateQuantity,
              ),
            ),
        ],
      ),
    ],
  );
}
