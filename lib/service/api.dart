import 'dart:isolate';

import 'package:mycomic/domain/comic_model.dart';
import 'package:mycomic/domain/home_model.dart';
import 'package:mycomic/domain/comic_detail_model.dart';
import 'package:mycomic/domain/comic_play_model.dart';
import 'package:mycomic/domain/ranking_item_model.dart';
import 'package:mycomic/service/webview_loader.dart';

abstract final class Api {
  static Future<List<RankingItemModel>> rankings(Uri uri) async {
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('排行榜地址无效');
    }
    final html = await WebViewLoader.instance.load(
      uri: uri,
      waitForSelector: 'table tbody tr a[href*="/comics/"]',
    );
    return Isolate.run(() => RankingItemModel.listFromHtml(html));
  }

  static Future<List<ComicModel>> comics(Uri uri) async {
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('漫画列表地址无效');
    }

    final html = await WebViewLoader.instance.load(
      uri: uri,
      waitForSelector:
          'div.group.relative a[href*="/comics/"] img[src*="/comics/"]',
    );
    return Isolate.run(() => ComicModel.listFromHtml(html));
  }

  static Future<ComicPlayModel> comicPlay(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('章节地址无效');
    }
    final html = await WebViewLoader.instance.load(
      uri: uri,
      waitForSelector: 'img.page',
    );
    return Isolate.run(() => ComicPlayModel.fromHtml(html));
  }

  static Future<ComicDetailModel> comicDetail(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('漫画地址无效');
    }
    final html = await WebViewLoader.instance.load(
      uri: uri,
      waitForSelector:
          'div.group.relative a[href*="/comics/"] img[src*="/comics/"]',
    );
    return Isolate.run(() => ComicDetailModel.fromHtml(html));
  }

  static Future<HomeModel> homeData() async {
    final html = await WebViewLoader.instance.load(
      uri: Uri.parse('https://mycomic.com/cn'),
      waitForSelector: 'div.space-y-12 > div:nth-child(2) a[href*="/comics/"]',
    );

    return Isolate.run(() => HomeModel.fromHtml(html));
  }
}
