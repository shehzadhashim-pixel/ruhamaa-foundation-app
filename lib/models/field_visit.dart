import 'dart:convert';

class FieldVisit {
  final String id;
  final String visitType; // 'School Visit' | 'Widow Visit' | 'HO Visit' | 'Other Visit'
  final String projectId;
  final String projectName;
  final String location;
  final double latitude;
  final double longitude;
  final String dateTime; // ISO date string
  final String startTime; // HH:MM
  final String endTime; // HH:MM
  final int durationMinutes;
  final String purpose;
  final String remarks;
  final String status; // 'Pending' | 'In Progress' | 'Completed'
  final String followUpRequired; // 'Yes' | 'No'
  final String? followUpDate; // YYYY-MM-DD
  final List<String> photos; // base64 or storage urls
  final List<String> documents; // base64 or storage urls
  final String employeeId;
  final String employeeName;

  FieldVisit({
    required this.id,
    required this.visitType,
    required this.projectId,
    required this.projectName,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.dateTime,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.purpose,
    required this.remarks,
    required this.status,
    required this.followUpRequired,
    this.followUpDate,
    required this.photos,
    required this.documents,
    required this.employeeId,
    required this.employeeName,
  });

  factory FieldVisit.fromMap(Map<String, dynamic> map) {
    return FieldVisit(
      id: map['id'] ?? '',
      visitType: map['visitType'] ?? 'School Visit',
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      dateTime: map['dateTime'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      purpose: map['purpose'] ?? '',
      remarks: map['remarks'] ?? '',
      status: map['status'] ?? 'Pending',
      followUpRequired: map['followUpRequired'] ?? 'No',
      followUpDate: map['followUpDate'],
      photos: List<String>.from(map['photos'] ?? []),
      documents: List<String>.from(map['documents'] ?? []),
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visitType': visitType,
      'projectId': projectId,
      'projectName': projectName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'dateTime': dateTime,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'purpose': purpose,
      'remarks': remarks,
      'status': status,
      'followUpRequired': followUpRequired,
      if (followUpDate != null) 'followUpDate': followUpDate,
      'photos': photos,
      'documents': documents,
      'employeeId': employeeId,
      'employeeName': employeeName,
    };
  }

  String toJson() => json.encode(toMap());

  factory FieldVisit.fromJson(String source) => FieldVisit.fromMap(json.decode(source));
}
