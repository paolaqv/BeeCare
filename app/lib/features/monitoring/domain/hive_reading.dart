class HiveReading {
  final double temperature;
  final double humidity;
  final double weight;
  final DateTime timestamp;

  const HiveReading({
    required this.temperature,
    required this.humidity,
    required this.weight,
    required this.timestamp,
  });
}