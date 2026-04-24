import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Handles scheduling of daily reminders with optional tone preview.
class ReminderService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Notification IDs for each reminder type
  static const int _waterId   = 10;
  static const int _breakfastId = 11;
  static const int _lunchId   = 12;
  static const int _dinnerId  = 13;
  static const int _stepsId   = 14;

  // ── Channels (one per reminder type so icons/colors differ) ──────────────

  static const _channels = {
    'water':     AndroidNotificationChannel('nutrify_water',     'Water Reminder',    description: 'Hydration reminder', importance: Importance.high),
    'breakfast': AndroidNotificationChannel('nutrify_breakfast', 'Breakfast Reminder',description: 'Breakfast time reminder', importance: Importance.high),
    'lunch':     AndroidNotificationChannel('nutrify_lunch',     'Lunch Reminder',    description: 'Lunch time reminder', importance: Importance.high),
    'dinner':    AndroidNotificationChannel('nutrify_dinner',    'Dinner Reminder',   description: 'Dinner time reminder', importance: Importance.high),
    'steps':     AndroidNotificationChannel('nutrify_steps',     'Steps Reminder',    description: 'Step goal reminder', importance: Importance.high),
  };

  static const _ids = {
    'water': _waterId, 'breakfast': _breakfastId,
    'lunch': _lunchId, 'dinner': _dinnerId, 'steps': _stepsId,
  };

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create all channels
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    for (final ch in _channels.values) {
      await android?.createNotificationChannel(ch);
    }
  }

  // ── Show instant notification (for test button) ───────────────────────────

  Future<void> showInstantReminder(String title, String body) async {
    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nutrify_main',
          'Nutrify Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Schedule a daily reminder ─────────────────────────────────────────────

  Future<void> scheduleReminder({
    required String reminderKey,  // 'water','breakfast','lunch','dinner','steps'
    required String title,
    required String body,
    required DateTime time,
  }) async {
    final channel = _channels[reminderKey] ?? _channels['water']!;
    final id      = _ids[reminderKey] ?? _waterId;

    // Build a TZDateTime for today at the chosen time (or tomorrow if past)
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      time.hour, time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  // ── Cancel a specific reminder ────────────────────────────────────────────

  Future<void> cancelReminder(String reminderKey) async {
    final id = _ids[reminderKey];
    if (id != null) await _plugin.cancel(id);
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Preview a tone using audioplayers ────────────────────────────────────

  Future<void> previewTone(String toneId) async {
    if (toneId == 'silent') return;
    final player = AudioPlayer();
    try {
      // Map tone IDs to asset files
      final assetMap = {
        'chime': 'sounds/chime.mp3',
        'water': 'sounds/water.mp3',
        'bell':  'sounds/bell.mp3',
        'beep':  'sounds/beep.mp3',
      };
      final asset = assetMap[toneId];
      if (asset != null) {
        await player.play(AssetSource(asset));
      }
    } catch (_) {
      // Sound file missing — silently ignore
    }
  }
}
