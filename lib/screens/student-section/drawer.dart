import 'package:smart_track/screens/student-section/main.dart';
import 'package:flutter/material.dart';
import 'package:smart_track/screens/auth/log-in.dart';
import 'package:smart_track/screens/student-section/pages/schedule.dart';
import 'package:smart_track/screens/student-section/pages/graph-enroll.dart';
import 'package:smart_track/screens/student-section/pages/today-report.dart';
import 'package:smart_track/services/share-preference-services.dart';
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
  String userName = "Guest"; // Default value
  String userEmail = "Guest"; // Default value
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

  Future<void> logoutUser() async {
    final prefs = await SharedPreferencesService.init();
    await prefs.clearAll();
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
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeStudent()),
                    );
                  },
                  child: Image.asset(
                    isBlue
                        ? 'assets/images/profile2.png'
                        : 'assets/images/profile.png',
                    width: 100,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName, // Display the user's name
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isBlue ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  userEmail, // Display the user's email
                  style: TextStyle(
                    fontSize: 14,
                    color: isBlue ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDrawerTile(
                  context,
                  icon: Icons.today_rounded,
                  label: 'Today Report',
                  targetPage: const TodayReportStudent(),
                  isBlue: isBlue,
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.schedule_rounded,
                  label: 'Schedule',
                  targetPage: const ScheduleStudent(),
                  isBlue: isBlue,
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.auto_graph_rounded,
                  label: 'Subjects Report',
                  targetPage: EnrollSubjectGraphStudent(),
                  isBlue: isBlue,
                ),
                const Spacer(),
                Divider(
                  thickness: 1,
                  color: isBlue ? Colors.white60 : Colors.black38,
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: widget.iconColor),
                  title: Text(
                    'Log Out',
                    style: TextStyle(
                      color: isBlue ? Colors.white60 : Colors.black,
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
    required Widget targetPage,
    required bool isBlue,
    // required Offset animationBegin,
  }) {
    return ListTile(
      leading: Icon(icon, color: widget.iconColor),
      title: Text(
        label,
        style: TextStyle(color: isBlue ? Colors.white60 : Colors.black),
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
