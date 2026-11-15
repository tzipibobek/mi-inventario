class Item {
  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    this.minimumQuantity = 0,
    this.trackLowStock = false,
    this.photoName,
    this.barcode,
    this.archived = false,
  });

  final bool archived;
  final int id;
  final String name;
  final String description;
  final int quantity;
  final int minimumQuantity;
  final bool trackLowStock;
  final String? photoName;
  final String? barcode;

  // clearPhoto/clearBarcode distinguen borrar un valor de conservarlo.
  Item copyWith({
    String? name,
    String? description,
    int? quantity,
    int? minimumQuantity,
    bool? trackLowStock,
    String? photoName,
    String? barcode,
    bool? archived,
    bool clearPhoto = false,
    bool clearBarcode = false,
  }) => Item(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    minimumQuantity: minimumQuantity ?? this.minimumQuantity,
    trackLowStock: trackLowStock ?? this.trackLowStock,
    photoName: clearPhoto ? null : photoName ?? this.photoName,
    barcode: clearBarcode ? null : barcode ?? this.barcode,
    archived: archived ?? this.archived,
  );

  bool get hasLowStock => trackLowStock && quantity <= minimumQuantity;

  String get stockStatus {
    if (quantity == 0) {
      return 'Agotado';
    }
    if (hasLowStock) {
      return 'Stock bajo';
    }
    return 'Disponible';
  }

  factory Item.fromMap(Map<String, Object?> map) => Item(
    id: map['id'] as int,
    name: map['name'] as String,
    description: map['description'] as String,
    quantity: map['quantity'] as int,
    minimumQuantity: map['minimum'] as int,
    trackLowStock: map['stock_alert_enabled'] == 1,
    photoName: map['photo_name'] as String?,
    archived: map['archived'] == 1,
    barcode: map['barcode'] as String?,
  );
}
