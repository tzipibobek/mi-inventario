import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import '../models/item.dart';
import '../models/stock_movement.dart';

class InventoryDatabase {
  Database? _database;

  Future<Database> _openDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final databaseFolder = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databaseFolder, 'mi_inventario.db'),
      version: 5,
      onConfigure: (database) {
        return database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            quantity INTEGER NOT NULL CHECK (quantity >= 0),
            minimum INTEGER NOT NULL CHECK (minimum >= 0),
            stock_alert_enabled INTEGER NOT NULL DEFAULT 0,
            photo_name TEXT,
            archived INTEGER NOT NULL DEFAULT 0,
            barcode TEXT
          )
        ''');
        await database.execute('''
          CREATE TABLE movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL REFERENCES items(id),
            item_name TEXT NOT NULL,
            type TEXT NOT NULL,
            before_qty INTEGER NOT NULL,
            after_qty INTEGER NOT NULL,
            reason TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            title TEXT NOT NULL,
            color_index INTEGER NOT NULL,
            theme TEXT NOT NULL
          )
        ''');
        await database.execute(
          'CREATE UNIQUE INDEX items_barcode_unique ON items(barcode) WHERE barcode IS NOT NULL',
        );
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await database.execute(
            'ALTER TABLE items ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE items ADD COLUMN stock_alert_enabled INTEGER NOT NULL DEFAULT 0',
          );
          // Los mínimos mayores que cero ya configurados se conservan activos.
          await database.execute(
            'UPDATE items SET stock_alert_enabled = 1 WHERE minimum > 0',
          );
        }
        if (oldVersion < 3) {
          await database.execute(
            'ALTER TABLE items ADD COLUMN photo_name TEXT',
          );
        }
        if (oldVersion < 4) {
          await database.execute('ALTER TABLE items ADD COLUMN barcode TEXT');
          await database.execute(
            'CREATE UNIQUE INDEX items_barcode_unique ON items(barcode) WHERE barcode IS NOT NULL',
          );
        }
      },
    );
    return _database!;
  }

  Future<void> setArchived(int id, bool archived) async {
    final db = await _openDatabase();
    final count = await db.update(
      'items',
      {'archived': archived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) throw const FormatException('El artículo ya no existe.');
  }

  Future<List<Item>> loadItems() async {
    final database = await _openDatabase();
    final savedItems = await database.query('items');
    return savedItems.map(Item.fromMap).toList();
  }

  Future<List<StockMovement>> loadMovements() async {
    final database = await _openDatabase();
    final savedMovements = await database.query(
      'movements',
      orderBy: 'created_at DESC, id DESC',
    );
    return savedMovements.map(StockMovement.fromMap).toList();
  }

  // Devuelve el movimiento inicial que se guardó junto con el artículo.
  Future<StockMovement> createItem({
    required String name,
    required String description,
    required int quantity,
    required int minimumQuantity,
    required bool trackLowStock,
    String? photoName,
    String? barcode,
  }) async {
    final database = await _openDatabase();
    return database.transaction((transaction) async {
      final itemId = await transaction.insert('items', {
        'name': name,
        'description': description,
        'quantity': quantity,
        'minimum': minimumQuantity,
        'stock_alert_enabled': trackLowStock ? 1 : 0,
        'photo_name': photoName,
        'barcode': barcode,
      });
      return _insertMovement(
        transaction: transaction,
        itemId: itemId,
        itemName: name,
        type: MovementType.initial,
        quantityBefore: 0,
        quantityAfter: quantity,
        reason: '',
      );
    });
  }

  Future<void> editItem({
    required int itemId,
    required String name,
    required String description,
    required int minimumQuantity,
    required bool trackLowStock,
    String? photoName,
    String? barcode,
  }) async {
    final database = await _openDatabase();
    final updatedCount = await database.update(
      'items',
      {
        'name': name,
        'description': description,
        'minimum': minimumQuantity,
        'stock_alert_enabled': trackLowStock ? 1 : 0,
        'photo_name': photoName,
        'barcode': barcode,
      },
      where: 'id = ? AND archived = 0',
      whereArgs: [itemId],
    );
    if (updatedCount == 0) {
      throw const FormatException('El artículo ya no existe.');
    }
  }

  Future<StockMovement> recordMovement({
    required int itemId,
    required MovementType type,
    required int amount,
    required String reason,
  }) async {
    final database = await _openDatabase();
    // La transacción guarda ambos cambios juntos, o revierte ambos si falla.
    return database.transaction((transaction) async {
      final savedItems = await transaction.query(
        'items',
        where: 'id = ?',
        whereArgs: [itemId],
      );
      if (savedItems.isEmpty) {
        throw const FormatException('El artículo ya no existe.');
      }
      final item = Item.fromMap(savedItems.single);
      if (item.archived) {
        throw const FormatException(
          'Restaurá el artículo antes de registrar movimientos.',
        );
      }
      final newQuantity = calculateQuantity(item.quantity, type, amount);
      await transaction.update(
        'items',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [itemId],
      );
      return _insertMovement(
        transaction: transaction,
        itemId: itemId,
        itemName: item.name,
        type: type,
        quantityBefore: item.quantity,
        quantityAfter: newQuantity,
        reason: reason,
      );
    });
  }

  Future<StockMovement> _insertMovement({
    required Transaction transaction,
    required int itemId,
    required String itemName,
    required MovementType type,
    required int quantityBefore,
    required int quantityAfter,
    required String reason,
  }) async {
    final movementData = <String, Object?>{
      'item_id': itemId,
      'item_name': itemName,
      'type': type.name,
      'before_qty': quantityBefore,
      'after_qty': quantityAfter,
      'reason': reason,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    final movementId = await transaction.insert('movements', movementData);
    movementData['id'] = movementId;
    return StockMovement.fromMap(movementData);
  }

  Future<AppSettings> loadSettings() async {
    final database = await _openDatabase();
    final savedSettings = await database.query('settings');
    if (savedSettings.isEmpty) {
      return const AppSettings();
    }
    final settings = savedSettings.single;
    return AppSettings(
      title: settings['title'] as String,
      colorIndex: settings['color_index'] as int,
      themeMode: ThemeMode.values.byName(settings['theme'] as String),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final database = await _openDatabase();
    await database.insert('settings', {
      'id': 1,
      'title': settings.title,
      'color_index': settings.colorIndex,
      'theme': settings.themeMode.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
