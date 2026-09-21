import 'package:flutter/material.dart';
import 'package:mycomic/domain/comic_detail_model.dart';
import 'package:mycomic/domain/comic_play_model.dart';
import 'package:mycomic/domain/local_comic_record.dart';
import 'package:mycomic/service/api.dart';
import 'package:mycomic/service/comic_library.dart';
import 'package:mycomic/widget/my_comic_image.dart';

class ComicPlayPage extends StatefulWidget {
  final String id;
  final String title;
  final ComicChapterGroup group;
  final String comicUrl;
  final String cover;
  const ComicPlayPage({
    super.key,
    required this.id,
    required this.title,
    required this.group,
    required this.comicUrl,
    required this.cover,
  });

  @override
  State<StatefulWidget> createState() => _ComicPlayPage();
}

class _ComicPlayPage extends State<ComicPlayPage> {
  final _scrollController = ScrollController();
  final _chapters = <ComicPlayModel>[];
  final _loadedUrls = <String>{};
  bool _initialLoading = true;
  bool _loadingNext = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadChapter(widget.id, initial: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 1200) _loadNextChapter();
  }

  Future<void> _loadChapter(String url, {bool initial = false}) async {
    if (!_loadedUrls.add(url)) return;
    setState(() {
      _error = null;
      if (initial) {
        _initialLoading = true;
      } else {
        _loadingNext = true;
      }
    });

    try {
      final chapter = await Api.comicPlay(url);
      if (!mounted) return;
      setState(() => _chapters.add(chapter));
      try {
        await ComicLibrary.addHistory(
          LocalComicRecord(
            title: widget.title,
            cover: widget.cover,
            comicUrl: widget.comicUrl,
            chapterTitle: _chapterTitle(url, chapter.chapterTitle),
            chapterUrl: url,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } catch (_) {
        // 阅读记录写入失败不影响已经加载好的章节。
      }
    } catch (error) {
      _loadedUrls.remove(url);
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
          _loadingNext = false;
        });
      }
    }
  }

  String _chapterTitle(String url, String loadedTitle) {
    if (loadedTitle.isNotEmpty) return loadedTitle;
    for (final chapter in widget.group.chapters) {
      if (chapter.url == url) return chapter.title;
    }
    return '已阅读章节';
  }

  void _loadNextChapter() {
    if (_initialLoading || _loadingNext || _chapters.isEmpty) return;
    final nextUrl = _chapters.last.nextUrl;
    if (nextUrl == null || _loadedUrls.contains(nextUrl)) return;
    _loadChapter(nextUrl);
  }

  void _reload() {
    if (_chapters.isEmpty) {
      _loadChapter(widget.id, initial: true);
    } else {
      _loadNextChapter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : _chapters.isEmpty
          ? Center(
              child: FilledButton.tonal(
                onPressed: _reload,
                child: const Text('重新加载'),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final displayWidth = constraints.maxWidth;
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      title: Text(widget.title),
                      floating: true,
                      snap: true,
                    ),
                    for (final (chapterIndex, chapter)
                        in _chapters.indexed) ...[
                      if (chapterIndex > 0)
                        SliverToBoxAdapter(
                          child: _ChapterDivider(title: chapter.chapterTitle),
                        ),
                      SliverList.builder(
                        itemCount: chapter.images.length,
                        itemBuilder: (context, index) {
                          final image = chapter.images[index];
                          return SizedBox(
                            width: displayWidth,
                            height: image.displayHeight(displayWidth),
                            child: MyComicImage(url: image.url),
                          );
                        },
                      ),
                    ],
                    if (_loadingNext)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (_error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: FilledButton.tonal(
                              onPressed: _reload,
                              child: const Text('加载下一话失败，点击重试'),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _ChapterDivider extends StatelessWidget {
  final String title;

  const _ChapterDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title.isEmpty ? '下一话' : title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
