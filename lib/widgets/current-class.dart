import 'package:smart_track/services/class-information-services.dart';
import 'package:flutter/material.dart';
import 'package:smart_track/services/text-helper.dart';
import 'package:smart_track/services/time-helper.dart';

Widget selectedClassDetails({
  required ClassInfo classInfo,
  required VoidCallback onJoinPressed,
  String? status,
  bool? isStudent,
}) {
  final bool studentPage = isStudent != null && isStudent == true;

  return Container(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextFormatHelper.formatCourseNameWithBreaks(
            classInfo.course,
            style: const TextStyle(
              fontSize: 25,
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
          // if (classInfo.attendanceSessionId == null)
          //   Text("class is not started yet"),
          // Text(
          //   classInfo.attendanceSessionId == null
          //       ? "0"
          //       : classInfo.attendanceSessionId.toString(),
          // ),
          const SizedBox(height: 10),
          if (status == "completed")
            Container(
              width: 130,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: const Color.fromARGB(255, 187, 230, 189),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check,
                    color: studentPage ? Colors.white54 : Colors.green,
                    size: 12,
                  ), // Added color here
                  SizedBox(width: 4),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: studentPage ? Colors.white54 : Colors.green,
                      fontFamily: 'Roboto',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            classInfo.attendanceSessionId == null && isStudent == true
                ? Text(
                  "Teacher did not join the class",
                  style: TextStyle(color: Colors.grey[700]),
                )
                : ElevatedButton(
                  onPressed: onJoinPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 20.0,
                    ),
                    backgroundColor: Color(0xFFEBEDF0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),

                  child: Text(
                    "Join Now",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
}
