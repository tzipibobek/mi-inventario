import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ItemPhotoStorage {
  Future<Directory> _getDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(documents.path, 'item_photos'));

    await directory.create(recursive: true);
    return directory;
  }

  Future<File> getFile(String photoName) async {
    final directory = await _getDirectory();

    return File(path.join(directory.path, path.basename(photoName)));
  }

  Future<String> saveCopy(File original) async {
    final extension = path.extension(original.path);
    final photoName = '${DateTime.now().microsecondsSinceEpoch}$extension';

    final destination = await getFile(photoName);
    await original.copy(destination.path);

    return photoName;
  }

  Future<void> deleteCopy(String? photoName) async {
    if (photoName == null) {
      return;
    }

    try {
      final file = await getFile(photoName);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      debugPrint('No se pudo eliminar la copia de la foto: $error');
    }
  }
}
