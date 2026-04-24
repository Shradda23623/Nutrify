import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../services/micronutrient_service.dart';

class MicronutrientScreen extends StatefulWidget {
  const MicronutrientScreen({super.key});

  @override
  State<MicronutrientScreen> createState() => _MicronutrientScreenState();
}

class _MicronutrientScreenState extends State<MicronutrientScreen>
    with SingleTickerProviderStateMixin {
  final _service = MicronutrientService();
  List<MicronutrientStatus> _statuses = [];
  List<WeeklyMicroSnapshot> _weekly  = [];
  bool _loading = true;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _service.getTodayStatus();
    final w = await _service.getWeeklySnapshots();
    if (mounted) {
      setState(() {
        _statuses = s;
        _weekly   = w;
        _loading  = false;
      });
      _animCtrl.forward(from: 0);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  Color _levelColor(DeficiencyLevel l) {
    switch (l) {
      case DeficiencyLevel.ok:       return const Color(0xFF6BCB77);
      case DeficiencyLevel.low:      return const Color(0xFFFFB347);
      case DeficiencyLevel.critical: return const Color(0xFFFF5252);
    }
  }

  String _levelLabel(DeficiencyLevel l) {
    switch (l) {
      case DeficiencyLevel.ok:       return 'Good';
      case DeficiencyLevel.low:      return 'Low';
      case DeficiencyLevel.critical: return 'Critical';
    }
  }

  int get _alertCount =>
      _statuses.where((s) => s.level != DeficiencyLevel.ok).length;

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
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(child: _buildSummaryBanner(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _buildNutrientCard(ctx, _statuses[i], i),
                        childCount: _statuses.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildWeeklyChart(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: context.pageBg,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Micronutrients',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                )),
            Text("Today's vitamin & mineral intake",
                style: TextStyle(
                    fontSize: 11,
                    color: context.textMuted,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  // ── Summary banner ─────────────────────────────────────────────────────────
  Widget _buildSummaryBanner(BuildContext context) {
    final criticals = _statuses
        .where((s) => s.level == DeficiencyLevel.critical)
        .length;
    final lows = _statuses
        .where((s) => s.level == DeficiencyLevel.low)
        .length;

    Color bannerColor;
    String bannerTitle;
    String bannerMsg;
    IconData bannerIcon;

    if (criticals > 0) {
      bannerColor = const Color(0xFFFF5252);
      bannerTitle = '$criticals nutrient${criticals > 1 ? 's' : ''} critically low';
      bannerMsg   = 'Your body needs more of these today. Check the tips below.';
      bannerIcon  = Icons.warning_amber_rounded;
    } else if (lows > 0) {
      bannerColor = const Color(0xFFFFB347);
      bannerTitle = '$lows nutrient${lows > 1 ? 's' : ''} running low';
      bannerMsg   = 'You\'re making progress — a few more servings will help.';
      bannerIcon  = Icons.info_outline_rounded;
    } else {
      bannerColor = const Color(0xFF6BCB77);
      bannerTitle = 'Great nutritional balance!';
      bannerMsg   = 'You\'re meeting your daily micronutrient targets today.';
      bannerIcon  = Icons.check_circle_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(bannerIcon, color: bannerColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bannerTitle,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: bannerColor)),
                const SizedBox(height: 2),
                Text(bannerMsg,
                    style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Nutrient card ──────────────────────────────────────────────────────────
  Widget _buildNutrientCard(BuildContext context, MicronutrientStatus s, int index) {
    final color = _levelColor(s.level);
    final anim  = CurvedAnimation(
      parent: _animCtrl,
      curve: Interval(index * 0.1, (index * 0.1 + 0.5).clamp(0, 1),
          curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: context.isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                      Text(
                        '${s.intake.toStringAsFixed(s.unit == 'mcg' ? 1 : 0)} / '
                        '${s.goal.toStringAsFixed(0)} ${s.unit}',
                        style: TextStyle(fontSize: 12, color: context.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _levelLabel(s.level),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: s.percent,
                minHeight: 7,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(s.percent * 100).toStringAsFixed(0)}% of daily goal',
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
                Text('${((1 - s.percent) * s.goal).toStringAsFixed(s.unit == 'mcg' ? 1 : 0)} ${s.unit} remaining',
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
              ],
            ),
            if (s.level != DeficiencyLevel.ok) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 14, color: const Color(0xFFFFB347)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(s.tip,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.textMuted,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Weekly bar chart ───────────────────────────────────────────────────────
  Widget _buildWeeklyChart(BuildContext context) {
    if (_weekly.isEmpty) return const SizedBox.shrink();

    const chartColors = [
      Color(0xFF6BCB77),
      Color(0xFF4D96FF),
      Color(0xFFFFB347),
      Color(0xFFFF5252),
    ];
    const labels = ['Iron', 'Calcium', 'B12', 'Vit D'];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7-Day Trends',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          const SizedBox(height: 4),
          Text('Percentage of daily goal met',
              style: TextStyle(fontSize: 12, color: context.textMuted)),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: List.generate(4, (i) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: chartColors[i], shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(labels[i],
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
              ],
            )),
          ),
          const SizedBox(height: 16),
          // Bars
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weekly.map((snap) {
                final values = [
                  snap.ironPct, snap.calciumPct, snap.b12Pct, snap.vitDPct
                ];
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: List.generate(4, (ci) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: AnimatedBuilder(
                              animation: _animCtrl,
                              builder: (_, __) => Container(
                                height: (values[ci] * 20 * _animCtrl.value)
                                    .clamp(2, 20),
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                decoration: BoxDecoration(
                                  color: chartColors[ci],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          )),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(snap.dateLabel,
                          style: TextStyle(
                              fontSize: 10, color: context.textMuted)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
