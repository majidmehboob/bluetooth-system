// lib/features/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_track/Services/share-preference-services.dart';
import 'package:smart_track/screens/auth/log-in.dart';
import 'package:smart_track/widgets/system-ui.dart';
import './onboarding-item.dart';
import './onboarding-page.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;

  final List<OnboardingItem> _onboardingItems = const [
    OnboardingItem(
      title: "Welcome to ClassTrack",
      description:
          "The ultimate solution for classroom attendance management using Bluetooth technology",
      imagePath: "assets/images/onboarding1.png",
    ),
    OnboardingItem(
      title: "Student Features",
      description:
          "Mark your attendance easily and view your attendance history with detailed analytics",
      imagePath: "assets/images/onboarding2.png",
    ),
    OnboardingItem(
      title: "Teacher Features",
      description:
          "Take attendance effortlessly and manage your class records with our intuitive interface",
      imagePath: "assets/images/onboarding3.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    setupSystemUI();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_currentPage < _onboardingItems.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferencesService.init();
    await prefs.setOnboardingComplete(true);
    widget.onCompleted();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LogInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingItems.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    item: _onboardingItems[index],
                    currentPage: _currentPage,
                    totalPages: _onboardingItems.length,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage != _onboardingItems.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Color(0xFF80A7D5),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed:
                        _currentPage == _onboardingItems.length - 1
                            ? _completeOnboarding
                            : () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn,
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80A7D5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage == _onboardingItems.length - 1
                          ? "Get Started"
                          : "Next",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
