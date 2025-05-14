import 'package:flutter/material.dart';
import 'package:smart_track/screens/teacher-section/pages/graph-subject.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SubjectDetailsPage extends StatefulWidget {
  final Map<String, dynamic> subjectData;

  const SubjectDetailsPage({super.key, required this.subjectData});

  @override
  State<SubjectDetailsPage> createState() => _SubjectDetailsPageState();
}

class _SubjectDetailsPageState extends State<SubjectDetailsPage> {
  List<dynamic> students = [];
  bool isLoading = true;
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    print(widget.subjectData);
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse(
          'https://bluetooth-attendence-system.tech-vikings.com/dashboard/filter-students-by-section?section_id=${widget.subjectData['section_id']}&degree_id=${widget.subjectData['degree_id']}',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          students = data['students'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
    }
  }

  List<dynamic> get filteredStudents {
    if (searchQuery.isEmpty) return students;
    return students.where((student) {
      final name = student['student_name'].toString().toLowerCase();
      final regNo = student['registration_number'].toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
          regNo.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.subjectData);
    return Scaffold(
      backgroundColor: ColorStyle.BlueStatic,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            toolbarHeight: 80,
            backgroundColor: Colors.white,

            pinned: true,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final expandRatio = constraints.biggest.height / 200;
                final textOpacity = expandRatio.clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    opacity: 1 - textOpacity,
                    duration: Duration(milliseconds: 200),
                    child: Text(
                      widget.subjectData['course'],
                      style: TextStyle(
                        color: ColorStyle.BlueStatic,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  background: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedOpacity(
                          opacity: textOpacity,
                          duration: Duration(milliseconds: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.subjectData['course'],
                                style: TextStyle(
                                  color: ColorStyle.BlueStatic,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.subjectData['code'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Semester ${widget.subjectData['semester']} | ${widget.subjectData['section'].toString().toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          if (isLoading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredStudents.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  searchQuery.isEmpty
                      ? 'No students found'
                      : 'No matching students',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final student = filteredStudents[index];
                print(student);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            ((context) => SingleSubjectGraphTeacher(
                              course: widget.subjectData['course'],
                              studentName: student['student_name'],
                              semesterId: widget.subjectData['semester_id'],
                              courseId: widget.subjectData['course_id'],
                              rollNumber: student['registration_number'],
                            )),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: ColorStyle.BlueStatic,
                        child: Text(
                          student['student_name'][0],
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        student['student_name'],
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            student['registration_number'],
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            student['uid'],
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${student['degree']} ${student['semester']} ${student['section'].toString().toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(student['session']),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: filteredStudents.length),
            ),
        ],
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final ValueChanged<String> onChanged;

  _SearchBarDelegate({required this.onChanged});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
