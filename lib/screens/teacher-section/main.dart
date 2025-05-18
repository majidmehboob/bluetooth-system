import 'package:smart_track/screens/teacher-section/drawer.dart';
import 'package:smart_track/screens/teacher-section/pages/mark-attendence.dart';
import 'package:smart_track/screens/teacher-section/pages/subject-detail.dart';
import 'package:smart_track/services/class-information-services.dart';
import 'package:smart_track/services/time-helper.dart';
import 'package:flutter/material.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Add this line
import 'package:shimmer/shimmer.dart';
import 'dart:async'; // For Timer
// For time formatting
import 'package:audioplayers/audioplayers.dart'; // For sound
import 'package:smart_track/widgets/next-class.dart';
import 'package:smart_track/widgets/not-any-class.dart';
import 'package:smart_track/widgets/current-class.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeTeacher extends StatefulWidget {
  const HomeTeacher({super.key});

  @override
  _TeacherHomeScreenState createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<HomeTeacher> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Define the current active tab
  String activeTab = "Enroll";
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  List<Map<String, dynamic>> enrolledSubjects = [];

  List<ClassInfo> todayClasses = [];
  bool isLoading = true;
  String? errorMessage;

  final List<Map<String, String>> students = [
    {"id": "1", "name": "Ali", "rollNumber": "BSCS123", "class": "3"},
    {"id": "2", "name": "Sara", "rollNumber": "BSCS124", "class": "5"},
    {"id": "3", "name": "John", "rollNumber": "BSCS125", "class": "7"},
  ];

  // Add these variables
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final AudioPlayer _player = AudioPlayer();
  final Set<int> _playedClassIds = {};
  ClassInfo? currentClass;
  ClassInfo? nextClass;
  Duration? nextClassRemainingTime;

  // Add these methods
  @override
  void initState() {
    super.initState();
    _player.setVolume(1.0);
    fetchTodayClasses();
    fetchEnrolledSubjects(); // New method to fetch enrolled subjects
    _loadUserData();
    filteredStudents = students; // Initialize audio player
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        _updateClassStates();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> fetchEnrolledSubjects({bool isRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/teacher-sections',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> sections = data['sections_taught'];

        setState(() {
          enrolledSubjects =
              sections.map((section) {
                final course = section['course'];
                final sectionData = section['section'];
                final semester = sectionData['semester'];
                final degree = section['degree'];

                return {
                  'course': course['name'],
                  'code': course['code'],
                  'semester': '${semester['number']}',
                  'section': sectionData['name'],
                  'section_id': sectionData['id'],
                  'degree_id': degree['id'],
                  'semester_id': semester['id'],
                  'course_id': course['id'],
                };
              }).toList();
        });
        if (isRefresh) {
          _refreshController.refreshCompleted();
        }
      } else {
        throw Exception(
          'Failed to load enrolled subjects: ${response.statusCode}',
        );
      }
      if (isRefresh) {
        _refreshController.refreshFailed();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching enrolled subjects: ${e.toString()}';
      });
    }
  }

  String _getCourseInitials(String courseName) {
    if (courseName.isEmpty) return '';

    final words = courseName.split(' ');
    if (words.length == 1) {
      return courseName.substring(0, 2).toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  void _updateClassStates() async {
    if (todayClasses.isEmpty) return;

    // Update current class
    ClassInfo? newCurrentClass;
    for (var classInfo in todayClasses) {
      final classStart = DateTime(
        _currentTime.year,
        _currentTime.month,
        _currentTime.day,
        classInfo.startTime.hour,
        classInfo.startTime.minute,
      );
      final classEnd = DateTime(
        _currentTime.year,
        _currentTime.month,
        _currentTime.day,
        classInfo.endTime.hour,
        classInfo.endTime.minute,
      );

      if (_currentTime.isAfter(classStart) && _currentTime.isBefore(classEnd)) {
        newCurrentClass = classInfo;

        // Play notification when class starts
        if (_currentTime.hour == classInfo.startTime.hour &&
            _currentTime.minute == classInfo.startTime.minute &&
            _currentTime.second == 0 &&
            !_playedClassIds.contains(classInfo.id)) {
          _playedClassIds.add(classInfo.id);
          await _player.play(AssetSource('sounds/sound.mp3'));
        }
        break;
      }
    }

    // Update next class (only if no current class)
    ClassInfo? newNextClass;
    Duration? newRemainingTime;
    if (newCurrentClass == null) {
      for (var classInfo in todayClasses) {
        final classStart = DateTime(
          _currentTime.year,
          _currentTime.month,
          _currentTime.day,
          classInfo.startTime.hour,
          classInfo.startTime.minute,
        );

        if (_currentTime.isBefore(classStart)) {
          newNextClass = classInfo;
          newRemainingTime = classStart.difference(_currentTime);
          break;
        }
      }
    }

    // Update state
    setState(() {
      currentClass = newCurrentClass;
      nextClass = newNextClass;
      nextClassRemainingTime = newRemainingTime;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return [
      if (hours > 0) '${hours}h',
      if (minutes > 0 || hours > 0) '${minutes}m',
      '${seconds}s',
    ].join(' ');
  }

  Future<void> fetchTodayClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/today-timetable?user_type=teacher',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> timetable = data['today_timetable'];

        setState(() {
          todayClasses =
              timetable.map((e) => ClassInfo.fromJson(e)).toList()..sort(
                (a, b) => TimeHelper.compareTimeOfDay(a.startTime, b.startTime),
              );
          isLoading = false;

          _updateClassStates(); // Update class states after loading
        });
      } else {
        throw Exception('Failed to load classes: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load classes: ${e.toString()}';
        todayClasses = [];
      });
    }
  }

  List<Map<String, String>> filteredStudents = [];
  String? employeeName; // Default value
  String? employeeDepartment; // Default value
  // Function to load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      employeeName = prefs.getString('userName');
      employeeDepartment = prefs.getString('department');
    });
  }

  // Function to handle search
  void searchStudent(String query) {
    setState(() {
      filteredStudents =
          students
              .where(
                (student) =>
                    student["id"]!.contains(query) ||
                    student["name"]!.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    student["rollNumber"]!.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    student["class"]!.contains(query),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(
        backgroundColor: Colors.white,
        iconColor: Colors.black,
      ),
      backgroundColor: ColorStyle.BlueStatic,
      appBar: AppBar(
        backgroundColor: ColorStyle.BlueStatic,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open drawer on menu tap
          },
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
        ),
        onRefresh: () async {
          try {
            await fetchEnrolledSubjects(isRefresh: true);
            _updateClassStates();
            // Show refresh a bit longer
            _refreshController.refreshCompleted();
          } catch (e) {
            _refreshController.refreshFailed();
          }
        },
        child: Column(
          children: [
            // Profile Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/profile.png', width: 70),
                  SizedBox(width: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName ?? 'unKnown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(employeeDepartment ?? 'unKnown'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.0),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height / 4,
                  color: Colors.white,

                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Class Card
                      if (currentClass != null &&
                          currentClass?.status != "completed")
                        selectedClassDetails(
                          classInfo: currentClass!,
                          status: currentClass?.status,
                          onJoinPressed: () async {
                            _player.play(AssetSource('sounds/sound.mp3'));
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MarkAttendenceTeacher(
                                      classData: currentClass!,
                                    ),
                              ),
                            );
                            // This code runs when returning from BluetoothScreen
                            await fetchTodayClasses(); // Reload today's classes
                            _updateClassStates();
                          },
                        ),
                      // Current Class Card
                      if (currentClass != null &&
                          currentClass?.status == "completed")
                        selectedClassDetails(
                          classInfo: currentClass!,
                          onJoinPressed: () {
                            _player.play(AssetSource('sounds/sound.mp3'));
                          },
                          status: currentClass?.status,
                        ),
                      // Next Class Card
                      if (currentClass == null && nextClass != null)
                        BuildNextClassCard(
                          classInfo: nextClass!,
                          nextClassRemainingTime: nextClassRemainingTime,
                          isStudent: true,
                        ),
                      if (currentClass == null && nextClass == null)
                        noClassDetail(Colors.black),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: -28,
                  child: Image.asset('assets/images/teacher.png', width: 180),
                ),
              ],
            ),
            // const Icon(Icons.calendar_today, size: 30, color: Colors.blue), // Calendar Icon
            // const Icon(Icons.people, size: 30, color: Colors.blue), // People Icon
            // const Icon(Icons.computer, size: 30, color: Colors.blue), // Monitor Icon
            // const Icon(Icons.storage, size: 30, color: Colors.blue), // Database Icon
            // const Icon(Icons.language, size: 30, color: Colors.blue), // Globe Icon
            SizedBox(height: 10),
            // Tabs: Enroll, Today, Student
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTab("Enroll", 'assets/images/Contract.png'),
                _buildTab("Today", 'assets/images/Calendar.png'),
                _buildTab("Student", 'assets/images/Student.png'),
              ],
            ),

            // Dynamic Content Section
            Expanded(
              child:
                  activeTab == "Enroll"
                      ? _buildEnrollSection()
                      : activeTab == "Today"
                      ? _buildTodaySection(isLoading)
                      : _buildStudentSection(),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for tabs
  Widget _buildTab(String title, String image) {
    return GestureDetector(
      onTap: () {
        setState(() {
          activeTab = title;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: activeTab == title ? const Color(0xFFD9D9D9) : null,
            ),
            child: Image.asset(image, width: 40),
          ),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildEnrollSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          enrolledSubjects.isEmpty
              ? _buildLoadingShimmer()
              : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.9, // Adjusted for text below
                ),
                itemCount: enrolledSubjects.length,
                itemBuilder: (context, index) {
                  final subject = enrolledSubjects[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  SubjectDetailsPage(subjectData: subject),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Original box with course initials
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: ColorStyle.BlueStatic,
                            child: Text(
                              _getCourseInitials(subject['course']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Text information in column
                        Column(
                          children: [
                            // Course name
                            Text(
                              subject['course'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Semester
                            Text(
                              'Semester ${subject['semester']} | ${subject['section'].toString().toUpperCase()}',

                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.9,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 12,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  Container(
                    width: 40,
                    height: 10,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 2),
                  ),
                  Container(width: 30, height: 10, color: Colors.white),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodaySection(bool isLoading) {
    return isLoading
        ? Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: todayClasses.length,
            itemBuilder: (context, index) {
              final classInfo = todayClasses[index];
              print(classInfo);
              return Container(
                margin: EdgeInsets.only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Color(0xFFD9D9D9),
                        ),
                        SizedBox(width: 15),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Semester:"),
                            Text("course: "),
                            Text("Room:"),
                          ],
                        ),
                      ],
                    ),

                    Container(
                      padding: EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Color(0xFFB2CCDF),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/Diagram.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: todayClasses.length,
          itemBuilder: (context, index) {
            final classInfo = todayClasses[index];
            print(classInfo);
            return Container(
              margin: EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Color(0xFFD9D9D9),
                        child: Text(
                          _getCourseInitials(classInfo.course),
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                      SizedBox(width: 15),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(classInfo.course),
                          Text("Semester: ${classInfo.semester}"),
                          Text("Respriby: ${classInfo.raspberry_Pi}"),
                          Text("Room: ${classInfo.room}"),
                        ],
                      ),
                    ],
                  ),

                  Container(
                    padding: EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: ColorStyle.BlueStatic,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/Diagram.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _buildNextClassCard(ClassInfo classInfo) {
    return Container(
      margin: EdgeInsets.only(bottom: 35.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${classInfo.course.split(' ').take(10).join(' ')} (${classInfo.courseCode})',
            style: TextStyle(
              fontSize: 24,
              color: Colors.black87,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Room: ${classInfo.room}',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF5C5C5C),
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatDuration(nextClassRemainingTime!),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Student Section
  Widget _buildStudentSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: "Search Student",
              border: OutlineInputBorder(),
            ),
            onChanged: searchStudent,
          ),
        ),
        Expanded(
          child:
              filteredStudents.isEmpty
                  ? const Center(child: Text("No Student Found"))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return Card(
                        child: ListTile(
                          title: Text(student["name"]!),
                          subtitle: Text(
                            "Roll No: ${student['rollNumber']} | Class: ${student['class']}",
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
