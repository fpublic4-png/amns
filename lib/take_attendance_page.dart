import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TakeAttendancePage extends StatefulWidget {
  const TakeAttendancePage({super.key});

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  String? _teacherId;
  String? _class;
  String? _section;
  List<DocumentSnapshot> _students = [];
  Map<String, String> _attendanceStatus = {};
  bool _isLoading = true;
  bool _isAttendanceSavedToday = false;
  final String _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchTeacherDetails();
    if (_class != null && _section != null) {
      await _fetchStudents();
      await _loadExistingAttendance();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchTeacherDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail == null) return;

    final teacherQuery = await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (teacherQuery.docs.isNotEmpty) {
      final teacherDoc = teacherQuery.docs.first;
      final teacherData = teacherDoc.data();
      if (teacherData['isClassTeacher'] == true) {
        setState(() {
          _teacherId = teacherDoc.id;
          _class = teacherData['classTeacherClass'];
          _section = teacherData['classTeacherSection'];
        });
      }
    }
  }

  Future<void> _fetchStudents() async {
    final studentQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('class', isEqualTo: _class)
        .where('section', isEqualTo: _section)
        .get();
    setState(() {
      _students = studentQuery.docs;
      for (var student in _students) {
        _attendanceStatus.putIfAbsent(student.id, () => 'Present');
      }
    });
  }

  Future<void> _loadExistingAttendance() async {
    final attendanceQuery = await FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: _currentDate)
        .where('class', isEqualTo: _class)
        .where('section', isEqualTo: _section)
        .get();

    if (attendanceQuery.docs.isNotEmpty) {
      Map<String, String> newStatus = {};
      bool allHoliday = true;
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        newStatus[data['studentId']] = data['status'];
        if(data['status'] != 'Holiday') allHoliday = false;
      }
      setState(() {
        _attendanceStatus = newStatus;
        _isAttendanceSavedToday = true;
      });
    }
  }

  void _markAllAsHoliday() {
    setState(() {
      for (var student in _students) {
        _attendanceStatus[student.id] = 'Holiday';
      }
    });
  }

  Future<void> _saveAttendance() async {
    final batch = FirebaseFirestore.instance.batch();

    for (var student in _students) {
      final studentId = student.id;
      final status = _attendanceStatus[studentId];

      if (status != null) {
        final docId = '${_currentDate}_$studentId';
        final attendanceRef = FirebaseFirestore.instance.collection('attendance').doc(docId);
        batch.set(attendanceRef, {
          'date': _currentDate,
          'class': _class,
          'section': _section,
          'studentId': studentId,
          'teacherId': _teacherId,
          'status': status,
        });
      }
    }

    await batch.commit();

    setState(() {
      _isAttendanceSavedToday = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved successfully!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        actions: [
          if (!_isAttendanceSavedToday)
            TextButton.icon(
              onPressed: _markAllAsHoliday,
              icon: const Icon(Icons.event_busy, color: Colors.white),
              label: const Text('Holiday', style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _class == null || _section == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'You are not assigned as a class teacher for any class.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
                )
              : _isAttendanceSavedToday
                  ? _buildSavedView()
                  : _buildEditView(),
      floatingActionButton: _isAttendanceSavedToday || _isLoading || _class == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saveAttendance,
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            ),
    );
  }

  Widget _buildEditView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Date: $_currentDate',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final studentData = student.data() as Map<String, dynamic>;
              final studentId = student.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(studentData['rollNumber']?.toString() ?? '-'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          studentData['name'] ?? 'N/A',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      _buildAttendanceButton(studentId, 'Present', Colors.green),
                      const SizedBox(width: 8),
                      _buildAttendanceButton(studentId, 'Absent', Colors.red),
                      const SizedBox(width: 8),
                      _buildAttendanceButton(studentId, 'Leave', Colors.amber),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 20),
          Text(
            'Attendance for $_currentDate has been saved.',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isAttendanceSavedToday = false;
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Attendance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(String studentId, String status, Color color) {
    final isSelected = _attendanceStatus[studentId] == status;
    return InkWell(
      onTap: () {
        setState(() {
          _attendanceStatus[studentId] = status;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : Colors.grey[300],
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            status[0],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
