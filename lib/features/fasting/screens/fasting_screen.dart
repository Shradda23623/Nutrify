import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../services/fasting_service.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen>
    with TickerProviderStateMixin {
  final _service = FastingService();

  FastingSession? _activeSession;
  FastingProtocolInfo _selectedProtocol = fastingProtocols[0];
  int _streak = 0;
  List<FastingSession> _history = [];
  bool _loading = true;

  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  late AnimationController _ringCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final active  = await _service.getActiveSession();
    final streak  = await _service.getStreak();
    final history = await _service.getHistory();
    if (mounted) {
      setState(() {
        _activeSession    = active;
        _streak           = streak;
        _history          = history;
        _loading          = false;
        if (active != null) {
          _elapsed = DateTime.now().difference(active.startTime);
          _startTicker();
        }
      });
      _ringCtrl.forward(from: 0);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSession != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(_activeSession!.startTime));
      }
    });
  }

  Future<void> _startFast() async {
    await _service.startSession(_selectedProtocol.protocol);
    await _load();
  }

  Future<void> _endFast() async {
    _ticker?.cancel();
    final ended = await _service.endSession();
    if (ended != null && mounted) {
      final info = fastingProtocols.firstWhere((p) => p.protocol == ended.protocol);
      final hours = ended.elapsed.inHours;
      showDialog(
        context: context,
        builder: (_) => _FastCompleteDialog(
          completed: ended.completed,
          hours: hours,
          targetHours: info.fastHours,
        ),
      );
    }
    await _load();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
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
                  SliverToBoxAdapter(child: _buildTimerSection(context)),
                  if (_activeSession == null)
                    SliverToBoxAdapter(child: _buildProtocolSelector(context)),
                  SliverToBoxAdapter(child: _buildActionButton(context)),
                  SliverToBoxAdapter(child: _buildStatsRow(context)),
                  if (_history.isNotEmpty)
                    SliverToBoxAdapter(child: _buildHistory(context)),
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
      title: Text('Intermittent Fasting',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textPrimary)),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('$_streak day streak',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Timer ring ─────────────────────────────────────────────────────────────
  Widget _buildTimerSection(BuildContext context) {
    final isActive  = _activeSession != null;
    final info      = isActive
        ? fastingProtocols.firstWhere((p) => p.protocol == _activeSession!.protocol)
        : _selectedProtocol;
    final targetSec = info.fastHours * 3600;
    final progress  = isActive && targetSec > 0
        ? (_elapsed.inSeconds / targetSec).clamp(0.0, 1.0)
        : 0.0;
    final inEatingWindow = progress >= 1.0;

    final Color ringColor = inEatingWindow
        ? const Color(0xFF6BCB77)
        : isActive
            ? const Color(0xFF4D96FF)
            : AppColors.green.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_ringCtrl, _pulseCtrl]),
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow pulse
              if (isActive)
                Container(
                  width: 270 + (_pulseCtrl.value * 20),
                  height: 270 + (_pulseCtrl.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor.withOpacity(0.04 * _pulseCtrl.value),
                  ),
                ),
              // Progress ring
              SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: progress * _ringCtrl.value,
                    color: ringColor,
                    bg: ringColor.withOpacity(0.1),
                  ),
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(info.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  if (isActive) ...[
                    Text(
                      _formatDuration(_elapsed),
                      style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                          letterSpacing: -1),
                    ),
                    Text(
                      inEatingWindow
                          ? 'Eating window!'
                          : 'of ${info.fastHours}h goal',
                      style: TextStyle(
                          fontSize: 13,
                          color: inEatingWindow
                              ? const Color(0xFF6BCB77)
                              : context.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% complete',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ringColor),
                    ),
                  ] else ...[
                    Text(
                      '${info.fastHours}:${info.eatHours.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                          letterSpacing: -1),
                    ),
                    Text('Fast : Eat ratio',
                        style: TextStyle(fontSize: 13, color: context.textMuted)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Protocol selector ──────────────────────────────────────────────────────
  Widget _buildProtocolSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text('Choose Protocol',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: fastingProtocols.length,
            itemBuilder: (_, i) {
              final p        = fastingProtocols[i];
              final selected = p.protocol == _selectedProtocol.protocol;
              return GestureDetector(
                onTap: () => setState(() => _selectedProtocol = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.15)
                        : context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.green
                          : context.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(p.name,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: selected
                                  ? AppColors.green
                                  : context.textPrimary)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(p.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10,
                                color: context.textMuted,
                                height: 1.4)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Action button ──────────────────────────────────────────────────────────
  Widget _buildActionButton(BuildContext context) {
    final isActive = _activeSession != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GestureDetector(
        onTap: isActive ? _endFast : _startFast,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFFFF5252), const Color(0xFFFF7B7B)]
                  : [AppColors.green, const Color(0xFF4BCF5A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (isActive ? Colors.red : AppColors.green)
                    .withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline_rounded,
                color: Colors.black87,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                isActive ? 'End Fast' : 'Start Fasting',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(BuildContext context) {
    final completedSessions = _history.where((s) => s.completed).length;
    final totalHours = _history.fold<int>(
        0, (sum, s) => sum + s.elapsed.inHours);
    final longestH = _history.isEmpty
        ? 0
        : _history.map((s) => s.elapsed.inHours).reduce(math.max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _statBox(context, '🏆', '$completedSessions', 'Completed'),
          const SizedBox(width: 12),
          _statBox(context, '⏱', '${totalHours}h', 'Total Fasted'),
          const SizedBox(width: 12),
          _statBox(context, '📈', '${longestH}h', 'Longest Fast'),
        ],
      ),
    );
  }

  Widget _statBox(BuildContext context, String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary)),
            Text(label,
                style: TextStyle(fontSize: 10, color: context.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── History list ───────────────────────────────────────────────────────────
  Widget _buildHistory(BuildContext context) {
    final recent = _history.take(7).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Fasts',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          const SizedBox(height: 12),
          ...recent.map((s) {
            final info  = fastingProtocols.firstWhere((p) => p.protocol == s.protocol);
            final hours = s.elapsed.inHours;
            final mins  = s.elapsed.inMinutes % 60;
            final date  = '${s.startTime.day}/${s.startTime.month}';
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
                  Text(info.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${info.name} — ${hours}h ${mins}m',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary)),
                        Text(date,
                            style: TextStyle(
                                fontSize: 12, color: context.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.completed
                          ? AppColors.green.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.completed ? 'Done' : 'Partial',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: s.completed
                              ? AppColors.green
                              : Colors.orange),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h  = d.inHours.toString().padLeft(2, '0');
    final m  = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s  = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ── Ring Painter ───────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;
  const _RingPainter({required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    final bgPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Completion dialog ──────────────────────────────────────────────────────
class _FastCompleteDialog extends StatelessWidget {
  final bool completed;
  final int hours;
  final int targetHours;
  const _FastCompleteDialog({
    required this.completed,
    required this.hours,
    required this.targetHours,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        completed ? '🎉 Fast Complete!' : '⏸ Fast Ended Early',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      content: Text(
        completed
            ? 'Amazing work! You fasted for ${hours}h, hitting your ${targetHours}h goal. Your streak grows!'
            : 'You fasted for ${hours}h out of a ${targetHours}h goal. Every minute counts — try again tomorrow!',
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
