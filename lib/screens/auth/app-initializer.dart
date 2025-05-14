// lib/main.dart
import 'package:flutter/material.dart';

import 'package:smart_track/features/connectivity/connection-wrapper.dart';
import 'package:smart_track/features/onboarding/splash-screen.dart';
import 'package:smart_track/screens/auth/log-in.dart';

import 'package:smart_track/screens/student-section/main.dart';
import 'package:smart_track/screens/teacher-section/main.dart';
import 'package:smart_track/services/share-preference-services.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(onInitializationComplete: _navigateToAppropriateScreen);
  }

  Future<void> _navigateToAppropriateScreen() async {
    final prefs = await SharedPreferencesService.init();
    final token = await prefs.getAccessToken();

    if (token != null && token.isNotEmpty) {
      final isStudent = await prefs.isStudent();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ConnectivityWrapper(
                child: isStudent ? const HomeStudent() : const HomeTeacher(),
              ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConnectivityWrapper(child: const LogInPage()),
        ),
      );
    }
  }
}
