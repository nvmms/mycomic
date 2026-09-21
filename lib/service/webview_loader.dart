import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

/// 复用同一个 WebViewController，串行加载需要 JavaScript 渲染的页面。
final class WebViewLoader {
  static const _extractContentJavaScript = '''
    (() => {
      const element = document.querySelector('[class*="[grid-area:main]"]');
      return element?.outerHTML ?? '';
    })()
  ''';

  WebViewLoader._() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _onPageFinished,
          onWebResourceError: _onWebResourceError,
        ),
      );
  }

  static final WebViewLoader instance = WebViewLoader._();

  late final WebViewController _controller;
  Future<void> _queue = Future<void>.value();
  _LoadTask? _activeTask;

  /// 加载页面并返回站点主内容区域的 HTML。
  /// 所有调用都会排队执行，避免多个地址共用 controller 时互相覆盖。
  Future<String> load({
    required Uri uri,
    String? waitForSelector,
    Duration timeout = const Duration(seconds: 30),
  }) {
    final scheduled = _queue.then(
      (_) =>
          _load(uri: uri, waitForSelector: waitForSelector, timeout: timeout),
    );

    // 无论当前任务成功还是失败，都允许队列继续处理后续任务。
    _queue = scheduled.then<void>((_) {}, onError: (_, _) {});
    return scheduled;
  }

  Future<String> _load({
    required Uri uri,
    required String? waitForSelector,
    required Duration timeout,
  }) async {
    final task = _LoadTask(waitForSelector: waitForSelector);
    _activeTask = task;

    try {
      await _controller.loadRequest(uri);
      return await task.completer.future.timeout(timeout);
    } on TimeoutException {
      try {
        await _controller.runJavaScript('window.stop();');
      } catch (_) {
        // 页面尚未建立 JavaScript 上下文时，直接让当前任务超时即可。
      }
      throw TimeoutException('加载页面超时：$uri', timeout);
    } finally {
      if (identical(_activeTask, task)) {
        _activeTask = null;
      }
    }
  }

  Future<void> _onPageFinished(String _) async {
    final task = _activeTask;
    if (task == null || task.isExtracting || task.completer.isCompleted) {
      return;
    }

    task.isExtracting = true;

    try {
      await _waitUntilReady(task);

      final result = await _controller.runJavaScriptReturningResult(
        _extractContentJavaScript,
      );

      if (!task.completer.isCompleted) {
        task.completer.complete(_decodeJavaScriptResult(result));
      }
    } catch (error, stackTrace) {
      if (!task.completer.isCompleted) {
        task.completer.completeError(error, stackTrace);
      }
    }
  }

  Future<void> _waitUntilReady(_LoadTask task) async {
    final selector = task.waitForSelector;
    if (selector == null) return;

    final encodedSelector = jsonEncode(selector);
    final deadline = DateTime.now().add(const Duration(seconds: 15));

    while (DateTime.now().isBefore(deadline)) {
      if (!identical(_activeTask, task) || task.completer.isCompleted) return;

      final result = await _controller.runJavaScriptReturningResult(
        "document.querySelector($encodedSelector) ? 'ready' : 'waiting'",
      );
      if (_decodeJavaScriptResult(result) == 'ready') return;

      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    throw TimeoutException('等待页面动态内容超时：$selector');
  }

  static String _decodeJavaScriptResult(Object result) {
    final value = result.toString();
    final trimmed = value.trim();

    // Android WebView 可能返回 JSON 编码后的字符串，例如
    // "\u003Cdiv...\u003E"；iOS 则可能直接返回 HTML。
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is String) return decoded;
      } on FormatException {
        // 不是 JSON 字符串时保留平台返回的原值。
      }
    }

    return value;
  }

  void _onWebResourceError(WebResourceError error) {
    final task = _activeTask;

    // 子资源加载失败不应导致整个页面任务失败。
    if (task == null || error.isForMainFrame != true) return;

    if (!task.completer.isCompleted) {
      task.completer.completeError(
        WebViewLoadException(error.description, errorCode: error.errorCode),
      );
    }
  }
}

final class _LoadTask {
  _LoadTask({required this.waitForSelector});

  final String? waitForSelector;
  final Completer<String> completer = Completer<String>();
  bool isExtracting = false;
}

final class WebViewLoadException implements Exception {
  const WebViewLoadException(this.message, {required this.errorCode});

  final String message;
  final int errorCode;

  @override
  String toString() => 'WebViewLoadException($errorCode): $message';
}
