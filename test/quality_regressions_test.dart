import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_inventario/models/app_settings.dart';
import 'package:mi_inventario/models/item.dart';
import 'package:mi_inventario/models/stock_movement.dart';
import 'package:mi_inventario/state/inventory_store.dart';
import 'package:mi_inventario/utils/text.dart';

import 'quality_fake_database.dart';

void main() {
  late QualityFakeDatabase database;
  late InventoryStore store;
  setUp(() async {
    database = QualityFakeDatabase();
    store = InventoryStore(database);
    await store.load();
  });
  tearDown(() => store.dispose());

  Future<void> create() => store.saveItem(
    name: 'Lápiz',
    description: 'Azul',
    quantity: 10,
    minimumQuantity: 2,
    trackLowStock: true,
    photoName: 'foto.jpg',
    barcode: '001',
  );

  test('normaliza tildes, diéresis, ñ y acentos descompuestos', () {
    expect(searchKey(' LÁPIZ '), 'lapiz');
    expect(searchKey('La\u0301piz'), 'lapiz');
    expect(searchKey('PINGÜINO Niño'), 'pinguino nino');
  });

  test('ordena nombres acentuados y mantiene ñ después de n', () async {
    for (final name in [
      'Zapato',
      'Árbol',
      'Escoba',
      'ñandú',
      'Alfombra',
      'Óleo',
      'Bolsa',
      'Nube',
    ]) {
      await store.saveItem(name: name, description: '', quantity: 1);
    }
    expect(store.items.map((item) => item.name), [
      'Alfombra',
      'Árbol',
      'Bolsa',
      'Escoba',
      'Nube',
      'ñandú',
      'Óleo',
      'Zapato',
    ]);
  });

  test(
    'copyWith conserva campos opcionales y permite borrarlos explícitamente',
    () {
      const item = Item(
        id: 7,
        name: 'Remera',
        description: 'Blanca',
        quantity: 3,
        minimumQuantity: 2,
        trackLowStock: true,
        photoName: 'foto.jpg',
        barcode: '001',
        archived: true,
      );
      final updated = item.copyWith(quantity: 0);
      expect(updated.id, 7);
      expect(updated.name, 'Remera');
      expect(updated.description, 'Blanca');
      expect(updated.minimumQuantity, 2);
      expect(updated.trackLowStock, isTrue);
      expect(updated.archived, isTrue);
      expect(updated.photoName, 'foto.jpg');
      expect(updated.barcode, '001');
      final cleared = updated.copyWith(clearPhoto: true, clearBarcode: true);
      expect(cleared.photoName, isNull);
      expect(cleared.barcode, isNull);
      expect(cleared.archived, isTrue);
    },
  );

  test('archivar y restaurar no requieren una segunda lectura', () async {
    await create();
    database.failReads = true;
    await store.setArchived(1, true);
    expect(store.items, isEmpty);
    expect(store.archivedItems.single.photoName, 'foto.jpg');
    expect(store.archivedItems.single.barcode, '001');
    expect(store.movements.length, 1);
    await store.setArchived(1, false);
    expect(store.items.single.quantity, 10);
    expect(store.archivedItems, isEmpty);
  });

  test('archivado fallido no modifica memoria ni notifica éxito', () async {
    await create();
    var notifications = 0;
    store.addListener(() => notifications++);
    database.failWrites = true;
    await expectLater(store.setArchived(1, true), throwsStateError);
    expect(store.items.single.archived, isFalse);
    expect(store.archivedItems, isEmpty);
    expect(notifications, 0);
  });

  test(
    'archiva por ID aunque una creación reordene la lista durante el await',
    () async {
      await store.saveItem(name: 'Zapato', description: '', quantity: 4);
      final gate = Completer<void>();
      database.archiveGate = gate;
      final saving = store.setArchived(1, true);
      await store.saveItem(name: 'Alfombra', description: '', quantity: 2);
      gate.complete();
      await saving;
      expect(store.archivedItems.single.name, 'Zapato');
      expect(store.items.single.name, 'Alfombra');
    },
  );

  test(
    'editar conserva stock e historial y permite quitar foto y código',
    () async {
      await create();
      await store.saveItem(
        itemId: 1,
        name: 'Lápiz nuevo',
        description: '',
        quantity: 999,
      );
      expect(store.items.single.quantity, 10);
      expect(store.items.single.photoName, isNull);
      expect(store.items.single.barcode, isNull);
      expect(store.movements.single.itemName, 'Lápiz');
    },
  );

  test('movimiento conserva foto, código, mínimo y alerta', () async {
    await create();
    database.failReads = true;
    await store.recordMovement(
      itemId: 1,
      type: MovementType.exit,
      amount: 3,
      reason: 'Uso',
    );
    final item = store.items.single;
    expect(item.quantity, 7);
    expect(item.photoName, 'foto.jpg');
    expect(item.barcode, '001');
    expect(item.minimumQuantity, 2);
    expect(item.trackLowStock, isTrue);
    expect(store.movements.first.quantityBefore, 10);
  });

  test('movimientos y archivado no reconstruyen el tema', () async {
    var changes = 0;
    store.settingsListenable.addListener(() => changes++);
    await create();
    await store.recordMovement(
      itemId: 1,
      type: MovementType.exit,
      amount: 1,
      reason: '',
    );
    await store.setArchived(1, true);
    expect(changes, 0);
    await store.saveSettings(const AppSettings(title: 'Nuevo nombre'));
    expect(changes, 1);
    await store.saveSettings(const AppSettings(title: 'Nuevo nombre'));
    expect(changes, 1);
  });

  test('ajustes fallidos conservan el tema y no notifican cambios', () async {
    var changes = 0;
    store.settingsListenable.addListener(() => changes++);
    database.failWrites = true;
    await expectLater(
      store.saveSettings(const AppSettings(title: 'Fallido')),
      throwsStateError,
    );
    expect(store.settings.title, 'Mi inventario');
    expect(changes, 0);
  });
}
