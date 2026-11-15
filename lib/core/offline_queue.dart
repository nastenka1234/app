import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// صف آفلاین برای /progress، /report، /focus/session.
class OfflineQueue {
  OfflineQueue._();
  static final OfflineQueue i = OfflineQueue._();

  final List<Map<String, dynamic>> _q = [];
  final ValueNotifier<int> pending = ValueNotifier(0);
  bool _busy = false;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('offline_q');
    if (raw != null) {
      _q
        ..clear()
        ..addAll((jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)));
    }
    pending.value = _q.length;
  }

  Future<void> _save() async {
    (await SharedPreferences.getInstance()).setString('offline_q', jsonEncode(_q));
    pending.value = _q.length;
  }

  /// می‌فرستد؛ اگر اینترنت نبود صف می‌کند. [key]: برای upsert (فقط آخرین مقدار نگه داشته شود).
  Future<bool> send(String path, Map<String, dynamic> body, {String? key}) async {
    try {
      await Api.i.post(path, body: body);
      return true;
    } on ApiError catch (e) {
      if (!e.isNetwork) rethrow;
      if (key != null) _q.removeWhere((x) => x['key'] == key);
      _q.add({'path': path, 'body': body, 'key': key});
      await _save();
      return false;
    }
  }

  Future<void> flush() async {
    if (_busy || _q.isEmpty) return;
    _busy = true;
    try {
      while (_q.isNotEmpty) {
        final e = _q.first;
        try {
          await Api.i.post('${e['path']}', body: Map<String, dynamic>.from(e['body']));
          _q.removeAt(0);
          await _save();
        } on ApiError catch (x) {
          if (x.isNetwork || x.status >= 500 || x.status == 429) break;
          // خطای دائمی (۴xx): این مورد را کنار بگذار
          _q.removeAt(0);
          await _save();
        }
      }
    } finally {
      _busy = false;
    }
  }
}
