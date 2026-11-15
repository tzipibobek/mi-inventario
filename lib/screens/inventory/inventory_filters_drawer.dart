import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InventoryFiltersDrawer extends StatefulWidget {
  const InventoryFiltersDrawer({
    super.key,
    required this.archived,
    required this.stock,
    required this.minimum,
    required this.maximum,
    required this.onApply,
  });
  final bool archived;
  final String stock;
  final int? minimum, maximum;
  final void Function(bool, String, int?, int?) onApply;
  @override
  State<InventoryFiltersDrawer> createState() => _InventoryFiltersDrawerState();
}

class _InventoryFiltersDrawerState extends State<InventoryFiltersDrawer> {
  late bool archived = widget.archived;
  late String stock = widget.stock;
  late final min = TextEditingController(
    text: widget.minimum?.toString() ?? '',
  );
  late final max = TextEditingController(
    text: widget.maximum?.toString() ?? '',
  );
  String? error;
  @override
  void dispose() {
    min.dispose();
    max.dispose();
    super.dispose();
  }

  void apply() {
    final lo = int.tryParse(min.text), hi = int.tryParse(max.text);
    if (stock == 'Rango' &&
        ((lo == null && hi == null) ||
            (lo != null && hi != null && lo > hi) ||
            (min.text.isNotEmpty && lo == null) ||
            (max.text.isNotEmpty && hi == null))) {
      setState(
        () => error =
            'Ingresá al menos un límite válido. Desde debe ser menor o igual a Hasta.',
      );
      return;
    }
    widget.onApply(
      archived,
      stock,
      stock == 'Rango' ? lo : null,
      stock == 'Rango' ? hi : null,
    );
  }

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              CloseButton(),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Estado del artículo'),
          Wrap(
            spacing: 6,
            children: [
              for (final v in [false, true])
                ChoiceChip(
                  label: Text(v ? 'Archivados' : 'Activos'),
                  selected: archived == v,
                  onSelected: (_) => setState(() => archived = v),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Stock'),
          Wrap(
            spacing: 6,
            children: [
              for (final v in ['Todos', 'Sin stock', 'Stock bajo', 'Rango'])
                ChoiceChip(
                  label: Text(v),
                  selected: stock == v,
                  onSelected: (_) => setState(() {
                    stock = v;
                    error = null;
                  }),
                ),
            ],
          ),
          if (stock == 'Rango') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final c in [min, max])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: c,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: c == min ? 'Desde' : 'Hasta',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (error != null) Text(error!),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: apply, child: const Text('Aplicar')),
          TextButton(
            onPressed: () => widget.onApply(false, 'Todos', null, null),
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    ),
  );
}
