class ChildLocation {
  final int? id;
  final int child;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String? accuracy;

  ChildLocation({
    this.id,
    required this.child,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  factory ChildLocation.fromJson(Map<String, dynamic> json) {
    return ChildLocation(
      id: json['id'],
      child: json['child'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timestamp: json['timestamp'],
      accuracy: json['accuracy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child': child,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'accuracy': accuracy,
    };
  }
}
