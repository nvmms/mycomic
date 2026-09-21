import 'package:html/parser.dart' as html_parser;

class ComicPageImage {
  final int index;
  final String url;
  final double width;
  final double height;

  const ComicPageImage({
    required this.index,
    required this.url,
    required this.width,
    required this.height,
  });

  double displayHeight(double displayWidth) => displayWidth * height / width;
}

class ComicPlayModel {
  final List<ComicPageImage> images;
  final String chapterTitle;
  final String? nextUrl;

  const ComicPlayModel({
    required this.images,
    required this.chapterTitle,
    required this.nextUrl,
  });

  factory ComicPlayModel.fromHtml(String html) {
    final document = html_parser.parse(html);
    final images = <ComicPageImage>[];

    for (final element in document.querySelectorAll('img.page')) {
      final indexText = element.attributes['x-ref']?.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final index = int.tryParse(indexText ?? '');
      final lazyUrl = element.attributes['data-src']?.trim() ?? '';
      final url = lazyUrl.isNotEmpty
          ? lazyUrl
          : element.attributes['src']?.trim() ?? '';
      final width = double.tryParse(element.attributes['width'] ?? '');
      final height = double.tryParse(element.attributes['height'] ?? '');
      if (url.isEmpty ||
          index == null ||
          width == null ||
          height == null ||
          width <= 0 ||
          height <= 0) {
        continue;
      }
      images.add(
        ComicPageImage(index: index, url: url, width: width, height: height),
      );
    }

    if (images.isEmpty) {
      throw const FormatException('无法从 HTML 中找到有效的漫画图片');
    }
    images.sort((left, right) => left.index.compareTo(right.index));

    String? nextUrl;
    for (final link in document.querySelectorAll('a[href]')) {
      final text = link.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (!text.contains('下一话')) continue;
      final href = link.attributes['href']?.trim() ?? '';
      if (href.isNotEmpty) {
        nextUrl = Uri.parse('https://mycomic.com').resolve(href).toString();
        break;
      }
    }

    final breadcrumbs = document.querySelectorAll(
      '[data-flux-breadcrumbs-item]',
    );
    final chapterTitle = breadcrumbs.isEmpty
        ? ''
        : breadcrumbs.last.text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ComicPlayModel(
      images: images,
      chapterTitle: chapterTitle,
      nextUrl: nextUrl,
    );
  }
}
