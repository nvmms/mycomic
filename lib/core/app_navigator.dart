import 'package:flutter/material.dart';
import 'package:mycomic/page/comic_detail_page.dart';

abstract final class AppNavigator {
  static late BuildContext context;

  static void startCoimcDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComicDetailPage(id: id)),
    );
  }
}
