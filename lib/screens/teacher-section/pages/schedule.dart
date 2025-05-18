import 'package:flutter/material.dart';
import 'package:smart_track/screens/teacher-section/drawer.dart';
import 'package:smart_track/screens/teacher-section/pages/attendence-detail.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smart_track/utils/colors.dart';

class ScheduleTeacher extends StatefulWidget {
  const ScheduleTeacher({super.key});

  @override
  State<ScheduleTeacher> createState() => _ScheduleState();
}

class _ScheduleState extends State<ScheduleTeacher> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  List<dynamic> _timetableData = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _fetchTimetableData(_selectedDay!);
  }

  String _getFirstClassTime() {
    if (_timetableData.isEmpty) return '';
    _timetableData.sort((a, b) => a['start_time'].compareTo(b['start_time']));
    return _timetableData.first['start_time'];
  }

  String _getLastClassTime() {
    if (_timetableData.isEmpty) return '';
    _timetableData.sort((a, b) => b['end_time'].compareTo(a['end_time']));
    return _timetableData.first['end_time'];
  }

  String _calculateTotalHours() {
    if (_timetableData.isEmpty) return '0h 0m';

    _timetableData.sort((a, b) => a['start_time'].compareTo(b['start_time']));
    final firstClass = _timetableData.first;
    final lastClass = _timetableData.last;

    try {
      final startParts = firstClass['start_time'].split(':');
      final endParts = lastClass['end_time'].split(':');
      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);

      int totalMinutes = (endHour * 60 + endMin) - (startHour * 60 + startMin);
      return '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
    } catch (e) {
      return '0h 0m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: TextStyle(
                color: Color(0xFF282424),
                fontSize: 25,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // Date Info Container
            Container(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: ColorStyle.BlueStatic,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Date Box
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 0, 0, 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat(
                              'd',
                            ).format(_selectedDay ?? DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'EEE',
                            ).format(_selectedDay ?? DateTime.now()),
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

                    // Punch In/Out Info
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimeInfo(
                            _timetableData.isNotEmpty
                                ? _formatTime(_getFirstClassTime())
                                : '--:--',
                            'Punch In',
                          ),
                          _buildTimeInfo(
                            _timetableData.isNotEmpty
                                ? _formatTime(_getLastClassTime())
                                : '--:--',
                            'Punch Out',
                          ),
                          _buildTimeInfo(
                            _timetableData.isNotEmpty
                                ? _calculateTotalHours()
                                : '--:--',
                            'Total Hours',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Calendar
            Container(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              decoration: BoxDecoration(color: ColorStyle.BlueStatic),
              child: TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                headerVisible: true,
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.white70,
                    border: Border.all(color: Colors.white70),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  titleTextStyle: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Roboto',
                    fontSize: 18,
                  ),
                ),
                rowHeight: 37,
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white60),
                  weekendStyle: TextStyle(color: Colors.white60),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.white70),
                  defaultTextStyle: TextStyle(color: Colors.white70),
                  selectedTextStyle: TextStyle(color: Colors.black),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  cellPadding: const EdgeInsets.all(2),
                ),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchTimetableData(selectedDay);
                },
              ),
            ),

            const SizedBox(height: 8),

            // Class List
            Expanded(child: _buildClassList(screenWidth)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String time, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          time,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildClassList(double screenWidth) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }
    if (_timetableData.isEmpty) {
      return const Center(child: Text('No classes scheduled'));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _timetableData.length,
      itemBuilder: (context, index) {
        final classData = _timetableData[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: ColorStyle.BlueStatic,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Row(
              children: [
                // Course Name
                SizedBox(
                  width: 160, // Fixed width
                  height: 60, // Fixed height
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        classData['course_name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Class Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Room:', classData['room'] ?? 'N/A'),
                      _buildDetailRow(
                        'Status:',
                        classData['class_status'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Time:',
                        '${_formatTime(classData['start_time'])} - ${_formatTime(classData['end_time'])}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToClassDetails(Map<String, dynamic> classData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceDetailsTeacher(sessionId: 1),
      ),
    );
  }

  Future<void> _fetchTimetableData(DateTime selectedDate) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _timetableData = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken == null) throw Exception('No access token found');

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/today-attendance-report?user_type=teacher&date=$formattedDate',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> allClasses = [
          ...data['upcoming_classes'] ?? [],
          ...data['completed_classes'] ?? [],
          ...data['ongoing_classes'] ?? [],
          ...data['not_taken_classes'] ?? [],
        ];

        setState(() {
          _timetableData = allClasses;
          if (_timetableData.isEmpty) {
            _errorMessage = 'No classes scheduled for selected date';
          }
        });
      } else {
        throw Exception('Failed to load timetable: ${response.statusCode}');
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'Error loading timetable: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? time) {
    if (time == null) return 'N/A';
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute).format(context);
    } catch (e) {
      return time;
    }
  }
}
