import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _processing = false;

  Future<void> _handleAttendance(bool isCheckIn) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);

    // Prompt user to capture selfie
    final XFile? selfie = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selfie capture cancelled.')),
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final Uint8List bytes = await selfie.readAsBytes();
      Map<String, dynamic> result;

      if (isCheckIn) {
        result = await state.executeCheckIn(bytes);
      } else {
        result = await state.executeCheckOut(bytes);
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(result['success'] ? 'Success' : 'Attention'),
          content: Text(result['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (result['success']) {
                  Navigator.pop(context);
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('Verification process encountered an issue: $e'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final settings = state.settings;
    final locData = state.currentDeviceLocation;
    final todayRec = state.todayAttendance;

    final bool checkedIn = todayRec != null;
    final bool checkedOut = checkedIn && todayRec.checkOutTime != null;

    double distanceMeters = 0.0;
    bool isOutsideGeofence = true;

    if (settings != null && locData != null && locData.latitude != null && locData.longitude != null) {
      distanceMeters = state.calculateDistance(
        locData.latitude!,
        locData.longitude!,
        settings.officeLat,
        settings.officeLng,
      );
      isOutsideGeofence = distanceMeters > settings.officeRadius;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('Attendance Logs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xff4f46e5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _processing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xff4f46e5)),
                  SizedBox(height: 16),
                  Text(
                    'Verifying location & applying geotag watermark...',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xff64748b)),
                  )
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Geofence Warning or Safe Card
                  _buildGeofenceCard(settings, distanceMeters, isOutsideGeofence, locData),
                  const SizedBox(height: 20),

                  // Actions block
                  if (!checkedIn) ...[
                    _buildActionCard(
                      title: 'Start Workday Check-In',
                      description: 'Take a secure biometric selfie inside the geofence boundary to register your check-in.',
                      btnLabel: 'Verify & Check In',
                      icon: Icons.login_outlined,
                      color: const Color(0xff10b981),
                      onPressed: () => _handleAttendance(true),
                    ),
                  ] else if (checkedIn && !checkedOut) ...[
                    _buildActiveWorkdayCard(todayRec),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      title: 'End Workday Check-Out',
                      description: 'Complete your active task queue and check-out by uploading a secure checkout selfie.',
                      btnLabel: 'Verify & Check Out',
                      icon: Icons.logout_outlined,
                      color: const Color(0xffef4444),
                      onPressed: () => _handleAttendance(false),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xffdbeafe),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.celebration_outlined, size: 48, color: Color(0xff2563eb)),
                          const SizedBox(height: 12),
                          const Text(
                            'Workday Completed!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1e3a8a)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Shift hours logged: ${todayRec!.workingHours?.toStringAsFixed(2)} hours.',
                            style: const TextStyle(fontSize: 13, color: Color(0xff1e40af)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  const Text(
                    'Recent Logs Timeline',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
                  ),
                  const SizedBox(height: 12),
                  _buildTimelineList(state.attendanceHistory),
                ],
              ),
            ),
    );
  }

  Widget _buildGeofenceCard(
    dynamic settings,
    double distance,
    bool isOutside,
    dynamic locData,
  ) {
    if (settings == null) return const SizedBox.shrink();

    final Color statusColor = isOutside ? const Color(0xffef4444) : const Color(0xff10b981);
    final String label = isOutside ? 'OUTSIDE GEOFENCE' : 'INSIDE GEOFENCE';
    final IconData icon = isOutside ? Icons.gpp_bad_outlined : Icons.verified_user_outlined;

    return CustomCard(
      border: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, fontSize: 13, letterSpacing: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Distance to HQ: ${distance.toStringAsFixed(1)}m',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff1e293b)),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Limit: ${settings.officeRadius.round()}m',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff475569)),
                ),
              ),
            ],
          ),
          if (isOutside) ...[
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xfffffbeb),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Color(0xffd97706), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attendance check attempts are strictly logged. Submitting outside geofence is restricted.',
                      style: TextStyle(fontSize: 11, color: Color(0xffb45309), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required String btnLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: btnLabel,
            icon: icon,
            backgroundColor: color,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkdayCard(AttendanceRecord record) {
    return CustomCard(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: Color(0xff4f46e5), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Active Workday Record',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff4f46e5)),
              ),
              const Spacer(),
              StatusBadge(label: record.checkInStatus, type: record.checkInStatus == 'On Time' ? 'success' : 'warning'),
            ],
          ),
          const Divider(height: 20),
          InfoRow(label: 'Check-In Location', value: '${record.checkInLat.toStringAsFixed(4)}, ${record.checkInLng.toStringAsFixed(4)}'),
          InfoRow(label: 'Check-In Distance', value: '${record.checkInDistance.toStringAsFixed(1)}m'),
          InfoRow(label: 'Check-In Time', value: record.checkInTime),
        ],
      ),
    );
  }

  Widget _buildTimelineList(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text('No historical logs registered.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final rec = records[i];
        final bool isDoubleClock = rec.checkOutTime != null;

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rec.date,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1e293b)),
                  ),
                  if (rec.workingHours != null)
                    StatusBadge(label: '${rec.workingHours!.toStringAsFixed(2)} hrs', type: 'info')
                  else
                    const StatusBadge(label: 'Active', type: 'warning'),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.login, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('In: ${rec.checkInTime}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (isDoubleClock) ...[
                    const Icon(Icons.logout, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Text('Out: ${rec.checkOutTime}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ] else ...[
                    const Text('Missing Check-Out', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  ]
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
