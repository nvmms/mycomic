import 'package:flutter/material.dart';
import 'package:mycomic/page/home_page.dart';
import 'package:mycomic/service/webview_loader.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: WebViewLoader.instance.verificationRequired,
        builder: (context, visible, _) => Stack(
          fit: StackFit.expand,
          children: [
            ?child,
            if (visible)
              Positioned.fill(
                child: PopScope(
                  canPop: false,
                  child: Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      title: const Text('请完成人机验证'),
                    ),
                    body: SafeArea(
                      child: WebViewWidget(
                        controller: WebViewLoader.instance.controller,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      home: const HomePage(),
    );
  }
}
