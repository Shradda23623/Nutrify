import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/water_model.dart';
import '../services/water_service.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen>
    with SingleTickerProviderStateMixin {
  final WaterService _service = WaterService();
  WaterModel? _model;
  List<int> _weekHistory = List.filled(7, 0);
  late AnimationController _waveCtrl;

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.load();
    final history = await _service.getWeeklyHistory(7);
    if (mounted) {
      setState(() {
        _model = data;
        _weekHistory = history;
      });
    }
  }

  Future<void> _addGlasses(int count) async {
    if (_model == null) return;
    setState(() => _model!.intake = (_model!.intake + count).clamp(0, 99));
    await _service.save(_model!);
    final history = await _service.getWeeklyHistory(7);
    if (mounted) setState(() => _weekHistory = history);
  }

  Future<void> _removeGlass() async {
    if (_model == null || _model!.intake == 0) return;
    setState(() => _model!.intake--);
    await _service.save(_model!);
    final history = await _service.getWeeklyHistory(7);
    if (mounted) setState(() => _weekHistory = history);
  }

  Future<void> _showCustomInput() async {
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          decoration: BoxDecoration(
              color: ctx.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: ctx.isDark
                  ? Border.all(color: ctx.cardBorder, width: 1)
                  : null),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: ctx.textHint.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Custom Amount',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ctx.textPrimary)),
              const SizedBox(height: 4),
              Text('Enter the number of glasses to add',
                  style: TextStyle(fontSize: 12, color: ctx.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ctx.textPrimary),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: ctx.textHint),
                  suffixText: 'glasses',
                  suffixStyle: TextStyle(color: ctx.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: ctx.inputFill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: ctx.isDark
                          ? BorderSide(color: ctx.mutedBorder, width: 1)
                          : BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: ctx.isDark
                          ? BorderSide(color: ctx.mutedBorder, width: 1)
                          : BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.blue, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final v = int.tryParse(ctrl.text);
                    Navigator.pop(ctx, v);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Add',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result > 0) _addGlasses(result);
  }

  Future<void> _showGoalEditor() async {
    if (_model == null) return;
    final ctrl = TextEditingController(text: '${_model!.goal}');
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          decoration: BoxDecoration(
              color: ctx.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: ctx.isDark
                  ? Border.all(color: ctx.cardBorder, width: 1)
                  : null),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: ctx.textHint.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Daily Water Goal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ctx.textPrimary)),
              const SizedBox(height: 4),
              Text('How many glasses per day?',
                  style: TextStyle(fontSize: 12, color: ctx.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ctx.textPrimary),
                decoration: InputDecoration(
                  hintText: '8',
                  hintStyle: TextStyle(color: ctx.textHint),
                  suffixText: 'glasses',
                  suffixStyle: TextStyle(color: ctx.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: ctx.inputFill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: ctx.isDark
                          ? BorderSide(color: ctx.mutedBorder, width: 1)
                          : BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: ctx.isDark
                          ? BorderSide(color: ctx.mutedBorder, width: 1)
                          : BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.blue, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final v = int.tryParse(ctrl.text);
                    Navigator.pop(ctx, v);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Set Goal',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result > 0) {
      setState(() => _model!.goal = result);
      await _service.save(_model!);
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) {
      return Scaffold(
        backgroundColor: context.pageBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final m = _model!;
    final progress = (m.intake / m.goal).clamp(0.0, 1.0);
    final mlDrunk = (m.intake * 250).toInt();
    final mlGoal = (m.goal * 250).toInt();
    final pct = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text('Water Tracker',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
        actions: [
          GestureDetector(
            onTap: _showGoalEditor,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(context.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.water_drop_rounded, size: 14, color: AppColors.blue),
                  const SizedBox(width: 4),
                  Text('Goal: ${m.goal}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WaveCard(
                intake: m.intake,
                goal: m.goal,
                progress: progress,
                pct: pct,
                mlDrunk: mlDrunk,
                mlGoal: mlGoal,
                waveCtrl: _waveCtrl,
                onRemove: _removeGlass,
              ),
              const SizedBox(height: 20),
              _sectionHeader('Add Water', Icons.add_circle_rounded, AppColors.blue),
              const SizedBox(height: 12),
              _quickAddRow(),
              const SizedBox(height: 24),
              _statsRow(m, mlDrunk, mlGoal, pct),
              const SizedBox(height: 24),
              _sectionHeader('This Week', Icons.bar_chart_rounded, AppColors.blue),
              const SizedBox(height: 12),
              _weeklyCard(m.goal),
              const SizedBox(height: 24),
              _tipsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAddRow() {
    final options = [
      (1, '1 Glass', '250 ml'),
      (2, '2 Glasses', '500 ml'),
      (3, '3 Glasses', '750 ml'),
    ];
    return Column(
      children: [
        Row(
          children: options.map((o) {
            return Expanded(
              child: GestureDetector(
                onTap: () => _addGlasses(o.$1),
                child: Container(
                  margin: EdgeInsets.only(right: o.$1 == 3 ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: context.isDark
                            ? context.cardBorder
                            : AppColors.blue.withOpacity(0.2),
                        width: 1),
                    boxShadow: context.isDark
                        ? null
                        : [
                            BoxShadow(
                                color: AppColors.blue.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.water_drop_rounded, color: AppColors.blue, size: 22),
                      const SizedBox(height: 6),
                      Text(o.$2,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                      Text(o.$3,
                          style: TextStyle(fontSize: 10, color: context.textHint)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _showCustomInput,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(context.isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.blue.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: AppColors.blue, size: 18),
                const SizedBox(width: 6),
                Text('Custom Amount',
                    style: TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statsRow(WaterModel m, int mlDrunk, int mlGoal, int pct) {
    return Row(
      children: [
        Expanded(
            child: _statCard(
                icon: Icons.water_drop_rounded,
                color: AppColors.blue,
                value: '$mlDrunk ml',
                label: 'Consumed')),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                icon: Icons.flag_rounded,
                color: AppColors.green,
                value: '$mlGoal ml',
                label: 'Goal')),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                icon: Icons.percent_rounded,
                color: AppColors.orange,
                value: '$pct%',
                label: 'Progress')),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: context.cardDecoration(radius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: context.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: context.textHint)),
        ],
      ),
    );
  }

  Widget _weeklyCard(int goal) {
    final todayIdx = DateTime.now().weekday - 1;
    final maxY = _weekHistory.fold(0, (a, b) => a > b ? a : b).toDouble();
    final chartMax = math.max(maxY, goal.toDouble()) + 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Intake',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.textSecondary)),
                    const SizedBox(height: 2),
                    Text('Goal: $goal glasses/day',
                        style: TextStyle(fontSize: 11, color: context.textHint)),
                  ],
                ),
              ),
              _legendDot(AppColors.blue, 'Intake'),
              const SizedBox(width: 12),
              _legendDot(AppColors.green.withOpacity(0.5), 'Goal'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: goal.toDouble(),
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: v == goal
                        ? AppColors.green.withOpacity(0.25)
                        : Colors.transparent,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        final isToday = idx == todayIdx;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _weekDays[idx],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                              color: isToday ? AppColors.blue : context.textHint,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  final val = _weekHistory[i].toDouble();
                  final isToday = i == todayIdx;
                  final metGoal = val >= goal;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val == 0 ? 0.15 : val,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        color: metGoal
                            ? AppColors.green
                            : isToday
                                ? AppColors.blue
                                : AppColors.blue.withOpacity(0.35),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A1A2E),
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()} glasses',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: context.textMuted)),
      ],
    );
  }

  Widget _tipsCard() {
    final tips = [
      (Icons.wb_sunny_rounded, Colors.amber, 'Start your day with 2 glasses of warm water'),
      (Icons.restaurant_rounded, Colors.deepOrange, 'Drink a glass before each meal'),
      (Icons.fitness_center_rounded, AppColors.green, 'Add 1–2 extra glasses on workout days'),
      (Icons.bedtime_rounded, Colors.indigo, 'Avoid large amounts right before sleep'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(context.isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.blue),
              ),
              const SizedBox(width: 10),
              Text('Hydration Tips',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: t.$2.withOpacity(context.isDark ? 0.15 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(t.$1, size: 15, color: t.$2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.$3,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: color.withOpacity(context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
      ],
    );
  }
}

// ── Wave Card Widget ───────────────────────────────────────────────────────────
class _WaveCard extends StatelessWidget {
  final int intake;
  final int goal;
  final double progress;
  final int pct;
  final int mlDrunk;
  final int mlGoal;
  final AnimationController waveCtrl;
  final VoidCallback onRemove;

  const _WaveCard({
    required this.intake,
    required this.goal,
    required this.progress,
    required this.pct,
    required this.mlDrunk,
    required this.mlGoal,
    required this.waveCtrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A2980).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AnimatedBuilder(
                animation: waveCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _WavePainter(
                    progress: progress,
                    animValue: waveCtrl.value,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$pct%',
                            style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        Text('of daily goal',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$intake / $goal',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('glasses',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7))),
                        const SizedBox(height: 6),
                        Text('$mlDrunk / $mlGoal ml',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.55))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(goal, (i) {
                    final filled = i < intake;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: filled
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        size: 14,
                        color: filled
                            ? AppColors.blue
                            : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.undo_rounded,
                            size: 16, color: Colors.white.withOpacity(0.85)),
                        const SizedBox(width: 6),
                        Text('Remove Last',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double animValue;

  _WavePainter({required this.progress, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final fillLevel = size.height * (1 - progress.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, fillLevel);
    for (double x = 0; x <= size.width; x++) {
      final y = fillLevel +
          math.sin((x / size.width * 2 * math.pi) +
                  (animValue * 2 * math.pi)) *
              8;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, fillLevel + 4);
    for (double x = 0; x <= size.width; x++) {
      final y = fillLevel +
          4 +
          math.sin((x / size.width * 2 * math.pi) +
                  (animValue * 2 * math.pi) +
                  math.pi) *
              10;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.animValue != animValue;
}
