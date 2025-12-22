import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/edit_student_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  String? _userRole;
  String? _teacherClass;
  String? _teacherSection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');
      setState(() {
        _userRole = prefs.getString('userRole');
      });

      if (_userRole == 'teacher' && userEmail != null) {
        final teacherQuery = await FirebaseFirestore.instance
            .collection('teachers')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (mounted && teacherQuery.docs.isNotEmpty) {
          final teacherData = teacherQuery.docs.first.data();
          if (teacherData['isClassTeacher'] == true) {
            setState(() {
              _teacherClass = teacherData['classTeacherClass'];
              _teacherSection = teacherData['classTeacherSection'];
            });
          }
        }
      }
    } catch (e, s) {
      developer.log(
        'Error fetching user data',
        name: 'myapp.manage_students',
        error: e,
        stackTrace: s,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddStudentDialog(
          userRole: _userRole,
          teacherClass: _teacherClass,
          teacherSection: _teacherSection,
        );
      },
    );
  }

  void _showEditStudentDialog(DocumentSnapshot student) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: EditStudentForm(
            student: student,
            onStudentUpdated: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student updated successfully!'),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteStudent(String studentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete student: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacherWithoutClass = _userRole == 'teacher' && _teacherClass == null;
    final canAddStudent = _userRole == 'admin' || !isTeacherWithoutClass;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          if (canAddStudent)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _showAddStudentDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Student',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isTeacherWithoutClass
              ? const Center(
                  child: Text('You are not assigned as a class teacher.'),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student List',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A list of all registered students.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _getStudentsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            developer.log(
                              'Error in students stream',
                              name: 'myapp.manage_students',
                              error: snapshot.error,
                            );
                            return const Center(
                              child: Text('Something went wrong.'),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text('No students found.'));
                          }

                          final students = snapshot.data!.docs;

                          return ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];
                              final studentData =
                                  student.data() as Map<String, dynamic>;
                              final className = studentData['class']?.toString();

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 6.0,
                                ),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              studentData['name'] ??
                                                  'No Name',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Email: ${studentData['email'] ?? 'N/A'}',
                                            ),
                                            Text(
                                              'Phone: ${studentData['phone'] ?? 'N/A'}',
                                            ),
                                            Text(
                                                'Class: ${className ?? 'N/A'}'),
                                            Text(
                                              'Section: ${studentData['section'] ?? 'N/A'}',
                                            ),
                                            Text(
                                              'House: ${studentData['house'] ?? 'N/A'}',
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed: () =>
                                            _showEditStudentDialog(student),
                                        tooltip: 'Edit Student',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _deleteStudent(student.id),
                                        tooltip: 'Delete Student',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Stream<QuerySnapshot> _getStudentsStream() {
    if (_userRole == 'teacher') {
      if (_teacherClass == null) {
        // Return an empty stream if the teacher is not a class teacher
        return const Stream.empty();
      }
      return FirebaseFirestore.instance
          .collection('students')
          .where('class', isEqualTo: _teacherClass)
          .where('section', isEqualTo: _teacherSection)
          .snapshots();
    } else {
      // Admin sees all students
      return FirebaseFirestore.instance.collection('students').snapshots();
    }
  }
}

class AddStudentDialog extends StatefulWidget {
  final String? userRole;
  final String? teacherClass;
  final String? teacherSection;

  const AddStudentDialog({
    super.key,
    this.userRole,
    this.teacherClass,
    this.teacherSection,
  });

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _motherNameController = TextEditingController();
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedHouse;
  bool _passwordVisible = false;

  final List<String> _classes = [
    'Nursery',
    'LKG',
    'UKG',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
  ];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];
  final List<String> _houses = ['Earth', 'Uranus', 'Saturn', 'Mars'];

  @override
  void initState() {
    super.initState();
    if (widget.userRole == 'teacher') {
      _selectedClass = widget.teacherClass;
      _selectedSection = widget.teacherSection;
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _motherNameController.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final studentData = {
      'studentId': _studentIdController.text,
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'fatherName': _fatherNameController.text,
      'fatherPhone': _fatherPhoneController.text,
      'motherName': _motherNameController.text,
      'class': _selectedClass,
      'section': _selectedSection,
      'house': _selectedHouse,
    };

    try {
      await FirebaseFirestore.instance.collection('students').add(studentData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added successfully!'),
          ),
        );
      }
    } catch (e, s) {
      developer.log(
        'Error saving student',
        name: 'myapp.manage_students',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save student: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.userRole == 'teacher';

    return AlertDialog(
      title: const Text('Add Student'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a student ID' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a password' : null),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _fatherNameController,
                decoration: const InputDecoration(labelText: 'Father\'s Name'),
              ),
              TextFormField(
                controller: _fatherPhoneController,
                decoration: const InputDecoration(labelText: 'Father\'s Phone'),
              ),
              TextFormField(
                controller: _motherNameController,
                decoration: const InputDecoration(labelText: 'Mother\'s Name'),
              ),
              if (!isTeacher)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedClass,
                        hint: const Text('Select Class'),
                        items: _classes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) =>
                            setState(() => _selectedClass = newValue),
                        validator: (value) =>
                            value == null ? 'Please select a class' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSection,
                        hint: const Text('Select Section'),
                        items: _sections.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) =>
                            setState(() => _selectedSection = newValue),
                        validator: (value) =>
                            value == null ? 'Please select a section' : null,
                      ),
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Class: $_selectedClass - Section $_selectedSection',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _selectedHouse,
                hint: const Text('Select House'),
                items: _houses.map((String house) {
                  return DropdownMenuItem<String>(
                    value: house,
                    child: Text(house),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedHouse = newValue),
                validator: (value) =>
                    value == null ? 'Please select a house' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addStudent,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
