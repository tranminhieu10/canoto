import 'package:canoto/data/models/enums/weighing_enums.dart';

/// Model phiếu cân
class WeighingTicket {
  final int? id;
  final String ticketNumber;
  final String licensePlate;
  final String? vehicleType;
  final String? driverName;
  final String? driverPhone;
  final int? customerId;
  final String? customerName;
  final int? productId;
  final String? productName;
  final double? firstWeight;
  final DateTime? firstWeightTime;
  final double? secondWeight;
  final DateTime? secondWeightTime;
  final double? netWeight;
  final double? deduction;
  final double? actualWeight;
  final double? unitPrice;
  final double? totalAmount;
  final WeighingType weighingType;
  final WeighingStatus status;
  final String? note;
  final String? firstWeightImage;
  final String? secondWeightImage;
  final String? licensePlateImage;
  final int? scaleId;
  final String? operatorId;
  final String? operatorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Sync fields - for Azure sync
  final bool isSynced;
  final int? azureId;
  final DateTime? syncedAt;

  WeighingTicket({
    this.id,
    required this.ticketNumber,
    required this.licensePlate,
    this.vehicleType,
    this.driverName,
    this.driverPhone,
    this.customerId,
    this.customerName,
    this.productId,
    this.productName,
    this.firstWeight,
    this.firstWeightTime,
    this.secondWeight,
    this.secondWeightTime,
    this.netWeight,
    this.deduction,
    this.actualWeight,
    this.unitPrice,
    this.totalAmount,
    this.weighingType = WeighingType.incoming,
    this.status = WeighingStatus.pending,
    this.note,
    this.firstWeightImage,
    this.secondWeightImage,
    this.licensePlateImage,
    this.scaleId,
    this.operatorId,
    this.operatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.azureId,
    this.syncedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Copy with
  WeighingTicket copyWith({
    int? id,
    String? ticketNumber,
    String? licensePlate,
    String? vehicleType,
    String? driverName,
    String? driverPhone,
    int? customerId,
    String? customerName,
    int? productId,
    String? productName,
    double? firstWeight,
    DateTime? firstWeightTime,
    double? secondWeight,
    DateTime? secondWeightTime,
    double? netWeight,
    double? deduction,
    double? actualWeight,
    double? unitPrice,
    double? totalAmount,
    WeighingType? weighingType,
    WeighingStatus? status,
    String? note,
    String? firstWeightImage,
    String? secondWeightImage,
    String? licensePlateImage,
    int? scaleId,
    String? operatorId,
    String? operatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    int? azureId,
    DateTime? syncedAt,
  }) {
    return WeighingTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleType: vehicleType ?? this.vehicleType,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      firstWeight: firstWeight ?? this.firstWeight,
      firstWeightTime: firstWeightTime ?? this.firstWeightTime,
      secondWeight: secondWeight ?? this.secondWeight,
      secondWeightTime: secondWeightTime ?? this.secondWeightTime,
      netWeight: netWeight ?? this.netWeight,
      deduction: deduction ?? this.deduction,
      actualWeight: actualWeight ?? this.actualWeight,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      weighingType: weighingType ?? this.weighingType,
      status: status ?? this.status,
      note: note ?? this.note,
      firstWeightImage: firstWeightImage ?? this.firstWeightImage,
      secondWeightImage: secondWeightImage ?? this.secondWeightImage,
      licensePlateImage: licensePlateImage ?? this.licensePlateImage,
      scaleId: scaleId ?? this.scaleId,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      azureId: azureId ?? this.azureId,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// To Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'license_plate': licensePlate,
      'vehicle_type': vehicleType,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'customer_id': customerId,
      'customer_name': customerName,
      'product_id': productId,
      'product_name': productName,
      'first_weight': firstWeight,
      'first_weight_time': firstWeightTime?.toIso8601String(),
      'second_weight': secondWeight,
      'second_weight_time': secondWeightTime?.toIso8601String(),
      'net_weight': netWeight,
      'deduction': deduction,
      'actual_weight': actualWeight,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'weighing_type': weighingType.value,
      'status': status.value,
      'note': note,
      'first_weight_image': firstWeightImage,
      'second_weight_image': secondWeightImage,
      'license_plate_image': licensePlateImage,
      'scale_id': scaleId,
      'operator_id': operatorId,
      'operator_name': operatorName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'azure_id': azureId,
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  /// To JSON for API upload
  Map<String, dynamic> toJson() {
    return {
      'ticketNumber': ticketNumber,
      'licensePlate': licensePlate,
      'vehicleType': vehicleType,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'customerId': customerId,
      'customerName': customerName,
      'productId': productId,
      'productName': productName,
      'firstWeight': firstWeight,
      'firstWeightTime': firstWeightTime?.toIso8601String(),
      'secondWeight': secondWeight,
      'secondWeightTime': secondWeightTime?.toIso8601String(),
      'netWeight': netWeight,
      'deduction': deduction,
      'actualWeight': actualWeight,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'weighingType': weighingType.value,
      'status': status.value,
      'note': note,
      'scaleId': scaleId,
      'operatorId': operatorId,
      'operatorName': operatorName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// From Map
  factory WeighingTicket.fromMap(Map<String, dynamic> map) {
    return WeighingTicket(
      id: map['id'] as int?,
      ticketNumber: map['ticket_number'] as String,
      licensePlate: map['license_plate'] as String,
      vehicleType: map['vehicle_type'] as String?,
      driverName: map['driver_name'] as String?,
      driverPhone: map['driver_phone'] as String?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String?,
      firstWeight: map['first_weight'] as double?,
      firstWeightTime: map['first_weight_time'] != null
          ? DateTime.parse(map['first_weight_time'])
          : null,
      secondWeight: map['second_weight'] as double?,
      secondWeightTime: map['second_weight_time'] != null
          ? DateTime.parse(map['second_weight_time'])
          : null,
      netWeight: map['net_weight'] as double?,
      deduction: map['deduction'] as double?,
      actualWeight: map['actual_weight'] as double?,
      unitPrice: map['unit_price'] as double?,
      totalAmount: map['total_amount'] as double?,
      weighingType: WeighingType.fromValue(map['weighing_type'] ?? 'incoming'),
      status: WeighingStatus.fromValue(map['status'] ?? 'pending'),
      note: map['note'] as String?,
      firstWeightImage: map['first_weight_image'] as String?,
      secondWeightImage: map['second_weight_image'] as String?,
      licensePlateImage: map['license_plate_image'] as String?,
      scaleId: map['scale_id'] as int?,
      operatorId: map['operator_id'] as String?,
      operatorName: map['operator_name'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: (map['is_synced'] as int?) == 1,
      azureId: map['azure_id'] as int?,
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at']) : null,
    );
  }
}
