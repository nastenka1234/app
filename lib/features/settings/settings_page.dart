import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/auth_store.dart';
import '../../core/jalali.dart';
import '../../core/media_cache.dart';
import '../../core/offline_queue.dart';
import '../../core/prefs.dart';
import '../../theme/glass.dart';
import '../../theme/tokens.dart';
import '../music/player_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int cacheBytes = 0;

  @override
  void initState() {
    super.initState();
    _size();
  }

  Future<void> _size() async {
    final b = await MediaCache.sizeBytes();
    if (mounted) setState(() => cacheBytes = b);
  }

  Widget _drop(String label, int value, List<int> opts, ValueChanged<int> on) => Row(children: [
        Expanded(child: Text(label)),
        DropdownButton<int>(
          value: value,
          dropdownColor: T.sec,
          underline: const SizedBox.shrink(),
          items: [for (final o in opts) DropdownMenuItem(value: o, child: Text('${fa(o)} دقیقه'))],
          onChanged: (v) {
            if (v != null) {
              on(v);
              Prefs.save();
              setState(() {});
            }
          },
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(authProvider);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      PageTitle('تنظیمات', sub: s?.name),
      Glass(
        child: Column(children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تعویض خودکار موزیک در استراحت'),
            value: Prefs.autoMusic,
            onChanged: (v) {
              setState(() => Prefs.autoMusic = v);
              Prefs.save();
            },
          ),
          const Divider(),
          _drop('مدت تمرکز (پومودورو)', Prefs.focusMin, [25, 35, 45, 50], (v) => Prefs.focusMin = v),
          _drop('مدت استراحت', Prefs.breakMin, [5, 10, 15], (v) => Prefs.breakMin = v),
        ]),
      ),
      const SizedBox(height: 12),
      Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('کش موزیک: ${fa((cacheBytes / 1048576).toStringAsFixed(1))} مگابایت')),
            GhostButton('پاک‌کردن', onPressed: () async {
              await PlayerService.i.stop();
              await MediaCache.clear();
              _size();
            }),
          ]),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: OfflineQueue.i.pending,
            builder: (_, n, __) => Row(children: [
              Expanded(child: Text('منتظر ارسال: ${fa(n)} مورد')),
              GhostButton('ارسال الان', onPressed: n == 0 ? null : () => OfflineQueue.i.flush()),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Glass(
        child: Text('سرور: ${Api.i.baseUrl}',
            textDirection: TextDirection.ltr, style: const TextStyle(color: T.tx2, fontSize: 12)),
      ),
      const SizedBox(height: 20),
      PrimaryButton('خروج', icon: Icons.logout_rounded, onPressed: () async {
        await PlayerService.i.stop();
        await ref.read(authProvider.notifier).logout();
      }),
    ]);
  }
}
