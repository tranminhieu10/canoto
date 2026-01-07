/// Model kết quả nhận diện biển số
class LicensePlateResult {
  final String licensePlate;
  final double confidence;
  final String? imagePath;
  final DateTime timestamp;
  final Map<String, dynamic>? rawData;

  LicensePlateResult({
    required this.licensePlate,
    required this.confidence,
    this.imagePath,
    DateTime? timestamp,
    this.rawData,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'license_plate': licensePlate,
      'confidence': confidence,
      'image_path': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LicensePlateResult.fromMap(Map<String, dynamic> map) {
    return LicensePlateResult(
      licensePlate: map['license_plate'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      imagePath: map['image_path'] as String?,
      timestamp: DateTime.parse(map['timestamp']),
      rawData: map,
    );
  }
}
