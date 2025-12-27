import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ChapterContentPage extends StatefulWidget {
  final DocumentSnapshot chapter;

  const ChapterContentPage({super.key, required this.chapter});

  @override
  State<ChapterContentPage> createState() => _ChapterContentPageState();
}

class _ChapterContentPageState extends State<ChapterContentPage> {
  bool _isLoading = true;
  String? _pdfPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final contentUrl = widget.chapter['contentUrl'];
    if (contentUrl != null && contentUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(contentUrl));
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/temp.pdf');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _pdfPath = file.path;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Error loading PDF: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.chapter['content'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter['name']),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _pdfPath != null
                  ? PDFView(
                      filePath: _pdfPath,
                    )
                  : content != null
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(content),
                        )
                      : const Center(
                          child: Text('No content available for this chapter.'),
                        ),
    );
  }
}
