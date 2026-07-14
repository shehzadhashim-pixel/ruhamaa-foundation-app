import 'dart:convert';

class RoutePoint {
  final double latitude;
  final double longitude;
  final String timestamp;
  final String? locationName;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.locationName,
  });

  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    return RoutePoint(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] ?? '',
      locationName: map['locationName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      if (locationName != null) 'locationName': locationName,
    };
  }
}

class EmployeeLocation {
  final String employeeId;
  final String employeeName;
  final double latitude;
  final double longitude;
  final String status; // 'In Office' | 'Travelling' | 'School Visit' | 'Widow Visit' | 'Head Office (HO) Visit' | 'Other Visit' | 'Checked Out' | 'Offline'
  final String lastUpdated;
  final List<RoutePoint> routeHistory;

  EmployeeLocation({
    required this.employeeId,
    required this.employeeName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.lastUpdated,
    required this.routeHistory,
  });

  factory EmployeeLocation.fromMap(Map<String, dynamic> map) {
    var historyList = map['routeHistory'] as List? ?? [];
    List<RoutePoint> parsedHistory = historyList
        .map((item) => RoutePoint.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return EmployeeLocation(
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Offline',
      lastUpdated: map['lastUpdated'] ?? '',
      routeHistory: parsedHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'lastUpdated': lastUpdated,
      'routeHistory': routeHistory.map((point) => point.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());

  factory EmployeeLocation.fromJson(String source) => EmployeeLocation.fromMap(json.decode(source));
}
