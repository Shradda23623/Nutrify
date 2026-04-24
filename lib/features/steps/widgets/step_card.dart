import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/progress_ring.dart';

class StepCard extends StatelessWidget {
  final int steps;
  final int goal;

  const StepCard({super.key, required this.steps, required this.goal});

  double get _progress => goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
  int get _percent => (_progress * 100).round();

  // Derived stats
  double get _distanceKm => steps * 0.000762;
  double get _caloriesBurned => steps * 0.04;
  int get _activeMinutes => (steps / 100).round();

  String get _motivationalMessage {
    if (_progress >= 1.0) return 'Goal crushed! Amazing work today!';
    if (_progress >= 0.75) return 'Almost there — keep pushing!';
    if (_progress >= 0.5) return 'Great pace — you\'re halfway!';
    if (_progress >= 0.25) return 'Good start — keep moving!';
    return 'Every step counts — let\'s go!';
  }

  Color get _progressColor {
    if (_progress >= 1.0) return AppColors.green;
    if (_progress >= 0.5) return AppColors.blue;
    return AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Ring + step count ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            child: Row(
              children: [
                // Progress ring
                ProgressRing(
                  value: _progress,
                  size: 140,
                  strokeWidth: 14,
                  progressColor: _progressColor,
                  trackColor: Colors.white.withOpacity(0.08),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatSteps(steps),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'steps',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Right side info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Steps",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$_percent',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: _progressColor,
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: '%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _progressColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'of ${_formatSteps(goal)} goal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Motivational chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _progressColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _progressColor.withOpacity(0.3),
                              width: 1),
                        ),
                        child: Text(
                          _motivationalMessage,
                          style: TextStyle(
                            fontSize: 10,
                            color: _progressColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────
          Divider(
            color: Colors.white.withOpacity(0.08),
            height: 1,
            indent: 24,
            endIndent: 24,
          ),

          // ── Stats row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                _statCell(
                  icon: Icons.route_outlined,
                  value: _distanceKm.toStringAsFixed(2),
                  unit: 'km',
                  label: 'Distance',
                  color: AppColors.blue,
                ),
                _vDivider(),
                _statCell(
                  icon: Icons.local_fire_department_outlined,
                  value: _caloriesBurned.toStringAsFixed(0),
                  unit: 'kcal',
                  label: 'Burned',
                  color: AppColors.orange,
                ),
                _vDivider(),
                _statCell(
                  icon: Icons.timer_outlined,
                  value: '$_activeMinutes',
                  unit: 'min',
                  label: 'Active',
                  color: AppColors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSteps(int s) {
    if (s >= 1000) {
      return '${(s / 1000).toStringAsFixed(s % 1000 == 0 ? 0 : 1)}k';
    }
    return '$s';
  }

  Widget _statCell({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color.withOpacity(0.8)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
        width: 1, height: 36, color: Colors.white.withOpacity(0.08));
  }
}
