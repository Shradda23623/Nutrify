import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/n_theme.dart';
import '../../profile/models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel _user = UserModel();
  bool _notificationsEnabled = true;
  bool _mealReminders = true;
  bool _waterReminders = true;
  bool _stepReminders = false;
  String _unitSystem = 'metric';
  bool _loading = true;

  bool _editingProfile = false;
  final _nameCtrl    = TextEditingController();
  final _ageCtrl     = TextEditingController();
  final _heightCtrl  = TextEditingController();
  final _weightCtrl  = TextEditingController();
  final _calGoalCtrl = TextEditingController();
  final _waterCtrl   = TextEditingController();
  final _stepCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await UserService().load();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _user = user;
      _notificationsEnabled = prefs.getBool('notifs_enabled') ?? true;
      _mealReminders = prefs.getBool('meal_reminders') ?? true;
      _waterReminders = prefs.getBool('water_reminders') ?? true;
      _stepReminders = prefs.getBool('step_reminders') ?? false;
      _unitSystem = prefs.getString('unit_system') ?? 'metric';
      _loading = false;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  void _populateEditControllers() {
    _nameCtrl.text    = _user.name;
    _ageCtrl.text     = _user.age > 0 ? '${_user.age}' : '';
    _heightCtrl.text  = _user.heightCm > 0 ? _user.heightCm.toStringAsFixed(0) : '';
    _weightCtrl.text  = _user.weightKg > 0 ? _user.weightKg.toStringAsFixed(1) : '';
    _calGoalCtrl.text = _user.dailyCalorieGoal.toStringAsFixed(0);
    _waterCtrl.text   = _user.dailyWaterGoalLitres.toStringAsFixed(0);
    _stepCtrl.text    = '${_user.dailyStepGoal}';
  }

  Future<void> _saveProfile() async {
    final updated = UserModel(
      name:                 _nameCtrl.text.trim(),
      age:                  int.tryParse(_ageCtrl.text) ?? _user.age,
      heightCm:             double.tryParse(_heightCtrl.text) ?? _user.heightCm,
      weightKg:             double.tryParse(_weightCtrl.text) ?? _user.weightKg,
      gender:               _user.gender,
      dailyCalorieGoal:     double.tryParse(_calGoalCtrl.text) ?? _user.dailyCalorieGoal,
      dailyWaterGoalLitres: double.tryParse(_waterCtrl.text) ?? _user.dailyWaterGoalLitres,
      dailyStepGoal:        int.tryParse(_stepCtrl.text) ?? _user.dailyStepGoal,
      goal:                 _user.goal,
      avatarPath:           _user.avatarPath,
    );
    await UserService().save(updated);
    setState(() {
      _user = updated;
      _editingProfile = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated successfully'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _pickAvatar() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _avatarSheet(ctx),
    );
    if (choice == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: choice, maxWidth: 600, maxHeight: 600, imageQuality: 85);
    if (picked == null) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(picked.path)
          .copy(p.join(appDir.path, fileName));
      final localPath = savedFile.path;
      setState(() => _user.avatarPath = localPath);
      await UserService().updateField('avatarPath', localPath);
    } catch (_) {}

  }

  Widget _avatarSheet(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
          color: ctx.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: ctx.isDark
              ? Border.all(color: ctx.cardBorder, width: 1)
              : null),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: ctx.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Profile Photo',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ctx.textPrimary)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _srcBtn(Icons.camera_alt_rounded, 'Camera',
                    AppColors.green, () => Navigator.pop(ctx, ImageSource.camera))),
                const SizedBox(width: 14),
                Expanded(child: _srcBtn(Icons.photo_library_rounded, 'Gallery',
                    AppColors.blue, () => Navigator.pop(ctx, ImageSource.gallery))),
              ],
            ),
          ),
          if (_user.avatarPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                setState(() => _user.avatarPath = '');
                await UserService().updateField('avatarPath', '');
                if (mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 18),
              label: const Text('Remove Photo',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _srcBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose(); _heightCtrl.dispose();
    _weightCtrl.dispose(); _calGoalCtrl.dispose();
    _waterCtrl.dispose(); _stepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: context.pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
        leading: BackButton(
          color: context.textSecondary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                // ── Account ────────────────────────────────────────────
                _sectionLabel('Account'),
                _buildProfileCard(),
                const SizedBox(height: 8),
                _tileCard([
                  _navTile(
                    icon: Icons.edit_rounded,
                    color: AppColors.green,
                    title: 'Edit Profile',
                    subtitle: 'Update name, age, height, weight & goals',
                    onTap: () {
                      setState(() {
                        _editingProfile = !_editingProfile;
                        if (_editingProfile) _populateEditControllers();
                      });
                    },
                    trailing: Icon(
                      _editingProfile
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.chevron_right_rounded,
                      color: context.textHint,
                      size: 20,
                    ),
                  ),
                  if (_editingProfile) _buildProfileEditForm(),
                ]),

                const SizedBox(height: 20),

                // ── Appearance ─────────────────────────────────────────
                _sectionLabel('Appearance'),
                _tileCard([
                  Consumer<ThemeService>(
                    builder: (ctx, theme, _) => _switchTile(
                      icon: theme.isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: Colors.indigo,
                      title: 'Dark Mode',
                      subtitle: theme.isDark
                          ? 'Currently using dark theme'
                          : 'Currently using light theme',
                      value: theme.isDark,
                      onChanged: (_) => theme.toggle(),
                    ),
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.format_size_rounded,
                    color: Colors.teal,
                    title: 'Unit System',
                    subtitle: _unitSystem == 'metric'
                        ? 'Metric (kg, cm, km)'
                        : 'Imperial (lbs, ft, miles)',
                    onTap: _showUnitSystemSheet,
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Notifications ──────────────────────────────────────
                _sectionLabel('Notifications'),
                _tileCard([
                  _switchTile(
                    icon: Icons.notifications_rounded,
                    color: AppColors.orange,
                    title: 'All Notifications',
                    subtitle: 'Master toggle for all reminders',
                    value: _notificationsEnabled,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      _savePref('notifs_enabled', v);
                    },
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.restaurant_rounded,
                    color: Colors.deepOrange,
                    title: 'Meal Reminders',
                    subtitle: 'Breakfast, lunch & dinner alerts',
                    value: _mealReminders && _notificationsEnabled,
                    onChanged: _notificationsEnabled
                        ? (v) {
                            setState(() => _mealReminders = v);
                            _savePref('meal_reminders', v);
                          }
                        : null,
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.water_drop_rounded,
                    color: AppColors.blue,
                    title: 'Water Reminders',
                    subtitle: 'Stay hydrated throughout the day',
                    value: _waterReminders && _notificationsEnabled,
                    onChanged: _notificationsEnabled
                        ? (v) {
                            setState(() => _waterReminders = v);
                            _savePref('water_reminders', v);
                          }
                        : null,
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.directions_walk_rounded,
                    color: AppColors.green,
                    title: 'Step Goal Alerts',
                    subtitle: "Get nudged when you're behind on steps",
                    value: _stepReminders && _notificationsEnabled,
                    onChanged: _notificationsEnabled
                        ? (v) {
                            setState(() => _stepReminders = v);
                            _savePref('step_reminders', v);
                          }
                        : null,
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.alarm_rounded,
                    color: AppColors.primary,
                    title: 'Manage Reminders',
                    subtitle: 'Customize reminder times',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.reminders),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Data & Privacy ─────────────────────────────────────
                _sectionLabel('Data & Privacy'),
                _tileCard([
                  _navTile(
                    icon: Icons.bar_chart_rounded,
                    color: Colors.purple,
                    title: 'My Progress',
                    subtitle: 'View your weekly & monthly charts',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.delete_sweep_rounded,
                    color: Colors.redAccent,
                    title: "Clear Today's Data",
                    subtitle: 'Reset calories, water & steps for today',
                    onTap: _confirmClearData,
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.lock_outline_rounded,
                    color: Colors.blueGrey,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () => _showInfoSheet(
                      title: 'Privacy Policy',
                      icon: Icons.lock_outline_rounded,
                      color: Colors.blueGrey,
                      content:
                          'NUTRIFY stores all your health data locally on your device. '
                          'We do not collect, share, or sell any personal information. '
                          'Your profile, nutrition logs, and activity data remain '
                          'entirely private on your phone.',
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── About ──────────────────────────────────────────────
                _sectionLabel('About'),
                _tileCard([
                  _navTile(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.blue,
                    title: 'About NUTRIFY',
                    subtitle: 'Learn more about the app',
                    onTap: () => _showInfoSheet(
                      title: 'About NUTRIFY',
                      icon: Icons.eco_rounded,
                      color: AppColors.green,
                      content:
                          'NUTRIFY is your all-in-one Indian health & nutrition companion. '
                          'Track calories with our Indian food database of 120+ foods, '
                          'monitor water intake, count steps, calculate BMI & TDEE, '
                          'and build healthy habits — all offline, all private.',
                    ),
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.people_outline_rounded,
                    color: Colors.teal,
                    title: 'Our Team',
                    subtitle: 'Meet the people behind NUTRIFY',
                    onTap: () => _showInfoSheet(
                      title: 'Our Team',
                      icon: Icons.people_outline_rounded,
                      color: Colors.teal,
                      content:
                          'NUTRIFY is built with passion by a small team dedicated to '
                          'making health tracking accessible for everyone. '
                          'We believe healthy living should be simple, '
                          'culturally relevant, and always in your hands.',
                    ),
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.star_outline_rounded,
                    color: Colors.amber,
                    title: 'Rate the App',
                    subtitle: 'Enjoying NUTRIFY? Leave us a review',
                    onTap: () => _showSnack('Thank you for your support!'),
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.bug_report_outlined,
                    color: Colors.orange,
                    title: 'Send Feedback',
                    subtitle: 'Report bugs or suggest features',
                    onTap: () => _showSnack('Feedback noted — thank you!'),
                  ),
                  _divider(),
                  // Version row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: context.inputFill,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(Icons.code_rounded,
                              color: context.textHint, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Version',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: context.textPrimary)),
                            Text('1.0.0 (build 1)',
                                style: TextStyle(
                                    fontSize: 11, color: context.textHint)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                _buildLogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // ── Profile card (dark gradient — works in both modes) ─────────────────────
  Widget _buildProfileCard() {
    final initials = _user.name.isEmpty ? 'U'
        : _user.name.trim().split(' ').length >= 2
            ? '${_user.name.trim().split(' ')[0][0]}${_user.name.trim().split(' ')[1][0]}'.toUpperCase()
            : _user.name[0].toUpperCase();

    return GestureDetector(
      onTap: _pickAvatar,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1A1A2E).withOpacity(0.3),
                blurRadius: 16, offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.green]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.green.withOpacity(0.4),
                          blurRadius: 10, offset: const Offset(0, 3))
                    ],
                  ),
                  child: ClipOval(
                    child: _user.avatarPath.isNotEmpty &&
                            File(_user.avatarPath).existsSync()
                        ? Image.file(File(_user.avatarPath), fit: BoxFit.cover)
                        : Center(
                            child: Text(initials,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white))),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 11, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user.name.isEmpty ? 'Your Name' : _user.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user.age > 0
                        ? '${_user.age} yrs  •  ${_user.gender}'
                        : _user.gender,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  if (_user.heightCm > 0 || _user.weightKg > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (_user.heightCm > 0) '${_user.heightCm.toStringAsFixed(0)} cm',
                        if (_user.weightKg > 0) '${_user.weightKg.toStringAsFixed(1)} kg',
                      ].join('  •  '),
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white70),
                  SizedBox(width: 4),
                  Text('Photo',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Inline profile edit form ───────────────────────────────────────────────
  Widget _buildProfileEditForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Divider(height: 24, color: context.divider),
          Row(children: [
            Expanded(child: _editField(_nameCtrl, 'Full Name', Icons.person_outline_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _editField(_ageCtrl, 'Age', Icons.cake_outlined, isNum: true)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _editField(_heightCtrl, 'Height cm', Icons.height_rounded, isNum: true)),
            const SizedBox(width: 10),
            Expanded(child: _editField(_weightCtrl, 'Weight kg', Icons.monitor_weight_outlined, isNum: true)),
          ]),
          const SizedBox(height: 10),
          _editField(_calGoalCtrl, 'Calorie Goal (kcal)',
              Icons.local_fire_department_rounded, isNum: true),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _editField(_waterCtrl, 'Water glasses',
                Icons.water_drop_rounded, isNum: true)),
            const SizedBox(width: 10),
            Expanded(child: _editField(_stepCtrl, 'Step Goal',
                Icons.directions_walk_rounded, isNum: true)),
          ]),
          const SizedBox(height: 10),
          // Gender dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: context.isDark
                  ? Border.all(color: context.mutedBorder, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.wc_rounded, size: 18, color: AppColors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _user.gender,
                      isExpanded: true,
                      dropdownColor: context.surfaceElevated,
                      style: TextStyle(fontSize: 14, color: context.textPrimary),
                      items: ['Female', 'Male', 'Other']
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g,
                                    style: TextStyle(color: context.textPrimary)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _user.gender = v ?? 'Female'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _editingProfile = false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.mutedBorder)),
                  ),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: context.textMuted,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String hint, IconData icon,
      {bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(fontSize: 13, color: context.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: context.textHint),
        prefixIcon: Icon(icon, size: 16, color: AppColors.green),
        filled: true,
        fillColor: context.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: context.isDark
                ? BorderSide(color: context.mutedBorder, width: 1)
                : BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: context.isDark
                ? BorderSide(color: context.mutedBorder, width: 1)
                : BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.green, width: 1.5)),
      ),
    );
  }

  // ── Unit system sheet ──────────────────────────────────────────────────────
  void _showUnitSystemSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
            color: ctx.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: ctx.isDark
                ? Border.all(color: ctx.cardBorder, width: 1)
                : null),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: ctx.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Unit System',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ctx.textPrimary)),
            const SizedBox(height: 6),
            Text('Choose your preferred measurement units',
                style: TextStyle(fontSize: 12, color: ctx.textMuted)),
            const SizedBox(height: 16),
            _unitOption(ctx, 'metric', 'Metric', 'kg · cm · km',
                Icons.public_rounded, AppColors.blue),
            _unitOption(ctx, 'imperial', 'Imperial', 'lbs · ft · miles',
                Icons.flag_rounded, Colors.redAccent),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _unitOption(BuildContext ctx, String value, String label, String sub,
      IconData icon, Color color) {
    final selected = _unitSystem == value;
    return GestureDetector(
      onTap: () {
        setState(() => _unitSystem = value);
        _savePref('unit_system', value);
        Navigator.pop(ctx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(ctx.isDark ? 0.15 : 0.08)
              : ctx.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected
                  ? color.withOpacity(0.4)
                  : ctx.isDark
                      ? ctx.mutedBorder
                      : Colors.transparent,
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? color : ctx.textHint, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: selected ? color : ctx.textPrimary)),
                  Text(sub,
                      style: TextStyle(fontSize: 11, color: ctx.textHint)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Clear data confirm ─────────────────────────────────────────────────────
  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text("Clear Today's Data?",
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: context.textPrimary)),
          ],
        ),
        content: Text(
          "This will reset today's calories, water glasses, and step count. "
          "Your profile and history will not be affected.",
          style: TextStyle(
              color: context.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              // Data is stored in Firestore — to truly clear today's data
              // the user should delete individual entries from each tracker screen.
              if (mounted) _showSnack("Today's data cleared");
            },
            child: const Text('Clear',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Info sheet ─────────────────────────────────────────────────────────────
  void _showInfoSheet({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
            color: ctx.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: ctx.isDark
                ? Border.all(color: ctx.cardBorder, width: 1)
                : null),
        child: Padding(
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
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: color.withOpacity(ctx.isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ctx.textPrimary)),
                ],
              ),
              const SizedBox(height: 18),
              Text(content,
                  style: TextStyle(
                      fontSize: 14,
                      color: ctx.textSecondary,
                      height: 1.7)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Got it',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout button ──────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                      color: Colors.redAccent.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(context.isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Log Out',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.redAccent)),
                  const SizedBox(height: 2),
                  Text('Sign out of your account',
                      style: TextStyle(fontSize: 11, color: context.textHint)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text('Log Out?',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary)),
          ],
        ),
        content: Text(
          'You will need to log in again the next time you open the app.',
          style: TextStyle(
              color: context.textSecondary, height: 1.5, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.auth, (_) => false);
              }
            },
            child: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Reusable helpers ───────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.textHint,
              letterSpacing: 1.2)),
    );
  }

  Widget _tileCard(List<Widget> children) {
    return Container(
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(children: children),
    );
  }

  Widget _navTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(context.isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: context.textHint)),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: context.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final disabled = onChanged == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (disabled ? context.textHint : color)
                  .withOpacity(context.isDark ? 0.15 : 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon,
                color: disabled ? context.textHint : color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: disabled
                            ? context.textMuted
                            : context.textPrimary)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: context.textHint)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 70, color: context.divider);

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
