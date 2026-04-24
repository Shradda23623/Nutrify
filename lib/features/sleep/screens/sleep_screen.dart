import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../models/sleep_model.dart';
import '../services/sleep_service.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final SleepService _service = SleepService();
  List<SleepEntry> _entries = [];
  Map<String, double> _weekly = {'hours': 0, 'quality': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _service.getEntries();
    final weekly  = await _service.getWeeklyAverage();
    if (mounted) {
      setState(() {
        _entries = entries;
        _weekly  = weekly;
        _loading = false;
      });
    }
  }

  // ── Today's sleep (most recent entry from last night) ─────────────────────
  SleepEntry? get _todayEntry {
    if (_entries.isEmpty) return null;
    final e = _entries.first;
    final diff = DateTime.now().difference(e.wakeTime).inHours;
    return diff < 24 ? e : null;
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSleepSheet(onSaved: () {
        Navigator.pop(context);
        _load();
      }, service: _service),
    );
  }

  Future<void> _delete(int index) async {
    await _service.deleteEntry(index);
    _load();
  }

  String _formatDuration(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $suffix';
  }

  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  Color _qualityColor(int q) {
    if (q <= 1) return Colors.redAccent;
    if (q <= 2) return AppColors.orange;
    if (q <= 3) return AppColors.yellow;
    if (q <= 4) return AppColors.green;
    return const Color(0xFF4D96FF);
  }

  String _qualityLabel(int q) {
    switch (q) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Great';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  Color _durationColor(double h) {
    if (h < 5) return Colors.redAccent;
    if (h < 7) return AppColors.orange;
    if (h <= 9) return AppColors.green;
    return AppColors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Sleep Tracker',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
        actions: [
          GestureDetector(
            onTap: _showAddSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF7986CB).withOpacity(context.isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Color(0xFF7986CB)),
                  SizedBox(width: 4),
                  Text('Log Sleep',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7986CB))),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF7986CB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildWeeklyCard(),
                    const SizedBox(height: 24),
                    if (_entries.isNotEmpty) ...[
                      _sectionLabel('Sleep History'),
                      const SizedBox(height: 12),
                      ..._entries.asMap().entries.map((e) =>
                          _buildEntryTile(e.value, e.key)),
                    ] else
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Summary hero card ──────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final today = _todayEntry;
    final hours = today?.durationHours ?? 0;
    final quality = today?.quality ?? 0;
    final dColor = hours == 0 ? context.textHint : _durationColor(hours);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A35), Color(0xFF2D2B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7986CB).withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF7986CB).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bedtime_rounded,
                    color: Color(0xFF9FA8DA), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Night',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                          fontWeight: FontWeight.w500)),
                  Text(
                    today != null ? _formatDate(today.wakeTime) : 'No data yet',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              if (today != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _qualityColor(quality).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_qualityLabel(quality),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _qualityColor(quality))),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      today != null ? _formatDuration(hours) : '--',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: dColor,
                          letterSpacing: -1),
                    ),
                    const Text('duration',
                        style: TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white12),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => Icon(
                        i < (today?.quality ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 18,
                        color: i < (today?.quality ?? 0)
                            ? AppColors.yellow
                            : Colors.white24,
                      )),
                    ),
                    const SizedBox(height: 4),
                    const Text('quality',
                        style: TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              if (today != null) ...[
                Container(width: 1, height: 48, color: Colors.white12),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _formatTime(today.bedtime),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70),
                      ),
                      const Text('bedtime',
                          style: TextStyle(fontSize: 10, color: Colors.white38)),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(today.wakeTime),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70),
                      ),
                      const Text('wake up',
                          style: TextStyle(fontSize: 10, color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (today == null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showAddSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7986CB).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF7986CB).withOpacity(0.3), width: 1),
                ),
                child: const Text('+ Log tonight\'s sleep',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9FA8DA))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 7-day averages card ────────────────────────────────────────────────────

  Widget _buildWeeklyCard() {
    final avgHours   = _weekly['hours'] ?? 0;
    final avgQuality = _weekly['quality'] ?? 0;
    final recHours   = 8.0;
    final pct        = (avgHours / recHours).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded,
                  size: 16, color: const Color(0xFF7986CB)),
              const SizedBox(width: 8),
              Text('7-Day Average',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _weekStat(
                  Icons.access_time_rounded,
                  'Avg Sleep',
                  avgHours > 0 ? _formatDuration(avgHours) : '--',
                  _durationColor(avgHours),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _weekStat(
                  Icons.star_rounded,
                  'Avg Quality',
                  avgQuality > 0
                      ? '${avgQuality.toStringAsFixed(1)} / 5'
                      : '--',
                  _qualityColor(avgQuality.round()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _weekStat(
                  Icons.hotel_rounded,
                  'Vs Ideal',
                  avgHours > 0
                      ? '${((pct - 1) * 100).toInt()}%'
                      : '--',
                  pct >= 1.0
                      ? AppColors.green
                      : pct >= 0.75
                          ? AppColors.orange
                          : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Target: 8h / night',
              style: TextStyle(fontSize: 11, color: context.textHint)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFF7986CB).withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(
                pct >= 1.0 ? AppColors.green : const Color(0xFF7986CB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
        Text(label,
            style: TextStyle(fontSize: 10, color: context.textMuted)),
      ],
    );
  }

  // ── History list ───────────────────────────────────────────────────────────

  Widget _buildEntryTile(SleepEntry e, int index) {
    final qc = _qualityColor(e.quality);
    return Dismissible(
      key: Key('sleep_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) => _delete(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(radius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: qc.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bedtime_rounded, color: qc, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(e.bedtime),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatTime(e.bedtime)} → ${_formatTime(e.wakeTime)}',
                    style: TextStyle(fontSize: 11, color: context.textMuted),
                  ),
                  if (e.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(e.notes,
                        style: TextStyle(fontSize: 11, color: context.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDuration(e.durationHours),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _durationColor(e.durationHours))),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < e.quality ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 12,
                    color: i < e.quality ? AppColors.yellow : context.textHint,
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(Icons.bedtime_outlined, size: 52, color: context.textHint),
          const SizedBox(height: 16),
          Text('No sleep logged yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap "Log Sleep" to start tracking\nyour sleep patterns',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _showAddSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF7986CB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Log Sleep',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3),
      );
}

// ── Add Sleep Bottom Sheet ─────────────────────────────────────────────────

class _AddSleepSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final SleepService service;

  const _AddSleepSheet({required this.onSaved, required this.service});

  @override
  State<_AddSleepSheet> createState() => _AddSleepSheetState();
}

class _AddSleepSheetState extends State<_AddSleepSheet> {
  TimeOfDay _bedtime  = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  int _quality = 3;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  // Assume bedtime is previous night if it's after noon
  DateTime _bedtimeDateTime() {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day, _bedtime.hour, _bedtime.minute);
    // If bedtime hour is >= 12 (evening), assume yesterday
    if (_bedtime.hour >= 12 && _wakeTime.hour < 12) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  DateTime _wakeTimeDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
  }

  double get _durationHours {
    final bed  = _bedtimeDateTime();
    final wake = _wakeTimeDateTime();
    final diff = wake.difference(bed).inMinutes;
    return (diff < 0 ? diff + 1440 : diff) / 60.0;
  }

  Future<void> _pickTime(bool isBed) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBed ? _bedtime : _wakeTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF7986CB),
            surface: const Color(0xFF1E1E28),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isBed) {
          _bedtime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final entry = SleepEntry(
      bedtime: _bedtimeDateTime(),
      wakeTime: _wakeTimeDateTime(),
      quality: _quality,
      notes: _notesCtrl.text.trim(),
    );
    await widget.service.addEntry(entry);
    widget.onSaved();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $suffix';
  }

  String _formatDur(double h) {
    final hours = h.floor();
    final mins  = ((h - hours) * 60).round();
    return '${hours}h ${mins}m';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dur = _durationHours;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: context.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7986CB).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bedtime_rounded,
                      color: Color(0xFF7986CB), size: 18),
                ),
                const SizedBox(width: 12),
                Text('Log Sleep',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary)),
              ],
            ),
            const SizedBox(height: 24),

            // Time pickers
            Row(
              children: [
                Expanded(child: _timeTile('Bedtime', _bedtime, true)),
                const SizedBox(width: 12),
                Expanded(child: _timeTile('Wake Time', _wakeTime, false)),
              ],
            ),
            const SizedBox(height: 12),

            // Duration display
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 16, color: const Color(0xFF7986CB)),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${dur >= 0 ? _formatDur(dur) : "Invalid"}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quality
            Text('Sleep Quality',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final q = i + 1;
                final selected = _quality >= q;
                return GestureDetector(
                  onTap: () => setState(() => _quality = q),
                  child: Column(
                    children: [
                      Icon(
                        selected ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 36,
                        color: selected ? AppColors.yellow : context.textHint,
                      ),
                      Text(
                        ['Poor', 'Fair', 'Good', 'Great', 'Excellent'][i],
                        style: TextStyle(
                            fontSize: 9,
                            color: selected ? AppColors.yellow : context.textHint),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Notes
            TextField(
              controller: _notesCtrl,
              style: TextStyle(fontSize: 14, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: TextStyle(fontSize: 13, color: context.textHint),
                prefixIcon: Icon(Icons.notes_rounded,
                    size: 18, color: context.textMuted),
                filled: true,
                fillColor: context.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF7986CB), width: 1.5)),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7986CB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Sleep Log',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(String label, TimeOfDay time, bool isBed) {
    return GestureDetector(
      onTap: () => _pickTime(isBed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF7986CB).withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.textHint)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isBed ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  size: 14,
                  color: isBed
                      ? const Color(0xFF7986CB)
                      : AppColors.yellow,
                ),
                const SizedBox(width: 6),
                Text(_formatTime(time),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
