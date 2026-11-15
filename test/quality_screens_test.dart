import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_inventario/models/stock_movement.dart';
import 'package:mi_inventario/screens/inventory_screen.dart';
import 'package:mi_inventario/screens/movements_screen.dart';
import 'package:mi_inventario/screens/summary_screen.dart';
import 'package:mi_inventario/state/inventory_store.dart';

import 'quality_fake_database.dart';

void main() {
  late InventoryStore store;
  setUp(() async {
    store = InventoryStore(QualityFakeDatabase());
    await store.load();
  });
  tearDown(() => store.dispose());

  testWidgets('buscar lapiz encuentra Lápiz y conserva el nombre mostrado', (
    tester,
  ) async {
    await store.saveItem(name: 'Lápiz', description: '', quantity: 10);
    await tester.pumpWidget(
      MaterialApp(
        home: InventoryScreen(store: store, onCustomize: () {}),
      ),
    );
    await tester.enterText(find.byType(TextField), 'lapiz');
    await tester.pump();
    expect(find.text('Lápiz'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump();
    expect(find.text('Lápiz'), findsNothing);
    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('inventario se actualiza sin reconstruir el widget padre', (
    tester,
  ) async {
    await store.saveItem(name: 'Lápiz', description: '', quantity: 10);
    await tester.pumpWidget(
      MaterialApp(
        home: InventoryScreen(store: store, onCustomize: () {}),
      ),
    );
    expect(find.text('10 unidades'), findsOneWidget);
    await store.recordMovement(
      itemId: 1,
      type: MovementType.exit,
      amount: 3,
      reason: '',
    );
    await tester.pump();
    expect(find.text('7 unidades'), findsOneWidget);
    expect(find.text('10 unidades'), findsNothing);
    await store.setArchived(1, true);
    await tester.pump();
    expect(find.text('Lápiz'), findsNothing);
    await store.setArchived(1, false);
    await tester.pump();
    expect(find.text('Lápiz'), findsOneWidget);
  });

  testWidgets('movimientos escucha el store sin depender de MaterialApp', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: MovementsScreen(store: store)));
    expect(find.text('Todavía no hay movimientos'), findsOneWidget);
    await store.saveItem(name: 'Lápiz', description: '', quantity: 10);
    await tester.pump();
    expect(find.text('Lápiz'), findsOneWidget);
    expect(find.text('Todavía no hay movimientos'), findsNothing);
  });

  testWidgets('resumen escucha el store sin depender de MaterialApp', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: SummaryScreen(store: store)));
    expect(find.text('0 movimientos'), findsOneWidget);
    await store.saveItem(name: 'Lápiz', description: '', quantity: 10);
    await tester.pump();
    expect(find.text('1 movimiento'), findsOneWidget);
  });
}
