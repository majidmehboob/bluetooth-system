import 'package:flutter/material.dart';
import 'package:smart_track/screens/student-section/main.dart';
import 'package:smart_track/screens/teacher-section/main.dart';
import 'package:smart_track/widgets/snackbar-helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  //  ---------------[ 🍀 Login Function ]-----------------   //

  static Future<void> loginUser({
    required BuildContext context,
    required String email,
    required String password,
    required Function(bool) setLoading,
  }) async {
    setLoading(true);

    try {
      final response = await http.post(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/auth/login',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await handleSuccessfulLogin(context, responseData);
      } else {
        final errorMessage =
            responseData['message'] ??
            'Login failed. Please check your credentials.';
        SnackbarHelper.showError(context, errorMessage);
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Network error. Please try again');
    } finally {
      setLoading(false);
    }
  }

  //  ---------------[ 🍀 After Login Function ]-----------------   //

  static Future<void> handleSuccessfulLogin(
    BuildContext context,
    Map<String, dynamic> responseData,
  ) async {
    final isStudent = responseData['user_details']['type'] == 'student';
    final isTeacher = responseData['user_details']['type'] == 'teacher';

    final prefs = await SharedPreferences.getInstance();
    await _storeCommonUserData(prefs, responseData, isStudent);

    if (isTeacher) {
      await _storeTeacherData(prefs, responseData);
    } else if (isStudent) {
      await _storeStudentData(prefs, responseData);
    }

    _navigateAfterLogin(context, isStudent, isTeacher);
  }

  //  ---------------[ 🍀 Store Common Data ]-----------------   //

  static Future<void> _storeCommonUserData(
    SharedPreferences prefs,
    Map<String, dynamic> responseData,
    bool isStudent,
  ) async {
    await prefs.setString('userName', responseData['user_details']['name']);
    await prefs.setString('userEmail', responseData['user_details']['email']);
    await prefs.setString('accessToken', responseData['tokens']['access']);
    await prefs.setString('refreshToken', responseData['tokens']['refresh']);
    await prefs.setBool('isStudent', isStudent);
  }

  //  ---------------[ 🍀 Store Teacher Data  ]-----------------   //

  static Future<void> _storeTeacherData(
    SharedPreferences prefs,
    Map<String, dynamic> responseData,
  ) async {
    final teacherDetails = responseData['user_details']['details'] ?? {};
    await prefs.setString('employeeId', teacherDetails['employee_id'] ?? '');
    await prefs.setString('department', teacherDetails['department'] ?? '');
  }

  //  ---------------[ 🍀 Store Student  Data ]-----------------   //

  static Future<void> _storeStudentData(
    SharedPreferences prefs,
    Map<String, dynamic> responseData,
  ) async {
    final studentDetails = responseData['user_details']['details'] ?? {};
    await prefs.setString('uid', studentDetails['uid'] ?? '');
    await prefs.setString(
      'registrationNumber',
      studentDetails['registration_number'] ?? '',
    );

    final degree = studentDetails['degree'] ?? {};
    await prefs.setString('degreeName', degree['name'] ?? '');
    await prefs.setString('degreeDepartment', degree['department'] ?? '');

    final section = studentDetails['section'] ?? {};
    await prefs.setString('sectionName', section['name'] ?? '');
    await prefs.setInt('semester', section['semester'] ?? 0);
  }

  //  ---------------[ 🍀 Navigation Function -----------------]   //

  static void _navigateAfterLogin(
    BuildContext context,
    bool isStudent,
    bool isTeacher,
  ) {
    if (isStudent) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeStudent()),
      );
    } else if (isTeacher) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeTeacher()),
      );
    } else {
      SnackbarHelper.showError(context, 'You are just a user');
    }
  }
}
