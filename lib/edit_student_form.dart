import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditStudentForm extends StatefulWidget {
  final DocumentSnapshot student;
  final VoidCallback onStudentUpdated;

  const EditStudentForm({
    super.key,
    required this.student,
    required this.onStudentUpdated,
  });

  @override
  State<EditStudentForm> createState() => _EditStudentFormState();
}

class _EditStudentFormState extends State<EditStudentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _studentIdController;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  String? _selectedClass;
  String? _selectedHouse;
  String? _selectedSection;
  late TextEditingController _addressController;
  late TextEditingController _fatherNameController;
  late TextEditingController _fatherPhoneController;
  late TextEditingController _motherNameController;
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
  final List<String> _houses = ['Earth', 'Uranus', 'Saturn', 'Mars'];
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    final data = widget.student.data() as Map<String, dynamic>;

    _studentIdController = TextEditingController(text: data['studentId']);
    _fullNameController = TextEditingController(text: data['fullName']);
    _emailController = TextEditingController(text: data['email']);
    _passwordController = TextEditingController(text: data['password']);
    _phoneController = TextEditingController(text: data['phone']);

    _selectedClass = data['class'];
    if (_selectedClass != null && _selectedClass!.startsWith('Class ')) {
      _selectedClass = _selectedClass!.split(' ').last;
    }

    _selectedHouse = data['house'];

    _selectedSection = data['section'];
    if (_selectedSection != null) {
      if (_selectedSection!.startsWith('Section ')) {
        _selectedSection = _selectedSection!.split(' ').last;
      } else if (_selectedSection!.startsWith('Sec ')) {
        _selectedSection = _selectedSection!.split(' ').last;
      }
    }

    _addressController = TextEditingController(text: data['address']);
    _fatherNameController = TextEditingController(text: data['fatherName']);
    _fatherPhoneController = TextEditingController(text: data['fatherPhone']);
    _motherNameController = TextEditingController(text: data['motherName']);
  }

  Future<void> _updateStudent() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.student.id)
            .update({
          'studentId': _studentIdController.text,
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'phone': _phoneController.text,
          'class': _selectedClass,
          'house': _selectedHouse,
          'section': _selectedSection,
          'address': _addressController.text,
          'fatherName': _fatherNameController.text,
          'fatherPhone': _fatherPhoneController.text,
          'motherName': _motherNameController.text,
        });

        widget.onStudentUpdated();

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
              SnackBar(content: Text('Failed to update student: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Student',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update the form below to edit the student\'s details.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a student ID';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a full name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedClass,
                      items: _classes.map((String className) {
                        final isNumeric = int.tryParse(className) != null;
                        return DropdownMenuItem<String>(
                          value: className,
                          child: Text(isNumeric ? 'Class $className' : className),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedClass = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'House',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedHouse,
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedSection,
                      items: _sections.map((String section) {
                        return DropdownMenuItem<String>(
                          value: section,
                          child: Text(section),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSection = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fatherNameController,
                      decoration: const InputDecoration(
                        labelText: 'Father\'s Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _fatherPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Father\'s Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motherNameController,
                decoration: const InputDecoration(
                  labelText: 'Mother\'s Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _updateStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Update Student'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
