import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/system_settings.dart';
import '../models/field_visit.dart';
import '../models/task.dart';
import '../models/leave.dart';
import '../models/employee_location.dart';
import '../models/other_models.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Authentication Streams and Actions
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // File/Image upload helper
  Future<String> uploadImageBytes(Uint8List bytes, String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Firebase Storage Upload Error: $e');
      // If upload fails, fall back to converting bytes to base64 inline so we never lose data
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }

  // System Settings
  Future<SystemSettings> getSettings() async {
    try {
      final snap = await _db.collection('settings').doc('global_config').get();
      if (snap.exists && snap.data() != null) {
        return SystemSettings.fromMap(snap.data()!);
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
    // Return standard system defaults
    return SystemSettings(
      officeName: "Ruhamaa Foundation HO",
      officeLat: 24.8607,
      officeLng: 67.0011,
      officeRadius: 100.0,
      officeStartTime: "09:00",
      officeEndTime: "17:00",
      gracePeriodMinutes: 15,
      workingHoursRequired: 8,
      appName: "Ruhamaa Field Force",
      logoText: "RUHAMAA",
      primaryColor: "#4F46E5",
    );
  }

  Future<void> saveSettings(SystemSettings settings) async {
    await _db.collection('settings').doc('global_config').set(settings.toMap());
  }

  // Employee Profile
  Future<Employee?> getEmployeeByEmail(String email) async {
    final query = await _db
        .collection('employees')
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Employee.fromMap(query.docs.first.data());
    }
    return null;
  }

  Future<List<Employee>> getEmployees() async {
    final snap = await _db.collection('employees').get();
    return snap.docs.map((doc) => Employee.fromMap(doc.data())).toList();
  }

  Stream<List<Employee>> streamEmployees() {
    return _db.collection('employees').snapshots().map((snap) {
      return snap.docs.map((doc) => Employee.fromMap(doc.data())).toList();
    });
  }

  // Attendance Records
  Stream<List<AttendanceRecord>> streamAttendance(String employeeId) {
    return _db
        .collection('attendance')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => AttendanceRecord.fromMap(doc.data())).toList();
    });
  }

  Future<AttendanceRecord?> getTodayAttendance(String employeeId, String dateStr) async {
    final docId = '${employeeId}_$dateStr';
    final snap = await _db.collection('attendance').doc(docId).get();
    if (snap.exists && snap.data() != null) {
      return AttendanceRecord.fromMap(snap.data()!);
    }
    return null;
  }

  Future<void> saveAttendance(AttendanceRecord record) async {
    final docId = '${record.employeeId}_${record.date}';
    await _db.collection('attendance').doc(docId).set(record.toMap());
  }

  // Field Visits
  Stream<List<FieldVisit>> streamFieldVisits(String employeeId, String role) {
    if (role == 'super_admin' || role == 'supervisor') {
      return _db
          .collection('visits')
          .orderBy('dateTime', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => FieldVisit.fromMap(doc.data())).toList());
    } else {
      return _db
          .collection('visits')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('dateTime', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => FieldVisit.fromMap(doc.data())).toList());
    }
  }

  Future<void> saveFieldVisit(FieldVisit visit) async {
    await _db.collection('visits').doc(visit.id).set(visit.toMap());
  }

  // Tasks Management
  Stream<List<Task>> streamTasks() {
    return _db.collection('tasks').orderBy('dueDate', descending: false).snapshots().map((snap) {
      return snap.docs.map((doc) => Task.fromMap(doc.data())).toList();
    });
  }

  Future<void> saveTask(Task task) async {
    await _db.collection('tasks').doc(task.id).set(task.toMap());
  }

  // Leaves Management
  Stream<List<LeaveRequest>> streamLeaveRequests(String employeeId, String role) {
    if (role == 'super_admin' || role == 'supervisor') {
      return _db
          .collection('leave_requests')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => LeaveRequest.fromMap(doc.data())).toList());
    } else {
      return _db
          .collection('leave_requests')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => LeaveRequest.fromMap(doc.data())).toList());
    }
  }

  Future<void> saveLeaveRequest(LeaveRequest request) async {
    await _db.collection('leave_requests').doc(request.id).set(request.toMap());
  }

  Future<LeaveBalance?> getLeaveBalance(String employeeId) async {
    final snap = await _db.collection('leave_balances').doc(employeeId).get();
    if (snap.exists && snap.data() != null) {
      return LeaveBalance.fromMap(snap.data()!);
    }
    return null;
  }

  Future<void> saveLeaveBalance(LeaveBalance balance) async {
    await _db.collection('leave_balances').doc(balance.employeeId).set(balance.toMap());
  }

  // Employee Location Periodic Sync
  Stream<List<EmployeeLocation>> streamEmployeeLocations() {
    return _db.collection('employee_locations').snapshots().map((snap) {
      return snap.docs.map((doc) => EmployeeLocation.fromMap(doc.data())).toList();
    });
  }

  Future<void> saveEmployeeLocation(EmployeeLocation location) async {
    await _db.collection('employee_locations').doc(location.employeeId).set(location.toMap());
  }

  // Notifications
  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AppNotification.fromMap(doc.data())).toList());
  }

  Future<void> markNotificationAsRead(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> createNotification(AppNotification notification) async {
    await _db.collection('notifications').doc(notification.id).set(notification.toMap());
  }

  // Audit Logging
  Future<void> logAudit(AuditLog log) async {
    await _db.collection('audit_logs').doc(log.id).set(log.toMap());
  }

  Stream<List<AuditLog>> streamAuditLogs() {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AuditLog.fromMap(doc.data())).toList());
  }

  // Metadata tables loading (Schools, Projects, Areas)
  Future<List<School>> getSchools() async {
    final snap = await _db.collection('schools').get();
    return snap.docs.map((doc) => School.fromMap(doc.data())).toList();
  }

  Future<List<Project>> getProjects() async {
    final snap = await _db.collection('projects').get();
    return snap.docs.map((doc) => Project.fromMap(doc.data())).toList();
  }

  Future<List<Area>> getAreas() async {
    final snap = await _db.collection('areas').get();
    return snap.docs.map((doc) => Area.fromMap(doc.data())).toList();
  }
}
