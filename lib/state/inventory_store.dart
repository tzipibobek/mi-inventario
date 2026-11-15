import 'package:flutter/foundation.dart';

import '../data/inventory_database.dart';
import '../models/app_settings.dart';
import '../models/item.dart';
import '../utils/text.dart';
import '../models/stock_movement.dart';

// Las pantallas comparten este objeto. El SQL queda en InventoryDatabase.
class InventoryStore extends ChangeNotifier {
  InventoryStore(this._database);

  final InventoryDatabase _database;
  List<Item> _items = [];
  List<StockMovement> _movements = [];
  AppSettings _settings = const AppSettings();
  bool _isDisposed = false;
  final _settingsChanges = ValueNotifier<AppSettings>(const AppSettings());
  ValueListenable<AppSettings> get settingsListenable => _settingsChanges;

  List<Item> get items =>
      List.unmodifiable(_items.where((item) => !item.archived));
  List<Item> get archivedItems =>
      List.unmodifiable(_items.where((item) => item.archived));
  Future<void> setArchived(int id, bool archived) async {
    if (itemById(id) == null) {
      throw const FormatException('El artículo ya no existe.');
    }
    await _database.setArchived(id, archived);
    _updateItem(id, (item) => item.copyWith(archived: archived));
    _notifyChanges();
  }

  List<StockMovement> get movements => List.unmodifiable(_movements);
  AppSettings get settings => _settings;

  Future<void> load() async {
    final savedItems = await _database.loadItems();
    final savedMovements = await _database.loadMovements();
    final savedSettings = await _database.loadSettings();
    _items = savedItems;
    _movements = savedMovements;
    _setSettings(savedSettings);
    _sortItems();
    _notifyChanges();
  }

  Item? itemById(int itemId) {
    for (final item in _items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  Item? itemByBarcode(String barcode) {
    final code = barcode.trim();
    if (code.isEmpty) {
      return null;
    }
    for (final item in _items) {
      if (item.barcode == code) {
        return item;
      }
    }
    return null;
  }

  Future<void> saveItem({
    int? itemId,
    required String name,
    required String description,
    required int quantity,
    int minimumQuantity = 0,
    bool trackLowStock = false,
    String? photoName,
    String? barcode,
  }) async {
    if (name.trim().isEmpty || quantity < 0 || minimumQuantity < 0) {
      throw const FormatException('Revisá el nombre y las cantidades.');
    }

    final trimmedCode = barcode?.trim();
    final savedBarcode = trimmedCode == null || trimmedCode.isEmpty
        ? null
        : trimmedCode;
    final existingItem = savedBarcode == null
        ? null
        : itemByBarcode(savedBarcode);
    if (existingItem != null && existingItem.id != itemId) {
      throw const FormatException('Ese código ya pertenece a otro artículo.');
    }

    if (itemId == null) {
      final initialMovement = await _database.createItem(
        name: name.trim(),
        description: description.trim(),
        quantity: quantity,
        minimumQuantity: minimumQuantity,
        trackLowStock: trackLowStock,
        photoName: photoName,
        barcode: savedBarcode,
      );
      _items.add(
        Item(
          id: initialMovement.itemId,
          name: name.trim(),
          description: description.trim(),
          quantity: quantity,
          minimumQuantity: minimumQuantity,
          trackLowStock: trackLowStock,
          photoName: photoName,
          barcode: savedBarcode,
        ),
      );
      _movements.insert(0, initialMovement);
    } else {
      final itemIndex = _items.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        throw const FormatException('El artículo ya no existe.');
      }
      await _database.editItem(
        itemId: itemId,
        name: name.trim(),
        description: description.trim(),
        minimumQuantity: minimumQuantity,
        trackLowStock: trackLowStock,
        photoName: photoName,
        barcode: savedBarcode,
      );
      _updateItem(
        itemId,
        (item) => item.copyWith(
          name: name.trim(),
          description: description.trim(),
          minimumQuantity: minimumQuantity,
          trackLowStock: trackLowStock,
          photoName: photoName,
          barcode: savedBarcode,
          clearPhoto: photoName == null,
          clearBarcode: savedBarcode == null,
        ),
      );
    }
    // Actualizar la memoria solo después de confirmar el guardado.
    _sortItems();
    _notifyChanges();
  }

  Future<void> recordMovement({
    required int itemId,
    required MovementType type,
    required int amount,
    required String reason,
  }) async {
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      throw const FormatException('El artículo ya no existe.');
    }
    final movement = await _database.recordMovement(
      itemId: itemId,
      type: type,
      amount: amount,
      reason: reason.trim(),
    );
    _updateItem(
      itemId,
      (item) => item.copyWith(quantity: movement.quantityAfter),
    );
    _movements.insert(0, movement);
    _notifyChanges();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _database.saveSettings(settings);
    _setSettings(settings);
    _notifyChanges();
  }

  // Resolver por ID después del await: otra operación pudo reordenar la lista.
  void _updateItem(int id, Item Function(Item) update) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = update(_items[index]);
    }
  }

  void _setSettings(AppSettings settings) {
    final changed =
        _settings.title != settings.title ||
        _settings.colorIndex != settings.colorIndex ||
        _settings.themeMode != settings.themeMode;
    _settings = settings;
    if (changed && !_isDisposed) {
      _settingsChanges.value = settings;
    }
  }

  void _sortItems() {
    _items.sort((firstItem, secondItem) {
      final comparison = spanishSortKey(
        firstItem.name,
      ).compareTo(spanishSortKey(secondItem.name));
      return comparison != 0
          ? comparison
          : firstItem.id.compareTo(secondItem.id);
    });
  }

  void _notifyChanges() {
    // Un guardado puede terminar cuando el widget principal ya se cerró.
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _settingsChanges.dispose();
    super.dispose();
  }
}
