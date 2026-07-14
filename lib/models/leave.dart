import 'dart:convert';

class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType; // 'Casual Leave' | 'Sick Leave' | 'Annual Leave' | 'Emergency Leave'
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final String reason;
  final String? documentUrl;
  final String status; // 'Pending' | 'Approved' | 'Rejected' | 'Cancelled'
  final String? supervisorComments;
  final String createdAt; // ISO String

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.documentUrl,
    required this.status,
    this.supervisorComments,
    required this.createdAt,
  });

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      leaveType: map['leaveType'] ?? 'Casual Leave',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      reason: map['reason'] ?? '',
      documentUrl: map['documentUrl'],
      status: map['status'] ?? 'Pending',
      supervisorComments: map['supervisorComments'],
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
      if (documentUrl != null) 'documentUrl': documentUrl,
      'status': status,
      if (supervisorComments != null) 'supervisorComments': supervisorComments,
      'createdAt': createdAt,
    };
  }

  String toJson() => json.encode(toMap());

  factory LeaveRequest.fromJson(String source) => LeaveRequest.fromMap(json.decode(source));
}

class LeaveBalance {
  final String employeeId;
  final int casual;
  final int sick;
  final int annual;
  final int emergency;

  LeaveBalance({
    required this.employeeId,
    required this.casual,
    required this.sick,
    required this.annual,
    required this.emergency,
  });

  factory LeaveBalance.fromMap(Map<String, dynamic> map) {
    return LeaveBalance(
      employeeId: map['employeeId'] ?? '',
      casual: (map['Casual'] ?? map['casual'] as num?)?.toInt() ?? 0,
      sick: (map['Sick'] ?? map['sick'] as num?)?.toInt() ?? 0,
      annual: (map['Annual'] ?? map['annual'] as num?)?.toInt() ?? 0,
      emergency: (map['Emergency'] ?? map['emergency'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'Casual': casual,
      'Sick': sick,
      'Annual': annual,
      'Emergency': emergency,
    };
  }
}
