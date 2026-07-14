import 'dart:convert';

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String date; // YYYY-MM-DD
  final String checkInTime; // HH:MM:SS
  final String checkInSelfie; // base64 or storage url
  final double checkInLat;
  final double checkInLng;
  final double checkInDistance; // in meters
  final String checkInStatus; // 'On Time' or 'Late'
  final String? checkOutTime;
  final String? checkOutSelfie;
  final double? checkOutLat;
  final double? checkOutLng;
  final double? checkOutDistance;
  final String? checkOutStatus; // 'Early Checkout' or 'Normal'
  final double? workingHours;
  final bool isOutsideGeofence;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.checkInTime,
    required this.checkInSelfie,
    required this.checkInLat,
    required this.checkInLng,
    required this.checkInDistance,
    required this.checkInStatus,
    this.checkOutTime,
    this.checkOutSelfie,
    this.checkOutLat,
    this.checkOutLng,
    this.checkOutDistance,
    this.checkOutStatus,
    this.workingHours,
    required this.isOutsideGeofence,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      date: map['date'] ?? '',
      checkInTime: map['checkInTime'] ?? '',
      checkInSelfie: map['checkInSelfie'] ?? '',
      checkInLat: (map['checkInLat'] as num?)?.toDouble() ?? 0.0,
      checkInLng: (map['checkInLng'] as num?)?.toDouble() ?? 0.0,
      checkInDistance: (map['checkInDistance'] as num?)?.toDouble() ?? 0.0,
      checkInStatus: map['checkInStatus'] ?? 'On Time',
      checkOutTime: map['checkOutTime'],
      checkOutSelfie: map['checkOutSelfie'],
      checkOutLat: (map['checkOutLat'] as num?)?.toDouble(),
      checkOutLng: (map['checkOutLng'] as num?)?.toDouble(),
      checkOutDistance: (map['checkOutDistance'] as num?)?.toDouble(),
      checkOutStatus: map['checkOutStatus'],
      workingHours: (map['workingHours'] as num?)?.toDouble(),
      isOutsideGeofence: map['isOutsideGeofence'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date,
      'checkInTime': checkInTime,
      'checkInSelfie': checkInSelfie,
      'checkInLat': checkInLat,
      'checkInLng': checkInLng,
      'checkInDistance': checkInDistance,
      'checkInStatus': checkInStatus,
      if (checkOutTime != null) 'checkOutTime': checkOutTime,
      if (checkOutSelfie != null) 'checkOutSelfie': checkOutSelfie,
      if (checkOutLat != null) 'checkOutLat': checkOutLat,
      if (checkOutLng != null) 'checkOutLng': checkOutLng,
      if (checkOutDistance != null) 'checkOutDistance': checkOutDistance,
      if (checkOutStatus != null) 'checkOutStatus': checkOutStatus,
      if (workingHours != null) 'workingHours': workingHours,
      'isOutsideGeofence': isOutsideGeofence,
    };
  }

  String toJson() => json.encode(toMap());

  factory AttendanceRecord.fromJson(String source) => AttendanceRecord.fromMap(json.decode(source));
}
