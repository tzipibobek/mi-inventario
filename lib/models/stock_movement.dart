enum MovementType { initial, entry, exit, adjustment }

String movementTypeLabel(MovementType type) {
  switch (type) {
    case MovementType.initial:
      return 'Cantidad inicial';
    case MovementType.entry:
      return 'Entrada';
    case MovementType.exit:
      return 'Salida';
    case MovementType.adjustment:
      return 'Ajuste';
  }
}

// En un ajuste, amount es el total contado; en entradas/salidas es el cambio.
int calculateQuantity(int currentQuantity, MovementType type, int amount) {
  if (currentQuantity < 0 || amount < 0) {
    throw const FormatException('La cantidad no puede ser negativa.');
  }
  if (type != MovementType.adjustment && amount == 0) {
    throw const FormatException('Ingresá una cantidad mayor que cero.');
  }
  final int newQuantity;
  switch (type) {
    case MovementType.entry:
      newQuantity = currentQuantity + amount;
      break;
    case MovementType.exit:
      newQuantity = currentQuantity - amount;
      break;
    case MovementType.adjustment:
      newQuantity = amount;
      break;
    case MovementType.initial:
      throw const FormatException('La cantidad inicial se registra al crear.');
  }
  if (newQuantity < 0) {
    throw const FormatException('La salida supera el stock disponible.');
  }
  if (newQuantity == currentQuantity) {
    throw const FormatException('La cantidad no cambió.');
  }
  return newQuantity;
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.reason,
    required this.date,
  });

  final int id;
  final int itemId;
  final String itemName;
  final MovementType type;
  final int quantityBefore;
  final int quantityAfter;
  final String reason;
  final DateTime date;

  int get quantityChange => quantityAfter - quantityBefore;

  factory StockMovement.fromMap(Map<String, Object?> map) => StockMovement(
    id: map['id'] as int,
    itemId: map['item_id'] as int,
    itemName: map['item_name'] as String,
    type: MovementType.values.byName(map['type'] as String),
    quantityBefore: map['before_qty'] as int,
    quantityAfter: map['after_qty'] as int,
    reason: map['reason'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
