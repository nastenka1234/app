import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Notifs {
  static final _p = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
    await _p.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    await _p
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleDaily() async {
    await _p.cancelAll();
    await _at(1, 7, 0, 'برنامه‌ی امروزت آماده است', 'اپ را باز کن و پارت اول را شروع کن.');
    await _at(2, 21, 30, 'وقت گزارشکار شبانه', 'تست‌ها و حال امروزت را ثبت کن تا برنامه‌ی فردا تنظیم شود.');
  }

  static Future<void> cancel() => _p.cancelAll();

  static Future<void> _at(int id, int h, int m, String title, String body) async {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));
    await _p.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails('daily', 'یادآوری‌ها',
            importance: Importance.high, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
