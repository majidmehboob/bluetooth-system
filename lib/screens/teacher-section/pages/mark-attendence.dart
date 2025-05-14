import 'package:smart_track/screens/teacher-section/drawer.dart';
import 'package:smart_track/services/class-information-services.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:smart_track/widgets/snackbar-helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class MarkAttendenceTeacher extends StatefulWidget {
  final ClassInfo classData;
  const MarkAttendenceTeacher({super.key, required this.classData});

  @override
  State<MarkAttendenceTeacher> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<MarkAttendenceTeacher> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _formattedTime;
  late String _formattedDate;
  late String _formattedDay;
  final bool _switchValue = false;
  Timer? _timer;
  bool _isUpdatingAttendance = false;
  Timer? _attendancePollingTimer;
  final RangeValues _currentRangeValues = const RangeValues(100, 500);
  bool _isCreatingSession = false;
  // Session management variables
  bool _isSessionActive = false;
  bool _isSessionEnded = false;
  Map<String, dynamic>? _sessionInfo;
  bool _isLoadingSession = true;
  Map<String, dynamic> _attendanceSummary = {};
  final bool _isLoadingAttendance = false;
  bool _showSessionEndedDialog = false;
  final bool _isFirstDataLoad = true;
  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _startTimer();
    _checkSessionStatus().then((_) {
      if (_isSessionActive) {
        _startAttendancePolling();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _attendancePollingTimer?.cancel();
    super.dispose();
  }

  // Add this method to check time and show dialog
  // Update the _checkSessionEndTime method
  void _checkSessionEndTime() async {
    if (_sessionInfo == null || _sessionInfo!['end_time'] == null) return;

    try {
      final now = DateTime.now();
      final endTimeStr = _sessionInfo!['end_time'] as String;
      final endTimeParts = endTimeStr.split(':');

      // Create DateTime for today with the end time
      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      if (now.isAfter(endTime) && !_showSessionEndedDialog) {
        setState(() => _showSessionEndedDialog = true);

        // Call end session API first
        await _endAttendanceSession();

        // Then show dialog
        if (mounted) {
          _showSessionCompletedDialog();
        }
      }
    } catch (e) {
      print('Error checking session end time: $e');
    }
  }

  // Add this method to show the dialog
  void _showSessionCompletedDialog() {
    final endTime = _sessionInfo!['end_time'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Class Completed'),
            content: Text('The class session ended at $endTime.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
    );
  }

  void _startAttendancePolling() {
    // Cancel any existing timer
    _attendancePollingTimer?.cancel();

    _fetchAttendanceData();

    // Then set up periodic fetching every 2 minutes
    _attendancePollingTimer = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) {
      if (_isSessionActive && mounted) {
        _fetchAttendanceData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkSessionStatus() async {
    setState(() {
      _isLoadingSession = true;
      _showSessionEndedDialog = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      print('Checking session for class ID: ${widget.classData.id}');

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/get-attendance-session?raspberrypi_name=${widget.classData.raspberry_Pi}',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print('Session check response: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['attendance_sessions'] != null &&
            data['attendance_sessions'].isNotEmpty) {
          setState(() {
            _sessionInfo = data['attendance_sessions'][0];
            _isSessionActive = _sessionInfo?['is_active'] ?? false;
            _isSessionEnded =
                !_isSessionActive && _sessionInfo?['end_time'] != null;
          });
          print(
            'Session found - ID: ${_sessionInfo?['id']}, Active: $_isSessionActive',
          );
          if (_isSessionActive) {
            await _fetchAttendanceData();
          }
        } else {
          setState(() {
            _isSessionActive = false;
            _isSessionEnded = false;
            _sessionInfo = null;
          });
          print('No active sessions found');
        }
      } else {
        throw Exception('Failed to load session: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error checking session: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Error checking session: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
        });
      }
    }
  }

  // Replace your _createAttendanceSession with this:
  Future<void> _createAttendanceSession() async {
    if (_isCreatingSession) return; // Prevent multiple clicks

    setState(() {
      _isCreatingSession = true;
    });

    try {
      // First check if session already exists
      await _checkSessionStatus();

      if (_isSessionActive) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Session already exists');
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.post(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/create-attendance-session',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'lecture_id': widget.classData.id}),
      );

      if (response.statusCode == 201) {
        await _checkSessionStatus();
        // final data = json.decode(response.body);
        // setState(() {
        //   _sessionInfo = data;
        //   _isSessionActive = true;
        // });

        // // Start polling for attendance data
        // _startAttendancePolling();

        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Session created successfully');
        }
      } else {
        SnackbarHelper.showError(
          context,
          'Failed to create session: ${response.statusCode}',
        );
        throw Exception();
      }
    } catch (e) {
      print('Error creating session: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Failed to create session: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
        });
      }
    }
  }

  Future<void> _endAttendanceSession() async {
    if (_sessionInfo == null || !_isSessionActive) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('End Session?'),
            content: const Text(
              'Are you sure you want to end this attendance session?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'End Session',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoadingSession = true;
      _showSessionEndedDialog = false; // Reset dialog flag
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final sessionId = _sessionInfo!['id'];

      print('Ending session with ID: $sessionId');

      final response = await http.post(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/end-attendance-session?session_id=$sessionId',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print('End session response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Stop the polling timer
        _attendancePollingTimer?.cancel();

        // Navigate to home
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception('Failed to end session: ${response.statusCode}');
      }
    } catch (e) {
      print('Error ending session: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Error ending session: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
        });
      }
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (_sessionInfo == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final sessionId = _sessionInfo!['id'];

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/mark-attendance?session_id=$sessionId&request_type=all_data',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newSummary = data['attendance_summary'] ?? {};

        // Convert to a new map to ensure state change is detected
        final Map<String, dynamic> formattedSummary = {};
        newSummary.forEach((key, value) {
          formattedSummary[key.toString()] = {
            'student_name': value['student_name'] ?? 'Unknown',
            'percentage': (value['percentage'] ?? 0.0).toDouble(),
            'is_present': value['is_present'] ?? false,
            'total_records': value['total_records'] ?? 0,
          };
        });
        // Only update if data has actually changed
        if (_hasDataChanged(formattedSummary)) {
          if (mounted) {
            setState(() {
              _attendanceSummary = formattedSummary;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching attendance: $e')),
        );
      }
    }
  }

  // Helper method to detect actual data changes
  bool _hasDataChanged(Map<String, dynamic> newData) {
    if (_attendanceSummary.length != newData.length) return true;

    for (final key in newData.keys) {
      if (!_attendanceSummary.containsKey(key) ||
          _attendanceSummary[key]?['is_present'] !=
              newData[key]['is_present'] ||
          _attendanceSummary[key]?['percentage'] !=
              newData[key]['percentage']) {
        return true;
      }
    }
    return false;
  }

  Future<void> _updateTeacherAttendance(
    String registrationNumber,
    bool isPresent,
  ) async {
    if (_sessionInfo == null || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.post(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/teacher-update-attendance?session_id=${_sessionInfo!['id']}',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'registration_number': registrationNumber,
          'is_present_by_teacher': isPresent,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh data after successful update
        await _fetchAttendanceData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_attendanceSummary[registrationNumber]?['student_name']} marked as ${isPresent ? 'Present' : 'Absent'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(
          'Failed to update attendance: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert the UI change
        setState(() {
          _attendanceSummary[registrationNumber]?['is_present'] = !isPresent;
        });
        SnackbarHelper.showError(
          context,
          'Failed to update attendance: ${e.toString()}',
        );
      }
    }
  }
  // Future<void> _fetchAttendanceData() async {
  //   if (_sessionInfo == null) return;

  //   setState(() {
  //     _isLoadingAttendance = true;
  //   });

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final accessToken = prefs.getString('accessToken');
  //     final sessionId = _sessionInfo!['id'];

  //     print('Fetching attendance for session ID: $sessionId');

  //     final response = await http.get(
  //       Uri.parse(
  //         'https://bluetooth-attendence-system.tech-vikings.com/dashboard/mark-attendance?session_id=$sessionId',
  //       ),
  //       headers: {'Authorization': 'Bearer $accessToken'},
  //     );

  //     print('Attendance response: ${response.statusCode}');
  //     print('Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       // Convert all keys to strings
  //       final summary = (data['attendance_summary'] as Map).map(
  //         (key, value) => MapEntry(key.toString(), value),
  //       );
  //       setState(() {
  //         _attendanceSummary = summary;
  //       });
  //       // setState(() {
  //       //   _attendanceSummary = data['attendance_summary'] ?? {};
  //       // });
  //       print('Attendance data loaded: ${_attendanceSummary.length} records');
  //     } else {
  //       throw Exception('Failed to fetch attendance: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error fetching attendance: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error fetching attendance: $e')),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoadingAttendance = false;
  //       });
  //     }
  //   }
  // }

  String _parseDateTime(dynamic dateTime) {
    try {
      if (dateTime is String) {
        if (dateTime.contains('T')) {
          return DateFormat('hh:mm a').format(DateTime.parse(dateTime));
        } else {
          final timeParts = dateTime.split(':');
          if (timeParts.length >= 2) {
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            final now = DateTime.now();
            final dt = DateTime(now.year, now.month, now.day, hour, minute);
            return DateFormat('hh:mm a').format(dt);
          }
        }
      }
      return 'Invalid time';
    } catch (e) {
      return 'Invalid time';
    }
  }

  void _updateDateTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _formattedTime = DateFormat('hh:mm a').format(now);
      _formattedDate = DateFormat('MMM d, yyyy').format(now);
      _formattedDay = DateFormat('EEEE').format(now);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateDateTime();
        _checkSessionEndTime();
      }
    });
  }

  Widget _buildSessionShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 150, height: 20, color: Colors.white),
                Container(width: 50, height: 20, color: Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 6, color: Colors.white),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 100, height: 16, color: Colors.white),
                Container(width: 80, height: 16, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    if (_isLoadingSession) {
      return _buildSessionShimmer();
    }

    if (!_isSessionActive && !_isSessionEnded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No active session',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: _createAttendanceSession,
            //   child: const Text('Start New Session'),
            // ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_isSessionEnded || _isSessionActive)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingAttendance)
                  const Center(child: CircularProgressIndicator())
                else if (_attendanceSummary.isEmpty)
                  const Center(child: Text('No attendance data available'))
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchAttendanceData,
                      child: ListView.builder(
                        itemCount: _attendanceSummary.length,
                        itemBuilder: (context, index) {
                          final entry = _attendanceSummary.entries.elementAt(
                            index,
                          );
                          final rollNumber =
                              entry.key.toString(); // Ensure this is a string
                          final data = entry.value as Map<String, dynamic>;

                          // Ensure percentage is between 0 and 100
                          double percentage =
                              (data['percentage'] ?? 0).toDouble();
                          percentage = percentage.clamp(0.0, 100.0);
                          // final entry = _attendanceSummary.entries.elementAt(
                          //   index,
                          // );
                          // final rollNumber = entry.key;
                          // final data = entry.value as Map<String, dynamic>;

                          // // Ensure percentage is between 0 and 100
                          // double percentage =
                          //     (data['percentage'] ?? 0).toDouble();
                          // percentage = percentage.clamp(0.0, 100.0);

                          return Container(
                            height: 200,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _isSessionActive
                                        ? ColorStyle.BlueStatic
                                        : Colors.grey,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['student_name'] ?? 'UnKnown',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          rollNumber,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF293646),
                                          ),
                                        ),

                                        const SizedBox(height: 4),
                                        Text(
                                          'Section ${_sessionInfo?['section_name'].toString().toUpperCase() ?? widget.classData.section}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6A7D94),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      activeColor: ColorStyle.BlueStatic,
                                      activeTrackColor: Colors.grey[200],
                                      inactiveThumbColor: ColorStyle.BlueStatic,
                                      inactiveTrackColor: Colors.grey[200],
                                      value: data['is_present'] ?? false,
                                      onChanged:
                                          _isUpdatingAttendance
                                              ? null
                                              : (value) async {
                                                // Show confirmation dialog
                                                final confirmed = await showDialog<
                                                  bool
                                                >(
                                                  context: context,
                                                  builder:
                                                      (context) => AlertDialog(
                                                        title: Text(
                                                          'Mark ${data['student_name']} as ${value ? 'Present' : 'Absent'}?',
                                                        ),
                                                        content: Text(
                                                          'Are you sure you want to update attendance status for ${data['student_name']}?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                            child: const Text(
                                                              'Cancel',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                            child: Text(
                                                              'Confirm',
                                                              style: TextStyle(
                                                                color:
                                                                    ColorStyle
                                                                        .BlueStatic,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );

                                                if (confirmed == true &&
                                                    mounted) {
                                                  // Show loading state
                                                  setState(() {
                                                    _attendanceSummary[rollNumber]?['is_present'] =
                                                        value;
                                                    _isUpdatingAttendance =
                                                        true;
                                                  });

                                                  // Call API to update attendance
                                                  await _updateTeacherAttendance(
                                                    rollNumber,
                                                    value,
                                                  );

                                                  if (mounted) {
                                                    setState(
                                                      () =>
                                                          _isUpdatingAttendance =
                                                              false,
                                                    );
                                                  }
                                                }
                                              }, // Make switch read-only
                                    ),
                                    // CustomSwitch(
                                    //   value: data['is_present'] ?? false,
                                    //   onChanged:
                                    //       (value) {}, // Make switch read-only
                                    // ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    disabledActiveTrackColor:
                                        ColorStyle.BlueStatic, // Add this
                                    disabledInactiveTickMarkColor:
                                        Colors.grey[200],
                                    trackHeight: 6,

                                    disabledThumbColor: ColorStyle.BlueStatic,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 10,
                                      disabledThumbRadius: 10,
                                    ),
                                    // overlayColor: Colors.purple.withAlpha(32),
                                    // overlayShape: RoundSliderOverlayShape(
                                    // overlayRadius: 14.0,
                                    // ),
                                    // inactiveTickMarkColor: Colors.grey[400],
                                    // activeTickMarkColor:
                                    //     ColorStyle
                                    //         .BlueStatic, // Add this for better visibility
                                  ),
                                  child: Slider(
                                    value: percentage,
                                    min: 0,
                                    max: 100,
                                    divisions: 10,
                                    label: '${percentage.toStringAsFixed(1)}%',
                                    onChanged: null,
                                    // activeColor: ColorStyle.BlueStatic,
                                    // inactiveColor: Colors.grey[300],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(data['total_records'].toString()),
                                    Text(data['percentage'].toString() ?? '00'),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(
        backgroundColor: Colors.white,
        iconColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          // Header with Time and Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Roboto',
                    color: Color(0xFF293646),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_formattedDate - $_formattedDay',
                  style: const TextStyle(
                    color: Color(0xFF6A7D94),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          // Session Button
          GestureDetector(
            onLongPress: _isSessionActive ? _endAttendanceSession : null,
            onTap:
                !_isSessionActive && !_isCreatingSession
                    ? _createAttendanceSession
                    : null,
            child: Center(
              child: Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(110),
                  color:
                      _isCreatingSession
                          ? Colors.grey
                          : _isSessionActive
                          ? Colors.blue
                          : _isSessionEnded
                          ? Colors.grey
                          : const Color(0xFF9CCAF9),
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(6.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFCFE2F8),
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB7D4F6),
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 70,
                      color:
                          _isSessionActive
                              ? Colors.white
                              : _isSessionEnded
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Debug information
          Text(
            'Class ID: ${widget.classData.id}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (_sessionInfo != null)
            Text(
              'Session ID: ${_sessionInfo!['id']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          const SizedBox(height: 10),
          // Status text
          if (_isLoadingSession)
            const Text(
              'Loading session...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            )
          else if (_isSessionActive)
            Column(
              children: [
                const Text(
                  'Session is active',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
                const Text(
                  'Long press to end session',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            )
          else if (_isSessionEnded)
            const Text(
              'Session has ended',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            )
          else
            const Text(
              'Session is not active',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          const SizedBox(height: 10),
          // Session Info and Attendance List
          Expanded(child: _buildSessionInfo()),
        ],
      ),
    );
  }
}
// import 'package:fyp_2025/pages/drawer/teacher_drawer.dart';
// import 'package:fyp_2025/utils/ClassInfo.dart';
// import 'package:fyp_2025/widgets/customSwitch.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:shimmer/shimmer.dart';
// import 'dart:async';

// class BluetoothScreen extends StatefulWidget {
//   final ClassInfo classData;
//   const BluetoothScreen({super.key, required this.classData});

//   @override
//   State<BluetoothScreen> createState() => _BluetoothScreenState();
// }

// class _BluetoothScreenState extends State<BluetoothScreen> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   late String _formattedTime;
//   late String _formattedDate;
//   late String _formattedDay;
//   bool _switchValue = false;
//   Timer? _timer;
//   RangeValues _currentRangeValues = const RangeValues(100, 500);

//   // Session management variables
//   bool _isSessionActive = false;
//   bool _isSessionEnded = false;
//   Map<String, dynamic>? _sessionInfo;
//   bool _isLoadingSession = true;
//   Map<String, dynamic> _attendanceSummary = {};
//   bool _isLoadingAttendance = false;

//   @override
//   void initState() {
//     super.initState();
//     _updateDateTime();
//     _startTimer();
//     _checkSessionStatus();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   Future<void> _checkSessionStatus() async {
//     setState(() {
//       _isLoadingSession = true;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('accessToken');

//       if (accessToken == null) {
//         throw Exception('No access token found');
//       }

//       print('Checking session for class ID: ${widget.classData.id}');

//       final response = await http.get(
//         Uri.parse(
//           'https://bluetooth-attendence-system.tech-vikings.com/dashboard/get-attendance-session?lecture_id=${widget.classData.id}',
//         ),
//         headers: {'Authorization': 'Bearer $accessToken'},
//       );

//       print('Session check response: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['attendance_sessions'] != null &&
//             data['attendance_sessions'].isNotEmpty) {
//           setState(() {
//             _sessionInfo = data['attendance_sessions'][0];
//             _isSessionActive = _sessionInfo?['is_active'] ?? false;
//             _isSessionEnded =
//                 !_isSessionActive && _sessionInfo?['end_time'] != null;
//           });
//           print(
//             'Session found - ID: ${_sessionInfo?['id']}, Active: $_isSessionActive',
//           );
//           if (_isSessionActive) {
//             await _fetchAttendanceData();
//           }
//         } else {
//           setState(() {
//             _isSessionActive = false;
//             _isSessionEnded = false;
//             _sessionInfo = null;
//           });
//           print('No active sessions found');
//         }
//       } else {
//         throw Exception('Failed to load session: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error checking session: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error checking session: $e')));
//     } finally {
//       setState(() {
//         _isLoadingSession = false;
//       });
//     }
//   }

//   Future<void> _createAttendanceSession() async {
//     setState(() {
//       _isLoadingSession = true;
//       _isSessionEnded = false;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('accessToken');

//       if (accessToken == null) {
//         throw Exception('No access token found');
//       }

//       final requestBody = {'lecture_id': widget.classData.id};

//       print('Creating session with body: $requestBody');

//       final response = await http.post(
//         Uri.parse(
//           'https://bluetooth-attendence-system.tech-vikings.com/dashboard/create-attendance-session',
//         ),
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       print('Create session response: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         if (data['id'] != null) {
//           setState(() {
//             _sessionInfo = data;
//             _isSessionActive = true;
//           });
//           print('Session created successfully - ID: ${data['id']}');
//           await _fetchAttendanceData();
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Session created successfully')),
//           );
//         } else {
//           throw Exception('Invalid session data received');
//         }
//       } else {
//         throw Exception(
//           'Failed to create session: ${response.statusCode} - ${response.body}',
//         );
//       }
//     } catch (e) {
//       print('Error creating session: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error creating session: $e')));
//     } finally {
//       setState(() {
//         _isLoadingSession = false;
//       });
//     }
//   }

//   Future<void> _endAttendanceSession() async {
//     if (_sessionInfo == null || !_isSessionActive) return;

//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('End Session?'),
//             content: const Text(
//               'Are you sure you want to end this attendance session?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: const Text(
//                   'End Session',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );

//     if (confirmed != true) return;

//     setState(() {
//       _isLoadingSession = true;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('accessToken');
//       final sessionId = _sessionInfo!['id'];

//       print('Ending session with ID: $sessionId');

//       final response = await http.post(
//         Uri.parse(
//           'https://bluetooth-attendence-system.tech-vikings.com/dashboard/end-attendance-session?session_id=$sessionId',
//         ),
//         headers: {'Authorization': 'Bearer $accessToken'},
//       );

//       print('End session response: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         setState(() {
//           _isSessionActive = false;
//           _isSessionEnded = true;
//         });
//         await _checkSessionStatus();
//         await _fetchAttendanceData();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Session ended successfully')),
//         );
//       } else {
//         throw Exception('Failed to end session: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error ending session: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error ending session: $e')));
//     } finally {
//       setState(() {
//         _isLoadingSession = false;
//       });
//     }
//   }

//   Future<void> _fetchAttendanceData() async {
//     if (_sessionInfo == null) return;

//     setState(() {
//       _isLoadingAttendance = true;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('accessToken');
//       final sessionId = _sessionInfo!['id'];

//       print('Fetching attendance for session ID: $sessionId');

//       final response = await http.get(
//         Uri.parse(
//           'https://bluetooth-attendence-system.tech-vikings.com/dashboard/mark-attendance?session_id=$sessionId',
//         ),
//         headers: {'Authorization': 'Bearer $accessToken'},
//       );

//       print('Attendance response: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _attendanceSummary = data['attendance-summary'] ?? {};
//         });
//         print('Attendance data loaded: ${_attendanceSummary.length} records');
//       } else {
//         throw Exception('Failed to fetch attendance: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching attendance: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error fetching attendance: $e')));
//     } finally {
//       setState(() {
//         _isLoadingAttendance = false;
//       });
//     }
//   }

//   String _parseDateTime(dynamic dateTime) {
//     try {
//       if (dateTime is String) {
//         if (dateTime.contains('T')) {
//           return DateFormat('hh:mm a').format(DateTime.parse(dateTime));
//         } else {
//           final timeParts = dateTime.split(':');
//           if (timeParts.length >= 2) {
//             final hour = int.parse(timeParts[0]);
//             final minute = int.parse(timeParts[1]);
//             final now = DateTime.now();
//             final dt = DateTime(now.year, now.month, now.day, hour, minute);
//             return DateFormat('hh:mm a').format(dt);
//           }
//         }
//       }
//       return 'Invalid time';
//     } catch (e) {
//       return 'Invalid time';
//     }
//   }

//   void _updateDateTime() {
//     final DateTime now = DateTime.now();
//     setState(() {
//       _formattedTime = DateFormat('hh:mm a').format(now);
//       _formattedDate = DateFormat('MMM d, yyyy').format(now);
//       _formattedDay = DateFormat('EEEE').format(now);
//     });
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _updateDateTime();
//     });
//   }

//   Widget _buildSessionShimmer() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         height: 180,
//         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         padding: const EdgeInsets.all(12.0),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey, width: 1.5),
//         ),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(width: 150, height: 20, color: Colors.white),
//                 Container(width: 50, height: 20, color: Colors.white),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Container(width: double.infinity, height: 6, color: Colors.white),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(width: 100, height: 16, color: Colors.white),
//                 Container(width: 80, height: 16, color: Colors.white),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSessionInfo() {
//     if (_isLoadingSession) {
//       return _buildSessionShimmer();
//     }

//     if (!_isSessionActive && !_isSessionEnded) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'No active session',
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _createAttendanceSession,
//               child: const Text('Start New Session'),
//             ),
//           ],
//         ),
//       );
//     }

//     return Column(
//       children: [
//         if (_isSessionEnded || _isSessionActive)
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (_isLoadingAttendance)
//                   const Center(child: CircularProgressIndicator())
//                 else if (_attendanceSummary.isEmpty)
//                   const Center(child: Text('No attendance data available'))
//                 else
//                   Expanded(
//                     child: RefreshIndicator(
//                       onRefresh: _fetchAttendanceData,
//                       child: ListView.builder(
//                         itemCount: _attendanceSummary.length,
//                         itemBuilder: (context, index) {
//                           final entry = _attendanceSummary.entries.elementAt(
//                             index,
//                           );
//                           final rollNumber = entry.key;
//                           final data = entry.value as Map<String, dynamic>;

//                           // Ensure percentage is between 0 and 100
//                           double percentage =
//                               (data['percentage'] ?? 0).toDouble();
//                           percentage = percentage.clamp(0.0, 100.0);

//                           return Container(
//                             height: 180,
//                             margin: const EdgeInsets.symmetric(
//                               horizontal: 20,
//                               vertical: 10,
//                             ),
//                             padding: const EdgeInsets.all(12.0),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color:
//                                     _isSessionActive
//                                         ? Colors.blue
//                                         : Colors.grey,
//                                 width: 1.5,
//                               ),
//                             ),
//                             child: Column(
//                               children: [
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           'Roll No: $rollNumber',
//                                           style: const TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold,
//                                             color: Color(0xFF293646),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           'Section ${_sessionInfo?['section_name'] ?? widget.classData.section}',
//                                           style: const TextStyle(
//                                             fontSize: 14,
//                                             color: Color(0xFF6A7D94),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     CustomSwitch(
//                                       value: data['is_present'] ?? false,
//                                       onChanged:
//                                           (value) {}, // Make switch read-only
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),
//                                 SliderTheme(
//                                   data: SliderTheme.of(context).copyWith(
//                                     trackHeight: 8,
//                                     activeTrackColor: Colors.blue,
//                                     inactiveTrackColor: Colors.grey[300],
//                                     thumbColor: Colors.blue,
//                                     thumbShape: const RoundSliderThumbShape(
//                                       enabledThumbRadius: 10,
//                                     ),
//                                     overlayColor: Colors.blue.withAlpha(32),
//                                   ),
//                                   child: Column(
//                                     children: [
//                                       Slider(
//                                         value: percentage,
//                                         min: 0,
//                                         max: 100,
//                                         divisions: 10,
//                                         label:
//                                             '${percentage.toStringAsFixed(1)}%',
//                                         onChanged:
//                                             null, // Make slider read-only
//                                       ),
//                                       Text(
//                                         'Status: ${data['is_present'] ? 'Present' : 'Absent'}',
//                                         style: const TextStyle(
//                                           fontSize: 12,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: CustomDrawer(
//         backgroundColor: Colors.white,
//         iconColor: Colors.black,
//       ),
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: () {
//             _scaffoldKey.currentState?.openDrawer();
//           },
//         ),
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 15),
//           // Header with Time and Date
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20.0),
//             child: Column(
//               children: [
//                 Text(
//                   _formattedTime,
//                   style: const TextStyle(
//                     fontSize: 50,
//                     fontWeight: FontWeight.w300,
//                     fontFamily: 'Roboto',
//                     color: Color(0xFF293646),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '$_formattedDate - $_formattedDay',
//                   style: const TextStyle(
//                     color: Color(0xFF6A7D94),
//                     fontSize: 14,
//                     fontFamily: 'Roboto',
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 30),
//           // Session Button
//           GestureDetector(
//             onLongPress: _isSessionActive ? _endAttendanceSession : null,
//             child: Center(
//               child: Container(
//                 width: 180,
//                 height: 180,
//                 padding: const EdgeInsets.all(18.0),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(110),
//                   color:
//                       _isSessionActive
//                           ? Colors.blue
//                           : _isSessionEnded
//                           ? Colors.grey
//                           : const Color(0xFF9CCAF9),
//                 ),
//                 child: Container(
//                   width: 90,
//                   height: 90,
//                   padding: const EdgeInsets.all(6.0),
//                   decoration: const BoxDecoration(
//                     color: Color(0xFFCFE2F8),
//                     borderRadius: BorderRadius.all(Radius.circular(100)),
//                   ),
//                   child: Container(
//                     width: 80,
//                     height: 80,
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFB7D4F6),
//                       borderRadius: BorderRadius.all(Radius.circular(100)),
//                     ),
//                     child: Icon(
//                       Icons.calendar_today,
//                       size: 70,
//                       color:
//                           _isSessionActive
//                               ? Colors.white
//                               : _isSessionEnded
//                               ? Colors.white
//                               : Colors.black,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           // Debug information
//           Text(
//             'Class ID: ${widget.classData.id}',
//             style: const TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//           if (_sessionInfo != null)
//             Text(
//               'Session ID: ${_sessionInfo!['id']}',
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           const SizedBox(height: 10),
//           // Status text
//           if (_isLoadingSession)
//             const Text(
//               'Loading session...',
//               style: TextStyle(color: Colors.grey, fontSize: 16),
//             )
//           else if (_isSessionActive)
//             Column(
//               children: [
//                 const Text(
//                   'Session is active',
//                   style: TextStyle(color: Colors.blue, fontSize: 16),
//                 ),
//                 const Text(
//                   'Long press to end session',
//                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             )
//           else if (_isSessionEnded)
//             const Text(
//               'Session has ended',
//               style: TextStyle(color: Colors.grey, fontSize: 16),
//             )
//           else
//             const Text(
//               'Session is not active',
//               style: TextStyle(color: Colors.grey, fontSize: 16),
//             ),
//           const SizedBox(height: 10),
//           // Session Info and Attendance List
//           Expanded(child: _buildSessionInfo()),
//         ],
//       ),
//     );
//   }
// }
