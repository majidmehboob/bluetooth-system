import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_track/features/api-section/student.dart';
import 'package:smart_track/screens/student-section/drawer.dart';
import 'package:smart_track/screens/student-section/pages/graph-subject.dart';

class EnrollSubjectGraphStudent extends StatefulWidget {
  const EnrollSubjectGraphStudent({super.key});

  @override
  _AttendanceReportState createState() => _AttendanceReportState();
}

class _AttendanceReportState extends State<EnrollSubjectGraphStudent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<dynamic> attendanceReport = [];
  Map<String, dynamic> semesterInfo = {};
  int totalClasses = 0;
  int presentDays = 0;
  int? selectedIndex; // Track which subject is selected

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    try {
      final response = await ClassApiService.fetchSemesterAttendanceReport();
      print(response);
      print(":::::::::::::::::::::::::::::::::::::::");
      setState(() {
        attendanceReport = response['attendance_report'];
        semesterInfo = response['semester_info'];

        // Calculate totals
        totalClasses = attendanceReport.fold(
          0,
          (sum, course) => sum + (course['total_sessions'] as int),
        );
        presentDays = attendanceReport.fold(
          0,
          (sum, course) => sum + (course['present_sessions'] as int),
        );

        // Select the first course by default
        if (attendanceReport.isNotEmpty) {
          selectedIndex = 0;
        }

        _isLoading = false;
      });
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

  void _handleBarClick(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final absentDays = totalClasses - presentDays;
    final double overallAttendancePercentage =
        totalClasses > 0 ? (presentDays / totalClasses) * 100 : 0;

    // Get selected subject data if available
    final selectedSubject =
        selectedIndex != null ? attendanceReport[selectedIndex!] : null;
    final selectedAttendancePercentage =
        selectedSubject != null
            ? (selectedSubject['attendance_percentage'] as num).toDouble()
            : overallAttendancePercentage;
    final selectedPresentDays =
        selectedSubject != null
            ? selectedSubject['present_sessions'] as int
            : presentDays;
    final selectedAbsentDays =
        selectedSubject != null
            ? (selectedSubject['total_sessions'] as int) - selectedPresentDays
            : absentDays;
    final selectedTotalClasses =
        selectedSubject != null
            ? selectedSubject['total_sessions'] as int
            : totalClasses;

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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        'Check Attendance Report',
                        style: TextStyle(
                          color: Color(0xFF282424),
                          fontSize: 25,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Semester ${semesterInfo['number']} - ${semesterInfo['degree']['name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Attendance Graph
                    const Spacer(),
                    AspectRatio(
                      aspectRatio: 2,
                      child: BarChart(
                        BarChartData(
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchCallback: (
                              FlTouchEvent event,
                              BarTouchResponse? response,
                            ) {
                              if (response == null || event is! FlTapUpEvent) {
                                return;
                              }
                              final tappedIndex =
                                  response.spot?.touchedBarGroupIndex;
                              if (tappedIndex != null) {
                                _handleBarClick(tappedIndex);
                              }
                            },
                          ),
                          barGroups: List.generate(
                            attendanceReport.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                      (attendanceReport[index]['attendance_percentage']
                                              as num)
                                          .toDouble(),
                                  color: _getBarColor(
                                    index,
                                  ), // Use helper function to determine color
                                  width: 30,
                                  borderRadius: BorderRadius.zero,
                                ),
                              ],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < attendanceReport.length) {
                                    final courseCode =
                                        attendanceReport[value
                                            .toInt()]['course_code'];
                                    return GestureDetector(
                                      onTap:
                                          () => _handleBarClick(value.toInt()),
                                      child: Text(
                                        courseCode.length > 2
                                            ? courseCode.substring(0, 2)
                                            : courseCode,
                                        style: TextStyle(
                                          color: const Color(0xFF868686),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const Text('');
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: true),
                          alignment: BarChartAlignment.center,
                          maxY:
                              attendanceReport.isNotEmpty
                                  ? attendanceReport
                                      .map(
                                        (e) =>
                                            (e['attendance_percentage'] as num)
                                                .toDouble(),
                                      )
                                      .reduce((a, b) => a > b ? a : b)
                                  : 100,
                          minY: 0,
                        ),
                      ),
                    ),
                    const Spacer(),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            flex: 1,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: selectedAttendancePercentage,
                                      color: const Color(0xFFB2CCDF),
                                      radius: 60,
                                      title:
                                          '${selectedAttendancePercentage.toStringAsFixed(1)}%',
                                      titleStyle: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: 100 - selectedAttendancePercentage,
                                      color: Colors.grey.shade300,
                                      radius: 60,
                                      title: '',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedSubject != null
                                          ? selectedSubject['course_name']
                                          : 'Overall Attendance',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Total Classes"),
                                        Text("$selectedTotalClasses"),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Present Days"),
                                        Text("$selectedPresentDays"),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Absent Days"),
                                        Text("$selectedAbsentDays"),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (selectedSubject != null)
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                    context,
                                                  ) => SingleSubjectGraphStudent(
                                                    semesterId:
                                                        selectedSubject['semester_id'],
                                                    courseId:
                                                        selectedSubject['course_id'],
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStateProperty.resolveWith<
                                                Color
                                              >((states) {
                                                // Use red for <= 75%, green for > 75%
                                                return selectedAttendancePercentage <=
                                                        75
                                                    ? Colors.red[700]!
                                                    : Colors.green[700]!;
                                              }),
                                          padding: WidgetStateProperty.all<
                                            EdgeInsets
                                          >(
                                            EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                          shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder
                                          >(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'View Details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer Message
                    Text(
                      selectedAttendancePercentage >= 75
                          ? "Keep Up the Good Work!"
                          : "You need to improve your attendance!",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Update the _getBarColor method:
  Color _getBarColor(int index) {
    final attendance =
        (attendanceReport[index]['attendance_percentage'] as num).toDouble();

    // Only apply red/green to the selected bar
    if (index == selectedIndex) {
      return attendance <= 75 ? Colors.red[700]! : Colors.green[700]!;
    }

    // Keep original colors for unselected bars
    return index % 2 == 0 ? const Color(0xFF80A7D5) : const Color(0xFF1C2C3F);
  }
}
