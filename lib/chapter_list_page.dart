import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterListPage extends StatefulWidget {
  final String subject;
  final String studentClass;

  const ChapterListPage({
    super.key,
    required this.subject,
    required this.studentClass,
  });

  @override
  State<ChapterListPage> createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage> {
  late Future<List<DocumentSnapshot>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = _fetchChapters();
  }

  Future<List<DocumentSnapshot>> _fetchChapters() async {
    final chaptersQuery = await FirebaseFirestore.instance
        .collection('chapters')
        .where('subject', isEqualTo: widget.subject)
        .where('class', isEqualTo: widget.studentClass)
        .get();
    return chaptersQuery.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No chapters found for this subject.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final chapter = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  leading: const Icon(Icons.library_books),
                  title: Text(chapter['name']),
                  subtitle: const Text('Notes & questions available inside.'),
                  onTap: () {
                    // TODO: Implement navigation to the chapter details page
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
