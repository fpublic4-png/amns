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
  List<String> _notifications = [];
  List<String> _homework = [];
  bool _isLoading = true;
  String? _studentClass;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStudentDataAndMessages();
  }

  Future<void> _fetchStudentDataAndMessages() async {
    await _fetchStudentClass();
    if (_studentClass != null) {
      await _fetchMessages();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStudentClass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        developer.log('User ID not found', name: 'myapp.notifications');
        return;
      }

      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(userId).get();
       if (studentDoc.exists) {
        _studentClass = studentDoc.data()?['class'];
      } else {
        final studentQuery = await FirebaseFirestore.instance.collection('students').where('studentId', isEqualTo: userId).get();
        if(studentQuery.docs.isNotEmpty){
             _studentClass = studentQuery.docs.first.data()['class'];
        }
      }
    } catch (e, s) {
      developer.log('Error fetching student class', name: 'myapp.notifications', error: e, stackTrace: s);
    }
  }

  Future<void> _fetchMessages() async {
    if (_studentClass == null) return;

    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('class', whereIn: [_studentClass, 'everyone'])
          .orderBy('timestamp', descending: true)
          .get();
      _notifications = notificationsSnapshot.docs.map((doc) => doc.data()['message'] as String).toList();

      final homeworkSnapshot = await FirebaseFirestore.instance
          .collection('homework')
          .where('class', isEqualTo: _studentClass)
          .orderBy('timestamp', descending: true)
          .get();
      _homework = homeworkSnapshot.docs.map((doc) => doc.data()['message'] as String).toList();
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
    return Container(
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

  Widget _buildMessageList(List<String> messages, String emptyMessage) {
    if (messages.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(emptyMessage),
      ));
    }
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(messages[index]),
        );
      },
    );
  }
}
