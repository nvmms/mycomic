import 'dart:convert';

import 'package:mycomic/domain/local_comic_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ComicLibrary {
  static const _favoritesKey = 'comic_favorites_v1';
  static const _historyKey = 'comic_reading_history_v1';
  static const _historyLimit = 100;
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static Future<List<LocalComicRecord>> followings() => _read(_favoritesKey);

  static Future<List<LocalComicRecord>> history() => _read(_historyKey);

  static Future<bool> isFollowing(String comicUrl) async {
    return (await followings()).any((item) => item.comicUrl == comicUrl);
  }

  static Future<bool> toggleFollowing(LocalComicRecord comic) async {
    final items = await followings();
    final index = items.indexWhere((item) => item.comicUrl == comic.comicUrl);
    if (index >= 0) {
      items.removeAt(index);
      await _write(_favoritesKey, items);
      return false;
    }
    items.insert(0, comic);
    await _write(_favoritesKey, items);
    return true;
  }

  static Future<void> addHistory(LocalComicRecord comic) async {
    final items = await history();
    final readChapterUrls = <String>{...comic.readChapterUrls};
    final oldIndex = items.indexWhere(
      (item) => item.comicUrl == comic.comicUrl,
    );
    if (oldIndex >= 0) {
      final oldRecord = items.removeAt(oldIndex);
      readChapterUrls
        ..addAll(oldRecord.readChapterUrls)
        ..add(oldRecord.chapterUrl);
    }
    readChapterUrls.add(comic.chapterUrl);
    items.insert(
      0,
      LocalComicRecord(
        title: comic.title,
        cover: comic.cover,
        comicUrl: comic.comicUrl,
        updatedAt: comic.updatedAt,
        chapterTitle: comic.chapterTitle,
        chapterUrl: comic.chapterUrl,
        readChapterUrls: readChapterUrls
            .where((url) => url.isNotEmpty)
            .toList(),
      ),
    );
    if (items.length > _historyLimit) {
      items.removeRange(_historyLimit, items.length);
    }
    await _write(_historyKey, items);
  }

  static Future<void> removeFollowing(String comicUrl) async {
    final items = await followings()
      ..removeWhere((item) => item.comicUrl == comicUrl);
    await _write(_favoritesKey, items);
  }

  static Future<void> removeHistory(String comicUrl) async {
    final items = await history()
      ..removeWhere((item) => item.comicUrl == comicUrl);
    await _write(_historyKey, items);
  }

  static Future<List<LocalComicRecord>> _read(String key) async {
    try {
      final value = await _preferences.getString(key);
      if (value == null) return [];
      return (jsonDecode(value) as List<dynamic>)
          .map((item) => LocalComicRecord.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(String key, List<LocalComicRecord> items) async {
    await _preferences.setString(
      key,
      jsonEncode(items.map((item) => item.toMap()).toList()),
    );
  }
}
