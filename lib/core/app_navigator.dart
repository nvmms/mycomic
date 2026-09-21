import 'package:flutter/material.dart';
import 'package:mycomic/domain/comic_detail_model.dart';
import 'package:mycomic/page/comic_detail_page.dart';
import 'package:mycomic/page/comic_play_page.dart';

abstract final class AppNavigator {
  static void startComicDetail(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComicDetailPage(id: id)),
    );
  }

  static void startComicPlay(
    BuildContext context,
    String id,
    String title,
    ComicChapterGroup group,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicPlayPage(id: id, title: title, group: group),
      ),
    );
  }
}
