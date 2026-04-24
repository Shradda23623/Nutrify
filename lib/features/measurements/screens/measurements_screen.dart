import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/measurement_model.dart';
import '../services/measurement_service.dart';

// ── Metric meta ──────────────────────────────────────────────────────────────

class _MetricMeta {
  final String field;
  final String label;
  final IconData icon;
  final Color color;
  // true = lower is better (green for decrease); false = higher is better
  final bool lowerIsBetter;

  const _MetricMeta({
    required this.field,
    required this.label,
    required this.icon,
    required this.color,
    required this.lowerIsBetter,
  });
}

const _metrics = [
  _MetricMeta(
    field: 'waist',
    label: 'Waist',
    icon: Icons.straighten_rounded,
    color: AppColors.orange,
    lowerIsBetter: true,
  ),
  _MetricMeta(
    field: 'hips',
    label: 'Hips',
    icon: Icons.accessibility_new_rounded,
    color: Color(0xFF9B59B6),
    lowerIsBetter: true,
  ),
  _MetricMeta(
    field: 'chest',
    label: 'Chest',
    icon: Icons.favorite_border_rounded,
    color: AppColors.blue,
    lowerIsBetter: false,
  ),
  _MetricMeta(
    field: 'arms',
    label: 'Arms',
    icon: Icons.fitness_center_rounded,
    color: AppColors.green,
    lowerIsBetter: false,
  ),
  _MetricMeta(
    field: 'thighs',
    label: 'Thighs',
    icon: Icons.directions_walk_rounded,
    color: Colors.teal,
    lowerIsBetter: true,
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  final _service = MeasurementService();
  List<MeasurementEntry> _entries = [];
  bool _loading = true;
  String _selectedChartMetric = 'waist';

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

  double? _fieldValue(MeasurementEntry e, String field) {
    switch (field) {
      case 'waist':
        return e.waist;
      case 'hips':
        return e.hips;
      case 'chest':
        return e.chest;
      case 'arms':
        return e.arms;
      case 'thighs':
        return e.thighs;
      default:
        return null;
    }
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showLogSheet() {
    final waistCtrl = TextEditingController();
    final hipsCtrl = TextEditingController();
    final chestCtrl = TextEditingController();
    final armsCtrl = TextEditingController();
    final thighsCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: ctx.surfaceElevated,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: ctx.mutedBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  'Log Measurements',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: ctx.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill in at least one measurement',
                  style: TextStyle(fontSize: 13, color: ctx.textMuted),
                ),
                const SizedBox(height: 20),

                // Fields
                _measureField(ctx, waistCtrl, 'Waist', AppColors.orange,
                    Icons.straighten_rounded),
                _measureField(ctx, hipsCtrl, 'Hips',
                    const Color(0xFF9B59B6), Icons.accessibility_new_rounded),
                _measureField(ctx, chestCtrl, 'Chest', AppColors.blue,
                    Icons.favorite_border_rounded),
                _measureField(ctx, armsCtrl, 'Arms', AppColors.green,
                    Icons.fitness_center_rounded),
                _measureField(ctx, thighsCtrl, 'Thighs', Colors.teal,
                    Icons.directions_walk_rounded),

                // Note
                const SizedBox(height: 4),
                TextField(
                  controller: noteCtrl,
                  style: TextStyle(color: ctx.textPrimary, fontSize: 14),
                  maxLines: 2,
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
                const SizedBox(height: 24),

                // Save button
                GestureDetector(
                  onTap: () async {
                    final waist = double.tryParse(waistCtrl.text);
                    final hips = double.tryParse(hipsCtrl.text);
                    final chest = double.tryParse(chestCtrl.text);
                    final arms = double.tryParse(armsCtrl.text);
                    final thighs = double.tryParse(thighsCtrl.text);

                    // At least one measurement required
                    if (waist == null &&
                        hips == null &&
                        chest == null &&
                        arms == null &&
                        thighs == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Enter at least one measurement to save.'),
                          backgroundColor: ctx.surface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final entry = MeasurementEntry.create(
                      waist: waist,
                      hips: hips,
                      chest: chest,
                      arms: arms,
                      thighs: thighs,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );

                    await _service.addEntry(entry);
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
                      child: Text(
                        'Save Measurements',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _measureField(BuildContext ctx, TextEditingController ctrl,
      String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: ctx.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: '$label (cm)',
          hintStyle: TextStyle(color: ctx.textHint),
          prefixIcon: Icon(icon, color: color, size: 20),
          suffixText: 'cm',
          suffixStyle: TextStyle(color: ctx.textMuted, fontSize: 13),
          filled: true,
          fillColor: ctx.inputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: ctx.isDark ? ctx.mutedBorder : Colors.transparent),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(
          'Body Measurements',
          style: TextStyle(color: context.textPrimary),
        ),
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: context.textSecondary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _emptyState(context)
              : _buildBody(context),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.straighten_rounded,
                  size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No measurements yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the + button to log your first\nbody measurements and track your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary cards ───────────────────────────────────────────────
          _summaryRow(context),
          const SizedBox(height: 20),

          // ── Chart ───────────────────────────────────────────────────────
          _chartCard(context),

          // ── History label ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              'History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
          ),

          // ── History tiles ───────────────────────────────────────────────
          ..._entries.map((e) => _entryTile(context, e)),
        ],
      ),
    );
  }

  // ── Summary row ─────────────────────────────────────────────────────────────

  Widget _summaryRow(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = _metrics[i];
          final latestVal = _service.latestFieldValue(_entries, m.field);
          final delta = _service.change(_entries, m.field);
          return _summaryCard(context, m, latestVal, delta);
        },
      ),
    );
  }

  Widget _summaryCard(BuildContext context, _MetricMeta m, double? latestVal,
      double? delta) {
    Color? deltaColor;
    String deltaLabel = '';
    if (delta != null) {
      final isGood =
          m.lowerIsBetter ? delta < 0 : delta > 0;
      deltaColor = isGood ? AppColors.green : Colors.redAccent;
      final sign = delta > 0 ? '▲' : '▼';
      deltaLabel = '$sign ${delta.abs().toStringAsFixed(1)}';
    }

    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: m.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: m.color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(m.icon, color: m.color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  m.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                latestVal != null
                    ? '${latestVal.toStringAsFixed(1)}'
                    : '—',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              if (latestVal != null)
                Text(
                  'cm',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textMuted,
                  ),
                ),
              if (delta != null)
                Text(
                  deltaLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: deltaColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chart card ───────────────────────────────────────────────────────────────

  Widget _chartCard(BuildContext context) {
    final meta = _metrics.firstWhere((m) => m.field == _selectedChartMetric);
    final entriesWithField = _entries
        .where((e) => _fieldValue(e, _selectedChartMetric) != null)
        .toList()
        .reversed
        .take(10)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration:
          context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trend Chart',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: context.textPrimary,
                ),
              ),
              Text(
                'Last 10 entries',
                style: TextStyle(fontSize: 11, color: context.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metric selector chips
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _metrics.map((m) {
                final selected = m.field == _selectedChartMetric;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedChartMetric = m.field),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? m.color.withOpacity(0.18)
                          : context.inputFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? m.color.withOpacity(0.6)
                            : context.mutedBorder,
                      ),
                    ),
                    child: Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? m.color : context.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Chart or placeholder
          if (entriesWithField.length >= 2)
            SizedBox(
              height: 180,
              child: LineChart(_buildLineChart(context, entriesWithField, meta)),
            )
          else
            SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded,
                        size: 36, color: context.textHint),
                    const SizedBox(height: 8),
                    Text(
                      'Need at least 2 ${meta.label.toLowerCase()} entries\nto show trend',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: context.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  LineChartData _buildLineChart(BuildContext context,
      List<MeasurementEntry> entries, _MetricMeta meta) {
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(
          e.key.toDouble(), _fieldValue(e.value, meta.field)!);
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) - 3;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 3;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (_) => FlLine(
          color: context.isDark
              ? const Color(0xFF2A2A38)
              : Colors.black.withOpacity(0.05),
          strokeWidth: 1,
        ),
        drawVerticalLine: false,
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (v, _) => Text(
              v.toStringAsFixed(0),
              style: TextStyle(fontSize: 10, color: context.textHint),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= entries.length) {
                return const SizedBox();
              }
              final d = entries[idx].date;
              return Text(
                '${d.day}/${d.month}',
                style: TextStyle(fontSize: 9, color: context.textHint),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: meta.color,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 4,
              color: meta.color,
              strokeWidth: 2,
              strokeColor: context.surface,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: meta.color.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  // ── Entry tile ───────────────────────────────────────────────────────────────

  Widget _entryTile(BuildContext context, MeasurementEntry entry) {
    final day = entry.date.day.toString().padLeft(2, '0');
    final month = entry.date.month.toString().padLeft(2, '0');
    final year = entry.date.year;
    final dateStr = '$day/$month/$year';

    final measurements = <MapEntry<_MetricMeta, double>>[];
    for (final m in _metrics) {
      final v = _fieldValue(entry, m.field);
      if (v != null) measurements.add(MapEntry(m, v));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration:
          context.cardDecoration(radius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.date.day.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
                Text(
                  _monthAbbr(entry.date.month),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Measurements
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: measurements.map((me) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: me.key.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: me.key.color.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(me.key.icon,
                              color: me.key.color, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${me.key.label}: ${me.value.toStringAsFixed(1)} cm',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.note_rounded,
                          size: 13, color: context.textHint),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entry.note!,
                          style: TextStyle(
                              fontSize: 12, color: context.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Delete
          GestureDetector(
            onTap: () async {
              await _service.deleteEntry(entry.id);
              _load();
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Icon(Icons.delete_outline_rounded,
                  color: context.textHint, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
