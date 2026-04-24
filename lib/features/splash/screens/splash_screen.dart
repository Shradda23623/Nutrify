import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbitCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _taglineFade;
  late Animation<double> _dotsFade;
  late Animation<double> _pulse;
  late Animation<double> _orbit;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainCtrl,
          curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainCtrl,
          curve: const Interval(0.0, 0.40, curve: Curves.easeIn)),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _mainCtrl,
          curve: const Interval(0.45, 0.75, curve: Curves.easeOut)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainCtrl,
          curve: const Interval(0.45, 0.75, curve: Curves.easeOut)),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainCtrl,
          curve: const Interval(0.65, 0.90, curve: Curves.easeOut)),
    );
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainCtrl,
          curve: const Interval(0.80, 1.0, curve: Curves.easeOut)),
    );

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
    _orbit = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_orbitCtrl);

    _mainCtrl.forward();

    Future.delayed(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      final loggedIn = await AuthService.isLoggedIn();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, loggedIn ? AppRoutes.home : AppRoutes.auth);
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.3),
                  radius: 1.4,
                  colors: [Color(0xFF1A1A3E), Color(0xFF0D0D1A)],
                ),
              ),
            ),
            Positioned(
              top: -80,
              left: -60,
              child: _GlowBlob(
                  color: const Color(0xFF6BCB77), size: 260, opacity: 0.07),
            ),
            Positioned(
              bottom: -100,
              right: -80,
              child: _GlowBlob(
                  color: const Color(0xFF4D96FF), size: 300, opacity: 0.06),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([_mainCtrl, _pulseCtrl, _orbitCtrl]),
                builder: (context, _) {
                  return Column(
                    children: [
                      const Spacer(flex: 3),
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: (_logoFade.value * _pulse.value * 0.5)
                                  .clamp(0.0, 1.0),
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.green.withOpacity(0.35),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: _logoFade.value.clamp(0.0, 1.0),
                              child: CustomPaint(
                                size: const Size(190, 190),
                                painter: _OrbitPainter(
                                    angle: _orbit.value,
                                    color: AppColors.green),
                              ),
                            ),
                            Transform.scale(
                              scale: _logoScale.value,
                              child: FadeTransition(
                                opacity: _logoFade,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2A2A4E),
                                        Color(0xFF1A1A2E),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color:
                                          AppColors.green.withOpacity(0.30),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0D0D1A)
                                            .withOpacity(0.6),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/app_logo.png',
                                      width: 130,
                                      height: 130,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                        child: Text(
                                          '\U0001F957',
                                          style: TextStyle(fontSize: 54),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _textFade,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: const Text(
                            'Nutrify',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.0,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _taglineFade,
                        child: const Text(
                          'TRACK  \u00b7  THRIVE  \u00b7  NOURISH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white38,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      FadeTransition(
                        opacity: _dotsFade,
                        child: _PulsingDots(),
                      ),
                      const SizedBox(height: 52),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double angle;
  final Color color;
  const _OrbitPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);
    canvas.drawCircle(
        Offset(dotX, dotY), 5, Paint()..color = color.withOpacity(0.85));
    final trailAngle = angle - 0.40;
    final trailX = center.dx + radius * math.cos(trailAngle);
    final trailY = center.dy + radius * math.sin(trailAngle);
    canvas.drawCircle(
        Offset(trailX, trailY), 3, Paint()..color = color.withOpacity(0.35));
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.angle != angle;
}

class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 700));
      final anim = Tween<double>(begin: 0.25, end: 1.0)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
      _ctrls.add(ctrl);
      _anims.add(anim);
      Future.delayed(Duration(milliseconds: i * 220), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(_ctrls),
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withOpacity(_anims[i].value),
              ),
            );
          }),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _GlowBlob(
      {required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity * 0.8),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}
