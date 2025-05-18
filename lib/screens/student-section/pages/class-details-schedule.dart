import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClassDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassDetailsScreen({super.key, required this.classData});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  Map<String, dynamic>? _attendanceData;
  bool _isLoadingAttendance = false;
  String _attendanceError = '';

  @override
  void initState() {
    super.initState();
    print("--------------------------------------------");
    print(widget.classData);
    if (widget.classData['class_status']?.toString().toLowerCase() ==
        'completed') {
      _fetchAttendanceDetails();
    }
  }

  Future<void> _fetchAttendanceDetails() async {
    setState(() {
      _isLoadingAttendance = true;
      _attendanceError = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final registrationNumber = prefs.getString('registrationNumber');

      if (accessToken == null || registrationNumber == null) {
        throw Exception('Missing required credentials');
      }

      final sessionId = widget.classData['attendance_session_id']?.toString();
      if (sessionId == null) {
        throw Exception('Session ID not found');
      }

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/mark-attendance?'
          'session_id=$sessionId&'
          'request_type=single_student&'
          'registration_number=$registrationNumber',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _attendanceData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _attendanceError = 'Error loading attendance: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        widget.classData['class_status']?.toString().toLowerCase() ==
        'completed';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData['course_name'] ?? 'Class Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard('Course Name', widget.classData['course_name']),
              _buildDetailCard('Instructor', widget.classData['instructor']),
              _buildDetailCard('Room', widget.classData['room']),
              _buildDetailCard(
                'Section',
                widget.classData['section']?.toString(),
              ),
              _buildDetailCard('Status', widget.classData['class_status']),
              _buildDetailCard(
                'Time',
                '${_formatTime(context, widget.classData['start_time'])} - ${_formatTime(context, widget.classData['end_time'])}',
              ),

              if (isCompleted) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Attendance Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (_isLoadingAttendance)
                  const Center(child: CircularProgressIndicator()),
                if (_attendanceError.isNotEmpty)
                  Text(
                    _attendanceError,
                    style: const TextStyle(color: Colors.red),
                  ),

                if (_attendanceData != null) ...[
                  _buildAttendanceSummary(
                    _attendanceData!['attendance_summary'],
                  ),
                  const SizedBox(height: 16),
                  ..._buildAttendanceRecords(
                    _attendanceData!['attendance_records'],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary(Map<String, dynamic> summary) {
    return Card(
      color:
          summary['overall_present'] == true
              ? Colors.green[50]
              : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Final Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    summary['overall_present'] == true ? 'Present' : 'Absent',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor:
                      summary['overall_present'] == true
                          ? Colors.green
                          : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Scans:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(summary['total_records'].toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Successful Scans:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(summary['present_records'].toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Percentage:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${summary['attendance_percentage']}%'),
              ],
            ),
            if (summary['teacher_override'] == true) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Teacher override applied',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAttendanceRecords(List<dynamic> records) {
    return [
      const Text(
        'Scan History:',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      ...records.map(
        (record) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${record['scanned_time']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Chip(
                      label: Text(
                        record['method'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor:
                          record['method'] == 'teacher'
                              ? Colors.blue
                              : Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Status: '),
                    Text(
                      record['is_present'] == true ? 'Present' : 'Absent',
                      style: TextStyle(
                        color:
                            record['is_present'] == true
                                ? Colors.green
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (record['is_present_by_teacher'] == true) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.gavel, color: Colors.orange, size: 16),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildDetailCard(String label, String? value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, String? time) {
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
