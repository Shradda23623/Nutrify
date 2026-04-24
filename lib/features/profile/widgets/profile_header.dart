import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onAvatarTap;

  const ProfileHeader({super.key, required this.user, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.name);
    final bmiColor = _bmiColor(user.bmi);
    final bmiLabel = user.bmiCategory;

    return Container(
      width: double.infinity,
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
          // ── Top band: avatar + name ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                // Avatar circle with photo or initials
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.green],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: user.avatarPath.isNotEmpty &&
                                  File(user.avatarPath).existsSync()
                              ? Image.file(
                                  File(user.avatarPath),
                                  fit: BoxFit.cover,
                                  width: 72,
                                  height: 72,
                                )
                              : Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (onAvatarTap != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF1A1A2E), width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 11, color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isEmpty ? 'Your Name' : user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (user.age > 0) ...[
                            _chip(
                              icon: Icons.cake_outlined,
                              label: '${user.age} yrs',
                            ),
                            const SizedBox(width: 6),
                          ],
                          _chip(
                            icon: user.gender == 'Female'
                                ? Icons.female_rounded
                                : Icons.male_rounded,
                            label: user.gender,
                          ),
                        ],
                      ),
                      if (user.goal.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _goalBadge(user.goal),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────
          Divider(
            color: Colors.white.withOpacity(0.08),
            height: 1,
            indent: 24,
            endIndent: 24,
          ),

          // ── Stats row ────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                _statCell(
                  icon: Icons.height_rounded,
                  value: user.heightCm > 0
                      ? '${user.heightCm.toStringAsFixed(0)}'
                      : '—',
                  unit: 'cm',
                  label: 'Height',
                ),
                _vDivider(),
                _statCell(
                  icon: Icons.monitor_weight_outlined,
                  value: user.weightKg > 0
                      ? '${user.weightKg.toStringAsFixed(1)}'
                      : '—',
                  unit: 'kg',
                  label: 'Weight',
                ),
                _vDivider(),
                _statCell(
                  icon: Icons.calculate_outlined,
                  value: user.bmi > 0
                      ? user.bmi.toStringAsFixed(1)
                      : '—',
                  unit: '',
                  label: 'BMI',
                  valueColor: user.bmi > 0 ? bmiColor : null,
                ),
                _vDivider(),
                _statCell(
                  icon: Icons.local_fire_department_outlined,
                  value: user.dailyCalorieGoal > 0
                      ? '${user.dailyCalorieGoal.toStringAsFixed(0)}'
                      : '—',
                  unit: 'kcal',
                  label: 'Goal',
                ),
              ],
            ),
          ),

          // ── BMI category bar ─────────────────────────────────────
          if (user.bmi > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bmiColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: bmiColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: bmiColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BMI Status: $bmiLabel',
                    style: TextStyle(
                        color: bmiColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    _bmiAdviceShort(user.bmi),
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _initials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _bmiColor(double bmi) {
    if (bmi <= 0) return AppColors.green;
    if (bmi < 18.5) return const Color(0xFF4D96FF);
    if (bmi < 25) return AppColors.green;
    if (bmi < 30) return const Color(0xFFFFBF00);
    return Colors.redAccent;
  }

  String _bmiAdviceShort(double bmi) {
    if (bmi < 18.5) return 'Below range';
    if (bmi < 25) return 'Healthy range';
    if (bmi < 30) return 'Above range';
    return 'High range';
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white54),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _goalBadge(String goal) {
    final map = {
      'lose': ('Lose Weight', Icons.trending_down_rounded,
          const Color(0xFF4D96FF)),
      'maintain': ('Stay Fit', Icons.balance_rounded, AppColors.green),
      'gain': ('Build Muscle', Icons.trending_up_rounded,
          const Color(0xFFFF9F1C)),
    };
    final data = map[goal] ??
        ('Stay Fit', Icons.balance_rounded, AppColors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: data.$3.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: data.$3.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.$2, size: 12, color: data.$3),
          const SizedBox(width: 5),
          Text(data.$1,
              style: TextStyle(
                  fontSize: 11,
                  color: data.$3,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statCell({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? Colors.white,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                        fontSize: 9, color: Colors.white38),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
        width: 1, height: 36, color: Colors.white.withOpacity(0.08));
  }
}
