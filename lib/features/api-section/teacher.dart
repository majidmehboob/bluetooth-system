import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_track/services/class-information-services.dart';

class ClassApiService {
  //     ---------[ 🍀 Get Today Classes ]------------   //

  static Future<List<ClassInfo>> fetchTodayClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/today-timetable?user_type=teacher',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> timetable = data['today_timetable'] ?? [];
        return timetable
            .map((e) => ClassInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching classes: $e');
    }
  }

  //     ---------[ 🍀 Get Today Report  ]------------   //
  static Future<Map<String, dynamic>> fetchTodayAttendanceReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/today-attendance-report?user_type=teacher',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load attendance report: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching attendance report: $e');
    }
  }
}
