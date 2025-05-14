import 'package:flutter/material.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:smart_track/widgets/search-bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class AttendanceDetailsTeacher extends StatefulWidget {
  final int sessionId;

  const AttendanceDetailsTeacher({super.key, required this.sessionId});

  @override
  State<AttendanceDetailsTeacher> createState() =>
      _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsTeacher> {
  Map<String, dynamic> _attendanceSummary = {};
  bool _isLoadingAttendance = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoadingAttendance = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final sessionId = widget.sessionId;

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/mark-attendance?session_id=$sessionId&request_type=all_data',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _attendanceSummary = data['attendance_summary'] ?? {};
        });
      } else {
        throw Exception('Failed to fetch attendance: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching attendance: $e';
      });
    } finally {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  Map<String, dynamic> get _filteredAttendance {
    if (_searchQuery.isEmpty) {
      return _attendanceSummary;
    }

    final filtered =
        _attendanceSummary.entries.where((entry) {
          final rollNumber = entry.key.toLowerCase();
          final studentName =
              (entry.value['student_name'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();

          return rollNumber.contains(query) || studentName.contains(query);
        }).toList();

    return filtered.isNotEmpty
        ? Map.fromEntries(filtered)
        : {}; // Return empty map if no matches
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorStyle.BlueStatic,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Attendance Details',
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAttendanceData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                if (_isLoadingAttendance)
                  _buildShimmerLoading()
                else if (_attendanceSummary.isEmpty)
                  const Center(
                    child: Text(
                      'No attendance data available',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else ...[
                  const SizedBox(height: 20),
                  searchbar(
                    'Search Student',
                    const Color(0xF1F1F1F1),
                    Icons.search,
                    (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_filteredAttendance.isEmpty && _searchQuery.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Text(
                        'No matching students found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  else
                    ..._buildAttendanceList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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

  List<Widget> _buildAttendanceList() {
    return _filteredAttendance.entries.map((entry) {
      final rollNumber = entry.key;
      final data = entry.value as Map<String, dynamic>;
      double percentage = (data['percentage'] ?? 0).toDouble();
      percentage = percentage.clamp(0.0, 100.0);

      return Container(
        height: 190,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black45, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['student_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      rollNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                Switch(
                  inactiveThumbColor: Colors.white,
                  activeTrackColor: Colors.green[200],
                  inactiveTrackColor: Colors.red[200],
                  value: data['is_present'] ?? false,
                  onChanged: null, // Make switch read-only
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                disabledActiveTrackColor:
                    percentage >= 75 ? Colors.green : Colors.red,
                disabledInactiveTrackColor: Colors.black12,
                disabledThumbColor:
                    percentage >= 75 ? Colors.green[200] : Colors.red[200],
                thumbShape: const RoundSliderThumbShape(
                  disabledThumbRadius: 10,
                ),
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: percentage,
                min: 0,
                max: 100,
                divisions: 10,
                label: '${percentage.toStringAsFixed(1)}%',
                onChanged: null, // Make slider read-only
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: data['is_present'] ? Colors.green : Colors.red,
                  ),
                  child: Text(
                    data['is_present'] ? 'present' : 'absent',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Records: ${data['total_records'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Override: ${data['teacher_override'] ? "Yes" : "No"}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
