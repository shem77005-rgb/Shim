class GeoZone {
  final int? id;
  final int child;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String zoneType; // 'safe', 'restricted', etc.
  final String? startTime; // Time restriction start (HH:MM format)
  final String? endTime; // Time restriction end (HH:MM format)
  final bool isActive; // Whether time restriction is active
  final bool
  notifyOnViolation; // Whether to send notifications when child crosses boundaries
  final String? createdAt;
  final String? updatedAt;

  GeoZone({
    this.id,
    required this.child,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.zoneType,
    this.startTime,
    this.endTime,
    this.isActive = true,
    this.notifyOnViolation = true,
    this.createdAt,
    this.updatedAt,
  });

  factory GeoZone.fromJson(Map<String, dynamic> json) {
    return GeoZone(
      id: json['id'],
      child: json['child'],
      name: json['name'],
      latitude:
          (json['latitude'] is int)
              ? json['latitude'].toDouble()
              : json['latitude'],
      longitude:
          (json['longitude'] is int)
              ? json['longitude'].toDouble()
              : json['longitude'],
      radius:
          (json['radius'] is int) ? json['radius'].toDouble() : json['radius'],
      zoneType: json['zone_type'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      isActive: json['is_active'] ?? true,
      notifyOnViolation: json['notify_on_violation'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    // Create a completely new map with only the fields required by the API
    // This ensures no object properties are inadvertently included
    final Map<String, dynamic> result = {
      'child': child,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'zone_type': zoneType,
      'notify_on_violation': notifyOnViolation,
    };

    // Add optional fields only if they have values
    if (id != null) result['id'] = id;
    if (startTime != null) result['start_time'] = startTime;
    if (endTime != null) result['end_time'] = endTime;

    return result;
  }

  // Method to convert to JSON including server-generated fields (for display purposes)
  Map<String, dynamic> toJsonWithServerFields() {
    final Map<String, dynamic> json = {
      'child': child,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'zone_type': zoneType,
      'is_active': isActive,
      'notify_on_violation': notifyOnViolation,
    };

    // Include optional fields only if they have values
    if (id != null) json['id'] = id;
    if (startTime != null) json['start_time'] = startTime;
    if (endTime != null) json['end_time'] = endTime;
    if (createdAt != null) json['created_at'] = createdAt;
    if (updatedAt != null) json['updated_at'] = updatedAt;

    return json;
  }
}
