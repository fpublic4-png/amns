import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTeachersPage extends StatefulWidget {
  const ManageTeachersPage({super.key});

  @override
  State<ManageTeachersPage> createState() => _ManageTeachersPageState();
}

class _ManageTeachersPageState extends State<ManageTeachersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Manage Teachers',
          style: TextStyle(color: Colors.green),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddTeacherDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Teacher',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No teachers found.'));
          }

          final teachers = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teacher List',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'A list of all registered teachers.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = teachers[index];
                        final data = teacher.data() as Map<String, dynamic>;

                        String classesDisplay = 'N/A';
                        if (data.containsKey('classesTaught')) {
                          final classesData = data['classesTaught'];
                          if (classesData is Map) {
                            final classes = classesData.cast<String, dynamic>();
                            classesDisplay = classes.entries
                                .map(
                                  (e) =>
                                      '${e.key}: ${((e.value as Map<String, dynamic>).entries.where((element) => element.value).map((e) => e.key).toList()).join(', ')}',
                                )
                                .join('\n');
                          } else if (classesData is List) {
                            classesDisplay = classesData.join(', ');
                          }
                        }

                        String subjectsDisplay = 'N/A';
                        if (data.containsKey('subjects')) {
                          final subjectsData = data['subjects'];
                          if (subjectsData is List) {
                            subjectsDisplay = subjectsData.join(', ');
                          } else if (subjectsData is String) {
                            subjectsDisplay = subjectsData;
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(data['fullName'] ?? 'N/A'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['email'] ?? 'N/A'),
                                Text('Classes: $classesDisplay'),
                                Text('Subjects: $subjectsDisplay'),
                                Text(
                                  'Class Teacher: ${data['isClassTeacher'] == true ? 'Yes' : 'No'}',
                                ),
                                if (data['isClassTeacher'] == true)
                                  Text(
                                    'Class: ${data['classTeacherClass']}, Section: ${data['classTeacherSection']}',
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _showAddTeacherDialog(teacher: teacher),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _showDeleteConfirmationDialog(teacher.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddTeacherDialog({DocumentSnapshot? teacher}) {
    showDialog(
      context: context,
      builder: (context) => AddTeacherDialog(teacher: teacher),
    );
  }

  void _showDeleteConfirmationDialog(String teacherId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: const Text('Are you sure you want to delete this teacher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('teachers')
                  .doc(teacherId)
                  .delete();
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddTeacherDialog extends StatefulWidget {
  final DocumentSnapshot? teacher;

  const AddTeacherDialog({this.teacher, super.key});

  @override
  State<AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _teacherIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectsController = TextEditingController();
  String? _selectedHouse;
  bool _isClassTeacher = false;
  String? _classTeacherClass;
  String? _classTeacherSection;
  Map<String, Map<String, bool>> _classesTaught = {};

  final List<String> _houses = ['Earth', 'Uranus', 'Saturn', 'Mars'];
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
  final List<String> _sections = [
    'Section A',
    'Section B',
    'Section C',
    'Section D',
    'Section E',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      final data = widget.teacher!.data() as Map<String, dynamic>;
      _teacherIdController.text = data['teacherId'] ?? '';
      _fullNameController.text = data['fullName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';

      if (data.containsKey('subjects')) {
        final subjectsData = data['subjects'];
        if (subjectsData is List) {
          _subjectsController.text = subjectsData.join(', ');
        } else if (subjectsData is String) {
          _subjectsController.text = subjectsData;
        }
      }

      _selectedHouse = data['house'];
      _isClassTeacher = data['isClassTeacher'] ?? false;
      _classTeacherClass = data['classTeacherClass'];
      _classTeacherSection = data['classTeacherSection'];

      if (data['classesTaught'] is Map) {
        _classesTaught =
            (data['classesTaught'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                key,
                (value as Map<String, dynamic>).cast<String, bool>(),
              ),
            ) ??
            {};
      }
    }
    for (var className in _classes) {
      if (!_classesTaught.containsKey(className)) {
        _classesTaught[className] = {
          'Section A': false,
          'Section B': false,
          'Section C': false,
          'Section D': false,
          'Section E': false,
        };
      } else {
        for (var sectionName in _sections) {
          if (!_classesTaught[className]!.containsKey(sectionName)) {
            _classesTaught[className]![sectionName] = false;
          }
        }
      }
    }
  }

  Future<void> _addOrUpdateTeacher() async {
    if (_formKey.currentState!.validate()) {
      try {
        final teacherData = {
          'teacherId': _teacherIdController.text,
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'phone': _phoneController.text,
          'house': _selectedHouse,
          'subjects': _subjectsController.text
              .split(',')
              .map((s) => s.trim())
              .toList(),
          'isClassTeacher': _isClassTeacher,
          'classTeacherClass': _classTeacherClass,
          'classTeacherSection': _classTeacherSection,
          'classesTaught': _classesTaught,
        };

        if (widget.teacher != null) {
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(widget.teacher!.id)
              .update(teacherData);
        } else {
          await FirebaseFirestore.instance
              .collection('teachers')
              .add(teacherData);
        }

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add/update teacher: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher != null ? 'Edit Teacher' : 'Add New Teacher'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _teacherIdController,
                decoration: const InputDecoration(labelText: 'Teacher ID'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter an ID'
                    : null,
              ),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value == null || value.isEmpty || !value.contains('@')
                    ? 'Please enter a valid email'
                    : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a password'
                    : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedHouse,
                hint: const Text('Select House'),
                items: _houses
                    .map(
                      (house) =>
                          DropdownMenuItem(value: house, child: Text(house)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedHouse = value),
              ),
              TextFormField(
                controller: _subjectsController,
                decoration: const InputDecoration(
                  labelText: 'Subjects (comma-separated)',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Classes Taught',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._classes.map((className) {
                return ExpansionTile(
                  title: Text(className),
                  children: _sections.map((sectionName) {
                    return CheckboxListTile(
                      title: Text(sectionName),
                      value:
                          _classesTaught.containsKey(className) &&
                          _classesTaught[className]!.containsKey(sectionName) &&
                          _classesTaught[className]![sectionName]!,
                      onChanged: (value) {
                        setState(() {
                          if (!_classesTaught.containsKey(className)) {
                            _classesTaught[className] = {};
                          }
                          _classesTaught[className]![sectionName] = value!;
                        });
                      },
                    );
                  }).toList(),
                );
              }),
              CheckboxListTile(
                title: const Text('Is Class Teacher?'),
                value: _isClassTeacher,
                onChanged: (value) => setState(() => _isClassTeacher = value!),
              ),
              if (_isClassTeacher)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _classTeacherClass,
                        hint: const Text('Select Class'),
                        items: _classes
                            .map(
                              (className) => DropdownMenuItem(
                                value: className,
                                child: Text(className),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _classTeacherClass = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _classTeacherSection,
                        hint: const Text('Select Section'),
                        items: _sections
                            .map(
                              (sectionName) => DropdownMenuItem(
                                value: sectionName,
                                child: Text(sectionName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _classTeacherSection = value),
                      ),
                    ),
                  ],
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
          onPressed: _addOrUpdateTeacher,
          child: Text(widget.teacher != null ? 'Update' : 'Add Teacher'),
        ),
      ],
    );
  }
}
