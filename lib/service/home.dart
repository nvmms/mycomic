import 'dart:isolate';

import 'package:mycomic/domain/home_model.dart';
import 'package:mycomic/service/webview_loader.dart';

abstract final class Home {
  static Future<HomeModel> list() async {
    final html = await WebViewLoader.instance.load(
      uri: Uri.parse('https://mycomic.com/cn'),
      waitForSelector: 'div.space-y-12 > div:nth-child(2) a[href*="/comics/"]',
    );

    return Isolate.run(() => HomeModel.fromHtml(html));
  }
}
