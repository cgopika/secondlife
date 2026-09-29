import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intro = CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _WelcomeBackdrop()),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) => CustomPaint(
                  painter: _AtmospherePainter(_floatController.value),
                  foregroundPainter: _FloatingLeavesPainter(_floatController.value),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: intro,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: .94, end: 1).animate(intro),
                          child: AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, math.sin(_floatController.value * math.pi * 2) * 3),
                              child: child,
                            ),
                            child: _AnimatedWordmark(progress: _floatController),
                          ),
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: intro,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WelcomeActionButton(label: 'CREATE ACCOUNT', primary: true, onPressed: () => Navigator.pushNamed(context, '/register')),
                        const SizedBox(height: 14),
                        _WelcomeActionButton(label: 'LOGIN', onPressed: () => Navigator.pushNamed(context, '/login')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackdrop extends StatelessWidget {
  const _WelcomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9FAF5), AppColors.warmBg, Color(0xFFF1F7F2)]),
      ),
    );
  }
}

class _FloatingLeavesPainter extends CustomPainter {
  final double progress;

  const _FloatingLeavesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * math.pi * 2;
    const leaves = [
      (x: .10, y: .16, size: 16.0, angle: -.7, opacity: 0x2B6F9471, speed: 1.0),
      (x: .86, y: .22, size: 11.0, angle: .7, opacity: 0x257A9E7B, speed: .7),
      (x: .08, y: .48, size: 23.0, angle: .3, opacity: 0x1E5C8565, speed: .45),
      (x: .91, y: .58, size: 18.0, angle: -.35, opacity: 0x23718E70, speed: 1.2),
      (x: .16, y: .79, size: 10.0, angle: .9, opacity: 0x32658A6D, speed: .8),
      (x: .78, y: .84, size: 14.0, angle: -.8, opacity: 0x1B789D78, speed: .55),
    ];

    for (final leaf in leaves) {
      final drift = math.sin(phase * leaf.speed + leaf.y * 8) * 12;
      final rise = math.cos(phase * leaf.speed + leaf.x * 5) * 9;
      final paint = Paint()..color = Color(leaf.opacity);
      _leaf(
        canvas,
        paint,
        Offset(size.width * leaf.x + drift, size.height * leaf.y + rise),
        leaf.angle + math.sin(phase * leaf.speed) * .16,
        leaf.size,
      );
    }
  }

  void _leaf(Canvas canvas, Paint paint, Offset center, double angle, double length) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * .75, -length * .8, length, 0)
      ..quadraticBezierTo(length * .55, length * .55, 0, 0)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FloatingLeavesPainter oldDelegate) => oldDelegate.progress != progress;
}

class _AtmospherePainter extends CustomPainter {
  final double progress;

  const _AtmospherePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * math.pi * 2;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x1A91B99A), Color(0x001C5C42)],
      ).createShader(Rect.fromCircle(center: Offset(size.width * .5, size.height * .43), radius: size.width * .55));
    canvas.drawCircle(Offset(size.width * .5, size.height * .43), size.width * .55, glow);

    final linePaint = Paint()
      ..color = const Color(0x1A5D886B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final orbit = Path()
      ..moveTo(size.width * .16, size.height * .4)
      ..cubicTo(size.width * .28, size.height * (.26 + math.sin(phase) * .01), size.width * .72, size.height * (.26 - math.sin(phase) * .01), size.width * .84, size.height * .4)
      ..cubicTo(size.width * .75, size.height * .53, size.width * .25, size.height * .53, size.width * .16, size.height * .4);
    canvas.drawPath(orbit, linePaint);

    final particlePaint = Paint()..color = const Color(0x305C886C);
    for (final point in [
      Offset(size.width * .27, size.height * .3),
      Offset(size.width * .74, size.height * .29),
      Offset(size.width * .2, size.height * .64),
      Offset(size.width * .8, size.height * .7),
    ]) {
      final pulse = 1.5 + math.sin(phase + point.dx) * .7;
      canvas.drawCircle(point, pulse, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) => oldDelegate.progress != progress;
}

class _AnimatedWordmark extends StatelessWidget {
  final Animation<double> progress;

  const _AnimatedWordmark({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final pulse = (math.sin(progress.value * math.pi * 2) + 1) / 2;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(
              'SecondLife',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0x26315C47),
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
                shadows: [Shadow(color: Color.fromRGBO(47, 107, 79, .10 + pulse * .08), blurRadius: 24, offset: const Offset(0, 6))],
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2F6B4F), Color(0xFF173C2D)],
              ).createShader(bounds),
              child: const Text(
                'SecondLife',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: .3),
              ),
            ),
            Positioned(
              right: -18,
              top: 1,
              child: Transform.rotate(
                angle: -.45,
                child: CustomPaint(size: const Size(22, 18), painter: _WordmarkLeafPainter()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WordmarkLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF6D956E);
    final path = Path()
      ..moveTo(2, size.height - 2)
      ..quadraticBezierTo(size.width * .45, 0, size.width - 1, 2)
      ..quadraticBezierTo(size.width * .62, size.height * .72, 2, size.height - 2)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(const Offset(4, 15), const Offset(17, 5), Paint()..color = const Color(0xFFB5CDAE)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WelcomeActionButton extends StatefulWidget {
  final String label;
  final bool primary;
  final VoidCallback onPressed;

  const _WelcomeActionButton({required this.label, required this.onPressed, this.primary = false});

  @override
  State<_WelcomeActionButton> createState() => _WelcomeActionButtonState();
}

class _WelcomeActionButtonState extends State<_WelcomeActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(58)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5)),
    );

    final button = widget.primary
        ? FilledButton(onPressed: widget.onPressed, style: style, child: Text(widget.label))
        : OutlinedButton(
            onPressed: widget.onPressed,
            style: style.copyWith(
              backgroundColor: const WidgetStatePropertyAll(Color(0xCCFFFFFF)),
              foregroundColor: const WidgetStatePropertyAll(AppColors.darkGreen),
              side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFBFD4C5), width: 1.2)),
            ),
            child: Text(widget.label),
          );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .985 : 1,
        duration: const Duration(milliseconds: 120),
        child: button,
      ),
    );
  }
}
