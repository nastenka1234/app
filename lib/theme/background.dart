import 'package:flutter/material.dart';
import 'tokens.dart';

/// بکگراند به سبک سونو: چند لکه‌ی بزرگ و محو که آرام جابه‌جا می‌شوند. بدون نقطه/ستاره/دانه.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key});
  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 22));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(Alignment a, double size, Color color) => Align(
        alignment: a,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return RepaintBoundary(
      child: Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: T.bg),
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = Curves.easeInOut.transform(_c.value);
            return Stack(fit: StackFit.expand, children: [
              _blob(Alignment(-1 + .5 * t, -.9 + .35 * t), w * 1.5, T.acc.withOpacity(.34)),
              _blob(Alignment(1 - .6 * t, -.1 + .3 * t), w * 1.4, T.sec.withOpacity(.95)),
              _blob(Alignment(-.3 + .5 * t, 1 - .4 * t), w * 1.5, T.acc.withOpacity(.22)),
              _blob(Alignment(.6 - .8 * t, .5 - .3 * t), w * 1.0, T.hi.withOpacity(.07)),
            ]);
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [T.bg.withOpacity(.3), T.bg.withOpacity(.6)],
            ),
          ),
        ),
      ]),
    );
  }
}
