import 'package:smart_track/screens/student-section/drawer.dart';
import 'package:smart_track/widgets/snackbar-helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smart_track/utils/colors.dart';

class SingleSubjectGraphStudent extends StatefulWidget {
  final int semesterId;
  final int courseId;
  const SingleSubjectGraphStudent({
    super.key,
    required this.semesterId,
    required this.courseId,
  });

  @override
  State<SingleSubjectGraphStudent> createState() => _HistorySlugState();
}

class _HistorySlugState extends State<SingleSubjectGraphStudent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic> _attendanceData = {};
  double _attendancePercentage = 0.0;
  String _courseName = 'Loading...';

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
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/course-attendance-report?semester_id=${widget.semesterId}&course_id=${widget.courseId}',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _attendanceData = data['attendance_data'] ?? {};
          _attendancePercentage =
              (data['attendance_percentage'] as num?)?.toDouble() ?? 0.0;
          _courseName = 'Course ${widget.courseId}';
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
      SnackbarHelper.showError(context, 'Error fetching attendance data');
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
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const CustomDrawer(
        backgroundColor: Colors.white,
        iconColor: Colors.black,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 2.0,
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
                    const SizedBox(height: 2),
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
                        size: 16.0,
                        scrollable: true,
                        datasets: heatmapDatasets,
                        colorsets: const {
                          1: Color(0xFFB2CCDF), // Present
                          2: Colors.red, // Absent
                          3: Colors.grey, // No data
                        },
                        onClick: (value) {
                          setState(() {
                            _selectedDay = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _courseName,
                            style: TextStyle(
                              color: Color(0xFF282424),
                              fontSize: 20,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            '${_attendancePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Color(0xFF282424),
                              fontSize: 20,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 100,
                          height: 250,
                          color: Colors.white,
                          child: TableCalendar(
                            focusedDay: _focusedDay,
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
                            firstDay: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDay: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            selectedDayPredicate:
                                (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1.0),
                    _buildAttendanceInfoCard(),
                  ],
                ),
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
      cardColor = ColorStyle.BlueStatic;
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
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
            color: Colors.grey,
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
