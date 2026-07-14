import 'dart:convert';

class Task {
  final String id;
  final String title;
  final String description;
  final String priority; // 'Low' | 'Medium' | 'High' | 'Urgent'
  final String dueDate; // YYYY-MM-DD
  final String dueTime; // HH:MM
  final List<String> assignedOfficerIds;
  final String projectId;
  final String schoolId;
  final List<String> attachedFiles;
  final String status; // 'Pending' | 'In Progress' | 'Paused' | 'Completed'
  final String remarks;
  final List<String> completionSelfies;
  final List<String> completionDocs;
  final String? startTime; // ISO string
  final String? completionTime; // ISO string
  final int pausedDurationMs;
  final int? lastStartTimestamp; // epoch ms
  final int? calculatedDurationMinutes;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.dueTime,
    required this.assignedOfficerIds,
    required this.projectId,
    required this.schoolId,
    required this.attachedFiles,
    required this.status,
    required this.remarks,
    required this.completionSelfies,
    required this.completionDocs,
    this.startTime,
    this.completionTime,
    required this.pausedDurationMs,
    this.lastStartTimestamp,
    this.calculatedDurationMinutes,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'Medium',
      dueDate: map['dueDate'] ?? '',
      dueTime: map['dueTime'] ?? '',
      assignedOfficerIds: List<String>.from(map['assignedOfficerIds'] ?? []),
      projectId: map['projectId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      attachedFiles: List<String>.from(map['attachedFiles'] ?? []),
      status: map['status'] ?? 'Pending',
      remarks: map['remarks'] ?? '',
      completionSelfies: List<String>.from(map['completionSelfies'] ?? []),
      completionDocs: List<String>.from(map['completionDocs'] ?? []),
      startTime: map['startTime'],
      completionTime: map['completionTime'],
      pausedDurationMs: (map['pausedDurationMs'] as num?)?.toInt() ?? 0,
      lastStartTimestamp: (map['lastStartTimestamp'] as num?)?.toInt(),
      calculatedDurationMinutes: (map['calculatedDurationMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'assignedOfficerIds': assignedOfficerIds,
      'projectId': projectId,
      'schoolId': schoolId,
      'attachedFiles': attachedFiles,
      'status': status,
      'remarks': remarks,
      'completionSelfies': completionSelfies,
      'completionDocs': completionDocs,
      if (startTime != null) 'startTime': startTime,
      if (completionTime != null) 'completionTime': completionTime,
      'pausedDurationMs': pausedDurationMs,
      if (lastStartTimestamp != null) 'lastStartTimestamp': lastStartTimestamp,
      if (calculatedDurationMinutes != null) 'calculatedDurationMinutes': calculatedDurationMinutes,
    };
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}
