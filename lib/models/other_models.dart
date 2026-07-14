import 'dart:convert';

class Area {
  final String id;
  final String name;
  final String code;
  final String district;
  final String province;
  final List<String> assignedOfficerIds;

  Area({
    required this.id,
    required this.name,
    required this.code,
    required this.district,
    required this.province,
    required this.assignedOfficerIds,
  });

  factory Area.fromMap(Map<String, dynamic> map) {
    return Area(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      district: map['district'] ?? '',
      province: map['province'] ?? '',
      assignedOfficerIds: List<String>.from(map['assignedOfficerIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'district': district,
      'province': province,
      'assignedOfficerIds': assignedOfficerIds,
    };
  }
}

class Project {
  final String id;
  final String name;
  final String description;
  final String status; // 'Active' | 'On Hold' | 'Completed'
  final List<String> assignedEmployeeIds;
  final String startDate;
  final String endDate;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.assignedEmployeeIds,
    required this.startDate,
    required this.endDate,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Active',
      assignedEmployeeIds: List<String>.from(map['assignedEmployeeIds'] ?? []),
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'assignedEmployeeIds': assignedEmployeeIds,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

class School {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String principalName;
  final String phoneNumber;
  final String district;
  final String province;
  final String status; // 'Active' | 'Inactive'

  School({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.principalName,
    required this.phoneNumber,
    required this.district,
    required this.province,
    required this.status,
  });

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      principalName: map['principalName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      district: map['district'] ?? '',
      province: map['province'] ?? '',
      status: map['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'principalName': principalName,
      'phoneNumber': phoneNumber,
      'district': district,
      'province': province,
      'status': status,
    };
  }
}

class AuditLog {
  final String id;
  final String timestamp; // ISO string
  final String userId;
  final String userName;
  final String userRole;
  final String action;
  final String details;

  AuditLog({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    required this.details,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'action': action,
      'details': details,
    };
  }
}

class RecentActivity {
  final String id;
  final String timestamp; // ISO String
  final String employeeName;
  final String role;
  final String action;
  final String details;
  final String type; // 'info' | 'warning' | 'success' | 'danger'

  RecentActivity({
    required this.id,
    required this.timestamp,
    required this.employeeName,
    required this.role,
    required this.action,
    required this.details,
    required this.type,
  });

  factory RecentActivity.fromMap(Map<String, dynamic> map) {
    return RecentActivity(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] ?? '',
      employeeName: map['employeeName'] ?? '',
      role: map['role'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      type: map['type'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'employeeName': employeeName,
      'role': role,
      'action': action,
      'details': details,
      'type': type,
    };
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String timestamp; // ISO string
  final bool isRead;
  final String type; // 'task_assigned' | 'task_reminder' | 'task_overdue' | 'checkin_reminder' | 'checkout_reminder' | 'leave_status' | 'announcement'

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? '',
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'announcement',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'type': type,
    };
  }
}
