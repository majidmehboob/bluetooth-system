import 'package:flutter/material.dart';
import 'package:smart_track/services/class-information-services.dart';
import 'package:smart_track/services/text-helper.dart';
import 'package:smart_track/services/time-helper.dart';

Widget BuildNextClassCard({
  required ClassInfo classInfo,
  required Duration? nextClassRemainingTime,
  required bool? isStudent,
}) {
  final bool studentPage = isStudent != null && isStudent == true;
  return Container(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormatHelper.formatCourseNameWithBreaks(
            classInfo.course,
            style: const TextStyle(
              fontSize: 26,
              color: Colors.black87,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 3),
          Text(
            'Room: ${classInfo.room}',
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF5C5C5C),
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 3),

          Text(
            '${TimeHelper.formatTimeOfDayForDisplay(classInfo.startTime)} - ${TimeHelper.formatTimeOfDayForDisplay(classInfo.endTime)}',
            style: TextStyle(
              fontSize: 15,
              color: studentPage ? Colors.black : Colors.grey[600],
              fontFamily: 'Roboto',
              fontWeight: FontWeight.normal,
              height: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            TimeHelper.formatDuration(nextClassRemainingTime!),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}
