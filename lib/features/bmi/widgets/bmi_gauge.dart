import 'package:flutter/material.dart';
import 'dart:math' as math;

class BmiGauge extends StatefulWidget {
  final double bmi;

  const BmiGauge({super.key, required this.bmi});

  @override
  State<BmiGauge> createState() => _BmiGaugeState();
}

class _BmiGaugeState extends State<BmiGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = Tween<double>(begin: 0, end: widget.bmi)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(BmiGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _anim =
        Tween<double>(begin: oldWidget.bmi, end: widget.bmi).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return CustomPaint(
          size: const Size(240, 130),
          painter: _GaugePainter(_anim.value),
          child: SizedBox(
            width: 240,
            height: 130,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.bmi > 0 ? _anim.value.toStringAsFixed(1) : '—',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double bmi;

  _GaugePainter(this.bmi);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final r = size.width / 2 - 10;

    // Draw zone arcs
    final colors = [
      const Color(0xFF4D96FF),
      const Color(0xFF6BCB77),
      const Color(0xFFFFE66D),
      const Color(0xFFFF6B6B),
    ];
    final sweeps = [math.pi * 0.25, math.pi * 0.25, math.pi * 0.25, math.pi * 0.25];
    double startAngle = -math.pi;

    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweeps[i],
        false,
        paint,
      );
      startAngle += sweeps[i];
    }

    // Needle
    if (bmi > 0) {
      // Map bmi 10–40 → -180° to 0°
      final normalised = ((bmi - 10) / 30).clamp(0.0, 1.0);
      final angle = -math.pi + normalised * math.pi;

      final needlePaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final needleEnd = Offset(
        cx + (r - 10) * math.cos(angle),
        cy + (r - 10) * math.sin(angle),
      );

      canvas.drawLine(Offset(cx, cy), needleEnd, needlePaint);

      // Centre dot
      canvas.drawCircle(Offset(cx, cy), 5,
          Paint()..color = Colors.black87);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) => oldDelegate.bmi != bmi;
}
