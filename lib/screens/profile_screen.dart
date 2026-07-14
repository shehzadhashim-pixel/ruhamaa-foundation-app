import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final emp = state.currentUserEmployee;

    if (emp == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xff4f46e5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Card Header
            CustomCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xff4f46e5).withOpacity(0.1),
                    child: const Icon(Icons.person, size: 48, color: Color(0xff4f46e5)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emp.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff0f172a)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emp.designation,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const Divider(height: 24),
                  
                  // Rating bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Supervisor Rating: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        children: List.generate(5, (index) {
                          final rating = emp.supervisorRating ?? 4.0;
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal Credentials
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personal & Work Credentials',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff475569)),
              ),
            ),
            const SizedBox(height: 10),

            CustomCard(
              child: Column(
                children: [
                  InfoRow(label: 'Employee ID', value: emp.id, icon: Icons.badge_outlined),
                  InfoRow(label: 'CNIC Number', value: emp.cnic, icon: Icons.credit_card_outlined),
                  InfoRow(label: 'Father Name', value: emp.fatherName, icon: Icons.people_outline),
                  InfoRow(label: 'Date of Birth', value: emp.dob, icon: Icons.cake_outlined),
                  InfoRow(label: 'Phone Contact', value: emp.phoneNumber, icon: Icons.phone_outlined),
                  InfoRow(label: 'Email', value: emp.email, icon: Icons.email_outlined),
                  InfoRow(label: 'Gender', value: emp.gender, icon: Icons.wc_outlined),
                  InfoRow(label: 'Date of Joining', value: emp.joiningDate, icon: Icons.calendar_today_outlined),
                  InfoRow(label: 'Status Code', value: emp.status, icon: Icons.toggle_on_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SecondaryButton(
              label: 'Sign Out Account',
              icon: Icons.logout_outlined,
              borderColor: Colors.red,
              onPressed: () => state.signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
