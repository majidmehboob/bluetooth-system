import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_track/features/api-section/student.dart';
import 'package:smart_track/screens/student-section/drawer.dart';
import 'package:smart_track/screens/student-section/pages/mark-attendence.dart';
import 'package:smart_track/screens/student-section/pages/graph-subject.dart';
import 'package:smart_track/services/audio-services.dart';
// import 'package:smart_track/pages/student/%5Bhistory%5D.dart';
import 'package:smart_track/services/class-information-services.dart';
import 'package:smart_track/services/text-helper.dart';
import 'package:smart_track/services/shimmer-services.dart';
import 'package:smart_track/services/time-helper.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:smart_track/widgets/next-class.dart';

import 'package:smart_track/widgets/snackbar-helper.dart';
// import 'package:fyp_2025/widgets/model.dart';
import 'package:smart_track/widgets/not-any-class.dart';
import 'package:smart_track/widgets/not-found.dart';

// import 'package:fyp_2025/pages/student/bluetooth_screen.dart';
import 'package:smart_track/widgets/search-bar.dart';
import 'package:smart_track/widgets/current-class.dart';
import 'package:smart_track/widgets/system-ui.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeStudent extends StatefulWidget {
  const HomeStudent({super.key});

  @override
  State<HomeStudent> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<HomeStudent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Set<int> _playedClassIds = {};
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  late List<ClassInfo> classes = [];
  late List<ClassInfo> filteredClasses = [];
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  ClassInfo? currentClass;
  ClassInfo? nextClass;
  ClassInfo? selectedClass;

  String searchQuery = '';
  Duration? nextClassRemainingTime;
  bool isLoading = false;
  // Add these new variables to your state class
  Timer? _attendanceCheckTimer;
  bool _isCheckingAttendance = false;

  @override
  void initState() {
    super.initState();
    setupSystemUI();
    AudioHelper.initialize();
    _fetchClassData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _attendanceCheckTimer?.cancel();

    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        _updateClassStates();
      });
    });
  }

  Future<void> _fetchClassData({
    bool isRefresh = false,
    bool checkSession = false,
  }) async {
    if (!isRefresh) {
      setState(() => isLoading = true);
    }
    if (searchQuery.isNotEmpty) {
      setState(() {
        searchQuery = '';
      });
    }
    try {
      final fetchedClasses = await ClassApiService.fetchTodayClasses();

      setState(() {
        classes =
            fetchedClasses..sort(
              (a, b) => TimeHelper.compareTimeOfDay(a.startTime, b.startTime),
            );
        filteredClasses = List.from(classes);
        selectedClass = filteredClasses.isNotEmpty ? filteredClasses[0] : null;

        _updateClassStates();

        // NotificationHelper.scheduleClassNotifications(classes);

        // If we're specifically checking for session ID
        if (checkSession &&
            currentClass != null &&
            currentClass!.attendanceSessionId == null) {
          _startAttendanceCheckTimer();
        }
      });
      if (isRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _startAttendanceCheckTimer() {
    if (_isCheckingAttendance) return;

    _isCheckingAttendance = true;
    _attendanceCheckTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) async {
      if (currentClass != null || currentClass!.attendanceSessionId != null) {
        _stopAttendanceCheckTimer();
        return;
      }

      await _fetchClassData(checkSession: true);
    });
  }

  void _stopAttendanceCheckTimer() {
    _attendanceCheckTimer?.cancel();
    _attendanceCheckTimer = null;
    _isCheckingAttendance = false;
  }

  void _updateClassStates() {
    if (classes.isEmpty) return;

    // Update current class
    currentClass = _findCurrentClass();
    // If we have a current class but no session ID, start checking
    if (currentClass != null && currentClass!.attendanceSessionId == null) {
      _startAttendanceCheckTimer();
    } else {
      _stopAttendanceCheckTimer();
    }
    // Update next class only if no current class
    if (currentClass == null) {
      final result = _findNextClass();
      nextClass = result.item1;
      nextClassRemainingTime = result.item2;
    } else {
      nextClass = null;
      nextClassRemainingTime = null;
    }
  }

  ClassInfo? _findCurrentClass() {
    for (var classInfo in classes) {
      final classStart = TimeHelper.getClassStartTime(
        _currentTime,
        classInfo.startTime,
      );
      final classEnd = TimeHelper.getClassEndTime(
        _currentTime,
        classInfo.endTime,
      );

      if (TimeHelper.isBetween(_currentTime, classStart, classEnd)) {
        _playClassStartNotification(classInfo);
        return classInfo;
      }
    }
    return null;
  }

  // void _playClassStartNotification(ClassInfo classInfo) async {
  //   if (_currentTime.hour == classInfo.startTime.hour &&
  //       _currentTime.minute == classInfo.startTime.minute &&
  //       _currentTime.second == 0 &&
  //       !_playedClassIds.contains(classInfo.id)) {
  //     _playedClassIds.add(classInfo.id);
  //     await _player.play(AssetSource('sounds/sound.mp3')).catchError((e) {
  //       debugPrint('Error playing sound: $e');
  //     });
  //   }
  // }

  void _playClassStartNotification(ClassInfo classInfo) async {
    if (_currentTime.hour == classInfo.startTime.hour &&
        _currentTime.minute == classInfo.startTime.minute &&
        _currentTime.second == 0 &&
        !_playedClassIds.contains(classInfo.id)) {
      _playedClassIds.add(classInfo.id);

      await AudioHelper.playClassStartSound();
      // await NotificationHelper.showClassStartNotification(classInfo);
    }
  }

  // Future<void> _showClassStartNotification(ClassInfo classInfo) async {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //       AndroidNotificationDetails(
  //         'class_start_channel',
  //         'Class Start Notifications',
  //         channelDescription:
  //             'Notifications for when classes are about to start',
  //         importance: Importance.high,
  //         priority: Priority.high,
  //         playSound: true,
  //         sound: RawResourceAndroidNotificationSound('notification_sound'),
  //         enableVibration: true,
  //       );

  //   const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //     iOS: DarwinNotificationDetails(),
  //   );

  //   final FlutterLocalNotificationsPlugin notificationsPlugin =
  //       FlutterLocalNotificationsPlugin();

  //   await notificationsPlugin.show(
  //     0, // Notification ID
  //     'Class Starting Now',
  //     '${classInfo.course} (${classInfo.courseCode}) is starting now in ${classInfo.room}',
  //     platformChannelSpecifics,
  //   );
  // }

  Tuple2<ClassInfo?, Duration?> _findNextClass() {
    for (var classInfo in classes) {
      final classStart = TimeHelper.getClassStartTime(
        _currentTime,
        classInfo.startTime,
      );

      if (_currentTime.isBefore(classStart)) {
        return Tuple2(classInfo, classStart.difference(_currentTime));
      }
    }
    return const Tuple2(null, null);
  }

  void onSearchTextChanged(String query) {
    setState(() {
      searchQuery = query;
      filteredClasses =
          query.isEmpty
              ? List.from(classes)
              : classes
                  .where(
                    (cls) =>
                        cls.course.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        cls.courseCode.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                  )
                  .toList();
      selectedClass = filteredClasses[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: CustomDrawer(
        backgroundColor: Colors.white,
        iconColor: Colors.black,
      ),
      appBar: AppBar(
        backgroundColor: ColorStyle.BlueStatic,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: false,
        header: const ClassicHeader(
          completeText: 'Refresh complete',
          refreshingText: 'Refreshing...',
          releaseText: 'Release to refresh',
          idleText: 'Pull down to refresh',
          // iconTheme: const IconThemeData(color: Colors.white),
        ),
        onRefresh: () async {
          setState(() => isLoading = true);
          try {
            await _fetchClassData(isRefresh: true);
            _updateClassStates();
            await Future.delayed(
              const Duration(milliseconds: 100),
            ); // Small delay
            _refreshController.refreshCompleted();
          } catch (e) {
            _refreshController.refreshFailed();
          } finally {
            if (mounted) setState(() => isLoading = false);
          }
        },
        child:
            isLoading
                ? ShimmerHelper.buildHomePageShimmer(context)
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      color: ColorStyle.BlueStatic,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 4.0,
                        ),
                        child: searchbar(
                          'Search Classes...',
                          const Color(0xF1F1F1F1),

                          Icons.search,
                          onSearchTextChanged,
                        ),
                      ),
                    ),

                    // Current/Next Class Section
                    _buildClassHeaderSection(),

                    // Main Content
                    if (searchQuery.isNotEmpty && filteredClasses.isEmpty)
                      Expanded(
                        child: NoClassesFound(
                          onRefresh: _fetchClassData,
                          message: 'Spell Mistake or May not have any class',
                          parameter: 'Classes',
                        ),
                      )
                    else
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today Classes',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Roboto',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: filteredClasses.isEmpty ? 2 : 10,
                              ),
                              _buildClassList(),
                              const SizedBox(height: 6),
                              _buildClassDetailsSection(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  Widget _buildClassHeaderSection() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height / 3.5,
      decoration: const BoxDecoration(
        color: Color(0xFF80A7D5),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 35.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentClass != null && currentClass?.status != "completed")
                  selectedClassDetails(
                    isStudent: true,
                    classInfo: currentClass!,
                    status: currentClass?.status,
                    onJoinPressed:
                        () async => {
                          _navigateToBluetoothScreen(currentClass!),
                          // This code runs when returning from BluetoothScreen
                          await _fetchClassData(), // Reload today's classes
                          _updateClassStates(),
                        },
                  )
                else if (nextClass != null)
                  BuildNextClassCard(nextClass!, nextClassRemainingTime)
                else
                  noClassDetail(Colors.white),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: -4,
            child: Image.asset('assets/images/Wireframe.png', width: 160),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    return SizedBox(
      height: 50,
      child:
          filteredClasses.isEmpty
              ? Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: ColorStyle.BlueStatic,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Not Any Class Available",
                    style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
                  ),
                ),
              )
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredClasses.length,
                itemBuilder:
                    (context, index) =>
                        _buildClassListItem(filteredClasses[index]),
              ),
    );
  }

  Widget _buildClassListItem(ClassInfo classInfo) {
    final isCurrent = currentClass == classInfo;
    final isNext = nextClass == classInfo;
    // if (isCurrent || isNext) return const SizedBox.shrink();

    final classEnd = DateTime(
      _currentTime.year,
      _currentTime.month,
      _currentTime.day,
      classInfo.endTime.hour,
      classInfo.endTime.minute,
    );
    final isPast = _currentTime.isAfter(classEnd);

    return GestureDetector(
      onTap: () => setState(() => selectedClass = classInfo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isCurrent || isNext
                    ? Colors.green
                    : selectedClass?.id == classInfo.id
                    ? const Color.fromARGB(255, 138, 138, 138)
                    : isPast
                    ? Colors.grey
                    : Colors.black,
          ),
          borderRadius: BorderRadius.circular(50),
          color:
              selectedClass?.id == classInfo.id
                  ? ColorStyle.BlueStatic
                  : isCurrent || isNext
                  ? Colors.green.withOpacity(0.2)
                  : isPast
                  ? Colors.grey.shade200
                  : Colors.white,
        ),
        child: Center(
          child: Text(
            classInfo.course,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w300,
              fontFamily: 'Roboto',
              color:
                  selectedClass?.id == classInfo.id || isCurrent || isNext
                      ? Colors.white
                      : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassDetailsSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(15),
          ),
          child:
              filteredClasses.isEmpty || selectedClass == null
                  ? Expanded(
                    child: NoClassesFound(
                      onRefresh: _fetchClassData,
                      message: 'No Class schedule for today ',
                      parameter: 'Selected Classes',
                    ),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Class Details",
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      _buildDetailsRow(
                        'Punch In:',
                        TimeHelper.formatTimeOfDayForDisplay(
                          selectedClass!.startTime,
                        ),
                      ),
                      _buildDetailsRow(
                        'Punch Out :',
                        TimeHelper.formatTimeOfDayForDisplay(
                          selectedClass!.endTime,
                        ),
                      ),

                      _buildDetailsRow(
                        'Teacher:',
                        selectedClass!.instructorName,
                      ),
                      _buildDetailsRow(
                        'Course Code:',
                        selectedClass!.courseCode,
                      ),
                      _buildDetailsRow(
                        'Class:',
                        ' ${selectedClass!.room} | Sec ${selectedClass!.section.toUpperCase()} | Rasq ${selectedClass!.raspberry_Pi}',
                      ),
                      _buildDetailsRow('Status:', selectedClass!.status),
                      _buildDetailsRow(
                        'Department:',
                        selectedClass!.department,
                      ),

                      const SizedBox(height: 5.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => SingleSubjectGraphStudent(
                                        semesterId: selectedClass!.semesterId,
                                        courseId: selectedClass!.courseId,
                                        course: selectedClass!.course,
                                        code: selectedClass!.courseCode,
                                      ),
                                ),
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorStyle.BlueStatic,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(
                              'View More',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildDetailsRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF293646),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color:
                  label == 'Status:'
                      ? TextFormatHelper.getStatusClass(value)
                      : Color(0xFF868686),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToBluetoothScreen(ClassInfo classData) async {
    await AudioHelper.playClassStartSound();
    if (classData.attendanceSessionId == null) {
      SnackbarHelper.showError(context, 'Session id is null');
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkAttendenceStudent(classData: classData),
        ),
      );
      await _fetchClassData();
      _updateClassStates();
    }
  }
}

// Helper tuple class
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  const Tuple2(this.item1, this.item2);
}
