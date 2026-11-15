import 'dart:async';

import 'package:mi_inventario/data/inventory_database.dart';
import 'package:mi_inventario/models/app_settings.dart';
import 'package:mi_inventario/models/item.dart';
import 'package:mi_inventario/models/stock_movement.dart';

// Solo para probar el estado: no reemplaza los futuros tests de SQLite.
class QualityFakeDatabase extends InventoryDatabase {
  final savedItems = <int, Item>{};
  final savedMovements = <StockMovement>[];
  AppSettings savedSettings = const AppSettings();
  bool failReads = false;
  bool failWrites = false;
  Completer<void>? archiveGate;
  var _nextItemId = 1;
  var _nextMovementId = 1;

  void _checkWrite() {
    if (failWrites) throw StateError('Fallo de escritura simulado');
  }

  @override
  Future<List<Item>> loadItems() async {
    if (failReads) throw StateError('Fallo de lectura simulado');
    return savedItems.values.toList();
  }

  @override
  Future<List<StockMovement>> loadMovements() async {
    if (failReads) throw StateError('Fallo de lectura simulado');
    return savedMovements.reversed.toList();
  }

  @override
  Future<AppSettings> loadSettings() async => savedSettings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _checkWrite();
    savedSettings = settings;
  }

  @override
  Future<void> setArchived(int id, bool archived) async {
    final gate = archiveGate;
    if (gate != null) await gate.future;
    _checkWrite();
    savedItems[id] = savedItems[id]!.copyWith(archived: archived);
  }

  StockMovement _movement(
    Item item,
    MovementType type,
    int before,
    String reason,
  ) {
    final movement = StockMovement(
      id: _nextMovementId++,
      itemId: item.id,
      itemName: item.name,
      type: type,
      quantityBefore: before,
      quantityAfter: item.quantity,
      reason: reason,
      date: DateTime.now(),
    );
    savedMovements.add(movement);
    return movement;
  }

  @override
  Future<StockMovement> createItem({
    required String name,
    required String description,
    required int quantity,
    required int minimumQuantity,
    required bool trackLowStock,
    String? photoName,
    String? barcode,
  }) async {
    _checkWrite();
    final item = Item(
      id: _nextItemId++,
      name: name,
      description: description,
      quantity: quantity,
      minimumQuantity: minimumQuantity,
      trackLowStock: trackLowStock,
      photoName: photoName,
      barcode: barcode,
    );
    savedItems[item.id] = item;
    return _movement(item, MovementType.initial, 0, '');
  }

  @override
  Future<void> editItem({
    required int itemId,
    required String name,
    required String description,
    required int minimumQuantity,
    required bool trackLowStock,
    String? photoName,
    String? barcode,
  }) async {
    _checkWrite();
    final item = savedItems[itemId]!;
    if (item.archived) throw const FormatException('Artículo archivado');
    savedItems[itemId] = item.copyWith(
      name: name,
      description: description,
      minimumQuantity: minimumQuantity,
      trackLowStock: trackLowStock,
      photoName: photoName,
      barcode: barcode,
      clearPhoto: photoName == null,
      clearBarcode: barcode == null,
    );
  }

  @override
  Future<StockMovement> recordMovement({
    required int itemId,
    required MovementType type,
    required int amount,
    required String reason,
  }) async {
    _checkWrite();
    final previous = savedItems[itemId]!;
    if (previous.archived) throw const FormatException('Artículo archivado');
    final item = previous.copyWith(
      quantity: calculateQuantity(previous.quantity, type, amount),
    );
    savedItems[itemId] = item;
    return _movement(item, type, previous.quantity, reason);
  }
}
