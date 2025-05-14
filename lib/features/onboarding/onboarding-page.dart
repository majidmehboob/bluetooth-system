// lib/features/onboarding/onboarding_page.dart
import 'package:flutter/material.dart';
import './onboarding-item.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final int currentPage;
  final int totalPages;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(item.imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      index == currentPage
                          ? const Color(0xFF80A7D5)
                          : Colors.grey.withOpacity(0.4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
