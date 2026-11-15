import 'dart:io';

import 'package:flutter/material.dart';
import '../widgets/item_stock_fields.dart';

import '../widgets/archive_item_dialog.dart';
import '../data/item_photo_storage.dart';
import '../models/item.dart';
import '../state/inventory_store.dart';
import '../widgets/item_photo_picker.dart';
import 'barcode_scanner_screen.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, required this.store, this.item});

  final InventoryStore store;
  final Item? item;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _photoStorage = ItemPhotoStorage();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minimumController;
  late final TextEditingController _barcodeController;
  File? _selectedPhoto;
  bool _photoChanged = false;
  bool _isPickingPhoto = false;
  bool _isScanning = false;
  bool _isSaving = false;
  bool _trackLowStock = false;
  String? _errorMessage;

  bool get _isBusy => _isSaving || _isPickingPhoto || _isScanning;

  @override
  void initState() {
    super.initState();
    _trackLowStock = widget.item?.trackLowStock ?? false;
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.item?.description ?? '',
    );
    _quantityController = TextEditingController(
      text: '${widget.item?.quantity ?? 0}',
    );
    _minimumController = TextEditingController(
      text: '${widget.item?.minimumQuantity ?? 0}',
    );
    _barcodeController = TextEditingController(
      text: widget.item?.barcode ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _minimumController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanCode() async {
    if (_isBusy) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isScanning = true);
    try {
      final code = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(builder: (_) => const BarcodeScannerScreen()),
      );
      if (mounted && code != null) {
        _barcodeController.text = code;
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _save() async {
    if (_isBusy || !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final previousPhotoName = widget.item?.photoName;
    String? copiedPhotoName;
    try {
      String? savedPhotoName = previousPhotoName;
      if (_photoChanged) {
        final photo = _selectedPhoto;
        if (photo == null) {
          savedPhotoName = null;
        } else {
          copiedPhotoName = await _photoStorage.saveCopy(photo);
          savedPhotoName = copiedPhotoName;
        }
      }
      await widget.store.saveItem(
        itemId: widget.item?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        quantity: int.parse(_quantityController.text),
        minimumQuantity: _trackLowStock
            ? int.parse(_minimumController.text)
            : 0,
        trackLowStock: _trackLowStock,
        photoName: savedPhotoName,
        barcode: _barcodeController.text,
      );
      if (previousPhotoName != savedPhotoName) {
        await _photoStorage.deleteCopy(previousPhotoName);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error, stackTrace) {
      await _photoStorage.deleteCopy(copiedPhotoName);
      debugPrint('No se pudo guardar: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = error is FormatException
              ? error.message
              : 'No se pudo guardar. Tus cambios siguen en el formulario.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _archive() async {
    final item = widget.item!;
    final confirm = await confirmArchiveItem(
      context,
      name: item.name,
      quantity: item.quantity,
    );
    if (confirm != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await widget.store.setArchived(item.id, true);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No se pudo archivar el artículo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isBusy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nuevo artículo' : 'Editar artículo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ItemPhotoPicker(
              storage: _photoStorage,
              initialPhotoName: widget.item?.photoName,
              enabled: !_isBusy,
              onChanged: (photo) {
                _selectedPhoto = photo;
                _photoChanged = true;
              },
              onBusyChanged: (busy) {
                if (mounted) setState(() => _isPickingPhoto = busy);
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              enabled: !_isBusy,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribí un nombre.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isBusy,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              enabled: !_isBusy,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Código de barras o QR (opcional)',
                helperText: 'Podés escribirlo o escanearlo.',
                suffixIcon: IconButton(
                  tooltip: 'Escanear código',
                  onPressed: _isBusy ? null : _scanCode,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ),
              validator: (value) {
                final code = value?.trim() ?? '';
                final existing = widget.store.itemByBarcode(code);
                if (existing != null && existing.id != widget.item?.id) {
                  return 'Ese código ya pertenece a otro artículo.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ItemStockFields(
              isNew: widget.item == null,
              enabled: !_isBusy,
              isSaving: _isSaving,
              trackLowStock: _trackLowStock,
              quantityController: _quantityController,
              minimumController: _minimumController,
              onTrackLowStockChanged: (value) =>
                  setState(() => _trackLowStock = value),
            ),
            const SizedBox(height: 28),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: _isBusy ? null : _save,
              child: Text(_isSaving ? 'Guardando…' : 'Guardar artículo'),
            ),
            if (widget.item != null)
              TextButton.icon(
                onPressed: _isBusy ? null : _archive,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archivar artículo'),
              ),
          ],
        ),
      ),
    ),
  );
}
