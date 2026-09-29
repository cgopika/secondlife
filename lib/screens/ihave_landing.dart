import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../main.dart';
import 'material_history.dart';
import 'material_tracking.dart';

class IHaveLandingScreen extends StatelessWidget {
  const IHaveLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('I Have', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              const _CompactToteBag(),
              const SizedBox(height: 4),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'What you don\'t need\n'),
                    TextSpan(text: 'could be exactly what\n', style: TextStyle(color: Color(0xFF315C47))),
                    TextSpan(text: 'someone else needs.'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, height: 1.12, fontWeight: FontWeight.w800, color: Color(0xFF18352A)),
              ),
              const SizedBox(height: 5),
              const Text('List it on SecondLife and help it find a new purpose.', style: TextStyle(color: Color(0xFF69756D))),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final tileWidth = math.min(250.0, MediaQuery.sizeOf(context).width - 48);
                  return Column(
                    children: [
                      SizedBox(
                        width: tileWidth,
                        child: _CompactActionTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemSheet())),
                          icon: Icons.add_rounded,
                          label: 'Add\nMaterial',
                          color: const Color(0xFF2F6B4F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: tileWidth,
                        child: _CompactActionTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialHistoryScreen())),
                          icon: Icons.history_rounded,
                          label: 'History',
                          color: const Color(0xFFE8F3EC),
                          iconColor: const Color(0xFF2F6B4F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: tileWidth,
                        child: _CompactActionTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialTrackingScreen())),
                          icon: Icons.track_changes_rounded,
                          label: 'Tracking',
                          color: const Color(0xFFE8F3EC),
                          iconColor: const Color(0xFF2F6B4F),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.home_outlined), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
              IconButton(icon: const Icon(Icons.person_outline_rounded), onPressed: () {}),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemSheet())), backgroundColor: const Color(0xFF2F6B4F), child: const Icon(Icons.add_rounded, color: Color(0xFFE8F3EC))),
    );
  }
}

class _CompactToteBag extends StatefulWidget {
  const _CompactToteBag();

  @override
  State<_CompactToteBag> createState() => _CompactToteBagState();
}

class _CompactToteBagState extends State<_CompactToteBag> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      width: 150,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * math.pi * 2;
          return Transform.translate(
            offset: Offset(0, math.sin(phase) * 2.5),
            child: CustomPaint(
              painter: _CompactTotePainter(handleSway: math.sin(phase)),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Icon(Icons.recycling_rounded, size: 27, color: Color(0xFF5A8056)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompactTotePainter extends CustomPainter {
  final double handleSway;

  const _CompactTotePainter({required this.handleSway});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final shadowPaint = Paint()..color = const Color(0x18315C47);
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, 105), width: 84, height: 8), shadowPaint);

    final handlePaint = Paint()
      ..color = const Color(0xFFB08C68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final handles = Path()
      ..moveTo(centerX - 24, 36)
      ..cubicTo(centerX - 31, 8 + handleSway * 1.5, centerX - 8, 6 - handleSway * 1.5, centerX, 32)
      ..moveTo(centerX + 24, 36)
      ..cubicTo(centerX + 31, 8 - handleSway * 1.5, centerX + 8, 6 + handleSway * 1.5, centerX, 32);
    canvas.drawPath(handles, handlePaint);

    final bag = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, 68), width: 72, height: 66),
      const Radius.circular(5),
    );
    canvas.drawRRect(bag, Paint()..color = const Color(0xFFF1E6D1));
    canvas.drawRRect(
      bag,
      Paint()
        ..color = const Color(0xFF8F755C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(Offset(centerX - 35, 42), Offset(centerX + 35, 42), Paint()..color = const Color(0xFFD7C2A6));
  }

  @override
  bool shouldRepaint(covariant _CompactTotePainter oldDelegate) => oldDelegate.handleSway != handleSway;
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFE8F3EC), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF2F6B4F), size: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF69756D)))])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF69756D))
        ]),
      ),
    );
  }
}

class _CompactActionTile extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;

  const _CompactActionTile({required this.onTap, required this.icon, required this.label, required this.color, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
