import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/item_photo_storage.dart';

class ItemPhotoPicker extends StatefulWidget {
  const ItemPhotoPicker({
    super.key,
    required this.storage,
    required this.enabled,
    required this.onChanged,
    required this.onBusyChanged,
    this.initialPhotoName,
  });

  final ItemPhotoStorage storage;
  final String? initialPhotoName;
  final bool enabled;
  final ValueChanged<File?> onChanged;
  final ValueChanged<bool> onBusyChanged;

  @override
  State<ItemPhotoPicker> createState() => _ItemPhotoPickerState();
}

class _ItemPhotoPickerState extends State<ItemPhotoPicker> {
  final _picker = ImagePicker();

  File? _photo;
  String? _error;
  bool _isPicking = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final photoName = widget.initialPhotoName;

    if (photoName == null) {
      return;
    }

    try {
      final file = await widget.storage.getFile(photoName);

      // No reemplazar una selección hecha mientras cargaba la foto anterior.
      if (mounted && !_hasChanged) {
        setState(() => _photo = file);
      }
    } catch (error) {
      debugPrint('No se pudo cargar la foto: $error');

      if (mounted && !_hasChanged) {
        setState(() => _error = 'No se pudo cargar la foto guardada.');
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPicking || !widget.enabled) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isPicking = true;
      _error = null;
    });
    widget.onBusyChanged(true);

    try {
      final selectedPhoto = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        requestFullMetadata: false,
      );

      if (!mounted || selectedPhoto == null) {
        return;
      }

      final file = File(selectedPhoto.path);
      setState(() {
        _photo = file;
        _hasChanged = true;
      });
      widget.onChanged(file);
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      final denied = code.contains('denied') || code.contains('restricted');

      if (mounted) {
        setState(() {
          _error = denied
              ? 'Habilitá el acceso a cámara o fotos desde Ajustes '
                    'del teléfono.'
              : 'No se pudo abrir la cámara o la galería.';
        });
      }
    } catch (error) {
      debugPrint('No se pudo elegir la foto: $error');

      if (mounted) {
        setState(() => _error = 'No pudimos cargar la foto.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
        widget.onBusyChanged(false);
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _photo = null;
      _hasChanged = true;
      _error = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    final enabled = widget.enabled && !_isPicking;
    final hasPhoto =
        photo != null || (!_hasChanged && widget.initialPhotoName != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto (opcional)'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: photo == null
                ? _placeholder(context)
                : Image.file(
                    photo,
                    fit: BoxFit.cover,
                    cacheWidth: 1000,
                    semanticLabel: 'Foto del artículo',
                    errorBuilder: (context, error, stackTrace) {
                      return _placeholder(context);
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: enabled ? () => _pickPhoto(ImageSource.camera) : null,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Cámara'),
            ),
            OutlinedButton.icon(
              onPressed: enabled ? () => _pickPhoto(ImageSource.gallery) : null,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galería'),
            ),
            if (hasPhoto)
              TextButton.icon(
                onPressed: enabled ? _removePhoto : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar'),
              ),
          ],
        ),
        if (_isPicking) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined, size: 48)),
    );
  }
}
