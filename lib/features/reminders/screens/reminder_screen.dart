import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/n_theme.dart';
import '../services/reminder_service.dart';
import '../widgets/reminder_card.dart';
import '../widgets/tone_picker.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ReminderService _service = ReminderService();
  String _selectedTone = 'default';

  @override
  void initState() {
    super.initState();
    _service.init();
  }

  void _showTimePicker({
    required String reminderKey,
    required String title,
    required String body,
    required IconData icon,
    required Color color,
  }) {
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Set $title',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ctx.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Time selector
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ctx.inputFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: ctx.isDark
                                  ? ctx.mutedBorder
                                  : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: Color(0xFF6BCB77)),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime.format(ctx),
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: ctx.textPrimary),
                            ),
                            const Spacer(),
                            Text('Tap to change',
                                style: TextStyle(
                                    fontSize: 12, color: ctx.textHint)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tone picker
                    TonePicker(
                      selectedTone: _selectedTone,
                      onSelected: (t) {
                        setModalState(() => _selectedTone = t);
                        setState(() => _selectedTone = t);
                        _service.previewTone(t);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Set button
                    GestureDetector(
                      onTap: () {
                        final now = DateTime.now();
                        var scheduledTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        if (scheduledTime.isBefore(now)) {
                          scheduledTime =
                              scheduledTime.add(const Duration(days: 1));
                        }
                        _service.scheduleReminder(
                          reminderKey: reminderKey,
                          title: title,
                          body: body,
                          time: scheduledTime,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '$title set for ${selectedTime.format(context)}'),
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Center(
                          child: Text('Set Reminder',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('Reminders',
            style: TextStyle(color: context.textPrimary)),
        backgroundColor: context.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: context.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Reminders',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary)),
            const SizedBox(height: 4),
            Text(
              'Set daily reminders with custom tones and popup alerts.',
              style: TextStyle(fontSize: 13, color: context.textMuted),
            ),
            const SizedBox(height: 20),

            ReminderCard(
              title: 'Water Reminder',
              subtitle: 'Stay hydrated throughout the day',
              icon: Icons.water_drop_rounded,
              color: AppColors.blue,
              onSet: () => _showTimePicker(
                reminderKey: 'water',
                title: 'Water Reminder',
                body: 'Time to drink water! Stay hydrated.',
                icon: Icons.water_drop_rounded,
                color: AppColors.blue,
              ),
            ),

            ReminderCard(
              title: 'Breakfast',
              subtitle: "Don't skip the most important meal",
              icon: Icons.free_breakfast_rounded,
              color: AppColors.orange,
              onSet: () => _showTimePicker(
                reminderKey: 'breakfast',
                title: 'Breakfast Time',
                body: 'Good morning! Time for a healthy breakfast.',
                icon: Icons.free_breakfast_rounded,
                color: AppColors.orange,
              ),
            ),

            ReminderCard(
              title: 'Lunch',
              subtitle: 'Midday fuel for your body',
              icon: Icons.lunch_dining_rounded,
              color: AppColors.green,
              onSet: () => _showTimePicker(
                reminderKey: 'lunch',
                title: 'Lunch Time',
                body: "Lunchtime! Don't forget your midday meal.",
                icon: Icons.lunch_dining_rounded,
                color: AppColors.green,
              ),
            ),

            ReminderCard(
              title: 'Dinner',
              subtitle: 'End your day with a balanced meal',
              icon: Icons.dinner_dining_rounded,
              color: const Color(0xFF9C6FDE),
              onSet: () => _showTimePicker(
                reminderKey: 'dinner',
                title: 'Dinner Time',
                body: 'Dinner time! Enjoy a balanced evening meal.',
                icon: Icons.dinner_dining_rounded,
                color: const Color(0xFF9C6FDE),
              ),
            ),

            ReminderCard(
              title: 'Step Goal Check',
              subtitle: 'Daily activity progress reminder',
              icon: Icons.directions_walk_rounded,
              color: AppColors.primary,
              onSet: () => _showTimePicker(
                reminderKey: 'steps',
                title: 'Step Check',
                body: 'How are your steps today? Keep moving!',
                icon: Icons.directions_walk_rounded,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            // Test notification button
            GestureDetector(
              onTap: () {
                _service.showInstantReminder(
                  'Test Notification',
                  'Your NUTRIFY reminders are working perfectly!',
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: context.cardDecoration(
                    radius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_active_rounded,
                        color: context.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Send Test Notification',
                      style: TextStyle(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
