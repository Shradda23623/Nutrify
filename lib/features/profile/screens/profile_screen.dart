import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/n_theme.dart';
import '../../../core/services/user_service.dart';
import '../models/user_model.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel _user = UserModel();
  bool _editing = false;
  bool _loading = true;

  final _userService = UserService();
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
    final user = await _userService.load();
    if (mounted) {
      setState(() {
        _user = user;
        _populateControllers();
        _loading = false;
      });
    }
  }

  void _populateControllers() {
    _nameCtrl.text    = _user.name;
    _ageCtrl.text     = _user.age > 0 ? '${_user.age}' : '';
    _heightCtrl.text  = _user.heightCm > 0 ? _user.heightCm.toStringAsFixed(0) : '';
    _weightCtrl.text  = _user.weightKg > 0 ? _user.weightKg.toStringAsFixed(1) : '';
    _calGoalCtrl.text = _user.dailyCalorieGoal.toStringAsFixed(0);
    _waterCtrl.text   = _user.dailyWaterGoalLitres.toStringAsFixed(0);
    _stepCtrl.text    = '${_user.dailyStepGoal}';
  }

  Future<void> _save() async {
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
    await _userService.save(updated);
    setState(() {
      _user = updated;
      _editing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile saved successfully'),
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
      builder: (ctx) => _avatarSourceSheet(ctx),
    );
    if (choice == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: choice,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (picked == null) return;
    try {
      // Save photo locally to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(picked.path)
          .copy(p.join(appDir.path, fileName));
      final localPath = savedFile.path;
      setState(() => _user.avatarPath = localPath);
      await _userService.updateField('avatarPath', localPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save photo: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Widget _avatarSourceSheet(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: ctx.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: ctx.isDark ? Border.all(color: ctx.cardBorder, width: 1) : null,
      ),
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
          Text('Choose Photo',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ctx.textPrimary)),
          const SizedBox(height: 4),
          Text('Select a source for your profile picture',
              style: TextStyle(fontSize: 12, color: ctx.textMuted)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _sourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: AppColors.green,
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                )),
                const SizedBox(width: 14),
                Expanded(child: _sourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: AppColors.blue,
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_user.avatarPath.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                setState(() => _user.avatarPath = '');
                await _userService.updateField('avatarUrl', '');
                if (mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 18),
              label: const Text('Remove Photo',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon, required String label,
    required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
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
    if (_loading) {
      return Scaffold(
        backgroundColor: context.pageBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            backgroundColor: context.pageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Text('My Profile',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary)),
            actions: [
              if (!_editing) ...[
                _appBarIconBtn(
                  icon: Icons.settings_rounded,
                  color: context.textSecondary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.settings)
                      .then((_) => _load()),
                ),
                const SizedBox(width: 6),
                _appBarIconBtn(
                  icon: Icons.edit_rounded,
                  color: AppColors.green,
                  onTap: () => setState(() {
                    _editing = true;
                    _populateControllers();
                  }),
                ),
              ],
              if (_editing) ...[
                _appBarPillBtn(
                  icon: Icons.close_rounded,
                  label: 'Cancel',
                  color: context.textMuted,
                  onTap: () => setState(() => _editing = false),
                ),
                const SizedBox(width: 4),
                _appBarPillBtn(
                  icon: Icons.check_rounded,
                  label: 'Save',
                  color: AppColors.green,
                  onTap: _save,
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(user: _user, onAvatarTap: _pickAvatar),
                  const SizedBox(height: 20),

                  if (_editing) ...[
                    _buildEditForm(),
                    const SizedBox(height: 20),
                  ],

                  if (!_editing) ...[
                    _sectionHeader('Daily Goals', Icons.flag_rounded, AppColors.orange),
                    const SizedBox(height: 12),
                    _buildGoalsGrid(),
                    const SizedBox(height: 24),
                    _sectionHeader('Tools & Features', Icons.apps_rounded, AppColors.blue),
                    const SizedBox(height: 12),
                    _buildToolsGrid(),
                    const SizedBox(height: 24),
                    _buildSettingsShortcut(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsShortcut() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.settings).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(context.isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.settings_rounded,
                  color: context.isDark
                      ? Colors.blueGrey.shade300
                      : Colors.blueGrey,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: context.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Theme, notifications, privacy & more',
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

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickAvatar,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(context.isDark ? 0.1 : 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.green]),
                  ),
                  child: ClipOval(
                    child: _user.avatarPath.isNotEmpty &&
                            File(_user.avatarPath).existsSync()
                        ? Image.file(File(_user.avatarPath), fit: BoxFit.cover)
                        : Center(
                            child: Text(_initials(_user.name),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white))),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user.avatarPath.isNotEmpty
                            ? 'Change Profile Photo'
                            : 'Add Profile Photo',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.green),
                      ),
                      const SizedBox(height: 2),
                      Text('Tap to choose from camera or gallery',
                          style: TextStyle(fontSize: 11, color: context.textHint)),
                    ],
                  ),
                ),
                Icon(Icons.camera_alt_rounded,
                    color: AppColors.green.withOpacity(0.6), size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _formCard(
          title: 'Personal Information',
          icon: Icons.person_rounded,
          children: [
            _formField(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _formField(_ageCtrl, 'Age', Icons.cake_outlined, isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: _genderDropdown()),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _formField(_heightCtrl, 'Height (cm)', Icons.height_rounded, isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: _formField(_weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined, isNum: true)),
            ]),
          ],
        ),
        const SizedBox(height: 14),
        _formCard(
          title: 'Daily Targets',
          icon: Icons.flag_rounded,
          children: [
            _formField(_calGoalCtrl, 'Calorie Goal (kcal)',
                Icons.local_fire_department_rounded, isNum: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _formField(_waterCtrl, 'Water (glasses)',
                  Icons.water_drop_rounded, isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: _formField(_stepCtrl, 'Step Goal',
                  Icons.directions_walk_rounded, isNum: true)),
            ]),
          ],
        ),
        const SizedBox(height: 14),
        _formCard(
          title: 'Fitness Goal',
          icon: Icons.emoji_events_rounded,
          children: [_goalSelector()],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _save,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.green, AppColors.primary]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: AppColors.green.withOpacity(0.35),
                    blurRadius: 12, offset: const Offset(0, 4))
              ],
            ),
            child: const Center(
              child: Text('Save Changes',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _goalSelector() {
    final goals = [
      ('lose', 'Lose Weight', Icons.trending_down_rounded, const Color(0xFF4D96FF)),
      ('maintain', 'Stay Fit', Icons.balance_rounded, AppColors.green),
      ('gain', 'Build Muscle', Icons.trending_up_rounded, const Color(0xFFFF9F1C)),
    ];
    return Row(
      children: goals.map((g) {
        final selected = _user.goal == g.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _user.goal = g.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? g.$4.withOpacity(context.isDark ? 0.18 : 0.12)
                    : context.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected
                        ? g.$4.withOpacity(0.4)
                        : context.isDark
                            ? context.mutedBorder
                            : Colors.transparent,
                    width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(g.$3,
                      color: selected ? g.$4 : context.textHint,
                      size: 20),
                  const SizedBox(height: 4),
                  Text(g.$2,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected ? g.$4 : context.textMuted),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalsGrid() {
    final goals = [
      _GoalData(Icons.local_fire_department_rounded, 'Calories',
          _user.dailyCalorieGoal.toStringAsFixed(0), 'kcal / day', AppColors.orange),
      _GoalData(Icons.water_drop_rounded, 'Water',
          _user.dailyWaterGoalLitres.toStringAsFixed(0), 'glasses / day', AppColors.blue),
      _GoalData(Icons.directions_walk_rounded, 'Steps',
          '${_user.dailyStepGoal}', 'steps / day', AppColors.green),
    ];
    return Column(children: goals.map(_goalCard).toList());
  }

  Widget _goalCard(_GoalData g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration(
        radius: BorderRadius.circular(16),
        extraShadow: [
          BoxShadow(
              color: g.color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: g.color.withOpacity(context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(g.icon, color: g.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.label,
                    style: TextStyle(fontSize: 12, color: context.textMuted)),
                const SizedBox(height: 2),
                Text(g.sub,
                    style: TextStyle(fontSize: 11, color: context.textHint)),
              ],
            ),
          ),
          Text(g.value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: g.color)),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    final tools = [
      _ToolData(Icons.qr_code_scanner_rounded, 'Food Scanner', 'Scan barcodes', AppRoutes.scanner, AppColors.primary),
      _ToolData(Icons.flash_on_rounded, 'TDEE Calculator', 'Daily energy needs', AppRoutes.tdee, Colors.redAccent),
      _ToolData(Icons.monitor_weight_rounded, 'Weight Tracker', 'Log your weight', AppRoutes.weight, Colors.teal),
      _ToolData(Icons.bar_chart_rounded, 'Progress', 'Weekly charts', AppRoutes.progress, Colors.purple),
      _ToolData(Icons.notifications_rounded, 'Reminders', 'Set meal alerts', AppRoutes.reminders, AppColors.orange),
      _ToolData(Icons.bluetooth_rounded, 'Connect Device', 'Sync wearable', AppRoutes.device, Colors.indigo),
    ];
    return Container(
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        children: tools.asMap().entries.map((e) {
          final t = e.value;
          final isLast = e.key == tools.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () => Navigator.pushNamed(context, t.route),
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(20))
                    : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: t.color.withOpacity(context.isDark ? 0.15 : 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(t.icon, color: t.color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: context.textPrimary)),
                            Text(t.subtitle,
                                style: TextStyle(
                                    fontSize: 11, color: context.textHint)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: context.textHint, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 70, color: context.divider),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _appBarIconBtn({
    required IconData icon, required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(context.isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _appBarPillBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF6BCB77),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(context.isDark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: color.withOpacity(context.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
      ],
    );
  }

  Widget _formCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(radius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.green),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _formField(
      TextEditingController ctrl, String hint, IconData icon,
      {bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(fontSize: 14, color: context.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: context.textHint),
        prefixIcon: Icon(icon, size: 18, color: AppColors.green),
        filled: true,
        fillColor: context.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: context.isDark
                ? BorderSide(color: context.mutedBorder, width: 1)
                : BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: context.isDark
                ? BorderSide(color: context.mutedBorder, width: 1)
                : BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: AppColors.green, width: 1.5)),
      ),
    );
  }

  Widget _genderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.inputFill,
        borderRadius: BorderRadius.circular(13),
        border: context.isDark
            ? Border.all(color: context.mutedBorder, width: 1)
            : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.wc_rounded, size: 18, color: Color(0xFF6BCB77)),
          const SizedBox(width: 4),
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
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

class _GoalData {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  const _GoalData(this.icon, this.label, this.value, this.sub, this.color);
}

class _ToolData {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final Color color;
  const _ToolData(this.icon, this.label, this.subtitle, this.route, this.color);
}
