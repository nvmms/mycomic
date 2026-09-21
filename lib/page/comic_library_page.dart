import 'package:flutter/material.dart';
import 'package:mycomic/core/app_navigator.dart';
import 'package:mycomic/domain/comic_detail_model.dart';
import 'package:mycomic/domain/local_comic_record.dart';
import 'package:mycomic/service/comic_library.dart';
import 'package:mycomic/widget/my_comic_image.dart';

enum ComicLibraryType { history, following }

class ComicLibraryPage extends StatefulWidget {
  const ComicLibraryPage({super.key, required this.type});

  final ComicLibraryType type;

  @override
  State<ComicLibraryPage> createState() => _ComicLibraryPageState();
}

class _ComicLibraryPageState extends State<ComicLibraryPage> {
  late Future<List<LocalComicRecord>> _items;

  bool get _isHistory => widget.type == ComicLibraryType.history;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = _isHistory ? ComicLibrary.history() : ComicLibrary.followings();
  }

  Future<void> _remove(LocalComicRecord item) async {
    if (_isHistory) {
      await ComicLibrary.removeHistory(item.comicUrl);
    } else {
      await ComicLibrary.removeFollowing(item.comicUrl);
    }
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isHistory ? '阅读记录' : '我的追漫')),
      body: FutureBuilder<List<LocalComicRecord>>(
        future: _items,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.requireData;
          if (items.isEmpty) {
            return Center(child: Text(_isHistory ? '暂无阅读记录' : '暂无追漫'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 84),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                onTap: () async {
                  if (_isHistory && item.chapterUrl.isNotEmpty) {
                    final chapter = ComicChapter(
                      title: item.chapterTitle,
                      url: item.chapterUrl,
                    );
                    await AppNavigator.startComicPlay(
                      context,
                      item.chapterUrl,
                      item.title,
                      ComicChapterGroup(title: '阅读记录', chapters: [chapter]),
                      item.comicUrl,
                      item.cover,
                    );
                  } else {
                    await AppNavigator.startComicDetail(context, item.comicUrl);
                  }
                  if (mounted) setState(_reload);
                },
                leading: SizedBox(
                  width: 52,
                  height: 70,
                  child: MyComicImage(url: item.cover, radius: 4),
                ),
                title: Text(item.title, maxLines: 2),
                subtitle: _isHistory && item.chapterTitle.isNotEmpty
                    ? Text('上次阅读：${item.chapterTitle}')
                    : null,
                trailing: IconButton(
                  tooltip: '删除',
                  onPressed: () => _remove(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
