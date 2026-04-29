import 'package:flutter/material.dart';
import 'package:testapp/features/achievement/achievement_screen.dart';
import 'package:testapp/features/challenges/challenges_screen.dart';
import 'features/intro/intro_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/habit/habit_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/reminder/reminder_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/editProfile_screen.dart';
import 'features/auth/login_screen.dart';


class GreenHabitApp extends StatelessWidget {
  const GreenHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green habit Tracker',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/intro',
      routes: {
        '/intro': (_) => const IntroScreen(),
        '/auth': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/habit': (_) => const HabitScreen(),
        '/progress': (_) => const ProgressScreen(),
        '/reminder': (_) => const ReminderScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/editProfile': (_) => const EditProfileScreen(),
        '/achievement': (_) => const AchievementScreen(),
        '/challenges': (_) => const ChallengesPage(),


      },
    );
  }
}
