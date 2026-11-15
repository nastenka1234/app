import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/jalali.dart';
import '../../core/models.dart';
import '../../theme/glass.dart';
import '../../theme/tokens.dart';

class PlanEditor extends StatefulWidget {
  final String studentId;
  const PlanEditor({super.key, required this.studentId});
  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  late final List<String> days = [for (var i = 0; i < 7; i++) addDays(todayIso(), i)];
  final Map<String, List<PlanItem>> mine = {};
  final Map<String, PlanDay> server = {};
  final Set<String> dirty = {};
  bool loading = true, saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.i.get('/admin/plan/${widget.studentId}', q: {'from': days.first});
      for (final x in (r['plans'] as List? ?? [])) {
        final p = PlanDay.fromJson(x);
        server[p.day] = p;
      }
      for (final d in days) {
        final p = server[d];
        final src = p == null ? <PlanItem>[] : (p.base.isNotEmpty ? p.base : p.items);
        mine[d] = [for (final i in src) PlanItem.fromJson(i.toJson())];
      }
    } on ApiError catch (e) {
      error = e.fa;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    if (dirty.isEmpty) return;
    setState(() => saving = true);
    try {
      await Api.i.put('/admin/plan/${widget.studentId}', body: {
        'days': [
          for (final d in days)
            if (dirty.contains(d)) {'day': d, 'items': [for (final i in mine[d]!) i.toJson()]},
        ],
      });
      dirty.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برنامه ذخیره شد')));
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.fa)));
    }
    if (mounted) setState(() => saving = false);
  }

  Future<void> _edit(String day, int? index) async {
    final it = index == null ? PlanItem(minutes: 60) : PlanItem.fromJson(mine[day]![index].toJson());
    final part = TextEditingController(text: it.part);
    final subject = TextEditingController(text: it.subject);
    final minutes = TextEditingController(text: it.minutes == 0 ? '' : '${it.minutes}');
    final tests = TextEditingController(text: it.testsTarget == 0 ? '' : '${it.testsTarget}');
    final note = TextEditingController(text: it.note);
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: part, decoration: const InputDecoration(labelText: 'نام پارت (اجباری)')),
            const SizedBox(height: 10),
            TextField(controller: subject, decoration: const InputDecoration(labelText: 'درس')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: minutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'دقیقه (۰–۳۶۰)'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: tests,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'هدف تست'))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'یادداشت')),
            const SizedBox(height: 14),
            Row(children: [
              if (index != null) ...[
                GhostButton('حذف', icon: Icons.delete_outline_rounded, onPressed: () => Navigator.pop(context, 'del')),
                const SizedBox(width: 10),
              ],
              Expanded(child: PrimaryButton('تأیید', onPressed: () => Navigator.pop(context, 'ok'))),
            ]),
          ]),
        ),
      ),
    );
    if (action == null) return;
    setState(() {
      final list = mine[day]!;
      if (action == 'del' && index != null) {
        list.removeAt(index);
      } else if (action == 'ok' && part.text.trim().isNotEmpty) {
        final n = PlanItem(
          part: part.text.trim(),
          subject: subject.text.trim(),
          minutes: (int.tryParse(minutes.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).clamp(0, 360),
          testsTarget: (int.tryParse(tests.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).clamp(0, 500),
          note: note.text.trim(),
        );
        if (index == null) {
          if (list.length >= 12) return;
          list.add(n);
        } else {
          list[index] = n;
        }
      }
      dirty.add(day);
    });
  }

  void _copyPrev(String day) {
    final i = days.indexOf(day);
    if (i <= 0) return;
    setState(() {
      mine[day] = [for (final x in mine[days[i - 1]]!) PlanItem.fromJson(x.toJson())];
      dirty.add(day);
    });
  }

  String _line(PlanItem i) =>
      '${i.part}${i.subject.isEmpty ? '' : ' — ${i.subject}'} · ${fmtMin(i.minutes)}${i.testsTarget > 0 ? ' · ${fa(i.testsTarget)} تست' : ''}';

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));
    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: [
        for (final d in days)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Glass(
              borderColor: dirty.contains(d) ? T.acc : null,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: Text(jalaliFull(d), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                  if (d != days.first)
                    TextButton(onPressed: () => _copyPrev(d), child: const Text('کپی از روز قبل')),
                ]),
                if (mine[d]!.isEmpty) const Text('خالی', style: TextStyle(color: T.tx2)),
                for (var i = 0; i < mine[d]!.length; i++)
                  InkWell(
                    onTap: () => _edit(d, i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        const Icon(Icons.edit_rounded, size: 15, color: T.tx2),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_line(mine[d]![i]))),
                      ]),
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                      onPressed: () => _edit(d, null),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('افزودن پارت')),
                ),
                if (server[d]?.source == 'ai')
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('نسخه‌ی AI در برابر برنامه‌ی من',
                          style: TextStyle(color: T.hi, fontSize: 13)),
                      children: [
                        Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('برنامه‌ی من:', style: TextStyle(fontWeight: FontWeight.w700)),
                              for (final i in server[d]!.base)
                                Text(_line(i), style: const TextStyle(color: T.tx2, fontSize: 12)),
                              const SizedBox(height: 8),
                              const Text('ویرایش AI:', style: TextStyle(fontWeight: FontWeight.w700)),
                              for (final i in server[d]!.items)
                                Text(_line(i), style: const TextStyle(color: T.hi, fontSize: 12)),
                              if (server[d]!.note.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(server[d]!.note, style: const TextStyle(color: T.tx2, fontSize: 12))),
                            ])),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
      ]),
      Positioned(
        left: 16,
        right: 16,
        bottom: 16,
        child: PrimaryButton(dirty.isEmpty ? 'تغییری نیست' : 'ذخیره‌ی برنامه (${fa(dirty.length)} روز)',
            busy: saving, onPressed: dirty.isEmpty ? null : _save),
      ),
    ]);
  }
}
