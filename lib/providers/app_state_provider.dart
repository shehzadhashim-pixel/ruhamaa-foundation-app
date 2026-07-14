import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/system_settings.dart';
import '../models/field_visit.dart';
import '../models/task.dart';
import '../models/leave.dart';
import '../models/employee_location.dart';
import '../models/other_models.dart';
import '../services/firebase_service.dart';
import '../utils/watermark_utils.dart';

class AppStateProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  // Active state
  Employee? _currentUserEmployee;
  SystemSettings? _settings;
  AttendanceRecord? _todayAttendance;
  
  List<AttendanceRecord> _attendanceHistory = [];
  List<FieldVisit> _visits = [];
  List<Task> _tasks = [];
  List<LeaveRequest> _leaves = [];
  List<AppNotification> _notifications = [];
  List<AuditLog> _auditLogs = [];
  List<EmployeeLocation> _employeeLocations = [];
  LeaveBalance? _leaveBalance;

  // Metadata tables
  List<School> _schools = [];
  List<Project> _projects = [];
  List<Area> _areas = [];

  // Loading/Sync variables
  bool _isLoading = false;
  String? _syncError;
  loc.LocationData? _currentDeviceLocation;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _visitsSub;
  StreamSubscription? _tasksSub;
  StreamSubscription? _leavesSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _auditSub;
  StreamSubscription? _locationsSub;

  // Getters
  Employee? get currentUserEmployee => _currentUserEmployee;
  SystemSettings? get settings => _settings;
  AttendanceRecord? get todayAttendance => _todayAttendance;
  List<AttendanceRecord> get attendanceHistory => _attendanceHistory;
  List<FieldVisit> get visits => _visits;
  List<Task> get tasks => _tasks;
  List<LeaveRequest> get leaves => _leaves;
  List<AppNotification> get notifications => _notifications;
  List<AuditLog> get auditLogs => _auditLogs;
  List<EmployeeLocation> get employeeLocations => _employeeLocations;
  LeaveBalance? get leaveBalance => _leaveBalance;
  
  List<School> get schools => _schools;
  List<Project> get projects => _projects;
  List<Area> get areas => _areas;

  bool get isLoading => _isLoading;
  String? get syncError => _syncError;
  loc.LocationData? get currentDeviceLocation => _currentDeviceLocation;

  AppStateProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _firebaseService.authStateChanges.listen((user) async {
      if (user != null && user.email != null) {
        _isLoading = true;
        notifyListeners();
        
        try {
          // Load system settings
          _settings = await _firebaseService.getSettings();
          
          // Get local employee profile matched by authenticated email
          _currentUserEmployee = await _firebaseService.getEmployeeByEmail(user.email!);
          
          if (_currentUserEmployee != null) {
            _setupRealtimeStreams();
            _startDeviceLocationTracking();
            await _loadMetadata();
          } else {
            _syncError = "User profile matching email not found in Firestore.";
            await _firebaseService.signOut();
          }
        } catch (e) {
          _syncError = "Initialization error: $e";
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      } else {
        _cleanupUserSession();
      }
    });
  }

  void _setupRealtimeStreams() {
    final emp = _currentUserEmployee;
    if (emp == null) return;

    // Stream User Attendance
    _attendanceSub = _firebaseService.streamAttendance(emp.id).listen((recs) {
      _attendanceHistory = recs;
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _todayAttendance = recs.firstWhere(
        (r) => r.date == todayStr,
        orElse: () => AttendanceRecord(
          id: '', employeeId: '', employeeName: '', date: '', checkInTime: '',
          checkInSelfie: '', checkInLat: 0.0, checkInLng: 0.0, checkInDistance: 0.0,
          checkInStatus: 'On Time', isOutsideGeofence: false,
        ),
      );
      if (_todayAttendance?.id.isEmpty ?? true) {
        _todayAttendance = null;
      }
      notifyListeners();
    });

    // Stream Visits
    _visitsSub = _firebaseService.streamFieldVisits(emp.id, emp.designation).listen((list) {
      _visits = list;
      notifyListeners();
    });

    // Stream Tasks
    _tasksSub = _firebaseService.streamTasks().listen((list) {
      // If field officer, filter tasks assigned to them
      if (emp.designation.toLowerCase().contains('officer') || emp.designation.toLowerCase().contains('field')) {
        _tasks = list.where((t) => t.assignedOfficerIds.contains(emp.id)).toList();
      } else {
        _tasks = list;
      }
      notifyListeners();
    });

    // Stream Leaves
    _leavesSub = _firebaseService.streamLeaveRequests(emp.id, emp.designation).listen((list) {
      _leaves = list;
      notifyListeners();
    });

    // Stream Notifications
    _notificationsSub = _firebaseService.streamNotifications(emp.id).listen((list) {
      _notifications = list;
      notifyListeners();
    });

    // Stream Audit Logs (for super_admins / supervisors)
    if (emp.designation.toLowerCase().contains('admin') || emp.designation.toLowerCase().contains('super')) {
      _auditSub = _firebaseService.streamAuditLogs().listen((list) {
        _auditLogs = list;
        notifyListeners();
      });
    }

    // Stream live employee map pins (for supervisors / admins)
    _locationsSub = _firebaseService.streamEmployeeLocations().listen((list) {
      _employeeLocations = list;
      notifyListeners();
    });

    // Load static Leave Balance
    _firebaseService.getLeaveBalance(emp.id).then((bal) {
      _leaveBalance = bal;
      notifyListeners();
    });
  }

  Future<void> _loadMetadata() async {
    try {
      _schools = await _firebaseService.getSchools();
      _projects = await _firebaseService.getProjects();
      _areas = await _firebaseService.getAreas();
    } catch (e) {
      print("Metadata loading error: $e");
    }
  }

  void _cleanupUserSession() {
    _attendanceSub?.cancel();
    _visitsSub?.cancel();
    _tasksSub?.cancel();
    _leavesSub?.cancel();
    _notificationsSub?.cancel();
    _auditSub?.cancel();
    _locationsSub?.cancel();
    _locationSubscription?.cancel();

    _currentUserEmployee = null;
    _todayAttendance = null;
    _attendanceHistory = [];
    _visits = [];
    _tasks = [];
    _leaves = [];
    _notifications = [];
    _auditLogs = [];
    _employeeLocations = [];
    _leaveBalance = null;
    _schools = [];
    _projects = [];
    _areas = [];
    _currentDeviceLocation = null;
    _syncError = null;
    notifyListeners();
  }

  // Real-time location tracking
  void _startDeviceLocationTracking() async {
    final location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    // Configure tracking settings
    await location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 10000, // every 10 seconds
      distanceFilter: 10.0, // every 10 meters
    );

    _locationSubscription = location.onLocationChanged.listen((locData) {
      _currentDeviceLocation = locData;
      notifyListeners();
      
      // Periodically sync coords to Firestore employee map pins
      _syncDeviceLocationToFirestore();
    });
  }

  DateTime? _lastSyncTime;
  Future<void> _syncDeviceLocationToFirestore() async {
    final emp = _currentUserEmployee;
    final locData = _currentDeviceLocation;
    if (emp == null || locData == null || locData.latitude == null || locData.longitude == null) return;

    final now = DateTime.now();
    // Throttle location updates to Firestore to once every 2 minutes or upon significant movement
    if (_lastSyncTime != null && now.difference(_lastSyncTime!).inSeconds < 120) {
      return;
    }

    _lastSyncTime = now;
    final lat = locData.latitude!;
    final lng = locData.longitude!;

    String status = 'Travelling';
    if (_settings != null) {
      final dist = calculateDistance(lat, lng, _settings!.officeLat, _settings!.officeLng);
      if (dist <= _settings!.officeRadius) {
        status = 'In Office';
      }
    }
    if (_todayAttendance == null) {
      status = 'Offline';
    }

    final timestamp = now.toIso8601String();
    final point = RoutePoint(
      latitude: lat,
      longitude: lng,
      timestamp: timestamp,
      locationName: status,
    );

    try {
      final List<RoutePoint> history = [];
      final existingLocDoc = _employeeLocations.firstWhere(
        (l) => l.employeeId == emp.id,
        orElse: () => EmployeeLocation(
          employeeId: emp.id, employeeName: emp.fullName, latitude: lat, longitude: lng,
          status: status, lastUpdated: timestamp, routeHistory: [],
        ),
      );

      history.addAll(existingLocDoc.routeHistory);
      // Keep only last 50 route steps to prevent excessive document inflation
      if (history.length > 50) {
        history.removeAt(0);
      }
      history.add(point);

      final updatedLoc = EmployeeLocation(
        employeeId: emp.id,
        employeeName: emp.fullName,
        latitude: lat,
        longitude: lng,
        status: status,
        lastUpdated: timestamp,
        routeHistory: history,
      );

      await _firebaseService.saveEmployeeLocation(updatedLoc);
    } catch (e) {
      print("Failed updating live tracking details: $e");
    }
  }

  // --- ACTIONS ---

  // Check In Command
  Future<Map<String, dynamic>> executeCheckIn(Uint8List selfieBytes) async {
    final emp = _currentUserEmployee;
    final settings = _settings;
    final locData = _currentDeviceLocation;

    if (emp == null || settings == null) {
      return {'success': false, 'message': 'Session expired or settings not loaded.'};
    }
    if (locData == null || locData.latitude == null || locData.longitude == null) {
      return {'success': false, 'message': 'GPS Signal not locked. Please ensure location services are enabled.'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final lat = locData.latitude!;
      final lng = locData.longitude!;
      final dist = calculateDistance(lat, lng, settings.officeLat, settings.officeLng);
      final isOutside = dist > settings.officeRadius;

      // Apply gorgeous watermarking
      final watermarkedSelfieBytes = await WatermarkUtils.addPhotoWatermark(
        imageBytes: selfieBytes,
        employeeName: emp.fullName,
        employeeId: emp.id,
        latitude: lat,
        longitude: lng,
        visitType: 'Check In',
      );

      // Upload watermarked selfie
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final selfieUrl = await _firebaseService.uploadImageBytes(
        watermarkedSelfieBytes,
        'attendance/${emp.id}/checkin_$todayStr.jpg',
      );

      // Verify if Late or On Time
      final nowTime = DateTime.now();
      final startTimeParts = settings.officeStartTime.split(':');
      final startHour = int.parse(startTimeParts[0]);
      final startMin = int.parse(startTimeParts[1]);
      final officeStart = DateTime(nowTime.year, nowTime.month, nowTime.day, startHour, startMin);
      final lateCutoff = officeStart.add(Duration(minutes: settings.gracePeriodMinutes));

      final String status = nowTime.isAfter(lateCutoff) ? 'Late' : 'On Time';
      final timeStr = DateFormat('HH:mm:ss').format(nowTime);

      final record = AttendanceRecord(
        id: '${emp.id}_$todayStr',
        employeeId: emp.id,
        employeeName: emp.fullName,
        date: todayStr,
        checkInTime: timeStr,
        checkInSelfie: selfieUrl,
        checkInLat: lat,
        checkInLng: lng,
        checkInDistance: dist,
        checkInStatus: status,
        isOutsideGeofence: isOutside,
      );

      await _firebaseService.saveAttendance(record);

      // Log Audit Entry
      await _logEvent(
        action: 'Attendance Check-In',
        details: 'Checked-in at $timeStr ($status). Location: $lat, $lng (${dist.toStringAsFixed(1)}m from office). Geofence Check: ${isOutside ? "Failed (Outside)" : "Passed"}',
      );

      return {'success': true, 'message': 'Checked In successfully as $status!'};
    } catch (e) {
      return {'success': false, 'message': 'Check-In failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check Out Command
  Future<Map<String, dynamic>> executeCheckOut(Uint8List selfieBytes) async {
    final emp = _currentUserEmployee;
    final settings = _settings;
    final locData = _currentDeviceLocation;
    final record = _todayAttendance;

    if (emp == null || settings == null || record == null) {
      return {'success': false, 'message': 'Active Check-In record not found.'};
    }
    if (locData == null || locData.latitude == null || locData.longitude == null) {
      return {'success': false, 'message': 'GPS Signal not locked.'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final lat = locData.latitude!;
      final lng = locData.longitude!;
      final dist = calculateDistance(lat, lng, settings.officeLat, settings.officeLng);

      // Apply watermarking
      final watermarkedSelfieBytes = await WatermarkUtils.addPhotoWatermark(
        imageBytes: selfieBytes,
        employeeName: emp.fullName,
        employeeId: emp.id,
        latitude: lat,
        longitude: lng,
        visitType: 'Check Out',
      );

      final todayStr = record.date;
      final selfieUrl = await _firebaseService.uploadImageBytes(
        watermarkedSelfieBytes,
        'attendance/${emp.id}/checkout_$todayStr.jpg',
      );

      final nowTime = DateTime.now();
      final timeStr = DateFormat('HH:mm:ss').format(nowTime);

      // Parse CheckIn Time
      final checkInParts = record.checkInTime.split(':');
      final dateParts = record.date.split('-');
      final checkInDateTime = DateTime(
        int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]),
        int.parse(checkInParts[0]), int.parse(checkInParts[1]), int.parse(checkInParts[2]),
      );
      final double workingHours = nowTime.difference(checkInDateTime).inMinutes / 60.0;

      // Check early checkout
      final endTimeParts = settings.officeEndTime.split(':');
      final endHour = int.parse(endTimeParts[0]);
      final endMin = int.parse(endTimeParts[1]);
      final officeEnd = DateTime(nowTime.year, nowTime.month, nowTime.day, endHour, endMin);

      final String status = nowTime.isBefore(officeEnd) ? 'Early Checkout' : 'Normal';

      final updatedRecord = AttendanceRecord(
        id: record.id,
        employeeId: record.employeeId,
        employeeName: record.employeeName,
        date: record.date,
        checkInTime: record.checkInTime,
        checkInSelfie: record.checkInSelfie,
        checkInLat: record.checkInLat,
        checkInLng: record.checkInLng,
        checkInDistance: record.checkInDistance,
        checkInStatus: record.checkInStatus,
        checkOutTime: timeStr,
        checkOutSelfie: selfieUrl,
        checkOutLat: lat,
        checkOutLng: lng,
        checkOutDistance: dist,
        checkOutStatus: status,
        workingHours: workingHours,
        isOutsideGeofence: record.isOutsideGeofence || (dist > settings.officeRadius),
      );

      await _firebaseService.saveAttendance(updatedRecord);

      await _logEvent(
        action: 'Attendance Check-Out',
        details: 'Checked-out at $timeStr. Worked: ${workingHours.toStringAsFixed(2)} hours. Status: $status.',
      );

      return {'success': true, 'message': 'Checked Out successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Check-out failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Field Visit
  Future<Map<String, dynamic>> submitFieldVisit({
    required String visitType,
    required String projectId,
    required String purpose,
    required String locationName,
    required String remarks,
    required Uint8List photoBytes,
  }) async {
    final emp = _currentUserEmployee;
    final locData = _currentDeviceLocation;
    if (emp == null) return {'success': false, 'message': 'Session expired.'};

    _isLoading = true;
    notifyListeners();

    try {
      final double lat = locData?.latitude ?? 24.8607;
      final double lng = locData?.longitude ?? 67.0011;

      // Look up project name
      final proj = _projects.firstWhere((p) => p.id == projectId, orElse: () => Project(id: '', name: 'General Field', description: '', status: 'Active', assignedEmployeeIds: [], startDate: '', endDate: ''));
      final projName = proj.name;

      // Apply beautiful watermark to the field photo
      final watermarkedBytes = await WatermarkUtils.addPhotoWatermark(
        imageBytes: photoBytes,
        employeeName: emp.fullName,
        employeeId: emp.id,
        latitude: lat,
        longitude: lng,
        visitType: visitType,
        projectName: projName,
      );

      final visitId = 'VISIT_${_uuid.v4().substring(0, 8).toUpperCase()}';
      final photoUrl = await _firebaseService.uploadImageBytes(
        watermarkedBytes,
        'visits/${emp.id}/visit_${visitId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final now = DateTime.now();
      final visit = FieldVisit(
        id: visitId,
        visitType: visitType,
        projectId: projectId,
        projectName: projName,
        location: locationName,
        latitude: lat,
        longitude: lng,
        dateTime: now.toIso8601String(),
        startTime: DateFormat('HH:mm').format(now),
        endTime: DateFormat('HH:mm').format(now.add(const Duration(hours: 1))),
        durationMinutes: 60,
        purpose: purpose,
        remarks: remarks,
        status: 'Completed',
        followUpRequired: 'No',
        photos: [photoUrl],
        documents: [],
        employeeId: emp.id,
        employeeName: emp.fullName,
      );

      await _firebaseService.saveFieldVisit(visit);

      await _logEvent(
        action: 'Field Visit Submitted',
        details: 'Submitted a $visitType for Project: $projName at $locationName.',
      );

      return {'success': true, 'message': 'Field Visit reported successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to report visit: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Leave Request
  Future<Map<String, dynamic>> submitLeaveRequest({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final emp = _currentUserEmployee;
    if (emp == null) return {'success': false, 'message': 'Session expired.'};

    _isLoading = true;
    notifyListeners();

    try {
      final leaveId = 'LEAVE_${_uuid.v4().substring(0, 8).toUpperCase()}';
      final request = LeaveRequest(
        id: leaveId,
        employeeId: emp.id,
        employeeName: emp.fullName,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        status: 'Pending',
        createdAt: DateTime.now().toIso8601String(),
      );

      await _firebaseService.saveLeaveRequest(request);

      await _logEvent(
        action: 'Leave Requested',
        details: 'Requested $leaveType from $startDate to $endDate.',
      );

      return {'success': true, 'message': 'Leave application submitted successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Leave application failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete Assigned Task with Selfie Upload
  Future<Map<String, dynamic>> completeTask({
    required String taskId,
    required String remarks,
    required Uint8List selfieBytes,
  }) async {
    final emp = _currentUserEmployee;
    final locData = _currentDeviceLocation;
    if (emp == null) return {'success': false, 'message': 'Session expired.'};

    _isLoading = true;
    notifyListeners();

    try {
      final lat = locData?.latitude ?? 24.8607;
      final lng = locData?.longitude ?? 67.0011;

      // Find active task
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) {
        return {'success': false, 'message': 'Task not found.'};
      }
      final activeTask = _tasks[taskIndex];

      // Geotag watermark completion selfie
      final watermarkedBytes = await WatermarkUtils.addPhotoWatermark(
        imageBytes: selfieBytes,
        employeeName: emp.fullName,
        employeeId: emp.id,
        latitude: lat,
        longitude: lng,
        visitType: 'Task Complete',
        projectName: activeTask.title,
      );

      final selfieUrl = await _firebaseService.uploadImageBytes(
        watermarkedBytes,
        'tasks/$taskId/completion_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final now = DateTime.now();
      
      // Calculate active task minutes
      int extraActiveMinutes = 0;
      if (activeTask.lastStartTimestamp != null) {
        extraActiveMinutes = now.difference(DateTime.fromMillisecondsSinceEpoch(activeTask.lastStartTimestamp!)).inMinutes;
      }
      final totalActiveMinutes = activeTask.calculatedDurationMinutes == null
          ? extraActiveMinutes
          : activeTask.calculatedDurationMinutes! + extraActiveMinutes;

      final updatedTask = Task(
        id: activeTask.id,
        title: activeTask.title,
        description: activeTask.description,
        priority: activeTask.priority,
        dueDate: activeTask.dueDate,
        dueTime: activeTask.dueTime,
        assignedOfficerIds: activeTask.assignedOfficerIds,
        projectId: activeTask.projectId,
        schoolId: activeTask.schoolId,
        attachedFiles: activeTask.attachedFiles,
        status: 'Completed',
        remarks: remarks,
        completionSelfies: [selfieUrl],
        completionDocs: [],
        startTime: activeTask.startTime,
        completionTime: now.toIso8601String(),
        pausedDurationMs: activeTask.pausedDurationMs,
        lastStartTimestamp: null,
        calculatedDurationMinutes: totalActiveMinutes,
      );

      await _firebaseService.saveTask(updatedTask);

      await _logEvent(
        action: 'Task Completed',
        details: 'Completed Task: ${activeTask.title}. Worked for $totalActiveMinutes mins.',
      );

      return {'success': true, 'message': 'Task marked as completed successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to complete task: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle Task Status (Start, Pause)
  Future<void> toggleTaskStatus(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final t = _tasks[taskIndex];
    final now = DateTime.now();

    String newStatus;
    String? startTime = t.startTime;
    int? lastStartTimestamp = t.lastStartTimestamp;
    int pausedDurationMs = t.pausedDurationMs;
    int? calculatedMinutes = t.calculatedDurationMinutes;

    if (t.status == 'Pending' || t.status == 'Paused') {
      newStatus = 'In Progress';
      if (startTime == null) {
        startTime = now.toIso8601String();
      }
      lastStartTimestamp = now.millisecondsSinceEpoch;
    } else if (t.status == 'In Progress') {
      newStatus = 'Paused';
      if (lastStartTimestamp != null) {
        final elapsed = now.millisecondsSinceEpoch - lastStartTimestamp;
        pausedDurationMs += elapsed;
        final elapsedMins = elapsed ~/ 60000;
        calculatedMinutes = (calculatedMinutes ?? 0) + elapsedMins;
      }
      lastStartTimestamp = null;
    } else {
      return;
    }

    final updated = Task(
      id: t.id,
      title: t.title,
      description: t.description,
      priority: t.priority,
      dueDate: t.dueDate,
      dueTime: t.dueTime,
      assignedOfficerIds: t.assignedOfficerIds,
      projectId: t.projectId,
      schoolId: t.schoolId,
      attachedFiles: t.attachedFiles,
      status: newStatus,
      remarks: t.remarks,
      completionSelfies: t.completionSelfies,
      completionDocs: t.completionDocs,
      startTime: startTime,
      completionTime: t.completionTime,
      pausedDurationMs: pausedDurationMs,
      lastStartTimestamp: lastStartTimestamp,
      calculatedDurationMinutes: calculatedMinutes,
    );

    await _firebaseService.saveTask(updated);
    await _logEvent(
      action: 'Task Status Updated',
      details: 'Task "${t.title}" is now $newStatus.',
    );
  }

  // Helper: Log event to Firestore Audit Logs and Recent Activities
  Future<void> _logEvent({required String action, required String details}) async {
    final emp = _currentUserEmployee;
    if (emp == null) return;

    final logId = 'LOG_${_uuid.v4().substring(0, 8).toUpperCase()}';
    final timestamp = DateTime.now().toIso8601String();

    final log = AuditLog(
      id: logId,
      timestamp: timestamp,
      userId: emp.id,
      userName: emp.fullName,
      userRole: emp.designation,
      action: action,
      details: details,
    );

    await _firebaseService.logAudit(log);
  }

  // Earth radius distance calculation (Haversine Formula) in meters
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000; // Earth radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (r * c).roundToDouble();
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
