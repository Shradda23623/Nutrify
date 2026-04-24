import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

// ── Background message handler (top-level function required by FCM) ───────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart before this runs.
  // Show a local notification for the background message.
  await NotificationService._showLocal(
    id:    message.hashCode,
    title: message.notification?.title ?? 'Nutrify',
    body:  message.notification?.body  ?? '',
  );
}

/// Manages both FCM (push) and flutter_local_notifications (on-device).
class NotificationService {
  static final _fcm   = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  // ── Android channel ────────────────────────────────────────────────────────
  static const _channel = AndroidNotificationChannel(
    'nutrify_main',
    'Nutrify Notifications',
    description: 'Reminders and health tips from Nutrify',
    importance: Importance.high,
  );

  // ── Initialize (called once in main()) ────────────────────────────────────

  static Future<void> initialize() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request iOS / Android 13+ permission
    await _fcm.requestPermission(
      alert:      true,
      badge:      true,
      sound:      true,
      provisional: false,
    );

    // 3. Init local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // 4. Create Android notification channel
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 5. Handle foreground FCM messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocal(
        id:    message.hashCode,
        title: message.notification?.title ?? 'Nutrify',
        body:  message.notification?.body  ?? '',
      );
    });

    // 6. Save FCM token to Firestore so backend can target this device
    _fcm.getToken().then(_saveFcmToken);
    _fcm.onTokenRefresh.listen(_saveFcmToken);
  }

  // ── Save FCM token ────────────────────────────────────────────────────────

  static Future<void> _saveFcmToken(String? token) async {
    if (token == null) return;
    try {
      await FirestoreService.userDoc.set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastSeen':  FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // User may not be logged in yet — token will be saved after login.
    }
  }

  // ── Show a local notification ─────────────────────────────────────────────

  static Future<void> _showLocal({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority:   Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ── Public: show notification manually ────────────────────────────────────

  static Future<void> showNotification({
    required int    id,
    required String title,
    required String body,
    String? payload,
  }) => _showLocal(id: id, title: title, body: body, payload: payload);

  // ── Schedule a local notification ─────────────────────────────────────────

  static Future<void> scheduleNotification({
    required int           id,
    required String        title,
    required String        body,
    required DateTime      scheduledDate,
    String?                payload,
  }) async {
    await _local.zonedSchedule(
      id,
      title,
      body,
      scheduledDate.toUtc() as dynamic, // TZDateTime in real usage
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority:   Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel a notification ─────────────────────────────────────────────────

  static Future<void> cancel(int id) => _local.cancel(id);
  static Future<void> cancelAll()    => _local.cancelAll();

  // ── Subscribe / unsubscribe to topics ────────────────────────────────────

  static Future<void> subscribeToTopic(String topic) =>
      _fcm.subscribeToTopic(topic);

  static Future<void> unsubscribeFromTopic(String topic) =>
      _fcm.unsubscribeFromTopic(topic);

  // ── Handle tap on local notification ─────────────────────────────────────

  static void _onLocalTap(NotificationResponse response) {
    // Navigate based on payload if needed.
    // Example: if (response.payload == 'water') navigate to water screen.
  }
}
