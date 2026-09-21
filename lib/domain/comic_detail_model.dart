import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:mycomic/domain/comic_model.dart';

class ComicChapter {
  final String title;
  final String url;

  const ComicChapter({required this.title, required this.url});
}

class ComicChapterGroup {
  final String title;
  final List<ComicChapter> chapters;

  const ComicChapterGroup({required this.title, required this.chapters});
}

class ComicDetailModel {
  final String title;
  final String cover;
  final String summary;
  final String status;
  final String author;
  final String lastUpdated;
  final String genres;
  final String region;
  final String progress;
  final List<ComicChapterGroup> chapterGroups;
  final List<ComicModel> recommendations;

  const ComicDetailModel({
    required this.title,
    required this.cover,
    required this.summary,
    required this.status,
    required this.author,
    required this.lastUpdated,
    required this.genres,
    required this.region,
    required this.progress,
    required this.chapterGroups,
    required this.recommendations,
  });

  factory ComicDetailModel.fromHtml(String html) {
    final document = html_parser.parse(html);
    final card = document.querySelector('[data-flux-card]');
    if (card == null) throw const FormatException('无法从 HTML 中找到漫画详情');

    final title = _text(card.querySelector('[data-flux-heading]'));
    final image = card.querySelector('img');
    final lazyCover = image?.attributes['data-src']?.trim() ?? '';
    final cover = lazyCover.isNotEmpty
        ? lazyCover
        : image?.attributes['src']?.trim() ?? '';

    final labels = card.querySelectorAll('label');
    String valueAfter(String name) {
      for (final label in labels) {
        if (_normalize(label.text).startsWith(name)) {
          return _normalize(label.parent?.querySelector('span')?.text ?? '');
        }
      }
      return '';
    }

    final chapterGroups = <ComicChapterGroup>[];
    for (final container in document.querySelectorAll(
      '[x-data*="chapters:"]',
    )) {
      final seen = <String>{};
      final chapters = <ComicChapter>[];
      for (final chapterLabel in container.querySelectorAll(
        'a[href*="/chapters/"] span[x-text="chapter.title"]',
      )) {
        final link = chapterLabel.parent;
        if (link == null) continue;
        final url = link.attributes['href']?.trim() ?? '';
        final chapterTitle = _normalize(chapterLabel.text);
        if (url.isNotEmpty && chapterTitle.isNotEmpty && seen.add(url)) {
          chapters.add(ComicChapter(title: chapterTitle, url: url));
        }
      }
      if (chapters.isEmpty) continue;
      final heading = container.querySelector('[data-flux-subheading] > div');
      chapterGroups.add(
        ComicChapterGroup(
          title: _text(heading).isEmpty ? '章节' : _text(heading),
          chapters: chapters,
        ),
      );
    }

    // 详情位于卡片正文容器的第 5 个直接子节点：
    // /html/body/div[3]/div/div[1]/div[2]/div[2]/div[5]
    final content = card.children
        .where(
          (element) => element.querySelector('[data-flux-heading]') != null,
        )
        .firstOrNull;
    final description = content != null && content.children.length >= 5
        ? content.children[4]
        : null;
    var summary = '';
    if (description != null) {
      final expanded = description.querySelector('[x-show="show"]');
      summary = _normalize(
        (expanded?.text ?? description.text).replaceAll('观看全部', ''),
      );
    }
    final subheadings = card.querySelectorAll('[data-flux-subheading]');

    return ComicDetailModel(
      title: title,
      cover: cover,
      summary: summary,
      status: _text(card.querySelector('[data-flux-badge]')),
      author: valueAfter('原创作者'),
      lastUpdated: valueAfter('最后更新'),
      genres: valueAfter('作品类型'),
      region: valueAfter('作品地区'),
      progress: subheadings.isEmpty ? '' : _normalize(subheadings.first.text),
      chapterGroups: chapterGroups,
      recommendations: ComicModel.listFromHtml(html).take(12).toList(),
    );
  }

  static String _text(Element? element) => _normalize(element?.text ?? '');

  List<ComicChapter> get chapters => [
    for (final group in chapterGroups) ...group.chapters,
  ];

  static String _normalize(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
