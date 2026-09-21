import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class DataCache {
  static const _prefix = 'tab_cache_v1_';
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static Future<Map<String, dynamic>?> read(String key) async {
    try {
      final value = await _preferences.getString('$_prefix$key');
      if (value == null) return null;
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, Map<String, dynamic> value) async {
    try {
      await _preferences.setString('$_prefix$key', jsonEncode(value));
    } catch (_) {
      // 缓存失败不应影响已经成功取得的数据。
    }
  }
}
