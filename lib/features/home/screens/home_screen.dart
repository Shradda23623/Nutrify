import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/n_theme.dart';
import '../../../features/calories/services/calorie_service.dart';
import '../../../features/water/services/water_service.dart';
import '../../../features/profile/models/user_model.dart';
import '../widgets/daily_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _navIndex = 0;

  // Live data
  int _calories    = 0;
  int _caloriesGoal = 2000;
  int _water       = 0;
  int _waterGoal   = 8;
  final int _steps     = 0;
  final int _stepsGoal = 10000;
  int _streak      = 0;
  UserModel _user  = UserModel();

  final _calorieService = CalorieService();
  final _waterService   = WaterService();
  final _streakService  = StreakService();
  final _userService    = UserService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _calorieService.load(),
      _waterService.load(),
      _streakService.getCurrentStreak(),
      _userService.load(),
    ]);

    final calModel   = results[0] as dynamic;
    final waterModel = results[1] as dynamic;
    final streak     = results[2] as int;
    final user       = results[3] as UserModel;

    if (mounted) {
      setState(() {
        _calories     = (calModel.totalCalories as double).toInt();
        _caloriesGoal = (calModel.goal as double).toInt();
        _water        = waterModel.intake as int;
        _waterGoal    = waterModel.goal as int;
        _streak       = streak;
        _user         = user;
      });
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0: break;
      case 1: Navigator.pushNamed(context, AppRoutes.calories).then((_) => _loadData()); break;
      case 2: Navigator.pushNamed(context, AppRoutes.water).then((_) => _loadData()); break;
      case 3: Navigator.pushNamed(context, AppRoutes.steps); break;
      case 4: Navigator.pushNamed(context, AppRoutes.profile).then((_) => _loadData()); break;
    }
    setState(() => _navIndex = 0);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName() {
    final n = _user.name.trim();
    if (n.isEmpty) return 'there';
    return n.split(' ').first;
  }

  String _formattedDate() {
    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  IconData _greetingIcon() {
    final h = DateTime.now().hour;
    if (h < 12) return Icons.wb_sunny_rounded;
    if (h < 17) return Icons.light_mode_rounded;
    return Icons.nights_stay_rounded;
  }

  Color _greetingIconColor() {
    final h = DateTime.now().hour;
    if (h < 12) return const Color(0xFFFFC940);
    if (h < 17) return const Color(0xFFFFAB40);
    return const Color(0xFF7986CB);
  }

  String _userInitials() {
    final n = _user.name.trim();
    if (n.isEmpty) return 'U';
    final parts = n.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.pageBg,
        bottomNavigationBar: BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.green,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────
                  _buildHeader(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Progress card ──────────────────────────────
                        DailySummaryCard(
                          caloriesConsumed: _calories,
                          caloriesGoal: _caloriesGoal,
                          waterGlasses: _water,
                          waterGoal: _waterGoal,
                          steps: _steps,
                          stepsGoal: _stepsGoal,
                          dateLabel: _formattedDate(),
                          onCalTap: () => Navigator.pushNamed(context, AppRoutes.calories).then((_) => _loadData()),
                          onWaterTap: () => Navigator.pushNamed(context, AppRoutes.water).then((_) => _loadData()),
                          onStepsTap: () => Navigator.pushNamed(context, AppRoutes.steps),
                        ),

                        const SizedBox(height: 28),

                        // ── Today's Focus ──────────────────────────────
                        _sectionLabel('Today\'s Focus'),
                        const SizedBox(height: 14),
                        _buildFocusGrid(),

                        const SizedBox(height: 28),

                        // ── Tools ──────────────────────────────────────
                        _sectionLabel('More Tools'),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // Horizontal tools scroll (full-bleed, no padding)
                  _buildToolsRow(),

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Reminders ──────────────────────────────────
                        _buildRemindersSection(),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: greeting + name + streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_greetingIcon(), size: 14, color: _greetingIconColor()),
                    const SizedBox(width: 5),
                    Text(
                      _formattedDate(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_greeting()}, ${_firstName()}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                if (_streak > 0) ...[
                  const SizedBox(height: 8),
                  _StreakPill(streak: _streak),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: actions + avatar
          Row(
            children: [
              _HeaderIconBtn(
                icon: Icons.notifications_outlined,
                onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
              ),
              const SizedBox(width: 8),
              _HeaderIconBtn(
                icon: Icons.settings_outlined,
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings)
                    .then((_) => _loadData()),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile)
                    .then((_) => _loadData()),
                child: _AvatarBadge(
                  initials: _userInitials(),
                  avatarPath: _user.avatarPath,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Focus Grid (2×2) ──────────────────────────────────────────────────────

  Widget _buildFocusGrid() {
    final calRemaining = (_caloriesGoal - _calories).clamp(0, _caloriesGoal);
    final calPct       = _caloriesGoal > 0
        ? (_calories / _caloriesGoal).clamp(0.0, 1.0)
        : 0.0;
    final waterPct     = _waterGoal > 0
        ? (_water / _waterGoal).clamp(0.0, 1.0)
        : 0.0;
    final isCalOver    = _calories > _caloriesGoal;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FocusStatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Calories',
                value: '$_calories',
                unit: 'kcal eaten',
                subLabel: isCalOver
                    ? '${(_calories - _caloriesGoal)} kcal over'
                    : '$calRemaining kcal left',
                progress: calPct,
                color: isCalOver
                    ? Colors.redAccent
                    : calPct > 0.85
                        ? AppColors.orange
                        : AppColors.green,
                onTap: () => Navigator.pushNamed(context, AppRoutes.calories)
                    .then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FocusStatCard(
                icon: Icons.water_drop_rounded,
                label: 'Water',
                value: '$_water',
                unit: 'of $_waterGoal glasses',
                subLabel: _water >= _waterGoal
                    ? 'Goal reached! 🎉'
                    : '${_waterGoal - _water} more to go',
                progress: waterPct,
                color: AppColors.blue,
                onTap: () => Navigator.pushNamed(context, AppRoutes.water)
                    .then((_) => _loadData()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FocusActionCard(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan Food',
                sublabel: 'Barcode scanner',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, AppRoutes.scanner),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FocusActionCard(
                icon: Icons.restaurant_menu_rounded,
                label: 'Meal Plan',
                sublabel: 'Plan your day',
                color: const Color(0xFF9C6FDE),
                onTap: () => Navigator.pushNamed(context, AppRoutes.mealPlan),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Tools horizontal scroll ───────────────────────────────────────────────

  Widget _buildToolsRow() {
    final tools = [
      _ToolItem(icon: Icons.directions_walk_rounded, label: 'Steps',        color: AppColors.green,           route: AppRoutes.steps),
      _ToolItem(icon: Icons.calculate_rounded,       label: 'BMI',          color: AppColors.yellow,          route: AppRoutes.bmi),
      _ToolItem(icon: Icons.flash_on_rounded,        label: 'TDEE',         color: Colors.deepOrange,         route: AppRoutes.tdee),
      _ToolItem(icon: Icons.monitor_weight_rounded,  label: 'Weight',       color: Colors.teal,               route: AppRoutes.weight),
      _ToolItem(icon: Icons.bar_chart_rounded,       label: 'Progress',     color: Colors.purple,             route: AppRoutes.progress),
      _ToolItem(icon: Icons.straighten_rounded,      label: 'Measurements', color: const Color(0xFF26A69A),   route: AppRoutes.measurements),
      _ToolItem(icon: Icons.add_box_rounded,         label: 'My Foods',     color: AppColors.orange,          route: AppRoutes.customFoods),
      _ToolItem(icon: Icons.bluetooth_rounded,       label: 'Device',       color: Colors.indigo,             route: AppRoutes.device),
      _ToolItem(icon: Icons.science_rounded,         label: 'Vitamins',     color: const Color(0xFFAB47BC),   route: AppRoutes.micronutrients),
      _ToolItem(icon: Icons.timer_rounded,           label: 'Fasting',      color: const Color(0xFF4D96FF),   route: AppRoutes.fasting),
      _ToolItem(icon: Icons.bolt_rounded,            label: 'Glycemic',     color: const Color(0xFFFF9F1C),   route: AppRoutes.glycemic),
      _ToolItem(icon: Icons.bedtime_rounded,         label: 'Sleep',        color: const Color(0xFF7986CB),   route: AppRoutes.sleep),
      _ToolItem(icon: Icons.fitness_center_rounded,  label: 'Workout',      color: AppColors.green,           route: AppRoutes.workout),
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = tools[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, t.route)
                .then((_) => _loadData()),
            child: Container(
              width: 72,
              decoration: context.cardDecoration(radius: BorderRadius.circular(18)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t.color.withOpacity(context.isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(t.icon, color: t.color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Reminders section ─────────────────────────────────────────────────────

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('Reminders'),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
              child: Text(
                'Manage',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ReminderTile(
          icon: Icons.water_drop_rounded,
          title: 'Water Reminder',
          subtitle: '8 glasses · Every 2 hours',
          color: AppColors.blue,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
        ),
        const SizedBox(height: 10),
        _ReminderTile(
          icon: Icons.restaurant_rounded,
          title: 'Meal Reminder',
          subtitle: 'Breakfast · Lunch · Dinner',
          color: AppColors.orange,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: context.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ToolItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _ToolItem({required this.icon, required this.label, required this.color, required this.route});
}

// ── Streak pill ───────────────────────────────────────────────────────────────

class _StreakPill extends StatelessWidget {
  final int streak;
  const _StreakPill({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$streak day streak',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header icon button ────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorder, width: 1),
        ),
        child: Icon(icon, size: 19, color: context.textSecondary),
      ),
    );
  }
}

// ── Avatar badge ──────────────────────────────────────────────────────────────

class _AvatarBadge extends StatelessWidget {
  final String initials;
  final String avatarPath;
  const _AvatarBadge({required this.initials, required this.avatarPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.green.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: avatarPath.isNotEmpty
            ? Image.asset(avatarPath, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsWidget(context))
            : _initialsWidget(context),
      ),
    );
  }

  Widget _initialsWidget(BuildContext context) => Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
}

// ── Focus stat card (calories / water) ────────────────────────────────────────

class _FocusStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String subLabel;
  final double progress;
  final Color color;
  final VoidCallback onTap;

  const _FocusStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.subLabel,
    required this.progress,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(
          radius: BorderRadius.circular(20),
          extraShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(context.isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: context.textPrimary,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 10, color: context.textHint),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Focus action card (scanner / meal plan) ───────────────────────────────────

class _FocusActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _FocusActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(context.isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: context.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Reminder tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: context.cardDecoration(radius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(context.isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: context.textMuted)),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(context.isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
