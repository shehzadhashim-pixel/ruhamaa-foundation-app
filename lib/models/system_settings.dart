import 'dart:convert';

class SystemSettings {
  final String officeName;
  final double officeLat;
  final double officeLng;
  final double officeRadius; // in meters
  final String officeStartTime; // "HH:MM"
  final String officeEndTime; // "HH:MM"
  final int gracePeriodMinutes;
  final int workingHoursRequired;
  final String appName;
  final String logoText;
  final String primaryColor;
  final String? orgName;
  final String? secondaryColor;
  final String? logoUrl;
  final String? appIconUrl;
  final String? splashImageUrl;

  SystemSettings({
    required this.officeName,
    required this.officeLat,
    required this.officeLng,
    required this.officeRadius,
    required this.officeStartTime,
    required this.officeEndTime,
    required this.gracePeriodMinutes,
    required this.workingHoursRequired,
    required this.appName,
    required this.logoText,
    required this.primaryColor,
    this.orgName,
    this.secondaryColor,
    this.logoUrl,
    this.appIconUrl,
    this.splashImageUrl,
  });

  factory SystemSettings.fromMap(Map<String, dynamic> map) {
    return SystemSettings(
      officeName: map['officeName'] ?? 'Ruhamaa Office',
      officeLat: (map['officeLat'] as num?)?.toDouble() ?? 24.8607,
      officeLng: (map['officeLng'] as num?)?.toDouble() ?? 67.0011,
      officeRadius: (map['officeRadius'] as num?)?.toDouble() ?? 100.0,
      officeStartTime: map['officeStartTime'] ?? '09:00',
      officeEndTime: map['officeEndTime'] ?? '17:00',
      gracePeriodMinutes: (map['gracePeriodMinutes'] as num?)?.toInt() ?? 15,
      workingHoursRequired: (map['workingHoursRequired'] as num?)?.toInt() ?? 8,
      appName: map['appName'] ?? 'Ruhamaa Tracker',
      logoText: map['logoText'] ?? 'RUHAMAA',
      primaryColor: map['primaryColor'] ?? '#6366F1',
      orgName: map['orgName'],
      secondaryColor: map['secondaryColor'],
      logoUrl: map['logoUrl'],
      appIconUrl: map['appIconUrl'],
      splashImageUrl: map['splashImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'officeName': officeName,
      'officeLat': officeLat,
      'officeLng': officeLng,
      'officeRadius': officeRadius,
      'officeStartTime': officeStartTime,
      'officeEndTime': officeEndTime,
      'gracePeriodMinutes': gracePeriodMinutes,
      'workingHoursRequired': workingHoursRequired,
      'appName': appName,
      'logoText': logoText,
      'primaryColor': primaryColor,
      if (orgName != null) 'orgName': orgName,
      if (secondaryColor != null) 'secondaryColor': secondaryColor,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (appIconUrl != null) 'appIconUrl': appIconUrl,
      if (splashImageUrl != null) 'splashImageUrl': splashImageUrl,
    };
  }

  String toJson() => json.encode(toMap());

  factory SystemSettings.fromJson(String source) => SystemSettings.fromMap(json.decode(source));
}
