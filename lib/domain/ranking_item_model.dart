import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

class RankingItemModel {
  const RankingItemModel({
    required this.rank,
    required this.title,
    required this.url,
    required this.authors,
    required this.chapter,
    required this.chapterUrl,
    required this.updatedAt,
    required this.score,
  });

  final int rank;
  final String title;
  final String url;
  final String authors;
  final String chapter;
  final String chapterUrl;
  final String updatedAt;
  final String score;

  factory RankingItemModel.fromElement(Element row) {
    final cells = row.querySelectorAll('td');
    final comicLink = row.querySelector('a[href*="/comics/"]');
    final chapterLink = row.querySelector('a[href*="/chapters/"]');
    if (cells.length < 6 || comicLink == null) {
      throw const FormatException('无法从 HTML 中解析排行项目');
    }

    // 移动端和桌面端各有一列最新章节，故日期与评分取最后两列。
    return RankingItemModel(
      rank: int.tryParse(_text(cells.first.text)) ?? 0,
      title: _text(comicLink.text),
      url: comicLink.attributes['href']?.trim() ?? '',
      authors: cells.length > 2 ? _text(cells[2].text) : '',
      chapter: _text(chapterLink?.text ?? ''),
      chapterUrl: chapterLink?.attributes['href']?.trim() ?? '',
      updatedAt: _text(cells[cells.length - 2].text),
      score: _text(cells.last.text),
    );
  }

  factory RankingItemModel.fromMap(Map<String, dynamic> map) {
    return RankingItemModel(
      rank: map['rank'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      url: map['url'] as String? ?? '',
      authors: map['authors'] as String? ?? '',
      chapter: map['chapter'] as String? ?? '',
      chapterUrl: map['chapterUrl'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
      score: map['score'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'title': title,
      'url': url,
      'authors': authors,
      'chapter': chapter,
      'chapterUrl': chapterUrl,
      'updatedAt': updatedAt,
      'score': score,
    };
  }

  static List<RankingItemModel> listFromHtml(String html) {
    final document = html_parser.parse(html);
    return document
        .querySelectorAll('table tbody tr')
        .where((row) => row.querySelector('a[href*="/comics/"]') != null)
        .map(RankingItemModel.fromElement)
        .toList();
  }

  static String _text(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
