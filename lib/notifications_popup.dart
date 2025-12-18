import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class NotificationsPopup extends StatefulWidget {
  const NotificationsPopup({super.key});

  @override
  State<NotificationsPopup> createState() => _NotificationsPopupState();
}

class _NotificationsPopupState extends State<NotificationsPopup> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, String>> _notifications = [];
  List<Map<String, String>> _homework = [];
  bool _isLoading = true;
  String? _studentClass;
  String? _studentSection;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStudentDataAndMessages();
  }

  Future<void> _fetchStudentDataAndMessages() async {
    await _fetchStudentDetails();
    if (mounted && _studentClass != null) {
      await _fetchMessages();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStudentDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        developer.log('User ID not found', name: 'myapp.notifications');
        return;
      }

      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(userId).get();
      if (studentDoc.exists) {
        final data = studentDoc.data();
        _studentClass = data?['class'];
        _studentSection = data?['section'];
      } else {
        final studentQuery = await FirebaseFirestore.instance.collection('students').where('studentId', isEqualTo: userId).get();
        if (studentQuery.docs.isNotEmpty) {
           final data = studentQuery.docs.first.data();
           _studentClass = data['class'];
           _studentSection = data['section'];
        }
      }
    } catch (e, s) {
      developer.log('Error fetching student details', name: 'myapp.notifications', error: e, stackTrace: s);
    }
  }

  Future<void> _fetchMessages() async {
    if (_studentClass == null) return;

    try {
      // Use a Map to store items by their document ID, preventing duplicates.
      final Map<String, Map<String, dynamic>> allNotifications = {};
      final Map<String, Map<String, dynamic>> allHomework = {};

      // --- Step 1: Fetch items for "Everyone" ---
      final everyoneNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientType', isEqualTo: 'Everyone')
          .get();
      for (var doc in everyoneNotifications.docs) {
        allNotifications[doc.id] = doc.data();
      }

      final everyoneHomework = await FirebaseFirestore.instance
          .collection('homework')
          .where('recipientType', isEqualTo: 'Everyone')
          .get();
       for (var doc in everyoneHomework.docs) {
        allHomework[doc.id] = doc.data();
      }

      // --- Step 2: Fetch items for the "Whole Class" ---
      final wholeClassNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientType', isEqualTo: 'Whole Class')
          .where('class', isEqualTo: _studentClass)
          .get();
      for (var doc in wholeClassNotifications.docs) {
        allNotifications[doc.id] = doc.data();
      }
      
      final wholeClassHomework = await FirebaseFirestore.instance
          .collection('homework')
          .where('recipientType', isEqualTo: 'Whole Class')
          .where('class', isEqualTo: _studentClass)
          .get();
      for (var doc in wholeClassHomework.docs) {
        allHomework[doc.id] = doc.data();
      }

      // --- Step 3: Fetch items for the "Specific Class/Section" ---
      if (_studentSection != null) {
        final specificSectionNotifications = await FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientType', isEqualTo: 'Specific Class/Section')
            .where('class', isEqualTo: _studentClass)
            .where('section', isEqualTo: _studentSection)
            .get();
        for (var doc in specificSectionNotifications.docs) {
          allNotifications[doc.id] = doc.data();
        }

        final specificSectionHomework = await FirebaseFirestore.instance
            .collection('homework')
            .where('recipientType', isEqualTo: 'Specific Class/Section')
            .where('class', isEqualTo: _studentClass)
            .where('section', isEqualTo: _studentSection)
            .get();
        for (var doc in specificSectionHomework.docs) {
          allHomework[doc.id] = doc.data();
        }
      }

      // --- Process and Sort Notifications ---
      final notificationsList = allNotifications.values.toList();
      notificationsList.sort((a, b) {
        final timestampA = a['timestamp'] as Timestamp? ?? Timestamp(0,0);
        final timestampB = b['timestamp'] as Timestamp? ?? Timestamp(0,0);
        return timestampB.compareTo(timestampA);
      });
      _notifications = notificationsList.map((data) {
        return {
          'title': data['title'] as String? ?? 'No Title',
          'message': data['message'] as String? ?? 'No Message',
        };
      }).toList();

      // --- Process and Sort Homework ---
      final homeworkList = allHomework.values.toList();
      homeworkList.sort((a, b) {
        final timestampA = a['createdAt'] as Timestamp? ?? Timestamp(0,0);
        final timestampB = b['createdAt'] as Timestamp? ?? Timestamp(0,0);
        return timestampB.compareTo(timestampA);
      });
      _homework = homeworkList.map((data) {
        return {
          'title': data['title'] as String? ?? 'No Title',
          'description': data['description'] as String? ?? 'No Description',
          'dueDate': data['dueDate'] as String? ?? '',
        };
      }).toList();

    } catch (e, s) {
      developer.log('Error fetching messages', name: 'myapp.notifications', error: e, stackTrace: s);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 450,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications),
                    SizedBox(width: 8),
                    Text("Notifications"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_box),
                    SizedBox(width: 8),
                    Text("Homework"),
                  ],
                ),
              ),
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationList(),
                      _buildHomeworkList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_notifications.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('You have no new notifications.'),
      ));
    }
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return ListTile(
          title: Text(notification['title']!),
          subtitle: Text(notification['message']!),
        );
      },
    );
  }

  Widget _buildHomeworkList() {
    if (_homework.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('You have no new homework.'),
      ));
    }
    return ListView.builder(
      itemCount: _homework.length,
      itemBuilder: (context, index) {
        final hw = _homework[index];
        return ListTile(
          title: Text(hw['title']!),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hw['description']!),
              const SizedBox(height: 4),
              Text('Due: ${hw['dueDate']}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        );
      },
    );
  }
}
