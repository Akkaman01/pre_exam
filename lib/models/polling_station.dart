class PollingStation {
  final String stationId;
  final String stationName;
  final String zone;
  final String province;

  const PollingStation({
    required this.stationId,
    required this.stationName,
    required this.zone,
    required this.province,
  });

  factory PollingStation.fromMap(Map<String, Object?> map) {
    return PollingStation(
      stationId: (map['station_id'] ?? '').toString(),
      stationName: (map['station_name'] ?? '').toString(),
      zone: (map['zone'] ?? '').toString(),
      province: (map['province'] ?? '').toString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'station_id': stationId,
      'station_name': stationName,
      'zone': zone,
      'province': province,
    };
  }
}
