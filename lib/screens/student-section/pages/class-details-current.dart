import 'package:flutter/material.dart';

class AttendanceRecordsPage extends StatefulWidget {
  final List<dynamic> records;
  final Map<String, dynamic> studentinfo;
  final Map<String, dynamic> sessioninfo;
  final Map<String, dynamic> attendancesummary;

  const AttendanceRecordsPage({
    super.key,
    required this.records,
    required this.attendancesummary,
    required this.sessioninfo,
    required this.studentinfo,
  });

  @override
  State<AttendanceRecordsPage> createState() => _AttendanceRecordsPageState();
}

class _AttendanceRecordsPageState extends State<AttendanceRecordsPage> {
  bool _studentInfoExpanded = false;
  bool _sessionInfoExpanded = false;
  bool _attendanceSummaryExpanded = false;
  bool _recordsExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Records')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Student Information Section
              _buildExpandableSection(
                title: 'Student Information',
                expanded: _studentInfoExpanded,
                onExpand:
                    (value) => setState(() => _studentInfoExpanded = value),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Name', widget.studentinfo['name']),
                    _buildInfoRow(
                      'Registration Number',
                      widget.studentinfo['registration_number'],
                    ),
                    _buildInfoRow('UID', widget.studentinfo['uid']),
                    _buildInfoRow('Section', widget.studentinfo['section']),
                    _buildInfoRow('Degree', widget.studentinfo['degree']),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Session Information Section
              _buildExpandableSection(
                title: 'Session Information',
                expanded: _sessionInfoExpanded,
                onExpand:
                    (value) => setState(() => _sessionInfoExpanded = value),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Session ID',
                      widget.sessioninfo['id'].toString(),
                    ),
                    _buildInfoRow('Date', widget.sessioninfo['date']),
                    _buildInfoRow('Course', widget.sessioninfo['course']),
                    _buildInfoRow('Status', widget.sessioninfo['status']),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Attendance Summary Section
              _buildExpandableSection(
                title: 'Attendance Summary',
                expanded: _attendanceSummaryExpanded,
                onExpand:
                    (value) =>
                        setState(() => _attendanceSummaryExpanded = value),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Total Records',
                      widget.attendancesummary['total_records'].toString(),
                    ),
                    _buildInfoRow(
                      'Present Records',
                      widget.attendancesummary['present_records'].toString(),
                    ),
                    _buildInfoRow(
                      'Attendance Percentage',
                      '${widget.attendancesummary['attendance_percentage']}%',
                    ),
                    _buildInfoRow(
                      'Overall Present',
                      widget.attendancesummary['overall_present']
                          ? 'Yes'
                          : 'No',
                    ),
                    _buildInfoRow(
                      'Teacher Override',
                      widget.attendancesummary['teacher_override']
                          ? 'Yes'
                          : 'No',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Attendance Records Section
              _buildExpandableSection(
                title: 'Attendance Records (${widget.records.length})',
                expanded: _recordsExpanded,
                onExpand: (value) => setState(() => _recordsExpanded = value),
                content: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.records.length,
                  itemBuilder: (context, index) {
                    final record = widget.records[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: Icon(
                          record['is_present']
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              record['is_present'] ? Colors.green : Colors.red,
                        ),
                        title: Text(record['scanned_time']),
                        subtitle: Text('Method: ${record['method']}'),
                        trailing: Text(
                          record['is_present'] ? 'Present' : 'Absent',
                          style: TextStyle(
                            color:
                                record['is_present']
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool expanded,
    required Function(bool) onExpand,
    required Widget content,
  }) {
    return Card(
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: expanded,
        onExpansionChanged: onExpand,
        children: [
          Padding(padding: const EdgeInsets.all(16.0), child: content),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
