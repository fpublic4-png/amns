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
    if (_studentClass != null) {
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
      final Set<DocumentSnapshot> allNotifications = {};

      // 1. Get "Everyone" notifications
      final everyoneQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientType', isEqualTo: 'Everyone')
          .get();
      allNotifications.addAll(everyoneQuery.docs);

      // 2. Get "Whole Class" notifications
      final wholeClassQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientType', isEqualTo: 'Whole Class')
          .where('class', isEqualTo: _studentClass)
          .get();
      allNotifications.addAll(wholeClassQuery.docs);

      // 3. Get "Specific Class/Section" notifications
      if (_studentSection != null) {
        final specificSectionQuery = await FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientType', isEqualTo: 'Specific Class/Section')
            .where('class', isEqualTo: _studentClass)
            .where('section', isEqualTo: _studentSection)
            .get();
        allNotifications.addAll(specificSectionQuery.docs);
      }

      final notificationsList = allNotifications.toList();
      notificationsList.sort((a, b) {
        final timestampA = (a.data() as Map)['timestamp'] as Timestamp;
        final timestampB = (b.data() as Map)['timestamp'] as Timestamp;
        return timestampB.compareTo(timestampA); // descending
      });

      _notifications = notificationsList.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'title': data['title'] as String? ?? '',
          'message': data['message'] as String? ?? '',
        };
      }).toList();

      final Set<DocumentSnapshot> allHomework = {};

      final everyoneHomeworkQuery = await FirebaseFirestore.instance
          .collection('homework')
          .where('recipientType', isEqualTo: 'Everyone')
          .get();
      allHomework.addAll(everyoneHomeworkQuery.docs);

      final wholeClassHomeworkQuery = await FirebaseFirestore.instance
          .collection('homework')
          .where('recipientType', isEqualTo: 'Whole Class')
          .where('class', isEqualTo: _studentClass)
          .get();
      allHomework.addAll(wholeClassHomeworkQuery.docs);

      if (_studentSection != null) {
        final specificSectionHomeworkQuery = await FirebaseFirestore.instance
            .collection('homework')
            .where('recipientType', isEqualTo: 'Specific Class/Section')
            .where('class', isEqualTo: _studentClass)
            .where('section', isEqualTo: _studentSection)
            .get();
        allHomework.addAll(specificSectionHomeworkQuery.docs);
      }
      
      final homeworkList = allHomework.toList();
      homeworkList.sort((a, b) {
        final timestampA = (a.data() as Map)['timestamp'] as Timestamp;
        final timestampB = (b.data() as Map)['timestamp'] as Timestamp;
        return timestampB.compareTo(timestampA);
      });

      _homework = homeworkList.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'title': data['title'] as String? ?? '',
          'message': data['message'] as String? ?? '',
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
      width: 300,
      height: 400,
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
                      _buildMessageList(_notifications, 'You have no new notifications.'),
                      _buildMessageList(_homework, 'You have no new homework.'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Map<String, String>> messages, String emptyMessage) {
    if (messages.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(emptyMessage),
      ));
    }
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          title: Text(message['title']!),
          subtitle: Text(message['message']!),
        );
      },
    );
  }
}
