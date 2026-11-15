import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stock_movement.dart';
import '../state/inventory_store.dart';

class StockForm extends StatefulWidget {
  const StockForm({
    super.key,
    required this.store,
    required this.itemId,
    required this.type,
  });

  final InventoryStore store;
  final int itemId;
  final MovementType type;

  @override
  State<StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<StockForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.store.recordMovement(
        itemId: widget.itemId,
        type: widget.type,
        amount: int.parse(_amountController.text),
        reason: _reasonController.text,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (error, stackTrace) {
      debugPrint('No se pudo registrar el movimiento: $error\n$stackTrace');
      if (mounted) {
        setState(
          () => _errorMessage =
              'No se pudo guardar el movimiento. Intentá nuevamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.store.itemById(widget.itemId)!;
    final isAdjustment = widget.type == MovementType.adjustment;
    return PopScope(
      canPop: !_isSaving,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                movementTypeLabel(widget.type),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('${item.name} · Stock actual: ${item.quantity}'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: isAdjustment
                      ? 'Cantidad total contada'
                      : 'Cantidad',
                  helperText: isAdjustment
                      ? 'Ingresá el total real, no la diferencia.'
                      : 'Ingresá un número positivo.',
                ),
                validator: (value) {
                  final amount = int.tryParse(value ?? '');
                  if (amount == null || amount < 0) {
                    return 'Ingresá un número entero válido.';
                  }
                  try {
                    calculateQuantity(item.quantity, widget.type, amount);
                  } on FormatException catch (error) {
                    return error.message;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _reasonController,
                enabled: !_isSaving,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(
                  _isSaving
                      ? 'Guardando…'
                      : 'Confirmar ${movementTypeLabel(widget.type).toLowerCase()}',
                ),
              ),
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
