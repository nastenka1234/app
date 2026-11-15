import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'offline_queue.dart';

/// پیشرفت امروز به‌صورت محلی نگه داشته می‌شود و **مقدار کل** هر بار به /progress می‌رود.
class ProgressStore {
  static String _k(String day) => 'prog:$day';

  static Future<Map<String, PartProgress>> load(String day) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_k(day));
    if (raw == null) return {};
    final m = jsonDecode(raw) as Map;
    return {for (final e in m.entries) '${e.key}': PartProgress.fromJson(e.value as Map)};
  }

  static Future<PartProgress> update(String day, String part, void Function(PartProgress) fn,
      {bool send = true}) async {
    final all = await load(day);
    final pp = all[part] ?? PartProgress();
    fn(pp);
    all[part] = pp;
    final p = await SharedPreferences.getInstance();
    await p.setString(_k(day), jsonEncode({for (final e in all.entries) e.key: e.value.toJson()}));
    if (send) {
      try {
        await OfflineQueue.i.send('/progress', {'day': day, 'part': part, ...pp.toJson()},
            key: 'progress:$day:$part');
      } catch (_) {}
    }
    return pp;
  }
}
