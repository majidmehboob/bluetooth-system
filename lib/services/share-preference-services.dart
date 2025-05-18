// lib/services/shared_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const _onboardingCompleteKey = 'onboardingComplete';
  static const _accessTokenKey = 'accessToken';
  static const _isStudentKey = 'isStudent';
  static const _firstRunKey = 'first_run';
  static const _notificationPermissionRequestedKey =
      'notificationPermissionRequested';

  final SharedPreferences _prefs;

  SharedPreferencesService(this._prefs);

  // Initialize the service
  static Future<SharedPreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesService(prefs);
  }

  // Onboarding status
  Future<bool> getOnboardingComplete() async {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_onboardingCompleteKey, value);
  }

  // First run detection
  Future<bool> isFirstRunTime() async {
    bool isFirstRun = _prefs.getBool(_firstRunKey) ?? true;
    if (isFirstRun) {
      await _prefs.setBool(_firstRunKey, false);
      return true;
    }
    return false;
  }

  // Auth status
  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  Future<void> setAccessToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
  }

  Future<bool> isStudent() async {
    return _prefs.getBool(_isStudentKey) ?? false;
  }

  Future<void> setIsStudent(bool value) async {
    await _prefs.setBool(_isStudentKey, value);
  }

  // Notification permission status
  Future<bool> wasNotificationPermissionRequested() async {
    return _prefs.getBool(_notificationPermissionRequestedKey) ?? false;
  }

  Future<void> setNotificationPermissionRequested(bool value) async {
    await _prefs.setBool(_notificationPermissionRequestedKey, value);
  }

  // Clear all preferences (for logout)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
