// lib/services/shared_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const _onboardingCompleteKey = 'onboardingComplete';
  static const _accessTokenKey = 'accessToken';
  static const _isStudentKey = 'isStudent';

  final SharedPreferences _prefs;

  SharedPreferencesService(this._prefs);

  // Onboarding status
  Future<bool> getOnboardingComplete() async {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_onboardingCompleteKey, value);
  }

  // Auth status
  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  Future<bool> isStudent() async {
    return _prefs.getBool(_isStudentKey) ?? false;
  }

  // Initialize in main.dart
  static Future<SharedPreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesService(prefs);
  }
}
