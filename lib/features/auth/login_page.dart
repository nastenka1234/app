import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/auth_store.dart';
import '../../theme/glass.dart';
import '../../theme/tokens.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _pw = TextEditingController();
  final _url = TextEditingController(text: Api.i.baseUrl);
  bool _busy = false;
  String? _err;

  Future<void> _submit() async {
    if (_pw.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      if (_url.text.trim() != Api.i.baseUrl) await Api.i.setBaseUrl(_url.text);
      ref.read(flashProvider.notifier).state = null;
      await ref.read(authProvider.notifier).login(_pw.text.trim());
    } on ApiError catch (e) {
      if (mounted) setState(() => _err = e.fa);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flash = ref.watch(flashProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('همراه تحصیلی',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('رمزت را وارد کن', style: TextStyle(color: T.tx2)),
                const SizedBox(height: 24),
                Glass(
                  child: Column(children: [
                    TextField(
                      controller: _pw,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(hintText: 'رمز'),
                    ),
                    if (_err != null || flash != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_err ?? flash!,
                            style: const TextStyle(color: T.hi, fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: double.infinity,
                        child: PrimaryButton('ورود', onPressed: _submit, busy: _busy)),
                  ]),
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text('تنظیم آدرس سرور',
                        style: TextStyle(color: T.tx2, fontSize: 13)),
                    iconColor: T.tx2,
                    collapsedIconColor: T.tx2,
                    children: [
                      TextField(
                        controller: _url,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(hintText: 'https://…workers.dev'),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
