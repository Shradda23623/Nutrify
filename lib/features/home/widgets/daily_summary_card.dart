import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/progress_ring.dart';

class DailySummaryCard extends StatelessWidget {
  final int caloriesConsumed;
  final int caloriesGoal;
  final int waterGlasses;
  final int waterGoal;
  final int steps;
  final int stepsGoal;
  final String dateLabel;
  final VoidCallback? onCalTap;
  final VoidCallback? onWaterTap;
  final VoidCallback? onStepsTap;

  const DailySummaryCard({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesGoal,
    required this.waterGlasses,
    required this.waterGoal,
    required this.steps,
    required this.stepsGoal,
    this.dateLabel = '',
    this.onCalTap,
    this.onWaterTap,
    this.onStepsTap,
  });

  int get _calPct  => caloriesGoal  > 0 ? ((caloriesConsumed / caloriesGoal)  * 100).toInt().clamp(0, 999) : 0;
  int get _watPct  => waterGoal     > 0 ? ((waterGlasses     / waterGoal)     * 100).toInt().clamp(0, 100) : 0;
  int get _stpPct  => stepsGoal     > 0 ? ((steps            / stepsGoal)     * 100).toInt().clamp(0, 100) : 0;

  String _statusLabel() {
    final goalsHit = [_calPct >= 100, _watPct >= 100, _stpPct >= 100].where((b) => b).length;
    if (goalsHit == 3) return 'All goals met 🎉';
    if (goalsHit == 2) return '2 of 3 goals reached';
    if (goalsHit == 1) return '1 of 3 goals reached';
    final avg = (_calPct + _watPct + _stpPct) ~/ 3;
    if (avg >= 60) return 'Great progress';
    if (avg >= 30) return 'In progress';
    return 'Let\'s get started';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.40),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: title + date badge ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Progress",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              if (dateLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.10),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Three rings ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ringTile(
                value: caloriesGoal > 0
                    ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0)
                    : 0,
                label: 'Calories',
                primary: caloriesConsumed >= 1000
                    ? '${(caloriesConsumed / 1000).toStringAsFixed(1)}k'
                    : '$caloriesConsumed',
                sub: 'of $caloriesGoal',
                unit: 'kcal',
                color: _calPct > 100
                    ? Colors.redAccent
                    : _calPct > 85
                        ? AppColors.orange
                        : AppColors.green,
                onTap: onCalTap,
              ),
              _ringTile(
                value: waterGoal > 0
                    ? (waterGlasses / waterGoal).clamp(0.0, 1.0)
                    : 0,
                label: 'Water',
                primary: '$waterGlasses',
                sub: 'of $waterGoal',
                unit: 'glasses',
                color: AppColors.blue,
                onTap: onWaterTap,
              ),
              _ringTile(
                value: stepsGoal > 0
                    ? (steps / stepsGoal).clamp(0.0, 1.0)
                    : 0,
                label: 'Steps',
                primary: steps >= 1000
                    ? '${(steps / 1000).toStringAsFixed(1)}k'
                    : '$steps',
                sub: stepsGoal >= 1000
                    ? 'of ${(stepsGoal / 1000).toStringAsFixed(0)}k'
                    : 'of $stepsGoal',
                unit: 'steps',
                color: const Color(0xFF7986CB),
                onTap: onStepsTap,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Divider + status line ───────────────────────────────
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.07),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _statusDotColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _statusLabel(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
              const Spacer(),
              _miniChip('Cal', _calPct, AppColors.orange),
              const SizedBox(width: 6),
              _miniChip('H\u2082O', _watPct, AppColors.blue),
              const SizedBox(width: 6),
              _miniChip('Steps', _stpPct, const Color(0xFF7986CB)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusDotColor() {
    final avg = (_calPct + _watPct + _stpPct) ~/ 3;
    if (avg >= 100) return AppColors.green;
    if (avg >= 60)  return AppColors.orange;
    return Colors.white38;
  }

  Widget _miniChip(String label, int pct, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${pct.clamp(0, 999)}%',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _ringTile({
    required double value,
    required String label,
    required String primary,
    required String sub,
    required String unit,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ProgressRing(
            value: value,
            size: 80,
            progressColor: color,
            trackColor: Colors.white.withOpacity(0.07),
            strokeWidth: 7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  primary,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 8, color: Colors.white38),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
