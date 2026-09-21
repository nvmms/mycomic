import 'package:flutter/material.dart';
import 'package:mycomic/core/app_navigator.dart';
import 'package:mycomic/domain/comic_detail_model.dart';
import 'package:mycomic/domain/local_comic_record.dart';
import 'package:mycomic/service/api.dart';
import 'package:mycomic/service/comic_library.dart';
import 'package:mycomic/widget/my_comic_image.dart';

class ComicDetailPage extends StatefulWidget {
  final String id;
  const ComicDetailPage({super.key, required this.id});

  @override
  State<ComicDetailPage> createState() => _ComicDetailPageState();
}

class _ComicDetailPageState extends State<ComicDetailPage> {
  late Future<ComicDetailModel> _detail;
  bool _isFollowing = false;
  LocalComicRecord? _historyRecord;

  @override
  void initState() {
    super.initState();
    _detail = Api.comicDetail(widget.id);
    _loadLocalState();
  }

  Future<void> _loadLocalState() async {
    final following = await ComicLibrary.isFollowing(widget.id);
    final history = await ComicLibrary.history();
    LocalComicRecord? record;
    for (final item in history) {
      if (item.comicUrl == widget.id) {
        record = item;
        break;
      }
    }
    if (mounted) {
      setState(() {
        _isFollowing = following;
        _historyRecord = record;
      });
    }
  }

  Future<void> _toggleFollowing(ComicDetailModel detail) async {
    final value = await ComicLibrary.toggleFollowing(
      LocalComicRecord(
        title: detail.title,
        cover: detail.cover,
        comicUrl: widget.id,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (mounted) setState(() => _isFollowing = value);
  }

  void _reload() => setState(() => _detail = Api.comicDetail(widget.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<ComicDetailModel>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(onRetry: _reload);
          return _DetailBody(
            detail: snapshot.requireData,
            comicUrl: widget.id,
            isFollowing: _isFollowing,
            historyRecord: _historyRecord,
            onHistoryChanged: _loadLocalState,
            onToggleFollowing: () => _toggleFollowing(snapshot.requireData),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ComicDetailModel detail;
  final String comicUrl;
  final bool isFollowing;
  final LocalComicRecord? historyRecord;
  final VoidCallback onHistoryChanged;
  final VoidCallback onToggleFollowing;

  const _DetailBody({
    required this.detail,
    required this.comicUrl,
    required this.isFollowing,
    required this.historyRecord,
    required this.onHistoryChanged,
    required this.onToggleFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _ComicHeader(
          detail: detail,
          comicUrl: comicUrl,
          isFollowing: isFollowing,
          historyRecord: historyRecord,
          onHistoryChanged: onHistoryChanged,
          onToggleFollowing: onToggleFollowing,
        ),
        if (detail.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ExpandableSummary(text: detail.summary),
        ],
        const SizedBox(height: 10),
        if (detail.chapterGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text('暂无章节', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...detail.chapterGroups.indexed.map((entry) {
            final (_, group) = entry;
            final chapters = group.chapters.reversed.toList();
            return _ChapterGroupPreview(
              group: ComicChapterGroup(title: group.title, chapters: chapters),
              readChapterUrls: {
                ...?historyRecord?.readChapterUrls,
                if (historyRecord?.chapterUrl case final url?
                    when url.isNotEmpty)
                  url,
              },
              onShowAll: () => _showAllChapters(
                context,
                group.title,
                chapters,
                detail.title,
                group,
                comicUrl,
                detail.cover,
              ),
              title: detail.title,
              comicUrl: comicUrl,
              cover: detail.cover,
              onHistoryChanged: onHistoryChanged,
            );
          }),
        if (detail.recommendations.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            '看过这部作品的小伙伴还喜欢',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detail.recommendations.take(6).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 10,
              childAspectRatio: .58,
            ),
            itemBuilder: (context, index) {
              final comic = detail.recommendations[index];
              return InkWell(
                onTap: () => AppNavigator.startComicDetail(context, comic.url),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: MyComicImage(url: comic.cover, radius: 4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comic.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  void _showAllChapters(
    BuildContext context,
    String groupTitle,
    List<ComicChapter> chapters,
    String title,
    ComicChapterGroup group,
    String comicUrl,
    String cover,
  ) {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        var ascending = true;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final visibleChapters = ascending
                ? chapters
                : chapters.reversed.toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * .72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$groupTitle(${chapters.length})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                setSheetState(() => ascending = !ascending),
                            icon: Icon(
                              ascending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 15,
                            ),
                            label: Text(ascending ? '正序' : '倒序'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: visibleChapters.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              mainAxisExtent: 42,
                            ),
                        itemBuilder: (context, index) => _ChapterButton(
                          title: visibleChapters[index].title,
                          isRead:
                              historyRecord?.readChapterUrls.contains(
                                    visibleChapters[index].url,
                                  ) ==
                                  true ||
                              historyRecord?.chapterUrl ==
                                  visibleChapters[index].url,
                          onPressed: () async {
                            final chapter = visibleChapters[index];
                            Navigator.pop(sheetContext);
                            await AppNavigator.startComicPlay(
                              pageContext,
                              chapter.url,
                              title,
                              group,
                              comicUrl,
                              cover,
                            );
                            onHistoryChanged();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ExpandableSummary extends StatefulWidget {
  final String text;

  const _ExpandableSummary({required this.text});

  @override
  State<_ExpandableSummary> createState() => _ExpandableSummaryState();
}

class _ExpandableSummaryState extends State<_ExpandableSummary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xff8b8b8b),
      height: 1.55,
      fontSize: 12,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 2,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : 2,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: style,
            ),
            if (canExpand)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 5, 0, 5),
                    child: Text(
                      _expanded ? '收起' : '展开',
                      style: const TextStyle(
                        color: Color(0xff55a7f7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ComicMetadata extends StatelessWidget {
  final ComicDetailModel detail;

  const _ComicMetadata({required this.detail});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('最后更新', detail.lastUpdated),
      ('作品类型', detail.genres),
      ('作品地区', detail.region),
    ].where((item) => item.$2.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12, height: 1.35),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(color: Color(0xff8c8c8c)),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: Color(0xff353535)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ChapterGroupPreview extends StatelessWidget {
  final ComicChapterGroup group;
  final Set<String> readChapterUrls;
  final VoidCallback onShowAll;
  final String title;
  final String comicUrl;
  final String cover;
  final VoidCallback onHistoryChanged;

  const _ChapterGroupPreview({
    required this.group,
    required this.readChapterUrls,
    required this.onShowAll,
    required this.title,
    required this.comicUrl,
    required this.cover,
    required this.onHistoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleChapters = group.chapters.take(7).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${group.title}(${group.chapters.length})',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff444444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                visibleChapters.length + (group.chapters.length > 7 ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 39,
            ),
            itemBuilder: (context, index) {
              if (index == visibleChapters.length) {
                return _ChapterButton(title: '…', onPressed: onShowAll);
              }
              return _ChapterButton(
                title: visibleChapters[index].title,
                isRead: readChapterUrls.contains(visibleChapters[index].url),
                onPressed: () async {
                  await AppNavigator.startComicPlay(
                    context,
                    visibleChapters[index].url,
                    title,
                    group,
                    comicUrl,
                    cover,
                  );
                  onHistoryChanged();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChapterButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final bool isRead;

  const _ChapterButton({
    required this.title,
    required this.onPressed,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              foregroundColor: const Color(0xff444444),
              side: const BorderSide(color: Color(0xffededed)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        if (isRead)
          const Positioned(
            right: 0,
            bottom: 0,
            child: IgnorePointer(child: _ReadChapterMark()),
          ),
      ],
    );
  }
}

class _ReadChapterMark extends StatelessWidget {
  const _ReadChapterMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 19,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ClipPath(
            clipper: _BottomRightTriangleClipper(),
            child: const ColoredBox(color: Color(0xff22a447)),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 1, bottom: 1),
            child: Icon(Icons.check, size: 11, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BottomRightTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_BottomRightTriangleClipper oldClipper) => false;
}

class _ComicHeader extends StatelessWidget {
  final ComicDetailModel detail;
  final String comicUrl;
  final bool isFollowing;
  final LocalComicRecord? historyRecord;
  final VoidCallback onHistoryChanged;
  final VoidCallback onToggleFollowing;

  const _ComicHeader({
    required this.detail,
    required this.comicUrl,
    required this.isFollowing,
    required this.historyRecord,
    required this.onHistoryChanged,
    required this.onToggleFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          height: 164,
          child: MyComicImage(url: detail.cover, radius: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail.author.isEmpty ? '未知作者' : detail.author,
                style: const TextStyle(color: Color(0xff969696), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  detail.status,
                  detail.progress,
                ].where((text) => text.isNotEmpty).join('  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xffaaaaaa), fontSize: 11),
              ),
              const SizedBox(height: 7),
              _ComicMetadata(detail: detail),
              const SizedBox(height: 7),
              Row(
                children: [
                  InkWell(
                    onTap: onToggleFollowing,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFollowing
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xffffa726),
                            size: 21,
                          ),
                          const SizedBox(width: 3),
                          const Text('追漫', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  if (historyRecord != null &&
                      historyRecord!.chapterUrl.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: FilledButton(
                          onPressed: () => _resumeReading(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff55a7f7),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            _readingButtonText(historyRecord!.chapterTitle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _readingButtonText(String chapterTitle) {
    if (chapterTitle.isEmpty) return '续看';
    final title = chapterTitle.trim();
    return '续看 $title';
  }

  Future<void> _resumeReading(BuildContext context) async {
    final record = historyRecord;
    if (record == null) return;
    ComicChapterGroup? matchedGroup;
    for (final group in detail.chapterGroups) {
      if (group.chapters.any((chapter) => chapter.url == record.chapterUrl)) {
        matchedGroup = group;
        break;
      }
    }
    final chapter = ComicChapter(
      title: record.chapterTitle,
      url: record.chapterUrl,
    );
    await AppNavigator.startComicPlay(
      context,
      record.chapterUrl,
      detail.title,
      matchedGroup ?? ComicChapterGroup(title: '阅读记录', chapters: [chapter]),
      comicUrl,
      detail.cover,
    );
    onHistoryChanged();
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('加载漫画详情失败'),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
