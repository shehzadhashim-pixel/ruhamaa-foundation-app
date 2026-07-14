import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_state_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/visits_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/leaves_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase core services
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization warning: $e. Ensure google-services.json is configured.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: const RuhamaaApp(),
    ),
  );
}

class RuhamaaApp extends StatelessWidget {
  const RuhamaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruhamaa Foundation Tracker',
      debugShowCheckedModeBanner: false,
      
      // Gorgeous Purple Theme (Aligning with original branding)
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xff4f46e5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff4f46e5),
          primary: const Color(0xff4f46e5),
          secondary: const Color(0xff7c3aed),
          background: const Color(0xfff8fafc),
        ),
        fontFamily: 'Inter',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xff4f46e5), width: 1.5),
          ),
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xff64748b), fontWeight: FontWeight.w500),
        ),
      ),
      
      home: const AuthGate(),
      
      // Explicit Named Routes mapping
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/attendance': (_) => const AttendanceScreen(),
        '/visits': (_) => const VisitsScreen(),
        '/tasks': (_) => const TasksScreen(),
        '/leaves': (_) => const LeavesScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/notifications': (_) => const NotificationsScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xff4f46e5)),
              SizedBox(height: 16),
              Text(
                'Loading Security Settings...',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff475569)),
              )
            ],
          ),
        ),
      );
    }

    if (state.currentUserEmployee != null) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
