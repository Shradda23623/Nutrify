import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/n_theme.dart';
import '../services/step_service.dart';
import '../widgets/step_card.dart';

class StepScreen extends StatefulWidget {
  const StepScreen({super.key});

  @override
  State<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  final StepService _service = StepService();

  int _steps = 0;
  int _goal = 10000;
  List<_DayData> _weeklyData = [];

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadGoal();
    _loadWeeklyHistory();
    _service.getStepStream().listen((event) {
      if (!mounted) return;
      setState(() => _steps = event.steps);
      _saveToday(event.steps);
    });
  }

  Future<void> _showGoalEditor() async {
    final ctrl = TextEditingController(text: '$_goal');
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
              Text('Daily Step Goal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ctx.textPrimary)),
              const SizedBox(height: 4),
              Text('How many steps do you want to hit each day?',
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
                  hintText: '10000',
                  hintStyle: TextStyle(color: ctx.textHint),
                  suffixText: 'steps',
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
                      borderSide: BorderSide(color: AppColors.green, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [5000, 7500, 10000, 12000, 15000].map((v) =>
                  GestureDetector(
                    onTap: () => ctrl.text = '$v',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(
                            ctx.isDark ? 0.15 : 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.green.withOpacity(0.25)),
                      ),
                      child: Text(
                        v >= 1000 ? '${v ~/ 1000}k' : '$v',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green),
                      ),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
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
      await UserService().updateField('dailyStepGoal', result);
      if (mounted) setState(() => _goal = result);
    }
  }

  Future<void> _loadGoal() async {
    final user = await UserService().load();
    if (mounted) setState(() => _goal = user.dailyStepGoal);
  }

  Future<void> _loadWeeklyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final List<_DayData> data = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = _dayKey(day);
      final steps = prefs.getInt(key) ?? 0;
      final weekdayLabel = _weekDays[day.weekday - 1];
      data.add(_DayData(label: weekdayLabel, steps: steps, isToday: i == 0));
    }
    if (mounted) setState(() => _weeklyData = data);
  }

  Future<void> _saveToday(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey(DateTime.now());
    await prefs.setInt(key, steps);
  }

  String _dayKey(DateTime d) =>
      'steps_${d.year}_${d.month.toString().padLeft(2, '0')}_${d.day.toString().padLeft(2, '0')}';

  int get _weeklyTotal => _weeklyData.fold(0, (sum, d) => sum + d.steps);
  double get _weeklyAvg =>
      _weeklyData.isEmpty ? 0 : _weeklyTotal / _weeklyData.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Step Tracker',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimary),
        ),
        actions: [
          GestureDetector(
            onTap: _showGoalEditor,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green
                    .withOpacity(context.isDark ? 0.18 : 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, size: 14, color: AppColors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Goal: ${_goal >= 1000 ? '${(_goal / 1000).toStringAsFixed(0)}k' : '$_goal'}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.edit_rounded,
                      size: 10, color: AppColors.green.withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepCard(steps: _steps, goal: _goal),
            const SizedBox(height: 24),
            _sectionHeader(
                icon: Icons.bar_chart_rounded,
                label: 'Weekly History',
                color: AppColors.blue),
            const SizedBox(height: 12),
            _weeklyHistoryCard(),
            const SizedBox(height: 24),
            _sectionHeader(
                icon: Icons.insights_rounded,
                label: 'This Week',
                color: AppColors.orange),
            const SizedBox(height: 12),
            _weeklySummaryRow(),
            const SizedBox(height: 24),
            _tipsCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(context.isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
      ],
    );
  }

  Widget _weeklyHistoryCard() {
    if (_weeklyData.isEmpty) {
      return Container(
        height: 140,
        decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 36, color: context.textHint),
              const SizedBox(height: 8),
              Text('No history yet',
                  style: TextStyle(color: context.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final maxSteps =
        _weeklyData.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxSteps > 0 ? maxSteps.toDouble() : _goal.toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyData.map((day) {
                final barHeight =
                    day.steps > 0 ? (day.steps / effectiveMax) * 90 : 4.0;
                final metGoal = day.steps >= _goal;
                final barColor = day.isToday
                    ? AppColors.blue
                    : metGoal
                        ? AppColors.green
                        : AppColors.primary.withOpacity(0.6);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.isToday && day.steps > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              day.steps >= 1000
                                  ? '${(day.steps / 1000).toStringAsFixed(1)}k'
                                  : '${day.steps}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: barHeight.clamp(4.0, 90.0),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: day.isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: day.isToday
                                ? AppColors.blue
                                : context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.blue, 'Today'),
              const SizedBox(width: 12),
              _legendDot(AppColors.green, 'Goal met'),
              const SizedBox(width: 12),
              _legendDot(AppColors.primary, 'In progress'),
            ],
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

  Widget _weeklySummaryRow() {
    final daysActive = _weeklyData.where((d) => d.steps > 0).length;
    return Row(
      children: [
        _summaryCard(
            icon: Icons.directions_walk_rounded,
            label: 'Total Steps',
            value: _weeklyTotal >= 1000
                ? '${(_weeklyTotal / 1000).toStringAsFixed(1)}k'
                : '$_weeklyTotal',
            color: AppColors.blue),
        const SizedBox(width: 12),
        _summaryCard(
            icon: Icons.show_chart_rounded,
            label: 'Daily Avg',
            value: _weeklyAvg >= 1000
                ? '${(_weeklyAvg / 1000).toStringAsFixed(1)}k'
                : _weeklyAvg.toStringAsFixed(0),
            color: AppColors.orange),
        const SizedBox(width: 12),
        _summaryCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Active Days',
            value: '$daysActive/7',
            color: AppColors.green),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: context.cardDecoration(radius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(context.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: context.textHint),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _tipsCard() {
    final tips = [
      (Icons.directions_walk_rounded, AppColors.blue,
          'Take the stairs instead of the lift'),
      (Icons.directions_walk_rounded, AppColors.green,
          'Park further away to add extra steps'),
      (Icons.timer_outlined, AppColors.orange, 'Walk for 5 minutes every hour'),
      (Icons.lunch_dining_rounded, AppColors.green,
          'Walk after meals to boost metabolism'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(context.isDark ? 0.18 : 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    size: 18, color: Colors.amber),
              ),
              const SizedBox(width: 10),
              Text('Tips to Hit Your Goal',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.asMap().entries.map((e) {
            final isLast = e.key == tips.length - 1;
            final tip = e.value;
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: tip.$2.withOpacity(context.isDark ? 0.15 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(tip.$1, size: 16, color: tip.$2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(tip.$3,
                          style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
                              height: 1.3)),
                    ),
                  ],
                ),
                if (!isLast)
                  Divider(
                      height: 20,
                      color: context.divider,
                      indent: 42),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DayData {
  final String label;
  final int steps;
  final bool isToday;
  const _DayData(
      {required this.label, required this.steps, required this.isToday});
}
