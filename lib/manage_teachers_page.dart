import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTeachersPage extends StatelessWidget {
  const ManageTeachersPage({super.key});

  void _showAddTeacherDialog(
      {required BuildContext context, DocumentSnapshot? teacher}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTeacherDialog(teacher: teacher);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teachers = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    final data = teacher.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'N/A';
                    final email = data['email'] ?? 'N/A';
                    final phone = data['phone'] ?? 'N/A';
                    final teacherId = data['teacherId'] ?? 'N/A';
                    final isClassTeacher = data['isClassTeacher'] ?? false;

                    String subjectsDisplay = 'N/A';
                    if (data.containsKey('subjects')) {
                      final subjectsData = data['subjects'];
                      if (subjectsData is List) {
                        subjectsDisplay = subjectsData.join(', ');
                      } else if (subjectsData is String) {
                        subjectsDisplay = subjectsData;
                      }
                    }

                    final className = data['classTeacherClass'];
                    final isNumeric =
                        className != null && int.tryParse(className) != null;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('ID: $teacherId'),
                            Text('Email: $email'),
                            Text('Phone: $phone'),
                            Text('Subjects: $subjectsDisplay'),
                            if (isClassTeacher)
                              Text(
                                'Class Teacher of: ${isNumeric ? 'Class $className' : className}, Section: ${data['classTeacherSection']?.toString().replaceAll('Section ', '') ?? ''}',
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
                              onPressed: () => _showAddTeacherDialog(
                                  context: context, teacher: teacher),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('teachers')
                                    .doc(teacher.id)
                                    .delete();
                              },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeacherDialog(context: context),
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class AddTeacherDialog extends StatefulWidget {
  final DocumentSnapshot? teacher;

  const AddTeacherDialog({super.key, this.teacher});

  @override
  State<AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _teacherIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _subjectsController = TextEditingController();

  Map<String, List<String>> _classesTaught = {};
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
    '12'
  ];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  String? _selectedHouse;
  final List<String> _houses = ['Earth', 'Uranus', 'Saturn', 'Mars'];

  bool _isClassTeacher = false;
  String? _classTeacherClass;
  String? _classTeacherSection;

  @override
  void initState() {
    super.initState();
    if (widget.teacher != null) {
      final data = widget.teacher!.data() as Map<String, dynamic>;
      _teacherIdController.text = data['teacherId'] ?? '';
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _passwordController.text = data['password'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _qualificationController.text = data['qualification'] ?? '';

      if (data['subjects'] is List) {
        _subjectsController.text = (data['subjects'] as List).join(', ');
      }

      final rawClassesTaught = data['classes_taught'] as Map? ?? {};
      _classesTaught = rawClassesTaught.map((key, value) {
        final sectionList = (value as List? ?? [])
            .map((section) => section
                .toString()
                .replaceAll('Section ', '')
                .replaceAll('Sec ', ''))
            .toList()
            .cast<String>();
        return MapEntry(key.toString(), sectionList);
      });

      _selectedHouse = data['house'];
      _isClassTeacher = data['isClassTeacher'] ?? false;
      _classTeacherClass = data['classTeacherClass'];

      _classTeacherSection = data['classTeacherSection'];
      if (_classTeacherSection != null) {
        _classTeacherSection = _classTeacherSection!
            .replaceAll('Section ', '')
            .replaceAll('Sec ', '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher == null ? 'Add Teacher' : 'Edit Teacher'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _teacherIdController,
                decoration: const InputDecoration(labelText: 'Teacher ID'),
                validator: (value) => value!.isEmpty ? 'Enter a teacher ID' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value!.isEmpty || !value.contains('@')
                        ? 'Enter a valid email'
                        : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Enter a password' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: _qualificationController,
                decoration: const InputDecoration(labelText: 'Qualification'),
              ),
              TextFormField(
                controller: _subjectsController,
                decoration: const InputDecoration(
                  labelText: 'Subjects Taught',
                  hintText: 'Enter subjects, separated by commas',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Classes and Sections Taught',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._classes.map((className) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(className,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Wrap(
                      children: _sections.map((section) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: (_classesTaught[className] ?? [])
                                  .contains(section),
                              onChanged: (value) {
                                setState(() {
                                  if (value!) {
                                    _classesTaught
                                        .putIfAbsent(className, () => [])
                                        .add(section);
                                  } else {
                                    _classesTaught[className]?.remove(section);
                                    if (_classesTaught[className]?.isEmpty ??
                                        false) {
                                      _classesTaught.remove(className);
                                    }
                                  }
                                });
                              },
                            ),
                            Text(section),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedHouse,
                decoration: const InputDecoration(labelText: 'House'),
                items: _houses.map((String house) {
                  return DropdownMenuItem<String>(
                    value: house,
                    child: Text(house),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedHouse = newValue;
                  });
                },
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isClassTeacher,
                    onChanged: (value) {
                      setState(() {
                        _isClassTeacher = value!;
                      });
                    },
                  ),
                  const Text('Is Class Teacher?'),
                ],
              ),
              if (_isClassTeacher)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _classTeacherClass,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: _classes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _classTeacherClass = newValue;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _classTeacherSection,
                        decoration: const InputDecoration(labelText: 'Section'),
                        items: _sections.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _classTeacherSection = newValue;
                          });
                        },
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
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final subjectsList = _subjectsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              final teacherData = {
                'teacherId': _teacherIdController.text,
                'name': _nameController.text,
                'email': _emailController.text,
                'password': _passwordController.text,
                'phone': _phoneController.text,
                'qualification': _qualificationController.text,
                'subjects': subjectsList,
                'classes_taught': _classesTaught,
                'house': _selectedHouse,
                'isClassTeacher': _isClassTeacher,
                'classTeacherClass':
                    _isClassTeacher ? _classTeacherClass : null,
                'classTeacherSection':
                    _isClassTeacher ? _classTeacherSection : null,
              };

              if (widget.teacher == null) {
                await FirebaseFirestore.instance
                    .collection('teachers')
                    .add(teacherData);
              } else {
                await FirebaseFirestore.instance
                    .collection('teachers')
                    .doc(widget.teacher!.id)
                    .update(teacherData);
              }

              if (mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Text(widget.teacher == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
