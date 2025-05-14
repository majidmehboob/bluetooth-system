import 'package:smart_track/screens/teacher-section/pages/attendence-detail.dart';
import 'package:flutter/material.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:smart_track/screens/teacher-section/drawer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:slide_to_act/slide_to_act.dart';

class TodayReportTeacher extends StatefulWidget {
  const TodayReportTeacher({super.key});

  @override
  State<TodayReportTeacher> createState() => _TeacherTodayReportScreenState();
}

class _TeacherTodayReportScreenState extends State<TodayReportTeacher> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;
  String errorMessage = '';
  String currentDate = '';
  String currentDay = '';
  String currentTime = '';
  List<dynamic> upcomingClasses = [];
  List<dynamic> completedClasses = [];
  List<dynamic> ongoingClasses = [];
  List<dynamic> nottakenClasses = [];

  // Track expanded state for each section
  bool isOngoingExpanded = true;
  bool isUpcomingExpanded = true;
  bool isCompletedExpanded = true;
  bool isNotTakenExpanded = true;
  @override
  void initState() {
    super.initState();
    _fetchAttendanceReport();
  }

  Future<void> _fetchAttendanceReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'No access token found';
        });
        return;
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
        final data = json.decode(response.body);
        print(data);
        setState(() {
          currentDate = data['date'];
          currentDay = data['day'];
          currentTime = data['current_time'];
          upcomingClasses = data['upcoming_classes'] ?? [];
          completedClasses = data['completed_classes'] ?? [];
          ongoingClasses = data['ongoing_classes'] ?? [];
          nottakenClasses = data['not_taken_classes'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching data: ${e.toString()}';
      });
    }
  }

  String _formatTime(String timeString) {
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

  Color _getSessionStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'not_started':
        return Colors.orange;
      case 'no_session':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getMarksColor(dynamic status) {
    if (status == 'not_started') {
      return Colors.orange;
    } else if (status == 'no_session') {
      return Colors.grey;
    } else if (status is int) {
      if (status > 75) {
        return Colors.green;
      } else if (status > 50) {
        return Colors.blue;
      } else if (status > 25) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
    return Colors.blue; // default
  }

  // Usage would be the same
  String _getSessionStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'not_started':
        return 'Not Started';
      case 'no_session':
        return 'No Session';
      default:
        return status;
    }
  }

  Color _getAvatarColor(int index) {
    return index % 2 == 0 ? const Color(0xFF6A7D94) : const Color(0xFF293646);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: const CustomDrawer(
        backgroundColor: Colors.white,
        iconColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAttendanceReport,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child:
              isLoading
                  ? _buildShimmerLoading()
                  : errorMessage.isNotEmpty
                  ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(child: Text(errorMessage)),
                  )
                  : Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20.0,
                      horizontal: 16.0,
                    ),
                    child:
                        isLoading
                            ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : errorMessage.isNotEmpty
                            ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: Center(child: Text(errorMessage)),
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Classes - $currentDay",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Date: $currentDate | Time: ${_formatTime(currentTime)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Ongoing Classes
                                if (ongoingClasses.isNotEmpty) ...[
                                  _buildExpandableHeader(
                                    "Ongoing Classes",
                                    isOngoingExpanded,
                                    () {
                                      setState(() {
                                        isOngoingExpanded = !isOngoingExpanded;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (isOngoingExpanded) ...[
                                    ..._buildClassList(ongoingClasses),
                                    const SizedBox(height: 16),
                                  ],
                                ],

                                // Upcoming Classes
                                if (upcomingClasses.isNotEmpty) ...[
                                  _buildExpandableHeader(
                                    "Upcoming Classes",
                                    isUpcomingExpanded,
                                    () {
                                      setState(() {
                                        isUpcomingExpanded =
                                            !isUpcomingExpanded;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (isUpcomingExpanded) ...[
                                    ..._buildClassList(upcomingClasses),
                                    const SizedBox(height: 16),
                                  ],
                                ],

                                // Completed Classes
                                if (completedClasses.isNotEmpty) ...[
                                  _buildExpandableHeader(
                                    "Completed Classes",
                                    isCompletedExpanded,
                                    () {
                                      setState(() {
                                        isCompletedExpanded =
                                            !isCompletedExpanded;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (isCompletedExpanded) ...[
                                    ..._buildClassList(completedClasses),
                                  ],
                                ],

                                // Not Taken Classes
                                if (nottakenClasses.isNotEmpty) ...[
                                  _buildExpandableHeader(
                                    "Not Taken Classes",
                                    isNotTakenExpanded,
                                    () {
                                      setState(() {
                                        isNotTakenExpanded =
                                            !isNotTakenExpanded;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (isNotTakenExpanded) ...[
                                    ..._buildClassList(nottakenClasses),
                                  ],
                                ],
                                if (ongoingClasses.isEmpty &&
                                    nottakenClasses.isEmpty &&
                                    upcomingClasses.isEmpty &&
                                    completedClasses.isEmpty)
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.6,
                                    child: const Center(
                                      child: Text(
                                        "No classes scheduled for today.",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                  ),
        ),
      ),
    );
  }

  Widget _buildExpandableHeader(
    String text,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: ColorStyle.BlueStatic,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            Icon(
              isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildClassList(List<dynamic> classes) {
    return List.generate(classes.length, (index) {
      final classInfo = classes[index];
      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getAvatarColor(index),
                  child: Text(
                    classInfo['course_name']
                        .toString()
                        .substring(0, 2)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              classInfo['course_name'],
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(classInfo['start_time']),
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Section: ${classInfo['section'].toString().toUpperCase()} | Room: ${classInfo['room']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Students: ${classInfo['present_students']}/${classInfo['total_students']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "${classInfo['attendance_percentage']}%",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getMarksColor(
                                classInfo['attendance_percentage'],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Session: ${_getSessionStatusText(classInfo['session_status'])}",
                            style: TextStyle(
                              color: _getSessionStatusColor(
                                classInfo['session_status'],
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Add button for upcoming classes
                    ],
                  ),
                ),
              ],
            ),
            if (classInfo['attendance_session_id'] != null &&
                classInfo['class_status'] == 'completed')
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 2),
                color: Colors.grey[300],
                child: SlideAction(
                  height: 40,
                  sliderButtonIconPadding: 4,
                  sliderButtonIconSize: 20,

                  sliderRotate: false,

                  elevation: 0,
                  borderRadius: 0,
                  innerColor: Colors.white,
                  outerColor: Colors.grey[300],
                  textStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                  // Let's change the icon and the icon color
                  sliderButtonIcon: Icon(
                    Icons.arrow_right_rounded,
                    color: Colors.black,
                  ),

                  text: "View In Detail",
                  onSubmit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AttendanceDetailsTeacher(
                              sessionId: classInfo['attendance_session_id'],
                            ),
                      ),
                    );
                    return null;
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}

Widget _buildShimmerLoading() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 24,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
        ),
        Container(
          width: double.infinity,
          height: 18,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 16),
        ),
        ...List.generate(4, (index) => _buildShimmerClassItem()),
      ],
    ),
  );
}

Widget _buildShimmerClassItem() {
  return Container(
    margin: const EdgeInsets.only(bottom: 16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade300, width: 1),
      borderRadius: BorderRadius.circular(12.0),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 20,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
              ),
              Container(
                width: 150,
                height: 16,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
              ),
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
