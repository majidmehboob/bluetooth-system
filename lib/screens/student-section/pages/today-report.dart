import 'package:flutter/material.dart';
import 'package:smart_track/features/api-section/student.dart';
import 'package:smart_track/services/shimmer-services.dart';
import 'package:smart_track/services/time-helper.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:smart_track/screens/student-section/drawer.dart';
import 'package:smart_track/widgets/snackbar-helper.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:smart_track/services/text-helper.dart';
import 'package:smart_track/widgets/not-found.dart';

class TodayReportStudent extends StatefulWidget {
  const TodayReportStudent({super.key});

  @override
  State<TodayReportStudent> createState() => _TodayReportScreenState();
}

class _TodayReportScreenState extends State<TodayReportStudent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isInitialLoading = true;
  String errorMessage = '';
  String currentDate = '';
  String currentDay = '';
  String currentTime = '';
  String searchQuery = '';
  List<dynamic> upcomingClasses = [];
  List<dynamic> completedClasses = [];
  List<dynamic> ongoingClasses = [];
  List<dynamic> nottakenClasses = [];

  // Track expanded state for each section
  bool isOngoingExpanded = true;
  bool isUpcomingExpanded = true;
  bool isCompletedExpanded = true;
  bool isNotTakenExpanded = true;

  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final reportData = await ClassApiService.fetchTodayAttendanceReport();

      if (mounted) {
        setState(() {
          currentDate = reportData['date'];
          currentDay = reportData['day'];
          currentTime = reportData['current_time'];
          upcomingClasses = reportData['upcoming_classes'] ?? [];
          completedClasses = reportData['completed_classes'] ?? [];
          ongoingClasses = reportData['ongoing_classes'] ?? [];
          nottakenClasses = reportData['not_taken_classes'] ?? [];
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          SnackbarHelper.showError(context, 'Error: ${e.toString()}');
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final reportData = await ClassApiService.fetchTodayAttendanceReport();

      if (mounted) {
        setState(() {
          currentDate = reportData['date'];
          currentDay = reportData['day'];
          currentTime = reportData['current_time'];
          upcomingClasses = reportData['upcoming_classes'] ?? [];
          completedClasses = reportData['completed_classes'] ?? [];
          ongoingClasses = reportData['ongoing_classes'] ?? [];
          nottakenClasses = reportData['not_taken_classes'] ?? [];
        });
      }
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      drawer: CustomDrawer(
        backgroundColor: Colors.white,
        iconColor: Colors.black,
      ),
      body:
          _isInitialLoading
              ? ShimmerHelper.buildTodayShimmer()
              : SmartRefresher(
                controller: _refreshController,
                onRefresh: _handleRefresh,
                enablePullDown: true,
                header: ClassicHeader(
                  refreshStyle: RefreshStyle.Follow,
                  completeText: 'Refresh complete',
                  refreshingText: 'Refreshing...',
                  releaseText: 'Release to refresh',
                  idleText: 'Pull down to refresh',
                  textStyle: TextStyle(color: ColorStyle.BlueStatic),
                  height: 60,
                  refreshingIcon: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(ColorStyle.BlueStatic),
                  ),
                ),
                child: _buildContent(),
              ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Report - $currentDay",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Date: $currentDate | Time: ${TimeHelper.formatTimeDayHourMinute(currentTime)}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (ongoingClasses.isEmpty &&
                nottakenClasses.isEmpty &&
                upcomingClasses.isEmpty &&
                completedClasses.isEmpty)
              Expanded(
                child: NoClassesFound(
                  onRefresh: _handleRefresh,
                  message: 'No Class Schedule for today or Today is Sunday',
                  parameter: ' Todays Classes',
                ),
              ),

            // Ongoing Classes
            if (ongoingClasses.isNotEmpty) ...[
              _buildExpandableHeader(
                "Ongoing Classes",
                isOngoingExpanded,
                () => setState(() => isOngoingExpanded = !isOngoingExpanded),
              ),
              const SizedBox(height: 8),
              if (isOngoingExpanded) ...[
                ..._buildClassList(ongoingClasses),
                const SizedBox(height: 16),
              ],
            ],
            const SizedBox(height: 6),

            // Upcoming Classes
            if (upcomingClasses.isNotEmpty) ...[
              _buildExpandableHeader(
                "Upcoming Classes",
                isUpcomingExpanded,
                () => setState(() => isUpcomingExpanded = !isUpcomingExpanded),
              ),
              const SizedBox(height: 8),
              if (isUpcomingExpanded) ...[
                ..._buildClassList(upcomingClasses),
                const SizedBox(height: 16),
              ],
            ],

            // Completed Classes
            if (completedClasses.isNotEmpty) ...[
              _buildExpandableHeader(
                "Completed Classes",
                isCompletedExpanded,
                () =>
                    setState(() => isCompletedExpanded = !isCompletedExpanded),
              ),
              const SizedBox(height: 8),
              if (isCompletedExpanded) ...[
                ..._buildClassList(completedClasses),
              ],
            ],

            // Not Taken Classes
            if (nottakenClasses.isNotEmpty) ...[
              _buildExpandableHeader(
                "Not Taken Classes",
                isNotTakenExpanded,
                () => setState(() => isNotTakenExpanded = !isNotTakenExpanded),
              ),
              const SizedBox(height: 8),
              if (isNotTakenExpanded) ...[..._buildClassList(nottakenClasses)],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableHeader(
    String text,
    bool isExpanded,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: ColorStyle.BlueStatic,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            Icon(
              isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildClassList(List<dynamic> classes) {
    return List.generate(classes.length, (index) {
      final classInfo = classes[index];

      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: ColorStyle.WhiteStatic,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: TextFormatHelper.getAvatarColor(index),
              child: Text(
                classInfo['course_name']
                    .toString()
                    .substring(0, 2)
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          classInfo['course_name'],
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        TimeHelper.formatTimeDayHourMinute(
                          classInfo['start_time'],
                        ),
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Instructor: ${classInfo['instructor']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Room: ${classInfo['room']} | Sec: ${classInfo['section'].toString().toUpperCase()}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        TextFormatHelper.getStatusText(
                          classInfo['attendance_status'],
                        ),
                        style: TextStyle(
                          color: TextFormatHelper.getStatusColor(
                            classInfo['attendance_status'],
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
