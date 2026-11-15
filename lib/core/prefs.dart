import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class Prefs {
  static bool autoMusic = true;
  static int focusMin = Config.focusMinutes;
  static int breakMin = Config.breakMinutes;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    autoMusic = p.getBool('autoMusic') ?? true;
    focusMin = p.getInt('focusMin') ?? Config.focusMinutes;
    breakMin = p.getInt('breakMin') ?? Config.breakMinutes;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('autoMusic', autoMusic);
    await p.setInt('focusMin', focusMin);
    await p.setInt('breakMin', breakMin);
  }
}
