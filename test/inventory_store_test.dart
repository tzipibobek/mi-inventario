import 'package:flutter_test/flutter_test.dart';
import 'package:mi_inventario/data/inventory_database.dart';
import 'package:mi_inventario/models/app_settings.dart';
import 'package:mi_inventario/models/item.dart';
import 'package:mi_inventario/models/stock_movement.dart';
import 'package:mi_inventario/state/inventory_store.dart';

void main() {
  test('normaliza el código y evita duplicados antes de escribir', () async {
    final database = TestInventoryDatabase();
    final store = InventoryStore(database);
    addTearDown(store.dispose);
    await store.load();
    await store.saveItem(
      name: 'Remera',
      description: '',
      quantity: 2,
      barcode: ' 00123 ',
    );
    expect(store.itemByBarcode('00123')?.name, 'Remera');
    expect(store.items.single.barcode, '00123');
    await expectLater(
      store.saveItem(
        name: 'Pollera',
        description: '',
        quantity: 1,
        barcode: '00123',
      ),
      throwsFormatException,
    );
    expect(store.items.length, 1);
  });

  test('editar conserva el código propio y permite quitarlo', () async {
    final store = InventoryStore(TestInventoryDatabase());
    addTearDown(store.dispose);
    await store.load();
    await store.saveItem(
      name: 'Remera',
      description: '',
      quantity: 2,
      barcode: '00123',
    );
    await store.saveItem(
      itemId: 1,
      name: 'Remera azul',
      description: '',
      quantity: 2,
      barcode: '00123',
    );
    expect(store.items.single.barcode, '00123');
    await store.saveItem(
      itemId: 1,
      name: 'Remera azul',
      description: '',
      quantity: 2,
      barcode: '  ',
    );
    expect(store.items.single.barcode, isNull);
    expect(store.itemByBarcode(''), isNull);
  });

  test(
    'crear actualiza el inventario y agrega el movimiento inicial',
    () async {
      final database = TestInventoryDatabase();
      final store = InventoryStore(database);
      addTearDown(store.dispose);
      await store.load();
      database.failReads = true;

      await store.saveItem(
        name: 'Pinceles',
        description: 'Acuarela',
        quantity: 12,
        minimumQuantity: 3,
      );

      expect(store.items.single.quantity, 12);
      expect(store.items.single.minimumQuantity, 3);
      expect(store.movements.single.type, MovementType.initial);
    },
  );

  test('una salida exitosa no depende de una segunda lectura', () async {
    final database = TestInventoryDatabase();
    final store = InventoryStore(database);
    addTearDown(store.dispose);
    await store.load();
    await store.saveItem(
      name: 'Pinceles',
      description: '',
      quantity: 12,
      minimumQuantity: 3,
      photoName: 'pinceles.jpg',
      barcode: '00123',
    );
    database.failReads = true;

    await store.recordMovement(
      itemId: 1,
      type: MovementType.exit,
      amount: 3,
      reason: 'Uso',
    );

    expect(store.items.single.quantity, 9);
    expect(store.items.single.photoName, 'pinceles.jpg');
    expect(store.items.single.barcode, '00123');
    expect(store.movements.first.quantityBefore, 12);
    expect(store.movements.first.quantityAfter, 9);
    expect(database.movementWrites, 1);
  });

  test(
    'un guardado fallido conserva el stock y el historial en memoria',
    () async {
      final database = TestInventoryDatabase();
      final store = InventoryStore(database);
      addTearDown(store.dispose);
      await store.load();
      await store.saveItem(
        name: 'Pinceles',
        description: '',
        quantity: 12,
        minimumQuantity: 3,
      );
      database.failWrites = true;

      await expectLater(
        store.recordMovement(
          itemId: 1,
          type: MovementType.exit,
          amount: 3,
          reason: '',
        ),
        throwsException,
      );

      expect(store.items.single.quantity, 12);
      expect(store.movements.length, 1);
    },
  );

  test(
    'editar datos no cambia cantidad ni reescribe nombres históricos',
    () async {
      final database = TestInventoryDatabase();
      final store = InventoryStore(database);
      addTearDown(store.dispose);
      await store.load();
      await store.saveItem(
        name: 'Pinceles',
        description: '',
        quantity: 12,
        minimumQuantity: 3,
      );

      await store.saveItem(
        itemId: 1,
        name: 'Pinceles finos',
        description: 'Nuevos datos',
        quantity: 999,
        minimumQuantity: 5,
      );

      expect(store.items.single.name, 'Pinceles finos');
      expect(store.items.single.quantity, 12);
      expect(store.movements.single.itemName, 'Pinceles');
    },
  );
}

// Base de prueba: evita abrir un plugin nativo en estos tests del estado.
class TestInventoryDatabase extends InventoryDatabase {
  bool failReads = false;
  bool failWrites = false;
  int movementWrites = 0;
  int _currentQuantity = 0;

  @override
  Future<List<Item>> loadItems() async {
    if (failReads) {
      throw Exception('Error de lectura simulado');
    }
    return [];
  }

  @override
  Future<List<StockMovement>> loadMovements() async {
    if (failReads) {
      throw Exception('Error de lectura simulado');
    }
    return [];
  }

  @override
  Future<AppSettings> loadSettings() async => const AppSettings();

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
    if (failWrites) {
      throw Exception('Error de escritura simulado');
    }
    _currentQuantity = quantity;
    return StockMovement(
      id: 1,
      itemId: 1,
      itemName: name,
      type: MovementType.initial,
      quantityBefore: 0,
      quantityAfter: quantity,
      reason: '',
      date: DateTime.now(),
    );
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
    if (failWrites) {
      throw Exception('Error de escritura simulado');
    }
  }

  @override
  Future<StockMovement> recordMovement({
    required int itemId,
    required MovementType type,
    required int amount,
    required String reason,
  }) async {
    if (failWrites) {
      throw Exception('Error de escritura simulado');
    }
    movementWrites++;
    final quantityBefore = _currentQuantity;
    _currentQuantity = calculateQuantity(quantityBefore, type, amount);
    return StockMovement(
      id: 2,
      itemId: itemId,
      itemName: 'Pinceles',
      type: type,
      quantityBefore: quantityBefore,
      quantityAfter: _currentQuantity,
      reason: reason,
      date: DateTime.now(),
    );
  }
}
