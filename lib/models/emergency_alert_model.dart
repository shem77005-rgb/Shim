/// Emergency Alert Request Model
class EmergencyAlertRequest {
  final String childId;
  final String parentId;
  final bool active;

  EmergencyAlertRequest({
    required this.childId,
    required this.parentId,
    required this.active,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {'child': childId, 'parent': parentId, 'active': active};
  }
}
