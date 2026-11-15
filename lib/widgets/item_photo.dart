import 'dart:io';

import 'package:flutter/material.dart';

import '../data/item_photo_storage.dart';

class ItemPhoto extends StatefulWidget {
  const ItemPhoto({
    super.key,
    this.fit = BoxFit.cover,
    this.photoName,
    this.previewPath,
    this.semanticLabel = 'Foto del artículo',
    this.cacheWidth = 1000,
  });

  final BoxFit fit;
  final String? photoName;
  final String? previewPath;
  final String semanticLabel;
  final int cacheWidth;

  @override
  State<ItemPhoto> createState() => _ItemPhotoState();
}

class _ItemPhotoState extends State<ItemPhoto> {
  Future<File>? _photoFile;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(ItemPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoName != widget.photoName ||
        oldWidget.previewPath != widget.previewPath) {
      _loadPhoto();
    }
  }

  void _loadPhoto() {
    if (widget.previewPath != null) {
      _photoFile = Future.value(File(widget.previewPath!));
    } else if (widget.photoName != null) {
      _photoFile = ItemPhotoStorage().getFile(widget.photoName!);
    } else {
      _photoFile = null;
    }
  }

  Widget _placeholder(BuildContext context, {bool failed = false}) =>
      ColoredBox(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Center(
          child: Icon(
            failed ? Icons.broken_image_outlined : Icons.inventory_2_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            semanticLabel: failed ? 'No se pudo mostrar la foto' : 'Sin foto',
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_photoFile == null) {
      return _placeholder(context);
    }
    return FutureBuilder<File>(
      future: _photoFile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _placeholder(context, failed: true);
        }
        if (!snapshot.hasData) {
          return _placeholder(context);
        }
        return Image.file(
          snapshot.data!,
          width: double.infinity,
          height: double.infinity,
          fit: widget.fit,
          semanticLabel: widget.semanticLabel,
          cacheWidth: widget.cacheWidth,
          errorBuilder: (context, error, stackTrace) =>
              _placeholder(context, failed: true),
        );
      },
    );
  }
}
