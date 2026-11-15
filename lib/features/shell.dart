import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import 'music/mini_player.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  static const _tabs = [
    ('/today', 'امروز', Icons.today_rounded),
    ('/stats', 'آمار', Icons.bar_chart_rounded),
    ('/plan', 'برنامه', Icons.event_note_rounded),
    ('/music', 'موزیک', Icons.music_note_rounded),
    ('/settings', 'تنظیمات', Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.$1));
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniPlayer(),
        Container(
          decoration: BoxDecoration(
            color: T.sec.withOpacity(.88),
            border: const Border(top: BorderSide(color: T.line)),
          ),
          child: NavigationBar(
            height: 68,
            selectedIndex: idx < 0 ? 0 : idx,
            onDestinationSelected: (i) => context.go(_tabs[i].$1),
            destinations: [
              for (final t in _tabs) NavigationDestination(icon: Icon(t.$3), label: t.$2),
            ],
          ),
        ),
      ]),
    );
  }
}
