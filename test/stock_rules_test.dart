import 'package:flutter_test/flutter_test.dart';
import 'package:mi_inventario/models/stock_movement.dart';
import 'package:mi_inventario/utils/dates.dart';

void main() {
  test('una entrada aumenta el stock y una salida lo reduce', () {
    final afterEntry = calculateQuantity(12, MovementType.entry, 5);
    expect(afterEntry, 17);
    expect(calculateQuantity(afterEntry, MovementType.exit, 3), 14);
  });

  test('una salida puede agotar el artículo pero no dejar stock negativo', () {
    expect(calculateQuantity(3, MovementType.exit, 3), 0);
    expect(
      () => calculateQuantity(3, MovementType.exit, 4),
      throwsFormatException,
    );
  });

  test('un ajuste usa el total contado, incluyendo cero', () {
    expect(calculateQuantity(12, MovementType.adjustment, 10), 10);
    expect(calculateQuantity(12, MovementType.adjustment, 0), 0);
  });

  test('no se registran movimientos negativos, vacíos o sin cambio', () {
    expect(
      () => calculateQuantity(3, MovementType.entry, -1),
      throwsFormatException,
    );
    expect(
      () => calculateQuantity(3, MovementType.entry, 0),
      throwsFormatException,
    );
    expect(
      () => calculateQuantity(3, MovementType.adjustment, 3),
      throwsFormatException,
    );
  });

  test('la semana empieza el lunes y termina antes del siguiente lunes', () {
    final start = startOfWeek(DateTime(2026, 11, 8, 23, 59));
    expect(start, DateTime(2026, 11, 2));
    expect(nextWeek(start), DateTime(2026, 11, 9));
    expect(startOfWeek(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
  });
}
