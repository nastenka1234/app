import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/auth_store.dart';
import '../../core/jalali.dart';
import '../../core/models.dart';
import '../../core/offline_queue.dart';
import '../../core/progress_store.dart';
import '../../theme/glass.dart';
import '../../theme/tokens.dart';

class TodayData {
  final PlanDay plan;
  final Map<String, PartProgress> progress;
  TodayData(this.plan, this.progress);
}

final todayProvider = FutureProvider.autoDispose<TodayData>((ref) async {
  final day = todayIso();
  final r = await Api.i.get('/plan', q: {'day': day});
  final plan = PlanDay.fromJson(r);
  final prog = await ProgressStore.load(day);
  return TodayData(plan, prog);
});

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authProvider)?.name ?? '';
    final data = ref.watch(todayProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(todayProvider.future),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        PageTitle('سلام $name', sub: jalaliFull(todayIso())),
        ValueListenableBuilder<int>(
          valueListenable: OfflineQueue.i.pending,
          builder: (_, n, __) => n == 0
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Glass(
                      radius: 20,
                      padding: const EdgeInsets.all(12),
                      child: Text('${fa(n)} مورد منتظر اینترنت است و بعداً ارسال می‌شود.',
                          style: const TextStyle(color: T.tx2, fontSize: 13))),
                ),
        ),
        data.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Glass(child: Text(e is ApiError ? e.fa : 'خطا در دریافت برنامه')),
          data: (d) => _Body(d, () => ref.invalidate(todayProvider)),
        ),
      ]),
    );
  }
}

class _Body extends StatelessWidget {
  final TodayData d;
  final VoidCallback refresh;
  const _Body(this.d, this.refresh);

  @override
  Widget build(BuildContext context) {
    final plan = d.plan;
    final plannedMin = plan.items.fold<int>(0, (a, b) => a + b.minutes);
    final studiedMin = d.progress.values.fold<int>(0, (a, b) => a + b.studySeconds) ~/ 60;
    final frac = plannedMin == 0 ? 0.0 : (studiedMin / plannedMin).clamp(0.0, 1.0);
    return Column(children: [
      if (plan.source == 'ai')
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Glass(
            borderColor: T.acc,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('برنامه‌ی امروزت بر اساس دیروزت تنظیم شد',
                  style: TextStyle(fontWeight: FontWeight.w900, color: T.hi)),
              if (plan.note.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(plan.note, style: const TextStyle(color: T.tx2))),
            ]),
          ),
        )
      else if (plan.note.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Glass(child: Text(plan.note)),
        ),
      if (plan.items.isEmpty)
        const Glass(child: Text('برای امروز برنامه‌ای ثبت نشده. از مشاورت بخواه.'))
      else ...[
        Glass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('پیشرفت امروز', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('${fa(studiedMin)} از ${fmtMin(plannedMin)}', style: const TextStyle(color: T.tx2)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: frac, minHeight: 10, backgroundColor: T.glass, color: T.acc),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        for (final it in plan.items) _PartCard(plan.day, it, d.progress[it.part], refresh),
        const SizedBox(height: 8),
        PrimaryButton('گزارشکار شبانه', icon: Icons.nights_stay_rounded, onPressed: () => context.push('/report')),
      ],
    ]);
  }
}

class _PartCard extends StatelessWidget {
  final String day;
  final PlanItem it;
  final PartProgress? pp;
  final VoidCallback refresh;
  const _PartCard(this.day, this.it, this.pp, this.refresh);

  @override
  Widget build(BuildContext context) {
    final mins = (pp?.studySeconds ?? 0) ~/ 60;
    final frac = it.minutes == 0 ? 0.0 : (mins / it.minutes).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it.part, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                if (it.subject.isNotEmpty)
                  Text(it.subject, style: const TextStyle(color: T.tx2)),
              ]),
            ),
            if (pp?.done == true) const Icon(Icons.check_circle_rounded, color: T.acc),
          ]),
          const SizedBox(height: 8),
          Text('${fmtMin(it.minutes)}${it.testsTarget > 0 ? ' · هدف ${fa(it.testsTarget)} تست' : ''}',
              style: const TextStyle(color: T.hi)),
          if (it.note.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(it.note, style: const TextStyle(color: T.tx2, fontSize: 13))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: frac, minHeight: 6, backgroundColor: T.glass, color: T.acc),
          ),
          const SizedBox(height: 4),
          Text(
            'مطالعه: ${fmtMin(mins)} · تست: ${fa(pp?.tests ?? 0)} (${fa((pp?.percent ?? 0).round())}٪ درست)',
            style: const TextStyle(color: T.tx2, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: PrimaryButton('شروع', icon: Icons.play_arrow_rounded, onPressed: () async {
                await context.push(
                    '/focus?part=${Uri.encodeQueryComponent(it.part)}&subject=${Uri.encodeQueryComponent(it.subject)}');
                refresh();
              }),
            ),
            const SizedBox(width: 10),
            GhostButton('ثبت تست', icon: Icons.edit_rounded, onPressed: () async {
              final ok = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _TestSheet(day, it.part, pp),
              );
              if (ok == true) refresh();
            }),
          ]),
        ]),
      ),
    );
  }
}

class _TestSheet extends StatefulWidget {
  final String day, part;
  final PartProgress? pp;
  const _TestSheet(this.day, this.part, this.pp);
  @override
  State<_TestSheet> createState() => _TestSheetState();
}

class _TestSheetState extends State<_TestSheet> {
  late int tests = widget.pp?.tests ?? 0;
  late int correct = widget.pp?.correct ?? 0;
  late bool done = widget.pp?.done ?? false;

  Widget _stepper(String label, int v, ValueChanged<int> on) => Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton(onPressed: v > 0 ? () => on(v - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
        SizedBox(width: 44, child: Center(child: Text(fa(v), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)))),
        IconButton(onPressed: () => on(v + 1), icon: const Icon(Icons.add_circle_outline)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.part, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _stepper('تعداد تست', tests, (v) => setState(() {
                tests = v;
                if (correct > tests) correct = tests;
              })),
          _stepper('درست', correct, (v) => setState(() => correct = v > tests ? tests : v)),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('این پارت تمام شد'),
              value: done,
              onChanged: (v) => setState(() => done = v)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton('ذخیره', onPressed: () async {
              await ProgressStore.update(widget.day, widget.part, (p) {
                p.tests = tests;
                p.correct = correct;
                p.done = done;
              });
              if (context.mounted) Navigator.pop(context, true);
            }),
          ),
        ]),
      ),
    );
  }
}
