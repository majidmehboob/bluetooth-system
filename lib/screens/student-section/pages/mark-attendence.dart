import 'dart:async';
import 'dart:io';
import 'package:smart_track/screens/student-section/main.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:smart_track/services/class-information-services.dart';
import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_track/screens/student-section/drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_track/services/time-helper.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MarkAttendenceStudent extends StatefulWidget {
  final ClassInfo classData;
  final int? sessionId;

  const MarkAttendenceStudent({
    super.key,
    required this.classData,
    this.sessionId,
  });

  @override
  State<MarkAttendenceStudent> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<MarkAttendenceStudent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  final BeaconBroadcast beaconBroadcast = BeaconBroadcast();

  bool _isAdvertising = false;
  bool _isLoading = false;
  String _errorMessage = '';
  late String _formattedTime;
  late String _formattedDate;
  late String _formattedDay;
  Timer? _timer;
  String _deviceInfo = '';
  Timer? _attendanceTimer;
  Map<String, dynamic>? _attendanceData;
  bool _showAttendanceDialog = false;
  String _registrationNumber = '';
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _updateDateTime();
    _startTimer();
    _initBluetooth();
    _getDeviceInfo();
    _loadRegistrationNumber();
    _checkSessionStatus();
    // Listen to advertising state changes
    beaconBroadcast.getAdvertisingStateChange().listen((state) {
      print(state);
      setState(() {
        _isAdvertising = state;
      });
    });
  }

  Future<void> _loadRegistrationNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _registrationNumber = prefs.getString('registrationNumber') ?? '';
    });
  }

  Future<void> _checkSessionStatus() async {
    _attendanceTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchAttendanceData();
    });
  }

  Future<void> _fetchAttendanceData() async {
    if (widget.sessionId == null || _registrationNumber.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/mark-attendance?session_id=${widget.sessionId}&request_type=single_student&registration_number=$_registrationNumber',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      print("---------------------------------------------------");
      print("---------------  $response ------------------------");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _attendanceData = data;
        });

        // Check if class time has ended
        _checkClassEndTime(data);
      } else {
        throw Exception('Failed to load attendance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
    }
  }

  void _checkClassEndTime(Map<String, dynamic> attendanceData) {
    final sessionInfo = attendanceData['session_info'];
    if (sessionInfo != null && sessionInfo['status'] == 'completed') {
      // Show attendance summary dialog
      setState(() {
        _showAttendanceDialog = true;
      });
    }
  }

  Future<void> _showAttendanceSummary() async {
    if (_attendanceData == null) return;

    final summary = _attendanceData!['attendance_summary'];
    final sessionInfo = _attendanceData!['session_info'];
    final studentInfo = _attendanceData!['student_info'];

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Attendance Summary'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${studentInfo['name']}'),
                Text('Registration: ${studentInfo['registration_number']}'),
                const SizedBox(height: 16),
                Text('Course: ${sessionInfo['course']}'),
                Text('Date: ${sessionInfo['date']}'),
                const SizedBox(height: 16),
                Text('Total Records: ${summary['total_records']}'),
                Text(
                  'Attendance Percentage: ${summary['attendance_percentage']}%',
                ),
                Text(
                  'Status: ${summary['overall_present'] ? 'Present' : 'Absent'}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeStudent()),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AttendanceRecordsPage(
                            records: _attendanceData!['attendance_records'],
                          ),
                    ),
                  );
                },
                child: const Text('View Records'),
              ),
            ],
          ),
    );
  }

  Future<void> _getDeviceInfo() async {
    String deviceInfo = '';

    try {
      if (Platform.isAndroid) {
        deviceInfo = 'Android';
      } else if (Platform.isIOS) {
        deviceInfo = 'iOS';
      } else {
        deviceInfo = 'Unknown Platform';
      }

      // Get Bluetooth adapter info
      final adapterName = await FlutterBluePlus.adapterName.catchError((e) {
        debugPrint('Error getting adapter name: $e');
        return 'Unknown Device';
      });

      // final manufacturer = await FlutterBluePlus.adapterName.catchError(
      //   (e) => 'Unknown Manufacturer',
      // );

      deviceInfo += ' - $adapterName';

      // Print for debugging
      print('Device Info: $deviceInfo');

      setState(() {
        _deviceInfo = deviceInfo;
      });
    } catch (e) {
      debugPrint('Error getting device info: $e');
      setState(() {
        _deviceInfo = 'Error getting device info';
      });
    }
  }

  Future<void> _initBluetooth() async {
    try {
      await _requestPermissions();
      await _checkPermissions();
      // Get initial state
      _adapterState = await FlutterBluePlus.adapterState.first;
      setState(() {});
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        _adapterState = state;
        if (mounted) {
          setState(() {
            _adapterState = state;
            print('Bluetooth adapter state changed to: $state');
          });
        }
      });

      // Print current state
      print('Initial Bluetooth state: $_adapterState');
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization error: ${e.toString()}';
      });
    }
  }

  Future<bool> _checkPermissions() async {
    if (await Permission.bluetooth.isDenied) {
      await Permission.bluetooth.request();
    }
    if (await Permission.bluetoothAdvertise.isDenied) {
      await Permission.bluetoothAdvertise.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    return await Permission.bluetooth.isGranted &&
        await Permission.bluetoothAdvertise.isGranted &&
        await Permission.location.isGranted;
  }

  Future<void> _requestPermissions() async {
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported by this device');
    }
  }

  Future<void> _toggleBeaconTransmission() async {
    if (_isLoading) return;
    print('Toggling beacon transmission. Current state: $_isAdvertising');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isAdvertising) {
        print('Stopping advertising...');
        await _stopAdvertising();
      } else {
        print('Starting advertising...');
        await _startAdvertising();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      print('Toggle completed. New state: $_isAdvertising');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startAdvertising() async {
    try {
      // Check and request permissions again
      await _checkPermissions();
      // Ensure Bluetooth is on
      if (_adapterState != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
        // Wait for Bluetooth to turn on
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String uid = prefs.getString('uid') ?? '';
      print('----------uid-------------${uid}');
      // Validate UUID format (should be in format like '2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6')
      if (uid.isEmpty || !uid.contains('-')) {
        throw Exception('Invalid UUID format');
      }
      // Start beacon broadcasting
      await beaconBroadcast
          .setUUID(uid)
          .setMajorId(100)
          .setMinorId(1)
          .setIdentifier('com.yourcompany.smarttrack') // Add identifier
          .setLayout(
            'm:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24',
          ) // Standard iBeacon layout
          .setManufacturerId(0x004C) // Apple's company identifier
          .setTransmissionPower(-59)
          .start();

      setState(() {
        _isAdvertising = true;
        _errorMessage = '';
      });
    } catch (e) {
      debugPrint('Error starting advertising: $e');
      setState(() {
        _errorMessage = 'Failed to start broadcasting: ${e.toString()}';
        _isAdvertising = false;
      });
    }
  }

  Future<void> _stopAdvertising() async {
    try {
      await beaconBroadcast.stop();

      setState(() {
        _isAdvertising = false;
      });
    } catch (e) {
      debugPrint('Error stopping advertising: $e');
      rethrow;
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
      _updateDateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _attendanceTimer?.cancel();
    _sessionCheckTimer?.cancel();
    _adapterStateSubscription.cancel();
    _stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;

    if (_showAttendanceDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAttendanceSummary();
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ColorStyle.BlueStatic,
      appBar: AppBar(
        backgroundColor: ColorStyle.BlueStatic,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12.0 : 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15),
              // Header with Time and Date
              Column(
                children: [
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 40 : 50,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Roboto',
                      color: const Color(0xFF293646),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_formattedDate - $_formattedDay',
                    style: TextStyle(
                      color: const Color(0xFF6A7D94),
                      fontSize: isSmallScreen ? 12 : 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Bluetooth Button
              Column(
                children: [
                  GestureDetector(
                    onTap: _toggleBeaconTransmission,
                    child: Container(
                      width: isSmallScreen ? 150 : 180,
                      height: isSmallScreen ? 150 : 180,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color:
                            _isAdvertising
                                ? Colors.blue.withOpacity(0.8)
                                : const Color(0xFFE1E5E9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _isAdvertising
                                  ? Colors.blue.shade100
                                  : const Color(0xFFE4E7ED),
                              Colors.white,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x16000000),
                              blurRadius: 10,
                              offset: const Offset(1, 6),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : Image.asset(
                                    'assets/images/Ble_symbol.png',
                                    width: isSmallScreen ? 70 : 100,
                                    color:
                                        _isAdvertising
                                            ? Colors.blue.shade800
                                            : Colors.grey,
                                  ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isAdvertising
                        ? "Broadcasting BLE signal..."
                        : "Tap to start broadcasting",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      color:
                          _isAdvertising
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 30),
              // Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(
                      label: 'Device Info',
                      value: _deviceInfo,
                      valueColor: Colors.blue.shade800,
                    ),
                    const Divider(thickness: 1, color: Colors.grey),
                    InfoRow(
                      label: 'Punch In',
                      value:
                          TimeHelper.formatTimeOfDayForDisplay(
                            widget.classData.startTime,
                          ).toString(),
                    ),
                    const Divider(thickness: 1, color: Colors.grey),
                    InfoRow(
                      label: 'Punch Out',
                      value:
                          TimeHelper.formatTimeOfDayForDisplay(
                            widget.classData.endTime,
                          ).toString(),
                    ),
                    const Divider(thickness: 1, color: Colors.grey),
                    InfoRow(
                      label: 'Subject',
                      value: widget.classData.course.toString(),
                    ),
                    const Divider(thickness: 1, color: Colors.grey),
                    InfoRow(label: 'Room', value: widget.classData.room),
                    const Divider(thickness: 1, color: Colors.grey),
                    InfoRow(
                      label: 'Bluetooth Status',
                      value: _adapterState.toString().split('.').last,
                      valueColor:
                          _adapterState == BluetoothAdapterState.on
                              ? Colors.green
                              : Colors.orange,
                    ),
                    if (_attendanceData != null) ...[
                      const Divider(thickness: 1, color: Colors.grey),
                      InfoRow(
                        label: 'Attendance Status',
                        value:
                            _attendanceData!['attendance_summary']['overall_present']
                                ? 'Present'
                                : 'Absent',
                        valueColor:
                            _attendanceData!['attendance_summary']['overall_present']
                                ? Colors.green
                                : Colors.red,
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                      InfoRow(
                        label: 'Attendance Percentage',
                        value:
                            '${_attendanceData!['attendance_summary']['attendance_percentage']}%',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (_attendanceData != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AttendanceRecordsPage(
                              records: _attendanceData!['attendance_records'],
                            ),
                      ),
                    );
                  },
                  child: const Text('View Attendance Records'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceRecordsPage extends StatelessWidget {
  final List<dynamic> records;

  const AttendanceRecordsPage({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Records')),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Icon(
                record['is_present'] ? Icons.check_circle : Icons.cancel,
                color: record['is_present'] ? Colors.green : Colors.red,
              ),
              title: Text(record['scanned_time']),
              subtitle: Text('Method: ${record['method']}'),
              trailing: Text(
                record['is_present'] ? 'Present' : 'Absent',
                style: TextStyle(
                  color: record['is_present'] ? Colors.green : Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.20,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.grey.shade700,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.20,
            ),
          ),
        ],
      ),
    );
  }
}
// import 'dart:async';
// import 'dart:io';
// import 'package:fyp_2025/main.dart';
// import 'package:fyp_2025/utils/ClassInfo.dart';
// import 'package:fyp_2025/utils/colorStyle.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:fyp_2025/pages/drawer/student_drawer.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_beacon/flutter_beacon.dart';
// import 'package:flutter/services.dart'; // Import for SystemChrome
// import 'package:shared_preferences/shared_preferences.dart';

// class BluetoothScreen extends StatefulWidget {
//   final ClassInfo classData;

//   const BluetoothScreen({super.key, required this.classData});

//   @override
//   State<BluetoothScreen> createState() => _BluetoothScreenState();
// }

// class _BluetoothScreenState extends State<BluetoothScreen> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
//   late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

//   bool _isAdvertising = false;
//   bool _isLoading = false;
//   String _errorMessage = '';
//   late String _formattedTime;
//   late String _formattedDate;
//   late String _formattedDay;
//   Timer? _timer;
//   String _deviceInfo = '';

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setSystemUIOverlayStyle(
//       const SystemUiOverlayStyle(
//         statusBarColor: Colors.white,
//         statusBarIconBrightness: Brightness.dark,
//         systemNavigationBarColor: Colors.white,
//         systemNavigationBarIconBrightness: Brightness.dark,
//       ),
//     );
//     _updateDateTime();
//     _startTimer();
//     _initBluetooth();
//     _getDeviceInfo();
//   }

//   Future<void> _getDeviceInfo() async {
//     String deviceInfo = '';
//     if (Platform.isAndroid) {
//       deviceInfo = 'Android Device';
//     } else if (Platform.isIOS) {
//       deviceInfo = 'iOS Device';
//     }

//     try {
//       final deviceName = await FlutterBluePlus.adapterName;
//       deviceInfo += ' - $deviceName';
//     } catch (e) {
//       debugPrint('Error getting device name: $e');
//     }

//     setState(() {
//       _deviceInfo = deviceInfo;
//     });
//   }

//   Future<void> _initBluetooth() async {
//     try {
//       await _requestPermissions();
//       await _checkPermissions();
//       await _initializeBeacon();

//       _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
//         _adapterState = state;
//         if (mounted) {
//           setState(() {});
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Initialization error: ${e.toString()}';
//       });
//     }
//   }

//   Future<void> _checkPermissions() async {
//     final statuses =
//         await [
//           Permission.bluetooth,
//           Permission.bluetoothAdvertise,
//           Permission.bluetoothScan,
//           Permission.bluetoothConnect,
//           Permission.location,
//         ].request();

//     if (statuses[Permission.bluetoothAdvertise]!.isDenied ||
//         statuses[Permission.bluetoothScan]!.isDenied ||
//         statuses[Permission.location]!.isDenied) {
//       throw Exception('Required permissions not granted');
//     }
//   }

//   Future<void> _initializeBeacon() async {
//     try {
//       await flutterBeacon.initializeAndCheckScanning;
//     } catch (e) {
//       debugPrint('Error initializing beacon: $e');
//       throw Exception('Beacon initialization failed');
//     }
//   }

//   Future<void> _requestPermissions() async {
//     if (await FlutterBluePlus.isSupported == false) {
//       throw Exception('Bluetooth not supported by this device');
//     }
//   }

//   Future<void> _toggleBeaconTransmission() async {
//     if (_isLoading) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       if (_isAdvertising) {
//         await _stopAdvertising();
//       } else {
//         await _startAdvertising();
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error: ${e.toString()}';
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _startAdvertising() async {
//     try {
//       // Ensure Bluetooth is on
//       if (_adapterState != BluetoothAdapterState.on) {
//         await FlutterBluePlus.turnOn();
//         await Future.delayed(
//           const Duration(seconds: 1),
//         ); // Wait for Bluetooth to turn on
//       }
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String uid = prefs.getString('uid') ?? '';
//       // Start beacon broadcasting
//       await flutterBeacon.startBroadcast(
//         BeaconBroadcast(
//           proximityUUID: uid,
//           major: 100,
//           minor: 1,
//           txPower: -59,
//           identifier: 'MyBeacon',
//         ),
//       );

//       setState(() {
//         _isAdvertising = true;
//       });
//     } catch (e) {
//       debugPrint('Error starting advertising: $e');
//       rethrow;
//     }
//   }

//   Future<void> _stopAdvertising() async {
//     try {
//       await flutterBeacon.stopBroadcast();

//       setState(() {
//         _isAdvertising = false;
//       });
//     } catch (e) {
//       debugPrint('Error stopping advertising: $e');
//       rethrow;
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

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _adapterStateSubscription.cancel();
//     _stopAdvertising();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isSmallScreen = size.width < 350;

//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: ColorStyle.BlueStatic,
//       appBar: AppBar(
//         backgroundColor: ColorStyle.BlueStatic,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.black),
//           onPressed: () => _scaffoldKey.currentState?.openDrawer(),
//         ),
//       ),
//       drawer: const CustomDrawer(
//         backgroundColor: Colors.white,
//         iconColor: Colors.black,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.symmetric(
//             horizontal: isSmallScreen ? 12.0 : 20.0,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 15),
//               // Header with Time and Date
//               Column(
//                 children: [
//                   Text(
//                     _formattedTime,
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 40 : 50,
//                       fontWeight: FontWeight.w300,
//                       fontFamily: 'Roboto',
//                       color: const Color(0xFF293646),
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '$_formattedDate - $_formattedDay',
//                     style: TextStyle(
//                       color: const Color(0xFF6A7D94),
//                       fontSize: isSmallScreen ? 12 : 14,
//                       fontFamily: 'Roboto',
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 30),
//               // Bluetooth Button
//               Column(
//                 children: [
//                   GestureDetector(
//                     onTap: _toggleBeaconTransmission,
//                     child: Container(
//                       width: isSmallScreen ? 150 : 180,
//                       height: isSmallScreen ? 150 : 180,
//                       padding: const EdgeInsets.all(16.0),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(100),
//                         color:
//                             _isAdvertising
//                                 ? Colors.blue.withOpacity(0.8)
//                                 : const Color(0xFFE1E5E9),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 10,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               _isAdvertising
//                                   ? Colors.blue.shade100
//                                   : const Color(0xFFE4E7ED),
//                               Colors.white,
//                             ],
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0x16000000),
//                               blurRadius: 10,
//                               offset: const Offset(1, 6),
//                               spreadRadius: 0,
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child:
//                               _isLoading
//                                   ? const CircularProgressIndicator()
//                                   : Image.asset(
//                                     'assets/images/Ble_symbol.png',
//                                     width: isSmallScreen ? 70 : 100,
//                                     color:
//                                         _isAdvertising
//                                             ? Colors.blue.shade800
//                                             : Colors.grey,
//                                   ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     _isAdvertising
//                         ? "Broadcasting BLE signal..."
//                         : "Tap to start broadcasting",
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 16 : 18,
//                       color:
//                           _isAdvertising
//                               ? Colors.green.shade700
//                               : Colors.grey.shade700,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (_errorMessage.isNotEmpty) ...[
//                     const SizedBox(height: 10),
//                     Text(
//                       _errorMessage,
//                       style: const TextStyle(color: Colors.red, fontSize: 14),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ],
//               ),
//               const SizedBox(height: 30),
//               // Info Section
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16.0),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     InfoRow(
//                       label: 'Device Info',
//                       value: _deviceInfo,
//                       valueColor: Colors.blue.shade800,
//                     ),
//                     const Divider(thickness: 1, color: Colors.grey),
//                     InfoRow(
//                       label: 'Punch In',
//                       value: widget.classData.startTime.toString() ?? 'N/A',
//                     ),
//                     const Divider(thickness: 1, color: Colors.grey),
//                     InfoRow(
//                       label: 'Punch Out',
//                       value: widget.classData.endTime.toString() ?? 'N/A',
//                     ),
//                     const Divider(thickness: 1, color: Colors.grey),
//                     InfoRow(
//                       label: 'Subject',
//                       value: widget.classData.course.toString() ?? 'N/A',
//                     ),
//                     const Divider(thickness: 1, color: Colors.grey),
//                     InfoRow(
//                       label: 'Room',
//                       value: widget.classData.room ?? 'N/A',
//                     ),
//                     const Divider(thickness: 1, color: Colors.grey),
//                     InfoRow(
//                       label: 'Bluetooth Status',
//                       value: _adapterState.toString().split('.').last,
//                       valueColor:
//                           _adapterState == BluetoothAdapterState.on
//                               ? Colors.green
//                               : Colors.orange,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class InfoRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final Color? valueColor;

//   const InfoRow({
//     super.key,
//     required this.label,
//     required this.value,
//     this.valueColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.black45,
//               fontSize: 16,
//               fontFamily: 'Roboto',
//               fontWeight: FontWeight.w600,
//               letterSpacing: 0.20,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               color: valueColor ?? Colors.grey.shade700,
//               fontSize: 16,
//               fontFamily: 'Roboto',
//               fontWeight: FontWeight.w500,
//               letterSpacing: 0.20,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'dart:io';
// import 'package:fyp_2025/utils/colorStyle.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:fyp_2025/pages/drawer/student_drawer.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_beacon/flutter_beacon.dart';

// class BluetoothScreen extends StatefulWidget {
//   final Map<String, String> classData;

//   const BluetoothScreen({super.key, required this.classData});

//   @override
//   State<BluetoothScreen> createState() => _MyWidgetState();
// }

// class _MyWidgetState extends State<BluetoothScreen> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
//   late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

//   bool _isAdvertising = false;
//   late String _formattedTime;
//   late String _formattedDate;
//   late String _formattedDay;
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     _updateDateTime(); // Initialize the time immediately
//     _startTimer();
//     _requestPermissions();
//     _checkPermissions();
//     _initializeBeacon();
//     _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((
//       state,
//     ) {
//       _adapterState = state;
//       if (mounted) {
//         setState(() {});
//       }
//     });
//     // Start the timer to update the time
//   }

//   Future<void> _checkPermissions() async {
//     await [
//       Permission.bluetooth,
//       Permission.bluetoothAdvertise,
//       Permission.location,
//     ].request();
//   }

//   Future<void> _initializeBeacon() async {
//     try {
//       // Initialize the library for beacon operations
//       await flutterBeacon.initializeAndCheckScanning;
//     } catch (e) {
//       debugPrint('Error initializing beacon: $e');
//     }
//   }

//   Future<void> _requestPermissions() async {
//     if (await Permission.bluetoothAdvertise.isDenied) {
//       await Permission.bluetoothAdvertise.request();
//     }
//     if (await Permission.bluetoothScan.isDenied) {
//       await Permission.bluetoothScan.request();
//     }
//     if (await Permission.bluetoothConnect.isDenied) {
//       await Permission.bluetoothConnect.request();
//     }
//     if (await Permission.location.isDenied) {
//       await Permission.location.request();
//     }
//   }

//   Future<void> _toggleBeaconTransmission() async {
//     print("---------------------------------------toggle sucessfully---------");
//     // first, check if bluetooth is supported by your hardware
//     // Note: The platform is initialized on the first call to any FlutterBluePlus method.
//     if (await FlutterBluePlus.isSupported == false) {
//       print("Bluetooth not supported by this device");
//       return;
//     }

//     // handle bluetooth on & off
//     // note: for iOS the initial state is typically BluetoothAdapterState.unknown
//     // note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
//     var subscription = FlutterBluePlus.adapterState.listen((
//       BluetoothAdapterState state,
//     ) async {
//       print("------------state-------------$state");
//       if (state == BluetoothAdapterState.off) {
//         await FlutterBluePlus.turnOn();
//         setState(() {
//           _isAdvertising = true;
//         });
//         await flutterBeacon.startBroadcast(
//           BeaconBroadcast(
//             proximityUUID:
//                 '5BCE9431-6D10-4A3E-ABB2-EB6B9E546013', // Replace with your UUID
//             major: 100,
//             minor: 1,
//             txPower: -59, // Transmission power
//             identifier: 'MyBeacon',
//           ),
//         );
//         // usually start scanning, connecting, etc
//       } else {
//         await FlutterBluePlus.turnOff();
//         setState(() {
//           _isAdvertising = false;
//         });
//         await flutterBeacon.stopBroadcast();

//         // show an error to the user, etc
//       }
//     });

//     // turn on bluetooth ourself if we can
//     // for iOS, the user controls bluetooth enable/disable
//     if (Platform.isAndroid) {
//       await FlutterBluePlus.turnOn();

//       setState(() {
//         _isAdvertising = true;
//       });
//       await flutterBeacon.startBroadcast(
//         BeaconBroadcast(
//           proximityUUID:
//               '5BCE9431-6D10-4A3E-ABB2-EB6B9E546013', // Replace with your UUID
//           major: 100,
//           minor: 1,
//           txPower: -59, // Transmission power
//           identifier: 'MyBeacon',
//         ),
//       );
//     }

//     // cancel to prevent duplicate listeners
//     subscription.cancel();
//   }

//   void _updateDateTime() {
//     final DateTime now = DateTime.now();
//     setState(() {
//       _formattedTime = DateFormat('hh:mm a').format(now); // Time in HH:MM AM/PM
//       _formattedDate = DateFormat('MMM d, yyyy').format(now); // Date format
//       _formattedDay = DateFormat('EEEE').format(now); // Day of the week
//     });
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _updateDateTime();
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _adapterStateStateSubscription.cancel();
//     // flutterBeacon
//     // .stopBroadcast(); // Cancel the timer when the widget is disposed
//     super.dispose();
//   }

//   // void toggleButtonBluetooth(state, bluePlusMockable) {}
//   // const Color(0xFFB2CCDF)
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: ColorStyle.BlueStatic,
//       appBar: AppBar(
//         backgroundColor: ColorStyle.BlueStatic,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.black),
//           onPressed: () {
//             _scaffoldKey.currentState?.openDrawer(); // Open drawer on menu tap
//           },
//         ),
//       ),

//       drawer: const CustomDrawer(
//         backgroundColor: Colors.white, // Pass background color
//         iconColor: Colors.black, // Pass icon color
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
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
//           // Text(
//           //   _isTransmitting
//           //       ? 'Beacon is transmitting signals...'
//           //       : 'Beacon transmission is stopped.',
//           //   style: Theme.of(context).textTheme.headlineMedium,
//           //   textAlign: TextAlign.center,
//           // ),
//           // Bluetooth Button
//           GestureDetector(
//             onTap: _toggleBeaconTransmission,
//             child: Center(
//               child: Container(
//                 width: 180,
//                 height: 180,
//                 padding: const EdgeInsets.all(16.0),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(100),
//                   color:
//                       _isAdvertising
//                           ? Colors.blueGrey
//                           : const Color(0xFFE1E5E9),
//                 ),
//                 child: Container(
//                   width: 80,
//                   height: 80,
//                   decoration: const ShapeDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment(0.74, -0.67),
//                       end: Alignment(-0.74, 0.67),
//                       colors: [
//                         Color(0xFFE4E7ED),
//                         Color.fromRGBO(255, 255, 255, 1),
//                       ],
//                     ),
//                     shape: OvalBorder(),
//                     shadows: [
//                       BoxShadow(
//                         color: Color(0x16000000),
//                         blurRadius: 10,
//                         offset: Offset(1, 6),
//                         spreadRadius: 0,
//                       ),
//                     ],
//                   ),
//                   child: Image.asset(
//                     'assets/images/Ble_symbol.png',
//                     width: 100,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             _isAdvertising ? "Broadcasting BLE signal..." : "Not Broadcasting",
//             style: const TextStyle(fontSize: 18),
//           ),
//           const SizedBox(height: 20),
//           // Text(
//           //   _isTransmitting ? 'Stop Transmission' : 'Start Transmission',
//           //   style: const TextStyle(fontSize: 18),
//           // ),
//           // Info Section
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 InfoRow(
//                   label: 'Punch In',
//                   value: widget.classData['punchIn'] ?? 'N/A',
//                 ),
//                 InfoRow(
//                   label: 'Punch Out',
//                   value: widget.classData['punchOut'] ?? 'N/A',
//                 ),
//                 InfoRow(
//                   label: 'Subject',
//                   value: widget.classData['name'] ?? 'N/A',
//                 ),
//                 InfoRow(
//                   label: 'Teacher',
//                   value: widget.classData['teacher'] ?? 'N/A',
//                 ),
//                 // InfoRow(label: 'Class', value: 'Lab 5'),
//                 // InfoRow(label: 'Total Punch', value: '12'),
//                 // InfoRow(label: 'Connect Punch', value: '8'),
//               ],
//             ),
//           ),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
// }

// class InfoRow extends StatelessWidget {
//   final String label;
//   final String value;

//   const InfoRow({super.key, required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: Colors.black45,
//                   fontSize: 16,
//                   fontFamily: 'Roboto',
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: 0.20,
//                 ),
//               ),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   color: Colors.grey,
//                   fontSize: 16,
//                   fontFamily: 'Roboto',
//                   fontWeight: FontWeight.normal,
//                   letterSpacing: 0.20,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 1),
//           Divider(thickness: 1, color: Colors.grey),
//         ],
//       ),
//     );
//   }
// }

// // // // import 'package:fyp_2025/models/bluetooth_connection.dart';
// // // import 'package:fyp_2025/pages/drawer/student_drawer.dart';
// // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// // // import 'package:intl/intl.dart';
// // // // import 'package:provider/provider.dart';

// // // class BluetoothScreen extends StatefulWidget {
// // //   // final FlutterBluePlusMockable bluePlusMockable;

// // //   const BluetoothScreen({super.key,});

// // //   @override
// // //   State<BluetoothScreen> createState() => _MyWidgetState();
// // // }

// // // class _MyWidgetState extends State<BluetoothScreen> {
  
// // //   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
// // //   late String _formattedTime;
// // //   late String _formattedDate;
// // //   late String _formattedDay;
// // //   late String state;
// // //   // FlutterBluePlusMockable bluePlusMockable = FlutterBluePlusMockable();
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _updateDateTime();
// // //   }

// // //   void _updateDateTime() {
// // //     final DateTime now = DateTime.now();
// // //     setState(() {
// // //       _formattedTime =
// // //           DateFormat('hh:mm a').format(now); // Time in HH:MM AM/PM format
// // //       _formattedDate = DateFormat('MMM d, yyyy')
// // //           .format(now); // Date in Month, Day, Year format
// // //       _formattedDay =
// // //           DateFormat('EEEE').format(now); // Full name of the day (e.g., Monday)
// // //     });
// // //   }

// // //   // void _toggleBluetoothConnection(currentstate, bluePlusMockable) async {
// // //     // try {
// // //     //   if (currentstate == BluetoothAdapterState.off) {
// // //     //   await bluePlusMockable.turnOn(timeout: 12);
// // //     //   }
// // //     //   else{
// // //     //     await bluePlusMockable.turnOff();
// // //     //   }
// // //     // } catch (Error) {
// // //     //   print('Error');
// // //     // }
// // //   // }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //   // final bluePlusMockable = Provider.of<FlutterBluePlusMockable>(context);
// // //     return 
// // //     // StreamBuilder<BluetoothAdapterState>(
// // //         // stream: bluePlusMockable.adapterState,
// // //         // initialData: BluetoothAdapterState.unknown,
// // //         //     builder: (c, snapshot) {
// // //         //       final state = snapshot.data;
// // //         //       print("STATE");

// // //         //       print(state);
// // //         // builder: (c, snapshot) {
// // //           // final currentstate = snapshot.data.toString();
// // //            Scaffold(
// // //             key: _scaffoldKey,
// // //             backgroundColor: const Color(0xFFB2CCDF),
// // //             appBar: AppBar(
// // //               backgroundColor: const Color(0xFFB2CCDF),
// // //               elevation: 0,
// // //               leading: IconButton(
// // //                 icon: const Icon(Icons.menu, color: Colors.black),
// // //                 onPressed: () {
// // //                   _scaffoldKey.currentState
// // //                       ?.openDrawer(); // Open drawer on menu tap
// // //                 },
// // //               ),
// // //             ),
// // //             drawer: const CustomDrawer(
// // //               backgroundColor: Color(0xFFB2CCDF), // Pass background color
// // //               iconColor: Colors.black, // Pass icon color
// // //             ),
// // //             body: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.center,
// // //               children: [
// // //                 const SizedBox(height: 15),
// // //                 // Header with Time and Date
// // //                 Padding(
// // //                   padding: EdgeInsets.symmetric(horizontal: 20.0),
// // //                   child: Column(
// // //                     children: [
// // //                       Text(
// // //                         _formattedTime,
// // //                         style: TextStyle(
// // //                           fontSize: 50,
// // //                           fontWeight: FontWeight.w300,
// // //                           fontFamily: 'Roboto',
// // //                           color: Color(0xFF293646),
// // //                         ),
// // //                       ),
// // //                       SizedBox(height: 4),
// // //                       Text(
// // //                         '$_formattedDate - $_formattedDay',
// // //                         style: TextStyle(
// // //                           color: Color(0xFF6A7D94),
// // //                           fontSize: 14,
// // //                           fontFamily: 'Roboto',
// // //                           fontWeight: FontWeight.w400,
// // //                           height: 0,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 30),
// // //                 // Bluetooth Button
// // //                 GestureDetector(
// // //                   // onTap: () => _toggleBluetoothConnection(currentstate, bluePlusMockable),
// // //                   // _toggleBluetooth, // Toggle Bluetooth on press
// // //                   child: Center(
// // //                     child: Container(
// // //                       width: 180,
// // //                       height: 180,
// // //                       padding: EdgeInsets.all(16.0),
// // //                       decoration: BoxDecoration(
// // //                         borderRadius: BorderRadius.circular(100),
// // //                         color: const Color(0xFFE1E5E9),
// // //                       ),
// // //                       child: Container(
// // //                         width: 80,
// // //                         height: 80,
// // //                         decoration: const ShapeDecoration(
// // //                           gradient: LinearGradient(
// // //                             begin: Alignment(0.74, -0.67),
// // //                             end: Alignment(-0.74, 0.67),
// // //                             colors: [
// // //                               Color(0xFFE4E7ED),
// // //                               Color.fromRGBO(255, 255, 255, 1)
// // //                             ],
// // //                           ),
// // //                           shape: OvalBorder(),
// // //                           shadows: [
// // //                             BoxShadow(
// // //                               color: Color(0x16000000),
// // //                               blurRadius: 10,
// // //                               offset: Offset(1, 6),
// // //                               spreadRadius: 0,
// // //                             )
// // //                           ],
// // //                         ),
// // //                         child: Icon(
// // //                           // bluetoothState == BluetoothState.on
// // //                           //     ? Icons.bluetooth_connected
// // //                           //     :
// // //                           Icons.bluetooth_disabled,
// // //                           size: 60,
// // //                           color: Colors.black,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 Text(
// // //                   // currentstate,
// // //                   "12",
// // //                   style: TextStyle(color: Colors.red, fontSize: 12.0),
// // //                 ),
// // //                 const SizedBox(height: 20),
// // //                 // Info Section
// // //                 const Expanded(
// // //                   child: Padding(
// // //                     padding:
// // //                         EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         InfoRow(label: 'MAC Address', value: '8233556@#1WF'),
// // //                         InfoRow(label: 'Punch In', value: '12:00 AM'),
// // //                         InfoRow(label: 'Punch Out', value: '12:45 AM'),
// // //                         InfoRow(label: 'Subject', value: 'Data Structure'),
// // //                         InfoRow(label: 'Teacher', value: 'Dr. Nadeem Faisal'),
// // //                         InfoRow(label: 'Class', value: 'Lab 5'),
// // //                         InfoRow(label: 'Total Punch', value: '12'),
// // //                         InfoRow(label: 'Connect Punch', value: '8'),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
          
// // //         );
// // //   }
// // // }

// // // class InfoRow extends StatelessWidget {
// // //   final String label;
// // //   final String value;

// // //   const InfoRow({super.key, required this.label, required this.value});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 8.0),
// // //       child: Row(
// // //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //         children: [
// // //           Text(
// // //             label,
// // //             style: const TextStyle(
// // //               color: Color(0xFF293646),
// // //               fontSize: 20,
// // //               fontFamily: 'Roboto',
// // //               fontWeight: FontWeight.w700,
// // //               height: 0,
// // //               letterSpacing: 0.20,
// // //             ),
// // //           ),
// // //           Text(
// // //             value,
// // //             style: const TextStyle(
// // //               color: Colors.white,
// // //               fontSize: 20,
// // //               fontFamily: 'Roboto',
// // //               fontWeight: FontWeight.w500,
// // //               height: 0,
// // //               letterSpacing: 0.20,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
