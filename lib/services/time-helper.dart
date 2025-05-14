// time_helper.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeHelper {
  // Time comparison
  static int compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    if (a.hour < b.hour) return -1;
    if (a.hour > b.hour) return 1;
    if (a.minute < b.minute) return -1;
    if (a.minute > b.minute) return 1;
    return 0;
  }

  // Time formatting
  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  static String formatTimeOfDayForDisplay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  // Time range checking
  static bool isBetween(DateTime time, DateTime start, DateTime end) {
    return time.isAfter(start.subtract(const Duration(seconds: 1))) &&
        time.isBefore(end.add(const Duration(seconds: 1)));
  }

  // Class time calculations
  static DateTime getClassStartTime(DateTime currentDate, TimeOfDay startTime) {
    return DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      startTime.hour,
      startTime.minute,
    );
  }

  static DateTime getClassEndTime(DateTime currentDate, TimeOfDay endTime) {
    return DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      endTime.hour,
      endTime.minute,
    );
  }

  // Add this to time_helper.dart
  static String formatTimeOfDayForNotification(TimeOfDay time) {
    final hour = time.hourOfPeriod; // Gets hour in 12-hour format
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // Class status determination
  static ClassTimeStatus getClassTimeStatus({
    required DateTime currentTime,
    required TimeOfDay classStart,
    required TimeOfDay classEnd,
  }) {
    final startDateTime = getClassStartTime(currentTime, classStart);
    final endDateTime = getClassEndTime(currentTime, classEnd);

    if (isBetween(currentTime, startDateTime, endDateTime)) {
      return ClassTimeStatus.current;
    } else if (currentTime.isBefore(startDateTime)) {
      return ClassTimeStatus.upcoming;
    } else {
      return ClassTimeStatus.completed;
    }
  }

  static String formatTimeDayHourMinute(String timeString) {
    try {
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final timeFormat = DateFormat('h:mm a');
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, hour, minute);
      return timeFormat.format(dt);
    } catch (e) {
      return timeString;
    }
  }
}

enum ClassTimeStatus { current, upcoming, completed }
