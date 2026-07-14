import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/other_models.dart';
import '../widgets/custom_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final list = state.notifications;

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('Notifications Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xff4f46e5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: list.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No new announcements or alerts.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (context, i) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = list[i];
                return CustomCard(
                  color: n.isRead ? Colors.white : const Color(0xfff0fdf4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.isRead ? FontWeight.bold : FontWeight.w900,
                                fontSize: 14,
                                color: const Color(0xff1e293b),
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            GestureDetector(
                              onTap: () => state.markNotificationAsRead(n.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xff22c55e).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'New',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xff15803d)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.message,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        n.timestamp.split('T')[0],
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// Add markNotificationAsRead wrapper extension
extension AppStateProviderNotifExtension on AppStateProvider {
  Future<void> markNotificationAsRead(String id) async {
    await _firebaseService.markNotificationAsRead(id);
  }
}
