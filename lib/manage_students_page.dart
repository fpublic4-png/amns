import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    final userRole = prefs.getString('userRole');

    setState(() {
      _userRole = userRole;
    });

    if (userRole == 'teacher' && userEmail != null) {
      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherData = teacherQuery.docs.first.data();
        if (teacherData['isClassTeacher'] == true) {
          setState(() {
            _teacherClass = teacherData['classTeacherClass'];
            _teacherSection = teacherData['classTeacherSection'];
          });
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showAddStudentDialog({DocumentSnapshot? student}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddStudentDialog(
          userRole: _userRole,
          teacherClass: _teacherClass,
          teacherSection: _teacherSection,
          student: student,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          if (_userRole == 'admin' ||
              (_userRole == 'teacher' && _teacherClass != null))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddStudentDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userRole == 'teacher' &&
                (_teacherClass == null || _teacherSection == null)
          ? const Center(child: Text('You are not a class teacher.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student List',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A list of all registered students' +
                            (_userRole == 'teacher' ? ' in your class.' : '.'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _userRole == 'teacher'
                        ? FirebaseFirestore.instance
                              .collection('students')
                              .where('class', isEqualTo: _teacherClass)
                              .where('section', isEqualTo: _teacherSection)
                              .snapshots()
                        : FirebaseFirestore.instance
                              .collection('students')
                              .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Something went wrong.'),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No students found.'));
                      }

                      final students = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final studentData =
                              student.data() as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ListTile(
                              title: Text(studentData['fullName'] ?? 'No Name'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email: ${studentData['email'] ?? 'N/A'}',
                                  ),
                                  Text(
                                    'Class: ${studentData['class'] ?? 'N/A'}',
                                  ),
                                  Text(
                                    'Section: ${studentData['section'] ?? 'N/A'}',
                                  ),
                                  Text(
                                    'House: ${studentData['house'] ?? 'N/A'}',
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showAddStudentDialog(student: student),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteStudent(student.id),
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
}

class AddStudentDialog extends StatefulWidget {
  final String? userRole;
  final String? teacherClass;
  final String? teacherSection;
  final DocumentSnapshot? student;

  const AddStudentDialog({
    this.userRole,
    this.teacherClass,
    this.teacherSection,
    this.student,
    super.key,
  });

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedHouse;
  bool _passwordVisible = false;

  final List<String> _classes = [
    'Nursery',
    'LKG',
    'UKG',
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
  ];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];
  final List<String> _houses = ['Ganga', 'Yamuna', 'Jhelum', 'Chenab'];

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      final studentData = widget.student!.data() as Map<String, dynamic>;
      _studentIdController.text = studentData['studentId'] ?? '';
      _fullNameController.text = studentData['fullName'] ?? '';
      _emailController.text = studentData['email'] ?? '';
      _passwordController.text = studentData['password'] ?? '';
      _selectedClass = studentData['class'];
      _selectedSection = studentData['section'];
      _selectedHouse = studentData['house'];
    } else if (widget.userRole == 'teacher') {
      _selectedClass = widget.teacherClass;
      _selectedSection = widget.teacherSection;
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateStudent() async {
    if (_formKey.currentState!.validate()) {
      final studentData = {
        'studentId': _studentIdController.text,
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'class': _selectedClass,
        'section': _selectedSection,
        'house': _selectedHouse,
      };

      try {
        if (widget.student != null) {
          await FirebaseFirestore.instance
              .collection('students')
              .doc(widget.student!.id)
              .update(studentData);
        } else {
          await FirebaseFirestore.instance
              .collection('students')
              .add(studentData);
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Student ${widget.student != null ? 'updated' : 'added'} successfully!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save student: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student != null ? 'Edit Student' : 'Add Student'),
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
                controller: _fullNameController,
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
                    value!.isEmpty ? 'Please enter a password' : null,
              ),
              if (widget.userRole == 'admin')
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClass,
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
                        value: _selectedSection,
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
                    'Class: ${widget.teacherClass} - ${widget.teacherSection}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              DropdownButtonFormField<String>(
                value: _selectedHouse,
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
          onPressed: _addOrUpdateStudent,
          child: Text(widget.student != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
