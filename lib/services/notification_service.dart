import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles FCM push notifications for nudges, panic alerts, and reminders.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize notification permissions and handlers.
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened via notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }

  /// Get the current FCM token.
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Stream of token refreshes.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Subscribe to a topic.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // ─── Message Handlers ─────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    final data = message.data;
    final type = data['type'] as String?;

    switch (type) {
      case 'nudge':
        _handleNudgeNotification(data);
        break;
      case 'panic_alert':
        _handlePanicAlert(data);
        break;
      case 'daily_reminder':
        _handleDailyReminder(data);
        break;
      case 'milestone':
        _handleMilestoneNotification(data);
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened via notification: ${message.data}');
    // Navigation logic handled by the app's routing
  }

  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('Initial message: ${message.data}');
  }

  void _handleNudgeNotification(Map<String, dynamic> data) {
    final fromName = data['from_name'] ?? 'Someone';
    final emoji = data['emoji'] ?? '💪';
    final nudgeMessage = data['message'] ?? 'You got this!';
    debugPrint('Nudge from $fromName: $emoji $nudgeMessage');
  }

  void _handlePanicAlert(Map<String, dynamic> data) {
    final userName = data['user_name'] ?? 'Your loved one';
    debugPrint('Panic alert: $userName needs support');
  }

  void _handleDailyReminder(Map<String, dynamic> data) {
    debugPrint('Daily reminder received');
  }

  void _handleMilestoneNotification(Map<String, dynamic> data) {
    final milestone = data['milestone'] ?? 'a milestone';
    debugPrint('Milestone reached: $milestone');
  }

  // ─── Send Notification Payloads (for Cloud Functions) ─────────

  /// Build a nudge notification payload.
  static Map<String, dynamic> buildNudgePayload({
    required String targetToken,
    required String fromName,
    String emoji = '💪',
    String message = 'You got this!',
  }) {
    return {
      'to': targetToken,
      'priority': 'high',
      'notification': {
        'title': '$emoji Strength from $fromName',
        'body': message,
        'sound': 'default',
      },
      'data': {
        'type': 'nudge',
        'from_name': fromName,
        'emoji': emoji,
        'message': message,
      },
    };
  }

  /// Build a panic alert notification payload.
  static Map<String, dynamic> buildPanicAlertPayload({
    required String targetToken,
    required String userName,
  }) {
    return {
      'to': targetToken,
      'priority': 'high',
      'notification': {
        'title': '🆘 $userName needs support',
        'body': 'They hit the panic button. Send some strength!',
        'sound': 'default',
      },
      'data': {
        'type': 'panic_alert',
        'user_name': userName,
      },
    };
  }
}

/// Background message handler (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}
