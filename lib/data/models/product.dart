/// Model sản phẩm/hàng hóa
class Product {
  final int? id;
  final String code;
  final String name;
  final String? category;
  final String? unit;
  final double? unitPrice;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.code,
    required this.name,
    this.category,
    this.unit,
    this.unitPrice,
    this.description,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Product copyWith({
    int? id,
    String? code,
    String? name,
    String? category,
    String? unit,
    double? unitPrice,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'unit': unit,
      'unit_price': unitPrice,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      unit: map['unit'] as String?,
      unitPrice: map['unit_price'] as double?,
      description: map['description'] as String?,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
