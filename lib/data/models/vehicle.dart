/// Model phương tiện/xe
class Vehicle {
  final int? id;
  final String licensePlate;
  final String? vehicleType;
  final String? brand;
  final String? model;
  final String? color;
  final double? tareWeight;
  final int? customerId;
  final String? customerName;
  final String? driverName;
  final String? driverPhone;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    this.id,
    required this.licensePlate,
    this.vehicleType,
    this.brand,
    this.model,
    this.color,
    this.tareWeight,
    this.customerId,
    this.customerName,
    this.driverName,
    this.driverPhone,
    this.note,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Vehicle copyWith({
    int? id,
    String? licensePlate,
    String? vehicleType,
    String? brand,
    String? model,
    String? color,
    double? tareWeight,
    int? customerId,
    String? customerName,
    String? driverName,
    String? driverPhone,
    String? note,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      tareWeight: tareWeight ?? this.tareWeight,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'license_plate': licensePlate,
      'vehicle_type': vehicleType,
      'brand': brand,
      'model': model,
      'color': color,
      'tare_weight': tareWeight,
      'customer_id': customerId,
      'customer_name': customerName,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'note': note,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      licensePlate: map['license_plate'] as String,
      vehicleType: map['vehicle_type'] as String?,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      color: map['color'] as String?,
      tareWeight: map['tare_weight'] as double?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      driverName: map['driver_name'] as String?,
      driverPhone: map['driver_phone'] as String?,
      note: map['note'] as String?,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
