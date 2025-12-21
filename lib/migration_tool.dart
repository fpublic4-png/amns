
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class MigrationTool extends StatefulWidget {
  const MigrationTool({super.key});

  @override
  State<MigrationTool> createState() => _MigrationToolState();
}

class _MigrationToolState extends State<MigrationTool> {
  bool _isMigrating = false;
  String _status = '';
  double _progress = 0.0;
  int _updatedTeachers = 0;
  int _updatedStudents = 0;

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _status = 'Starting migration...';
      _progress = 0.0;
      _updatedTeachers = 0;
      _updatedStudents = 0;
    });

    try {
      // Migrate Teachers
      setState(() {
        _status = 'Migrating teachers...';
        _progress = 0.1;
      });
      final teachersRef = FirebaseFirestore.instance.collection('teachers');
      final teachersSnapshot = await teachersRef.get();
      final totalTeachers = teachersSnapshot.docs.length;
      int processedTeachers = 0;

      for (final doc in teachersSnapshot.docs) {
        final data = doc.data();
        final section = data['classTeacherSection'];
        if (section is String && section.startsWith('Section ')) {
          final newSection = section.split(' ').last;
          await doc.reference.update({'classTeacherSection': newSection});
          _updatedTeachers++;
        }
        processedTeachers++;
        setState(() {
          _progress = 0.1 + (processedTeachers / totalTeachers) * 0.4;
        });
      }
      developer.log('Finished migrating $_updatedTeachers teachers.');

      // Migrate Students
      setState(() {
        _status = 'Migrating students...';
        _progress = 0.5;
      });
      final studentsRef = FirebaseFirestore.instance.collection('students');
      final studentsSnapshot = await studentsRef.get();
      final totalStudents = studentsSnapshot.docs.length;
      int processedStudents = 0;

      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();
        final section = data()['section'];
        if (section is String && section.startsWith('Section ')) {
          final newSection = section.split(' ').last;
          await doc.reference.update({'section': newSection});
          _updatedStudents++;
        }
        processedStudents++;
        setState(() {
          _progress = 0.5 + (processedStudents / totalStudents) * 0.5;
        });
      }
      developer.log('Finished migrating $_updatedStudents students.');

      setState(() {
        _status =
            'Migration Complete!\nUpdated $_updatedTeachers teachers.\nUpdated $_updatedStudents students.';
        _progress = 1.0;
      });
    } catch (e, s) {
      setState(() {
        _status = 'Error during migration: $e';
      });
      developer.log('Migration Error', name: 'myapp.migration', error: e, stackTrace: s);
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One-Time Data Migration'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'This tool will fix inconsistent data in your database.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (!_isMigrating && _progress == 0.0)
                ElevatedButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Migrate Data'),
                  onPressed: _runMigration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              const SizedBox(height: 30),
              if (_isMigrating || _progress > 0.0) ...[
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 20),
                if (_progress == 1.0)
                  const Text(
                    'You can now close this. The fix will be finalized.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
