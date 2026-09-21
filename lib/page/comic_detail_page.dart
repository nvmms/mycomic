import 'package:flutter/material.dart';

class ComicDetailPage extends StatefulWidget {
  final String id;
  const ComicDetailPage({super.key, required this.id});

  @override
  State<StatefulWidget> createState() => _ComicDetailPage();
}

class _ComicDetailPage extends State<ComicDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar());
  }
}
