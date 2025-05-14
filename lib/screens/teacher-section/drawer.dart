import 'package:smart_track/screens/auth/log-in.dart';
import 'package:smart_track/screens/teacher-section/main.dart';
import 'package:smart_track/screens/teacher-section/pages/schedule.dart';
import 'package:smart_track/screens/teacher-section/pages/search-student.dart';
import 'package:smart_track/screens/teacher-section/pages/today-report.dart';
import 'package:flutter/material.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatefulWidget {
  final Color backgroundColor;
  final Color iconColor;

  const CustomDrawer({
    super.key,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String userName = "Guest";
  String userEmail = "Guest";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "Guest";
      userEmail = prefs.getString('userEmail') ?? "Guest";
    });
  }

  Future<void> checkUserStatus() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeTeacher()),
    );
  }

  // Function to handle logout
  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refreshToken');
    String? accessToken = prefs.getString('accessToken');

    if (refreshToken == null || accessToken == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeTeacher()),
      );
    }

    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LogInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBlue = widget.backgroundColor == ColorStyle.BlueStatic;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: widget.backgroundColor,
        elevation: 0,
        child: Drawer(
          width: MediaQuery.of(context).size.width / 1.5,
          child: Container(
            color: widget.backgroundColor,
            child: Column(
              children: [
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: checkUserStatus,
                  child: Image.asset(
                    isBlue
                        ? 'assets/images/profile2.png'
                        : 'assets/images/profile.png',
                    width: 100,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: isBlue ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDrawerTile(
                  context,
                  icon: Icons.bar_chart,
                  label: 'Search Student',
                  isBlue: isBlue,
                  targetPage: const SearchStudentTeacher(),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.show_chart,
                  label: 'Schedule',
                  isBlue: isBlue,
                  targetPage: ScheduleTeacher(),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Today Report',
                  isBlue: isBlue,
                  targetPage: TodayReportTeacher(),
                ),
                const Spacer(),
                const Divider(thickness: 1, color: Colors.black38),
                ListTile(
                  leading: Icon(Icons.logout, color: widget.iconColor),
                  title: Text(
                    'Log Out',
                    style: TextStyle(
                      color: isBlue ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: logoutUser,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ListTile _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isBlue,
    required Widget targetPage,
  }) {
    return ListTile(
      leading: Icon(icon, color: widget.iconColor),
      title: Text(
        label,
        style: TextStyle(color: isBlue ? Colors.white : Colors.black),
      ),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
    );
  }
}
