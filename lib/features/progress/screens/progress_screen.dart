import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../../../core/services/streak_service.dart';
import '../../calories/services/calorie_service.dart';
import '../../water/services/water_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<double> _calorieHistory = List.filled(7, 0);
  List<int> _waterHistory = List.filled(7, 0);
  int _streak = 0;
  int _bestStreak = 0;
  bool _loading = true;

  final _calService = CalorieService();
  final _waterService = WaterService();
  final _streakService = StreakService();

  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final cals = await _calService.getWeeklyHistory(7);
    final water = await _waterService.getWeeklyHistory(7);
    final streak = await _streakService.getCurrentStreak();
    final best = await _streakService.getBestStreak();

    if (mounted) {
      setState(() {
        _calorieHistory = cals;
        _waterHistory = water;
        _streak = streak;
        _bestStreak = best;
        _loading = false;
      });
    }
  }

  List<String> _last7DayLabels() {
    return List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return _days[d.weekday - 1];
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('Progress',
            style: TextStyle(color: context.textPrimary)),
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.green,
          labelColor: context.textPrimary,
          unselectedLabelColor: context.textMuted,
          tabs: const [
            Tab(text: 'Calories'),
            Tab(text: 'Water'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Streak cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                          child: _streakCard(
                              context,
                              Icons.local_fire_department_rounded,
                              'Current Streak',
                              '$_streak days',
                              AppColors.orange)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _streakCard(
                              context,
                              Icons.emoji_events_rounded,
                              'Best Streak',
                              '$_bestStreak days',
                              AppColors.yellow)),
                    ],
                  ),
                ),

                // Charts
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _CaloriesTab(
                          history: _calorieHistory,
                          labels: _last7DayLabels()),
                      _WaterTab(
                          history: _waterHistory,
                          labels: _last7DayLabels()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _streakCard(
      BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: context.textPrimary)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: context.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Calories Tab ─────────────────────────────────────────────────────────────

class _CaloriesTab extends StatelessWidget {
  final List<double> history;
  final List<String> labels;
  static const double _goal = 2000;

  const _CaloriesTab({required this.history, required this.labels});

  @override
  Widget build(BuildContext context) {
    final avg = history.isEmpty
        ? 0
        : history.reduce((a, b) => a + b) / history.length;
    final total = history.reduce((a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        children: [
          // Summary row
          Row(
            children: [
              Expanded(
                  child: _stat(context, 'Total',
                      '${total.toStringAsFixed(0)} kcal', AppColors.orange)),
              const SizedBox(width: 10),
              Expanded(
                  child: _stat(context, 'Daily Avg',
                      '${avg.toStringAsFixed(0)} kcal', AppColors.green)),
              const SizedBox(width: 10),
              Expanded(
                  child: _stat(context, 'Goal', '$_goal kcal', AppColors.blue)),
            ],
          ),
          const SizedBox(height: 20),

          // Bar chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: context.cardDecoration(
                radius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calories — Last 7 Days',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.textPrimary)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: 2800,
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: context.isDark
                              ? const Color(0xFF2A2A38)
                              : Colors.black.withOpacity(0.06),
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 700,
                            getTitlesWidget: (v, _) => Text(
                              '${(v / 1000).toStringAsFixed(1)}k',
                              style: TextStyle(
                                  fontSize: 10, color: context.textHint),
                            ),
                            reservedSize: 32,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox();
                              }
                              return Text(labels[i],
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.textMuted));
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: List.generate(
                        history.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: history[i],
                              color: history[i] >= _goal
                                  ? AppColors.green
                                  : AppColors.orange,
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 2800,
                                color: context.isDark
                                    ? const Color(0xFF242433)
                                    : Colors.black.withOpacity(0.04),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _legend(AppColors.green, 'Goal met', context),
                    const SizedBox(width: 16),
                    _legend(AppColors.orange, 'Below goal', context),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Day-by-day list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: context.cardDecoration(
                radius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day Breakdown',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.textPrimary)),
                const SizedBox(height: 12),
                ...List.generate(history.length, (i) {
                  final pct = (history[i] / _goal).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(labels[i],
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary)),
                            Text(
                                '${history[i].toStringAsFixed(0)} kcal',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: context.isDark
                                ? const Color(0xFF242433)
                                : Colors.black.withOpacity(0.06),
                            valueColor: AlwaysStoppedAnimation(
                                pct >= 1.0
                                    ? AppColors.green
                                    : AppColors.orange),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: context.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 11, color: context.textMuted)),
      ],
    );
  }
}

// ── Water Tab ────────────────────────────────────────────────────────────────

class _WaterTab extends StatelessWidget {
  final List<int> history;
  final List<String> labels;
  static const int _goal = 8;

  const _WaterTab({required this.history, required this.labels});

  @override
  Widget build(BuildContext context) {
    final avg = history.isEmpty
        ? 0
        : history.reduce((a, b) => a + b) / history.length;
    final total = history.reduce((a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _stat(context, 'Total', '$total glasses',
                      AppColors.blue)),
              const SizedBox(width: 10),
              Expanded(
                  child: _stat(context, 'Daily Avg',
                      '${avg.toStringAsFixed(1)} glasses', AppColors.green)),
              const SizedBox(width: 10),
              Expanded(
                  child: _stat(context, 'Goal', '$_goal glasses',
                      AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: context.cardDecoration(
                radius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Water Intake — Last 7 Days',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.textPrimary)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: 12,
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: context.isDark
                              ? const Color(0xFF2A2A38)
                              : Colors.black.withOpacity(0.06),
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 3,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}',
                              style: TextStyle(
                                  fontSize: 10, color: context.textHint),
                            ),
                            reservedSize: 24,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox();
                              }
                              return Text(labels[i],
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.textMuted));
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: List.generate(
                        history.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: history[i].toDouble(),
                              color: history[i] >= _goal
                                  ? AppColors.blue
                                  : AppColors.blue.withOpacity(0.4),
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 12,
                                color: context.isDark
                                    ? const Color(0xFF242433)
                                    : Colors.black.withOpacity(0.04),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _stat(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: context.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: context.textMuted)),
        ],
      ),
    );
  }
}
