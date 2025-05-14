import 'package:flutter/material.dart';

class ClassInfo {
  final int id;
  final int courseId;
  final String course;
  final String courseCode;
  final String instructorName;
  final String room;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String dayOfWeek;
  final String section;
  final int semester;
  final String degree;
  final String degreePrefix;
  final String department;
  final String university;
  final String raspberry_Pi;
  final String status;
  final String statusMessage;
  final bool attendanceSessionExists;
  final bool attendanceSessionActive;
  final int? attendanceSessionId;
  final String attendenceSessionStatus;
  final int semesterId;

  ClassInfo({
    required this.id,
    required this.courseId,
    required this.course,
    required this.courseCode,
    required this.instructorName,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.section,
    required this.semester,
    required this.degree,
    required this.degreePrefix,
    required this.department,
    required this.university,
    required this.raspberry_Pi,
    required this.status,
    required this.statusMessage,
    required this.attendanceSessionExists,
    required this.attendanceSessionActive,
    this.attendanceSessionId,
    required this.attendenceSessionStatus,
    required this.semesterId,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] as int? ?? 0,
      courseId: json['course_id'] as int? ?? 0,
      course: json['course'] as String? ?? 'Unknown Course',
      courseCode: json['course_code'] as String? ?? 'N/A',
      instructorName:
          json['instructor_name'] as String? ?? 'Unknown Instructor',
      room: json['room'] as String? ?? 'Unknown Room',
      startTime: _parseTime(json['start_time'] as String?),
      endTime: _parseTime(json['end_time'] as String?),
      dayOfWeek: json['day_of_week'] as String? ?? 'Unknown Day',
      section: json['section'] as String? ?? 'N/A',
      semester: json['semester'] as int? ?? 0,
      degree: json['degree'] as String? ?? 'Unknown Degree',
      degreePrefix: json['degree_prefix'] as String? ?? '',
      department: json['department'] as String? ?? 'Unknown Department',
      university: json['university'] as String? ?? 'Unknown University',
      raspberry_Pi: json['raspberry_pi'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'unknown',
      statusMessage: json['status_message'] as String? ?? '',
      attendanceSessionExists:
          json['attendance_session_exists'] as bool? ?? false,
      attendanceSessionActive:
          json['attendance_session_active'] as bool? ?? false,
      attendanceSessionId: json['attendance_session_id'] as int?,
      attendenceSessionStatus:
          json['attendance_session_status'] as String? ?? '',
      semesterId: json['semester_id'] as int? ?? 0,
    );
  }

  static TimeOfDay _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return const TimeOfDay(hour: 0, minute: 0);
    }

    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }
}
