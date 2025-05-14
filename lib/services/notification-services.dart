// // notification_helper.dart
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:fyo_2025/services/time-helper.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:fyo_2025/services/class-information-services.dart';

// class NotificationHelper {
//   static final FlutterLocalNotificationsPlugin notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> scheduleClassNotifications(
//     List<ClassInfo> classes,
//   ) async {
//     await notificationsPlugin.cancelAll();
//     final now = tz.TZDateTime.now(tz.local);

//     for (var classInfo in classes) {
//       final scheduledTime = tz.TZDateTime(
//         tz.local,
//         now.year,
//         now.month,
//         now.day,
//         classInfo.startTime.hour,
//         classInfo.startTime.minute,
//       );

//       if (scheduledTime.isAfter(now)) {
//         await _scheduleSingleNotification(classInfo, scheduledTime);
//       }
//     }
//   }

//   static Future<void> _scheduleSingleNotification(
//     ClassInfo classInfo,
//     tz.TZDateTime scheduledTime,
//   ) async {
//     const androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       'class_start_channel',
//       'Class Start Notifications',
//       channelDescription: 'Notifications for when classes are about to start',
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('notification_sound'),
//       enableVibration: true,
//     );

//     const platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//       iOS: DarwinNotificationDetails(),
//     );

//     final formattedTime = TimeHelper.formatTimeOfDayForNotification(
//       classInfo.startTime,
//     );

//     await notificationsPlugin.zonedSchedule(
//       classInfo.id,
//       'Class Starting Soon',
//       '${classInfo.course} (${classInfo.courseCode}) starts at $formattedTime in ${classInfo.room}',
//       scheduledTime,
//       platformChannelSpecifics,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );
//   }

//   static Future<void> showClassStartNotification(ClassInfo classInfo) async {
//     const androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       'class_start_channel',
//       'Class Start Notifications',
//       channelDescription: 'Notifications for when classes are about to start',
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('notification_sound'),
//       enableVibration: true,
//     );

//     const platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//       iOS: DarwinNotificationDetails(),
//     );
//     final formattedTime = TimeHelper.formatTimeOfDayForNotification(
//       classInfo.startTime,
//     );

//     await notificationsPlugin.show(
//       0,
//       'Class Starting Now',
//       '${classInfo.course} (${classInfo.courseCode}) is starting now ($formattedTime) in ${classInfo.room}',
//       platformChannelSpecifics,
//     );
//   }
// }
