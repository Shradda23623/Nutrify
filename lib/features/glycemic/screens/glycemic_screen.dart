import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../../calories/services/calorie_service.dart';
import '../../calories/models/calorie_model.dart';

class GlycemicScreen extends StatefulWidget {
  const GlycemicScreen({super.key});

  @override
  State<GlycemicScreen> createState() => _GlycemicScreenState();
}

class _GlycemicScreenState extends State<GlycemicScreen>
    with SingleTickerProviderStateMixin {
  final _service = CalorieService();
  CalorieModel? _model;
  bool _loading = true;
  late AnimationController _animCtrl;

  // Healthy GL threshold (daily): <100 = low, 100-150 = moderate, >150 = high
  static const double _lowGL     = 100;
  static const double _moderateGL = 150;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final model = await _service.load();
    if (mounted) {
      setState(() {
        _model   = model;
        _loading = false;
      });
      _animCtrl.forward(from: 0);
    }
  }

  Color _glColor(double gl) {
    if (gl < _lowGL)     return const Color(0xFF6BCB77);
    if (gl < _moderateGL) return const Color(0xFFFFB347);
    return const Color(0xFFFF5252);
  }

  String _glLabel(double gl) {
    if (gl < _lowGL)     return 'Low — Excellent';
    if (gl < _moderateGL) return 'Moderate';
    return 'High — Reduce carbs';
  }

  String _giCategory(double gi) {
    if (gi == 0)  return 'Unknown';
    if (gi <= 55) return 'Low GI';
    if (gi <= 69) return 'Medium GI';
    return 'High GI';
  }

  Color _giColor(double gi) {
    if (gi == 0)  return Colors.grey;
    if (gi <= 55) return const Color(0xFF6BCB77);
    if (gi <= 69) return const Color(0xFFFFB347);
    return const Color(0xFFFF5252);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            context.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.pageBg,
        body: _loading || _model == null
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(child: _buildDailySummary(context)),
                  SliverToBoxAdapter(child: _buildGLMeter(context)),
                  SliverToBoxAdapter(child: _buildInfoCards(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _buildEntryRow(ctx, _model!.entries[i]),
                        childCount: _model!.entries.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.pageBg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Glycemic Load',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textPrimary)),
    );
  }

  Widget _buildDailySummary(BuildContext context) {
    final model  = _model!;
    final gl     = model.totalGlycemicLoad;
    final color  = _glColor(gl);
    final label  = _glLabel(gl);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Glycemic Load",
                  style: TextStyle(fontSize: 13, color: context.textMuted)),
              const SizedBox(height: 4),
              Text(gl.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.0)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const Spacer(),
          _GlArcWidget(gl: gl, color: color),
        ],
      ),
    );
  }

  Widget _buildGLMeter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily GL Scale',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 40,
                      child: Container(height: 10,
                          color: const Color(0xFF6BCB77).withOpacity(0.8)),
                    ),
                    Expanded(
                      flex: 25,
                      child: Container(height: 10,
                          color: const Color(0xFFFFB347).withOpacity(0.8)),
                    ),
                    Expanded(
                      flex: 35,
                      child: Container(height: 10,
                          color: const Color(0xFFFF5252).withOpacity(0.8)),
                    ),
                  ],
                ),
                AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (_, __) {
                    final gl   = _model!.totalGlycemicLoad;
                    final pct  = (gl / 250).clamp(0.0, 1.0) * _animCtrl.value;
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct,
                      child: Container(
                        height: 10,
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('0', style: TextStyle(fontSize: 10, color: context.textMuted)),
              const Spacer(),
              Text('100\nLow', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: context.textMuted)),
              const Spacer(),
              Text('150\nMod', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: context.textMuted)),
              const Spacer(),
              Text('250+', style: TextStyle(fontSize: 10, color: context.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Foods",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          const SizedBox(height: 4),
          Text('Glycemic Index × net carbs ÷ 100',
              style: TextStyle(fontSize: 12, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _buildEntryRow(BuildContext context, CalorieEntry entry) {
    final gi      = entry.glycemicIndex;
    final gl      = entry.glycemicLoad;
    final giColor = _giColor(gi);
    final giCat   = _giCategory(gi);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: giColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                gi == 0 ? '?' : gi.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: giColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary)),
                Text('${entry.carbs.toStringAsFixed(1)}g carbs  •  $giCat',
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('GL ${gl.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _glColor(gl * 10))),
              Text('GI ${gi.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 11, color: context.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small arc widget for the summary card ─────────────────────────────────
class _GlArcWidget extends StatelessWidget {
  final double gl;
  final Color color;
  const _GlArcWidget({required this.gl, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (gl / 200).clamp(0.0, 1.0);
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(painter: _ArcPainter(pct: pct, color: color)),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double pct;
  final Color color;
  const _ArcPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        math.pi, math.pi, false,
        Paint()
          ..color = color.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);
    if (pct > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r),
          math.pi, math.pi * pct, false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.pct != pct;
}
