enum DeviceStatus { disconnected, scanning, connected }

class DeviceModel {
  final String id;
  final String name;
  final String type; // e.g. 'Fitness Band', 'Smartwatch'
  DeviceStatus status;
  int? stepCount;
  double? heartRate;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceStatus.disconnected,
    this.stepCount,
    this.heartRate,
  });
}
