import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final emp = state.currentUserEmployee;

    if (emp == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Dynamic stats Calculations
    final completedTasksCount = state.tasks.where((t) => t.status == 'Completed').length;
    final totalTasksCount = state.tasks.length;
    final pendingLeavesCount = state.leaves.where((l) => l.status == 'Pending').length;
    final completedVisitsCount = state.visits.length;

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: Text(
          state.settings?.appName ?? 'Ruhamaa Field Force',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xff4f46e5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            onPressed: () => state.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff4f46e5), Color(0xff7c3aed)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff4f46e5).withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Photo Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: emp.photo.startsWith('data:')
                          ? null // handle base64 if needed, fallback to asset/icons
                          : NetworkImage(emp.photo) as ImageProvider,
                      child: emp.photo.isEmpty || emp.photo.startsWith('data:')
                          ? const Icon(Icons.person_outline, size: 28, color: Color(0xff4f46e5))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${emp.designation} • ${emp.department}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Attendance / Tracker Status
            _buildLiveStatusCard(context, state),
            const SizedBox(height: 24),

            // Metrics Bento Grid
            const Text(
              'Performance Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1e293b)),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.5,
              children: [
                _buildBentoItem(
                  context: context,
                  label: 'Completed Tasks',
                  value: '$completedTasksCount/$totalTasksCount',
                  icon: Icons.task_alt_outlined,
                  color: Colors.blue,
                  routeName: '/tasks',
                ),
                _buildBentoItem(
                  context: context,
                  label: 'Field Visits',
                  value: '$completedVisitsCount',
                  icon: Icons.map_outlined,
                  color: Colors.green,
                  routeName: '/visits',
                ),
                _buildBentoItem(
                  context: context,
                  label: 'Leave Applications',
                  value: '$pendingLeavesCount Pending',
                  icon: Icons.time_to_leave_outlined,
                  color: Colors.orange,
                  routeName: '/leaves',
                ),
                _buildBentoItem(
                  context: context,
                  label: 'My Supervisor',
                  value: emp.assignedSupervisorId.isNotEmpty ? emp.assignedSupervisorId : 'HO Admin',
                  icon: Icons.supervisor_account_outlined,
                  color: Colors.purple,
                  routeName: '/profile',
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Quick Access Navigation
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1e293b)),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard(BuildContext context, AppStateProvider state) {
    final activeRecord = state.todayAttendance;
    final bool checkedIn = activeRecord != null;
    final bool checkedOut = checkedIn && activeRecord.checkOutTime != null;

    String headerText = "Clock Out Alert";
    String detailsText = "You have not checked-in for today yet.";
    IconData icon = Icons.timer_outlined;
    Color statusColor = Colors.orange;

    if (checkedIn && !checkedOut) {
      headerText = "Currently Logged In";
      detailsText = "Checked in at ${activeRecord.checkInTime} (${activeRecord.checkInStatus})";
      icon = Icons.check_circle_outline;
      statusColor = Colors.green;
    } else if (checkedOut) {
      headerText = "Completed Today's Shift";
      detailsText = "Checked out at ${activeRecord.checkOutTime}. Shift done!";
      icon = Icons.done_all_outlined;
      statusColor = Colors.blue;
    }

    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff1e293b)),
                ),
                const SizedBox(height: 2),
                Text(
                  detailsText,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4f46e5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            onPressed: () => Navigator.pushNamed(context, '/attendance'),
            child: const Text('Access', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String routeName,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: CustomCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Icon(Icons.arrow_forward_ios_outlined, color: Colors.grey.shade300, size: 12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': 'Attendance', 'icon': Icons.fingerprint_outlined, 'route': '/attendance', 'color': const Color(0xff4f46e5)},
      {'label': 'Field Visits', 'icon': Icons.pin_drop_outlined, 'route': '/visits', 'color': const Color(0xff10b981)},
      {'label': 'My Tasks', 'icon': Icons.assignment_outlined, 'route': '/tasks', 'color': const Color(0xff3b82f6)},
      {'label': 'Apply Leave', 'icon': Icons.beach_access_outlined, 'route': '/leaves', 'color': const Color(0xfff59e0b)},
      {'label': 'Live Map', 'icon': Icons.gps_fixed_outlined, 'route': '/reports', 'color': const Color(0xff8b5cf6)},
      {'label': 'Profile Info', 'icon': Icons.badge_outlined, 'route': '/profile', 'color': const Color(0xffec4899)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, i) {
        final act = actions[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, act['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100, width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (act['color'] as Color).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  act['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff334155),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
