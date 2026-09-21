import 'package:html/dom.dart';

class RankModel {
  final String title;
  final String url;
  final String chapter;
  final String chapterUrl;
  final String date;

  const RankModel({
    required this.title,
    required this.url,
    required this.chapter,
    required this.chapterUrl,
    required this.date,
  });

  factory RankModel.fromElement(Element element) {
    final comicLink = element.querySelector('a[href*="/comics/"]');
    final chapterLink = element.querySelector('a[href*="/chapters/"]');

    if (comicLink == null) {
      throw const FormatException('无法从 HTML 中解析排行漫画');
    }

    return RankModel(
      title: _normalizeText(comicLink.attributes['title'] ?? comicLink.text),
      url: comicLink.attributes['href']?.trim() ?? '',
      chapter: _normalizeText(chapterLink?.text ?? ''),
      chapterUrl: chapterLink?.attributes['href']?.trim() ?? '',
      date: _normalizeText(element.querySelector('div.flex-none')?.text ?? ''),
    );
  }

  factory RankModel.fromMap(Map<String, dynamic> map) {
    return RankModel(
      title: map['title'] as String? ?? '',
      url: map['url'] as String? ?? '',
      chapter: map['chapter'] as String? ?? '',
      chapterUrl: map['chapterUrl'] as String? ?? '',
      date: map['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'chapter': chapter,
      'chapterUrl': chapterUrl,
      'date': date,
    };
  }

  static List<RankModel> listFromCell(Element cell) {
    final container = cell.children.isEmpty ? null : cell.children.first;
    if (container == null) return const [];

    return container.children
        .where((element) => element.localName == 'div')
        .where(
          (element) => element.querySelector('a[href*="/comics/"]') != null,
        )
        .map(RankModel.fromElement)
        .toList();
  }

  static String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
