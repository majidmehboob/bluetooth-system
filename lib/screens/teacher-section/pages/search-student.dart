import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_track/screens/teacher-section/drawer.dart';

class SearchStudentTeacher extends StatefulWidget {
  const SearchStudentTeacher({super.key});

  @override
  State<SearchStudentTeacher> createState() => _SearchStudentState();
}

class _SearchStudentState extends State<SearchStudentTeacher> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> students = [
    {
      'name': 'Abdullah',
      'rollNumber': '21-NTU-CS-1231',
      'class': 'BSCS 4 semester',
      'chartData1': [
        FlSpot(0, 2),
        FlSpot(2, 3),
        FlSpot(5.9, 2),
        FlSpot(6.8, 4.1),
        FlSpot(8, 5),
        FlSpot(9.5, 1),
        FlSpot(11, 6),
      ],
      'chartData2': [
        FlSpot(0, 3),
        FlSpot(2.6, 2),
        FlSpot(4.9, 5),
        FlSpot(6.8, 3.1),
        FlSpot(8, 4),
        FlSpot(9.5, 3),
        FlSpot(11, 4),
      ],
    },
    {
      'name': 'Ali',
      'rollNumber': '21-NTU-CS-1232',
      'class': 'BSCS 4 semester',
      'chartData1': [
        FlSpot(0, 1),
        FlSpot(2, 4),
        FlSpot(5.9, 3),
        FlSpot(6.8, 2.1),
        FlSpot(8, 6),
        FlSpot(9.5, 2),
        FlSpot(11, 5),
      ],
      'chartData2': [
        FlSpot(0, 2),
        FlSpot(2.6, 3),
        FlSpot(4.9, 4),
        FlSpot(6.8, 2.1),
        FlSpot(8, 5),
        FlSpot(9.5, 4),
        FlSpot(11, 3),
      ],
    },
    {
      'name': 'Ahmed',
      'rollNumber': '21-NTU-CS-1233',
      'class': 'BSCS 4 semester',
      'chartData1': [
        FlSpot(0, 4),
        FlSpot(2, 2),
        FlSpot(5.9, 5),
        FlSpot(6.8, 3.1),
        FlSpot(8, 4),
        FlSpot(9.5, 6),
        FlSpot(11, 2),
      ],
      'chartData2': [
        FlSpot(0, 3),
        FlSpot(2.6, 4),
        FlSpot(4.9, 2),
        FlSpot(6.8, 5.1),
        FlSpot(8, 3),
        FlSpot(9.5, 4),
        FlSpot(11, 5),
      ],
    },
  ];

  List<Color> gradientColors = [
    const Color.fromRGBO(173, 183, 249, 1),
    const Color.fromRGBO(177, 185, 248, 0),
  ];

  List<Color> gradientColors2 = [
    const Color.fromRGBO(244, 167, 157, 1),
    const Color.fromRGBO(244, 167, 157, 0),
  ];

  List<Map<String, dynamic>> get filteredStudents {
    if (_searchController.text.isEmpty) {
      return students;
    }
    return students
        .where(
          (student) => student['name'].toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFB2CCDF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB2CCDF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: const CustomDrawer(
        backgroundColor: Colors.white,
        iconColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: 16),
            // Students List
            Expanded(
              child: ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildChartContainer(
                      student: _buildTextStudentName(
                        student['name'],
                        student['rollNumber'],
                      ),
                      chart: _buildOverlappingLineCharts(
                        student['chartData1'],
                        student['chartData2'],
                      ),
                      height: 200,
                      className: student['class'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search students...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildChartContainer({
    required Widget student,
    required Widget chart,
    required double height,
    required String className,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            student,
            const SizedBox(height: 8),
            SizedBox(height: height, child: chart),
            const SizedBox(height: 2),
            Text(
              className,

              style: TextStyle(
                fontSize: 12,
                color: Color.fromRGBO(123, 116, 116, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStudentName(String name, String rollNumber) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            rollNumber,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              color: Color.fromRGBO(123, 116, 116, 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlappingLineCharts(
    List<FlSpot> chartData1,
    List<FlSpot> chartData2,
  ) {
    return Stack(
      children: [
        // Background Chart (slightly larger and offset)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: 6,
              lineBarsData: [
                LineChartBarData(
                  spots: chartData1,
                  isCurved: true,
                  color: const Color(0xFF80A7D5),
                  barWidth: 1,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors:
                          gradientColors2
                              .map((color) => color.withOpacity(0.5))
                              .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Foreground Chart (main chart)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 80,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: 6,
              lineBarsData: [
                LineChartBarData(
                  spots: chartData2,
                  isCurved: true,
                  barWidth: 0,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors:
                          gradientColors
                              .map((color) => color.withOpacity(0.3))
                              .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
