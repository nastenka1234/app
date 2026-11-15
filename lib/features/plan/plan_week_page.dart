import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/jalali.dart';
import '../../core/models.dart';
import '../../theme/glass.dart';
import '../../theme/tokens.dart';

final weekPlanProvider = FutureProvider.autoDispose<List<PlanDay>>((ref) async {
  final r = await Api.i.get('/plan', q: {'day': todayIso(), 'days': 7});
  final list = r['plans'] as List?;
  if (list == null) return [PlanDay.fromJson(r)];
  return [for (final x in list) PlanDay.fromJson(x)];
});

class PlanWeekPage extends ConsumerWidget {
  const PlanWeekPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(weekPlanProvider);
    final tomorrow = addDays(todayIso(), 1);
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(weekPlanProvider.future),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        const PageTitle('برنامه', sub: 'هفته‌ی پیش‌رو'),
        plans.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Glass(child: Text(e is ApiError ? e.fa : 'خطا در دریافت برنامه')),
          data: (list) => Column(children: [
            for (final p in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Glass(
                  borderColor: p.source == 'ai' ? T.acc : null,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                          child: Text(
                              '${p.day == tomorrow ? 'فردا · ' : ''}${jalaliFull(p.day)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                      if (p.source == 'ai')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: T.acc, borderRadius: BorderRadius.circular(20)),
                          child: const Text('ویرایش‌شده توسط هوش مصنوعی',
                              style: TextStyle(color: T.bg, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                    if (p.note.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(p.note, style: const TextStyle(color: T.hi, fontSize: 13))),
                    const SizedBox(height: 8),
                    if (p.items.isEmpty)
                      const Text('برنامه‌ای ثبت نشده', style: TextStyle(color: T.tx2))
                    else
                      for (final it in p.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            const Icon(Icons.circle, size: 7, color: T.acc),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text('${it.part}${it.subject.isEmpty ? '' : ' — ${it.subject}'}')),
                            Text(
                                '${fmtMin(it.minutes)}${it.testsTarget > 0 ? ' · ${fa(it.testsTarget)} تست' : ''}',
                                style: const TextStyle(color: T.tx2, fontSize: 12)),
                          ]),
                        ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
