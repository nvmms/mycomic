import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

class ComicModel {
  final String title;
  final String cover;
  final String label;
  final String url;

  const ComicModel({
    required this.title,
    required this.cover,
    required this.label,
    required this.url,
  });

  factory ComicModel.fromHtml(String html) {
    final document = html_parser.parseFragment(html);
    final element = document.querySelector('div.group.relative');

    if (element == null) {
      throw const FormatException('无法从 HTML 中找到漫画卡片');
    }

    return ComicModel.fromElement(element);
  }

  factory ComicModel.fromElement(Element element) {
    final link = element.querySelector('a[href*="/comics/"]');
    final image = link?.querySelector('img');
    final titleElement = element.querySelector('[data-flux-subheading]');

    if (link == null || image == null) {
      throw const FormatException('无法从 HTML 中解析漫画信息');
    }

    final url = link.attributes['href']?.trim() ?? '';
    final lazyCover = image.attributes['data-src']?.trim() ?? '';
    final cover = lazyCover.isNotEmpty
        ? lazyCover
        : image.attributes['src']?.trim() ?? '';

    // 优先使用正文标题，取不到时使用图片 alt。
    final headingTitle = _normalizeText(titleElement?.text ?? '');
    final title = headingTitle.isNotEmpty
        ? headingTitle
        : _normalizeText(image.attributes['alt'] ?? '');

    // img 后面的 div 就是章节标签容器。
    final label = _normalizeText(image.nextElementSibling?.text ?? '');

    return ComicModel(title: title, cover: cover, label: label, url: url);
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'cover': cover, 'label': label, 'url': url};
  }

  static List<ComicModel> listFromHtml(String html) {
    final document = html_parser.parseFragment(html);

    return document
        .querySelectorAll('div.group.relative')
        .where(
          (element) => element.querySelector('a[href*="/comics/"] img') != null,
        )
        .map(ComicModel.fromElement)
        .toList();
  }

  static List<ComicModel> listFromElement(Element element) {
    return element
        .querySelectorAll('div.group.relative')
        .where(
          (element) => element.querySelector('a[href*="/comics/"] img') != null,
        )
        .map(ComicModel.fromElement)
        .toList();
  }

  static String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
