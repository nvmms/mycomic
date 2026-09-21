import 'package:flutter/material.dart';
import 'package:mycomic/domain/comic_detail_model.dart';
import 'package:mycomic/page/comic_detail_page.dart';
import 'package:mycomic/page/comic_library_page.dart';
import 'package:mycomic/page/comic_play_page.dart';

abstract final class AppNavigator {
  static Future<void> startComicDetail(BuildContext context, String id) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => ComicDetailPage(id: id)),
    );
  }

  static Future<void> startComicPlay(
    BuildContext context,
    String id,
    String title,
    ComicChapterGroup group,
    String comicUrl,
    String cover,
  ) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ComicPlayPage(
          id: id,
          title: title,
          group: group,
          comicUrl: comicUrl,
          cover: cover,
        ),
      ),
    );
  }

  static Future<void> startComicLibrary(
    BuildContext context,
    ComicLibraryType type,
  ) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => ComicLibraryPage(type: type)),
    );
  }
}
