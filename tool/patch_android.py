"""بعد از `flutter create` اجرا می‌شود: مجوزها، سرویس پخش، AudioServiceActivity و desugaring."""
import pathlib, re, sys

root = pathlib.Path(sys.argv[1])
man = root / 'android/app/src/main/AndroidManifest.xml'
s = man.read_text(encoding='utf8')

perms = ['INTERNET', 'FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_MEDIA_PLAYBACK',
         'WAKE_LOCK', 'POST_NOTIFICATIONS', 'RECEIVE_BOOT_COMPLETED']
add = ''.join(f'    <uses-permission android:name="android.permission.{p}"/>\n'
              for p in perms if f'android.permission.{p}"' not in s)
s = re.sub(r'(<manifest[^>]*>\n)', lambda m: m.group(1) + add, s, count=1)
if 'xmlns:tools' not in s:
    s = s.replace('<manifest ', '<manifest xmlns:tools="http://schemas.android.com/tools" ', 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="همراه تحصیلی"', s, count=1)

extra = '''
        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter><action android:name="android.media.browse.MediaBrowserService"/></intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true" tools:ignore="Instantiatable">
            <intent-filter><action android:name="android.intent.action.MEDIA_BUTTON"/></intent-filter>
        </receiver>
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
s = s.replace('</application>', extra + '    </application>', 1)
man.write_text(s, encoding='utf8')

for f in (root / 'android/app/src/main').rglob('MainActivity.*'):
    t = f.read_text(encoding='utf8')
    t = t.replace('io.flutter.embedding.android.FlutterActivity',
                  'com.ryanheise.audioservice.AudioServiceActivity')
    t = t.replace('FlutterActivity', 'AudioServiceActivity')
    f.write_text(t, encoding='utf8')

app = root / 'android/app'
kts, groovy = app / 'build.gradle.kts', app / 'build.gradle'
if kts.exists():
    g = kts.read_text(encoding='utf8')
    g = re.sub(r'(compileOptions\s*\{)', r'\1\n        isCoreLibraryDesugaringEnabled = true', g, count=1)
    g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    kts.write_text(g, encoding='utf8')
else:
    g = groovy.read_text(encoding='utf8')
    g = re.sub(r'(compileOptions\s*\{)', r'\1\n        coreLibraryDesugaringEnabled true', g, count=1)
    g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    groovy.write_text(g, encoding='utf8')
print('android patched')
