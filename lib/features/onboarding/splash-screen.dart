// lib/features/onboarding/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:smart_track/services/share-preference-services.dart';
import 'package:smart_track/widgets/system-ui.dart';
import './onboarding-screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const SplashScreen({super.key, required this.onInitializationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    setupSystemUI();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferencesService.init();
    bool firstRun = await prefs.isFirstRunTime(); // Now this will work
    final onboardingComplete = await prefs.getOnboardingComplete();

    if (firstRun || !onboardingComplete) {
      // Show onboarding if not completed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => OnboardingScreen(
                onCompleted: widget.onInitializationComplete,
              ),
        ),
      );
    } else {
      // Otherwise proceed with normal flow
      widget.onInitializationComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/splash_logo.png', width: 200),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF80A7D5)),
            ),
          ],
        ),
      ),
    );
  }
}
