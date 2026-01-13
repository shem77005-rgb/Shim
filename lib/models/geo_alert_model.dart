class GeoAlert {
  final int? id;
  final int child;
  final int? geoZone;
  final String eventType; // 'entry', 'exit'
  final double latitude;
  final double longitude;
  final String timestamp;
  final String? message;

  GeoAlert({
    this.id,
    required this.child,
    this.geoZone,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.message,
  });

  factory GeoAlert.fromJson(Map<String, dynamic> json) {
    return GeoAlert(
      id: json['id'],
      child: json['child'],
      geoZone: json['geo_zone'],
      eventType: json['event_type'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timestamp: json['timestamp'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child': child,
      'geo_zone': geoZone,
      'event_type': eventType,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'message': message,
    };
  }
}
