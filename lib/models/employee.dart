import 'dart:convert';

class Employee {
  final String id;
  final String fullName;
  final String fatherName;
  final String cnic;
  final String phoneNumber;
  final String email;
  final String gender;
  final String dob;
  final String joiningDate;
  final String designation;
  final String department;
  final String assignedSupervisorId;
  final String assignedAreaId;
  final String photo;
  final String status; // 'Active' or 'Inactive'
  final double? supervisorRating;

  Employee({
    required this.id,
    required this.fullName,
    required this.fatherName,
    required this.cnic,
    required this.phoneNumber,
    required this.email,
    required this.gender,
    required this.dob,
    required this.joiningDate,
    required this.designation,
    required this.department,
    required this.assignedSupervisorId,
    required this.assignedAreaId,
    required this.photo,
    required this.status,
    this.supervisorRating,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      fatherName: map['fatherName'] ?? '',
      cnic: map['cnic'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      gender: map['gender'] ?? '',
      dob: map['dob'] ?? '',
      joiningDate: map['joiningDate'] ?? '',
      designation: map['designation'] ?? '',
      department: map['department'] ?? '',
      assignedSupervisorId: map['assignedSupervisorId'] ?? '',
      assignedAreaId: map['assignedAreaId'] ?? '',
      photo: map['photo'] ?? '',
      status: map['status'] ?? 'Active',
      supervisorRating: map['supervisorRating'] != null 
          ? (map['supervisorRating'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'fatherName': fatherName,
      'cnic': cnic,
      'phoneNumber': phoneNumber,
      'email': email,
      'gender': gender,
      'dob': dob,
      'joiningDate': joiningDate,
      'designation': designation,
      'department': department,
      'assignedSupervisorId': assignedSupervisorId,
      'assignedAreaId': assignedAreaId,
      'photo': photo,
      'status': status,
      if (supervisorRating != null) 'supervisorRating': supervisorRating,
    };
  }

  String toJson() => json.encode(toMap());

  factory Employee.fromJson(String source) => Employee.fromMap(json.decode(source));
}
