import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class SingleSubjectGraphTeacher extends StatefulWidget {
  final String studentName;
  final int semesterId;
  final int courseId;
  final String course;
  final String rollNumber;
  const SingleSubjectGraphTeacher({
    super.key,
    required this.studentName,
    required this.course,
    required this.semesterId,
    required this.courseId,
    required this.rollNumber,
  });

  @override
  State<SingleSubjectGraphTeacher> createState() => _TeacherHistorySlugState();
}

class _TeacherHistorySlugState extends State<SingleSubjectGraphTeacher> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic> _attendanceData = {};
  double _attendancePercentage = 0.0;
  DateTime _currentPage = DateTime.now();
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/course-attendance-report?semester_id=${widget.semesterId}&course_id=${widget.courseId}&registration_number=${widget.rollNumber}',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          _attendanceData = data['attendance_data'] ?? {};
          _attendancePercentage =
              (data['attendance_percentage'] as num?)?.toDouble() ?? 0.0;

          _isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load attendance data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert API data to heatmap format
    final heatmapDatasets = _attendanceData.map((date, data) {
      final dateParts = date.split('-');
      final dateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      // Determine the value based on present status
      int value;
      if (data['present'] == true) {
        value = 1; // Present
      } else if (data['present'] == false) {
        value = 2; // Absent
      } else {
        value = 3; // No data (null)
      }

      return MapEntry(dateTime, value);
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance History',
                      style: TextStyle(
                        color: Color(0xFF282424),
                        fontSize: 25,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      color: Colors.white,
                      child: HeatMap(
                        startDate: DateTime.now().subtract(
                          const Duration(days: 60),
                        ),

                        endDate: DateTime.now().add(const Duration(days: 60)),
                        colorMode: ColorMode.color,
                        showText: false,
                        size: 14.0,
                        scrollable: true,
                        datasets: heatmapDatasets,
                        colorsets: {
                          1: Color(0xFFB2CCDF), // Present
                          2: Colors.red, // Absent
                          3: Colors.grey, // No data
                        },

                        // ... existing parameters ...
                        onClick: (value) {
                          setState(() {
                            _selectedDay = value;
                            _focusedDay = value;
                            _currentPage = DateTime(value.year, value.month);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            widget.studentName,
                            widget.rollNumber,
                          ),
                          SizedBox(height: 4),
                          _buildDetailRow(
                            widget.course,
                            '${_attendancePercentage.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10.0),
                            padding: EdgeInsets.symmetric(vertical: 2.0),
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 0.5,
                              ),
                              color: Colors.white,
                            ),
                            height: 260,

                            child: TableCalendar(
                              focusedDay: _focusedDay,
                              firstDay: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDay: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              currentDay: _selectedDay,
                              shouldFillViewport: true,
                              headerVisible: true,
                              rowHeight: 37.0,
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: false,
                                selectedDecoration: const BoxDecoration(
                                  color: Color(0xFFB2CCDF),
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: const BoxDecoration(
                                  color: Color(0xFFB2CCDF),
                                  shape: BoxShape.circle,
                                ),
                                rangeHighlightColor: Colors.grey,
                                markerDecoration: const BoxDecoration(
                                  color: Color(0xFFB2CCDF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Add this to track page changes
                              onPageChanged: (focusedDay) {
                                setState(() {
                                  _currentPage = focusedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              selectedDayPredicate:
                                  (day) => isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },

                              pageAnimationEnabled: true,
                              pageJumpingEnabled: true,
                              availableCalendarFormats: const {
                                CalendarFormat.month: 'Month',
                              },
                              calendarBuilders: CalendarBuilders(),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                              ),
                              calendarFormat: CalendarFormat.month,
                              availableGestures: AvailableGestures.all,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              // Add this controller
                            ),
                          ),
                          const SizedBox(height: 1.0),
                          _buildAttendanceInfoCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black45,
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceInfoCard() {
    final dateKey = _selectedDay != null ? _formatDate(_selectedDay!) : null;
    final attendanceStatus =
        dateKey != null && _attendanceData.containsKey(dateKey)
            ? _attendanceData[dateKey]
            : null;

    Color cardColor;
    String statusText;
    String percentageText;

    if (attendanceStatus == null) {
      cardColor = Colors.grey;
      statusText = 'No Data';
      percentageText = '--%';
    } else if (attendanceStatus['present'] == true) {
      cardColor = Color(0xFFB2CCDF);
      statusText = 'Present';
      percentageText =
          '${attendanceStatus['percentage']?.toStringAsFixed(1) ?? '--'}%';
    } else if (attendanceStatus['present'] == false) {
      cardColor = Colors.red;
      statusText = 'Absent';
      percentageText =
          '${attendanceStatus['percentage']?.toStringAsFixed(1) ?? '--'}%';
    } else {
      cardColor = Colors.grey;
      statusText = 'No Data';
      percentageText = '--%';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Color.fromRGBO(246, 246, 246, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Date Box
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(_selectedDay ?? DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('EEE').format(_selectedDay ?? DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // Attendance Info
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttendanceInfo(statusText, 'Status'),
                  _buildAttendanceInfo(percentageText, 'Percentage'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceInfo(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 14,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
