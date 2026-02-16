class BleLogEntry {
  final DateTime timestamp;
  final double accX;
  final double accY;
  final double accZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double mq9Ppm;
  final int prediction;

  BleLogEntry({
    required this.timestamp,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.mq9Ppm,
    required this.prediction,
  });

  factory BleLogEntry.fromJson(Map<String, dynamic> json, DateTime timestamp) {
    return BleLogEntry(
      timestamp: timestamp,
      accX: (json['accX'] as num).toDouble(),
      accY: (json['accY'] as num).toDouble(),
      accZ: (json['accZ'] as num).toDouble(),
      gyroX: (json['gyroX'] as num).toDouble(),
      gyroY: (json['gyroY'] as num).toDouble(),
      gyroZ: (json['gyroZ'] as num).toDouble(),
      mq9Ppm: (json['mq9_ppm'] as num).toDouble(),
      prediction: json['prediction'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'accX': accX,
      'accY': accY,
      'accZ': accZ,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
      'mq9_ppm': mq9Ppm,
      'prediction': prediction,
    };
  }
}
