import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles FCM push notifications for nudges, panic alerts, and reminders.
class NotificationService {
  static const int _dailyReminderId = 1001;
  static const String _dailyReminderEnabledKey = 'daily_reminder_enabled_local';
  static const String _dailyReminderHourKey = 'daily_reminder_hour_local';
  static const String _dailyReminderMinuteKey = 'daily_reminder_minute_local';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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

    await _initializeLocalNotifications();
    await _scheduleFromStoredPreferences();

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
        // Show generic notification if it has a notification payload
        if (message.notification != null) {
          _showLocalNotification(
            title: message.notification!.title ?? 'BreatheFree',
            body: message.notification!.body ?? '',
            payload: data['route'] as String?,
          );
        }
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
    
    // Show local notification for nudges
    _showLocalNotification(
      title: '$emoji Strength from $fromName',
      body: nudgeMessage,
      channelId: 'nudge_channel',
      channelName: 'Nudges & Support',
      channelDescription: 'Notifications when someone sends you strength',
      payload: '/home',
    );
  }

  void _handlePanicAlert(Map<String, dynamic> data) {
    final userName = data['user_name'] ?? 'Your loved one';
    debugPrint('Panic alert: $userName needs support');
    
    // Show local notification for panic alerts
    _showLocalNotification(
      title: '🆘 $userName needs support',
      body: 'They hit the panic button. Send some strength!',
      channelId: 'panic_channel',
      channelName: 'Panic Alerts',
      channelDescription: 'Urgent alerts when someone needs support',
      payload: '/circle',
    );
  }

  void _handleDailyReminder(Map<String, dynamic> data) {
    debugPrint('Daily reminder received');
    _showLocalNotification(
      title: 'Quick check-in',
      body: 'Log any event or open BreatheFree to stay on track.',
      payload: '/journal/new',
    );
  }

  void _handleMilestoneNotification(Map<String, dynamic> data) {
    final milestone = data['milestone'] ?? 'a milestone';
    debugPrint('Milestone reached: $milestone');
    
    _showLocalNotification(
      title: '🎉 Milestone Achieved!',
      body: milestone,
      channelId: 'milestone_channel',
      channelName: 'Milestones',
      channelDescription: 'Celebrations when you reach health milestones',
      payload: '/stats',
    );
  }

  /// Show a local notification immediately
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
    String channelName = 'General',
    String channelDescription = 'General notifications',
  }) async {
    debugPrint('Showing notification: $title - $body');
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    debugPrint('Notification ID: $notificationId');

    try {
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        payload: payload,
      );
      debugPrint('Notification shown successfully');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // ─── Local Daily Reminder Scheduling ──────────────────────────

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );

    // Create notification channels on Android
    await _createNotificationChannels();

    tz.initializeTimeZones();
    try {
      String timezoneName = await FlutterTimezone.getLocalTimezone();

      // Handle deprecated timezone names
      final timezoneMapping = {
        'Asia/Calcutta': 'Asia/Kolkata',
        'US/Eastern': 'America/New_York',
        'US/Pacific': 'America/Los_Angeles',
        'US/Central': 'America/Chicago',
        'US/Mountain': 'America/Denver',
      };

      if (timezoneMapping.containsKey(timezoneName)) {
        timezoneName = timezoneMapping[timezoneName]!;
      }

      tz.setLocalLocation(tz.getLocation(timezoneName));
      debugPrint('Timezone set to: $timezoneName');
    } catch (e) {
      debugPrint('Could not detect local timezone. Falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    await _requestLocalNotificationPermission();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    // Create all notification channels
    final channels = [
      const AndroidNotificationChannel(
        'default_channel',
        'General',
        description: 'General notifications',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'nudge_channel',
        'Nudges & Support',
        description: 'Notifications when someone sends you strength',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'panic_channel',
        'Panic Alerts',
        description: 'Urgent alerts when someone needs support',
        importance: Importance.max,
      ),
      const AndroidNotificationChannel(
        'milestone_channel',
        'Milestones',
        description: 'Celebrations when you reach health milestones',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'daily_reminder_channel',
        'Daily Check-in Reminders',
        description: 'Daily reminders to log events and open the app',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'journal_followup_channel',
        'Journal Follow-ups',
        description: 'Motivational messages based on your journal entries',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
    debugPrint('Notification channels created');
  }

  Future<void> _requestLocalNotificationPermission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('Android notification permission granted: $granted');
    }

    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _scheduleFromStoredPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_dailyReminderEnabledKey) ?? true;
    final hour = prefs.getInt(_dailyReminderHourKey) ?? 9;
    final minute = prefs.getInt(_dailyReminderMinuteKey) ?? 0;

    await syncDailyReminderSettings(
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
  }

  Future<void> syncDailyReminderSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, enabled);
    await prefs.setInt(_dailyReminderHourKey, hour);
    await prefs.setInt(_dailyReminderMinuteKey, minute);

    await _requestLocalNotificationPermission();
    await _localNotifications.cancel(_dailyReminderId);

    if (!enabled) {
      debugPrint('Daily reminder disabled');
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    debugPrint('Scheduling daily reminder for: $scheduled (now: $now)');

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Check-in Reminders',
      channelDescription: 'Daily reminders to log events and open the app',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _localNotifications.zonedSchedule(
        _dailyReminderId,
        'Quick check-in',
        'Log any event or open BreatheFree to stay on track.',
        scheduled,
        const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/journal/new',
      );
      debugPrint('zonedSchedule called successfully');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }

    final pending = await _localNotifications.pendingNotificationRequests();
    debugPrint(
      'Daily reminder scheduled for $hour:$minute, pending=${pending.length}',
    );
    for (final p in pending) {
      debugPrint('  Pending: id=${p.id}, title=${p.title}');
    }
  }

  // Future<void> _scheduleDailyReminder({
  //   required int hour,
  //   required int minute,
  // }) async {
  //   await _localNotifications.cancel(_dailyReminderId);

  //   final now = tz.TZDateTime.now(tz.local);
  //   var scheduled =
  //       tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

  //   if (scheduled.isBefore(now)) {
  //     scheduled = scheduled.add(const Duration(days: 1));
  //   }

  //   const androidDetails = AndroidNotificationDetails(
  //     'daily_reminder_channel',
  //     'Daily Check-in Reminders',
  //     channelDescription: 'Daily reminders to log events and open the app',
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     playSound: true,
  //   );

  //   const darwinDetails = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );

  //   const details = NotificationDetails(
  //     android: androidDetails,
  //     iOS: darwinDetails,
  //     macOS: darwinDetails,
  //   );

  //   await _localNotifications.zonedSchedule(
  //     _dailyReminderId,
  //     'Quick check-in',
  //     'Log any smoking event or open BreatheFree to stay on track.',
  //     scheduled,
  //     details,
  //     androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  //     uiLocalNotificationDateInterpretation:
  //         UILocalNotificationDateInterpretation.absoluteTime,
  //     matchDateTimeComponents: DateTimeComponents.time,
  //     payload: '/journal/new',
  //   );

  //   debugPrint('Daily reminder scheduled for $hour:$minute');
  // }

  // ─── Send Notification Payloads (for Cloud Functions) ─────────

  /// Test method to verify notifications are working
  Future<void> showTestNotification() async {
    debugPrint('Triggering test notification...');
    await _showLocalNotification(
      title: '🧪 Test Notification',
      body: 'If you see this, notifications are working!',
      channelId: 'default_channel',
      channelName: 'General',
      channelDescription: 'General notifications',
    );
  }

  /// Test scheduled notification - triggers in 10 seconds
  Future<void> showTestScheduledNotification() async {
    debugPrint('Scheduling test notification for 10 seconds from now...');
    
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    debugPrint('Scheduled time: $scheduled');
    
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _localNotifications.zonedSchedule(
        9999, // Test ID
        '⏰ Scheduled Test',
        'This notification was scheduled 10 seconds ago!',
        scheduled,
        const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '/home',
      );
      debugPrint('Test scheduled notification set successfully');
      
      final pending = await _localNotifications.pendingNotificationRequests();
      debugPrint('Pending notifications: ${pending.length}');
      for (final p in pending) {
        debugPrint('  id=${p.id}, title=${p.title}');
      }
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
    }
  }

  /// Show a nudge notification locally (call this when nudge is received via Firestore)
  Future<void> showNudgeNotification({
    required String fromName,
    String emoji = '💪',
    String message = 'You got this!',
  }) async {
    await _showLocalNotification(
      title: '$emoji Strength from $fromName',
      body: message,
      channelId: 'nudge_channel',
      channelName: 'Nudges & Support',
      channelDescription: 'Notifications when someone sends you strength',
      payload: '/home',
    );
  }

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

  Future<void> schedulePostLoginJournalReminder() async {
    const int postLoginReminderId = 1002;
    await _localNotifications.cancel(postLoginReminderId);

    final scheduled =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5));

    const androidDetails = AndroidNotificationDetails(
      'post_login_reminder_channel',
      'Login Reminders',
      channelDescription: 'Reminder to log an entry after login',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.zonedSchedule(
      postLoginReminderId,
      'Welcome back!',
      'Take 30 seconds to log your latest moment in the journal.',
      scheduled,
      const NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/journal/new',
    );
  }

  /// Schedule a motivational notification based on journal entry type
  /// Relapse: shows immediately, Others: 30 minutes later
  Future<void> scheduleJournalFollowUp({
    required String entryType,
    String? triggerType,
  }) async {
    // Cancel any existing journal follow-up
    const int journalFollowUpId = 1003;
    await _localNotifications.cancel(journalFollowUpId);
    
    // Select message based on entry type
    String title;
    String body;
    
    switch (entryType) {
      case 'relapse':
        const messages = _relapseMessages;
        final random = DateTime.now().millisecondsSinceEpoch % messages.length;
        title = messages[random]['title']!;
        body = messages[random]['body']!;
        break;
      case 'craving':
        const messages = _cravingMessages;
        final random = DateTime.now().millisecondsSinceEpoch % messages.length;
        title = messages[random]['title']!;
        body = messages[random]['body']!;
        break;
      case 'nearMiss':
        const messages = _nearMissMessages;
        final random = DateTime.now().millisecondsSinceEpoch % messages.length;
        title = messages[random]['title']!;
        body = messages[random]['body']!;
        break;
      case 'milestone':
        const messages = _milestoneMessages;
        final random = DateTime.now().millisecondsSinceEpoch % messages.length;
        title = messages[random]['title']!;
        body = messages[random]['body']!;
        break;
      default:
        title = '💚 You\'re doing great!';
        body = 'Every moment smoke-free is a victory. Keep going!';
    }

    // For relapse, show notification immediately
    if (entryType == 'relapse') {
      debugPrint('Showing immediate relapse support notification');
      await _showLocalNotification(
        title: title,
        body: body,
        channelId: 'journal_followup_channel',
        channelName: 'Journal Follow-ups',
        channelDescription: 'Motivational messages based on your journal entries',
        payload: '/journal',
      );
      return;
    }

    // For other entry types, schedule for 30 minutes later
    final scheduled =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 30));

    debugPrint('Scheduling journal follow-up for $entryType in 30 minutes');

    const androidDetails = AndroidNotificationDetails(
      'journal_followup_channel',
      'Journal Follow-ups',
      channelDescription: 'Motivational messages based on your journal entries',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _localNotifications.zonedSchedule(
        journalFollowUpId,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
          macOS: darwinDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '/journal',
      );
      debugPrint('Journal follow-up scheduled for: $scheduled');
    } catch (e) {
      debugPrint('Error scheduling journal follow-up: $e');
    }
  }

  // Motivational messages for different entry types
  static const List<Map<String, String>> _relapseMessages = [
    {
      'title': '💪 One slip doesn\'t define you',
      'body': 'Recovery isn\'t linear. What matters is that you\'re still trying. You\'ve got this!',
    },
    {
      'title': '🌱 Growth comes from setbacks',
      'body': 'Every relapse teaches us something. What did you learn today? Use it to grow stronger.',
    },
    {
      'title': '❤️ Be kind to yourself',
      'body': 'Quitting is hard. The fact that you logged this shows commitment. Tomorrow is a new day.',
    },
    {
      'title': '🔄 Reset, don\'t restart',
      'body': 'Your progress isn\'t erased. Every smoke-free moment still counts. Keep moving forward.',
    },
    {
      'title': '🎯 Focus on the next choice',
      'body': 'You can\'t change the past, but the next craving? That\'s your chance to win.',
    },
  ];

  static const List<Map<String, String>> _cravingMessages = [
    {
      'title': '🏆 You resisted! Amazing!',
      'body': 'That craving you beat? Your brain is literally rewiring itself. Keep it up!',
    },
    {
      'title': '💎 Willpower level: Expert',
      'body': 'You felt the urge and said NO. That takes real strength. Proud of you!',
    },
    {
      'title': '🧠 Your brain thanks you',
      'body': 'Every craving you resist makes the next one easier. You\'re building new neural pathways!',
    },
    {
      'title': '⚡ That was impressive!',
      'body': 'Cravings are temporary, but your victory is permanent. Well done!',
    },
  ];

  static const List<Map<String, String>> _nearMissMessages = [
    {
      'title': '😮‍💨 Close call, but you made it!',
      'body': 'Being honest about near misses shows real self-awareness. That\'s key to success.',
    },
    {
      'title': '🛡️ Your defenses held',
      'body': 'It was close, but you pulled through. What helped you resist? Remember that for next time.',
    },
    {
      'title': '🌟 Stronger than you think',
      'body': 'A near miss is still a WIN. You faced the hardest moment and came out on top.',
    },
  ];

  static const List<Map<String, String>> _milestoneMessages = [
    {
      'title': '🎉 Milestone achieved!',
      'body': 'You\'re making history - YOUR history. Each milestone is proof of your strength.',
    },
    {
      'title': '🌟 Look how far you\'ve come!',
      'body': 'Remember when this seemed impossible? You\'re living proof it\'s not.',
    },
    {
      'title': '🏅 Champion status!',
      'body': 'Milestones aren\'t luck - they\'re the result of daily choices. You earned this!',
    },
  ];

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
