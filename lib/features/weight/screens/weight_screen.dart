import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/weight_model.dart';
import '../services/weight_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _service = WeightService();
  List<WeightEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _service.loadAll();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.surfaceElevated,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log Weight',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ctx.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(color: ctx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Weight in kg (e.g. 68.5)',
                  hintStyle: TextStyle(color: ctx.textHint),
                  prefixIcon: const Icon(Icons.monitor_weight_outlined,
                      color: Color(0xFF6BCB77)),
                  filled: true,
                  fillColor: ctx.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: ctx.isDark
                            ? ctx.mutedBorder
                            : Colors.transparent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                style: TextStyle(color: ctx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Note (optional)',
                  hintStyle: TextStyle(color: ctx.textHint),
                  prefixIcon: Icon(Icons.note_rounded,
                      color: ctx.textSecondary, size: 20),
                  filled: true,
                  fillColor: ctx.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: ctx.isDark
                            ? ctx.mutedBorder
                            : Colors.transparent),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final kg = double.tryParse(ctrl.text);
                  if (kg == null || kg <= 0) return;
                  await _service.addEntry(WeightEntry(
                    kg: kg,
                    date: DateTime.now(),
                    note: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Save Entry',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = _service.latestEntry(_entries);
    final change = _service.weightChange(_entries);

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('Weight Tracker',
            style: TextStyle(color: context.textPrimary)),
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: context.textSecondary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          context,
                          Icons.monitor_weight_rounded,
                          'Current',
                          latest != null
                              ? '${latest.kg.toStringAsFixed(1)} kg'
                              : '—',
                          Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          context,
                          change == null
                              ? Icons.remove_rounded
                              : change < 0
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                          'Change',
                          change != null
                              ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg'
                              : '—',
                          change == null
                              ? Colors.grey
                              : change < 0
                                  ? AppColors.green
                                  : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Line chart
                  if (_entries.length >= 2)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: context.cardDecoration(
                          radius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weight Trend',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: context.textPrimary)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: LineChart(_buildChart(context)),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // History list
                  Text('History',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  const SizedBox(height: 12),

                  if (_entries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.monitor_weight_rounded,
                                size: 48, color: context.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'No weight logged yet.\nTap + to add your first entry!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: context.textMuted, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...(_entries.reversed.toList().asMap().entries.map(
                          (e) => _entryTile(
                              context, e.value, _entries.length - 1 - e.key),
                        )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  LineChartData _buildChart(BuildContext context) {
    final spots = _entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.kg);
    }).toList();

    final minY =
        (_entries.map((e) => e.kg).reduce((a, b) => a < b ? a : b) - 2);
    final maxY =
        (_entries.map((e) => e.kg).reduce((a, b) => a > b ? a : b) + 2);

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (_) => FlLine(
            color: context.isDark
                ? const Color(0xFF2A2A38)
                : Colors.black.withOpacity(0.05),
            strokeWidth: 1),
        drawVerticalLine: false,
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 10, color: context.textHint)),
            reservedSize: 30,
          ),
        ),
        bottomTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.teal,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: Colors.teal,
                strokeWidth: 2,
                strokeColor: context.surface),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.teal.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
                      fontSize: 18,
                      color: context.textPrimary)),
              Text(label,
                  style:
                      TextStyle(fontSize: 11, color: context.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _entryTile(
      BuildContext context, WeightEntry entry, int index) {
    final dateStr =
        '${entry.date.day}/${entry.date.month}/${entry.date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration(radius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
                child: Icon(Icons.monitor_weight_rounded,
                    color: Colors.teal, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.kg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: context.textPrimary)),
                Text(
                    entry.note != null && entry.note!.isNotEmpty
                        ? '$dateStr · ${entry.note}'
                        : dateStr,
                    style: TextStyle(
                        fontSize: 12, color: context.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await _service.deleteEntry(index);
              _load();
            },
            child: Icon(Icons.delete_outline_rounded,
                color: context.textHint, size: 20),
          ),
        ],
      ),
    );
  }
}
