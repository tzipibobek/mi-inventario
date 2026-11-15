import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_inventario/widgets/empty_state.dart';

void main() {
  testWidgets('el estado vacío permite scroll cuando queda poca altura', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Tu inventario empieza acá',
            message: 'Agregá tu primer artículo para registrar cantidades y movimientos.',
            action: FilledButton(
              onPressed: () {},
              child: const Text('Agregar'),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
