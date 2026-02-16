import 'package:cloud_firestore/cloud_firestore.dart';
import 'supporter_model.dart';
import 'stats_model.dart';

/// Core user model matching the Firestore schema.
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String supportCode; // Unique 6-digit "BF-XXXX" code
  final List<String> supporterUids;
  final List<String> supportingUids; // Users this person supports
  final UserStats stats;
  final PrivacySettings privacySettings;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime? quitDate;
  final String? fcmToken;
  final SupporterRole role;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.supportCode,
    this.supporterUids = const [],
    this.supportingUids = const [],
    this.stats = const UserStats(),
    this.privacySettings = const PrivacySettings(),
    this.preferences = const UserPreferences(),
    required this.createdAt,
    this.quitDate,
    this.fcmToken,
    this.role = SupporterRole.user,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      displayName: map['display_name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      supportCode: map['support_code'] as String? ?? '',
      supporterUids: List<String>.from(map['supporters'] ?? []),
      supportingUids: List<String>.from(map['supporting'] ?? []),
      stats: UserStats.fromMap(map['stats'] as Map<String, dynamic>? ?? {}),
      privacySettings: PrivacySettings.fromMap(
          map['privacy_settings'] as Map<String, dynamic>? ?? {}),
      preferences: UserPreferences.fromMap(
          map['preferences'] as Map<String, dynamic>? ?? {}),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quitDate: map['quit_date'] != null
          ? (map['quit_date'] as Timestamp).toDate()
          : null,
      fcmToken: map['fcm_token'] as String?,
      role: SupporterRole.fromString(map['role'] as String? ?? 'user'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'email': email,
      'photo_url': photoUrl,
      'support_code': supportCode,
      'supporters': supporterUids,
      'supporting': supportingUids,
      'stats': stats.toMap(),
      'privacy_settings': privacySettings.toMap(),
      'preferences': preferences.toMap(),
      'created_at': Timestamp.fromDate(createdAt),
      'quit_date': quitDate != null ? Timestamp.fromDate(quitDate!) : null,
      'fcm_token': fcmToken,
      'role': role.value,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? supportCode,
    List<String>? supporterUids,
    List<String>? supportingUids,
    UserStats? stats,
    PrivacySettings? privacySettings,
    UserPreferences? preferences,
    DateTime? quitDate,
    String? fcmToken,
    SupporterRole? role,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      supportCode: supportCode ?? this.supportCode,
      supporterUids: supporterUids ?? this.supporterUids,
      supportingUids: supportingUids ?? this.supportingUids,
      stats: stats ?? this.stats,
      privacySettings: privacySettings ?? this.privacySettings,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      quitDate: quitDate ?? this.quitDate,
      fcmToken: fcmToken ?? this.fcmToken,
      role: role ?? this.role,
    );
  }

  /// Calculate current streak days from last smoke timestamp.
  int get currentStreakDays {
    final reference = stats.lastSmokeTimestamp ?? quitDate ?? createdAt;
    return DateTime.now().difference(reference).inDays;
  }

  /// Calculate money saved based on user preferences.
  double get calculatedMoneySaved {
    final perDay = preferences.cigarettesPerDay * preferences.pricePerCigarette;
    return currentStreakDays * perDay;
  }

  /// Calculate cigarettes not smoked.
  int get calculatedCigarettesNotSmoked {
    return currentStreakDays * preferences.cigarettesPerDay;
  }
}

/// User-configurable preferences.
class UserPreferences {
  final int cigarettesPerDay;
  final double pricePerCigarette;
  final String currency;
  final bool hapticFeedback;
  final bool dailyReminders;
  final int reminderHour;
  final int reminderMinute;
  final List<String> selectedInterventions;

  const UserPreferences({
    this.cigarettesPerDay = 20,
    this.pricePerCigarette = 0.50,
    this.currency = '₹',
    this.hapticFeedback = true,
    this.dailyReminders = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.selectedInterventions = const [],
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      cigarettesPerDay: (map['cigarettes_per_day'] as num?)?.toInt() ?? 20,
      pricePerCigarette: (map['price_per_cigarette'] as num?)?.toDouble() ?? 10,
      currency: map['currency'] as String? ?? '₹',
      hapticFeedback: map['haptic_feedback'] as bool? ?? true,
      dailyReminders: map['daily_reminders'] as bool? ?? true,
      reminderHour: (map['reminder_hour'] as num?)?.toInt() ?? 9,
      reminderMinute: (map['reminder_minute'] as num?)?.toInt() ?? 0,
      selectedInterventions: (map['selected_interventions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cigarettes_per_day': cigarettesPerDay,
      'price_per_cigarette': pricePerCigarette,
      'currency': currency,
      'haptic_feedback': hapticFeedback,
      'daily_reminders': dailyReminders,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'selected_interventions': selectedInterventions,
    };
  }

  UserPreferences copyWith({
    int? cigarettesPerDay,
    double? pricePerCigarette,
    String? currency,
    bool? hapticFeedback,
    bool? dailyReminders,
    int? reminderHour,
    int? reminderMinute,
    List<String>? selectedInterventions,
  }) {
    return UserPreferences(
      cigarettesPerDay: cigarettesPerDay ?? this.cigarettesPerDay,
      pricePerCigarette: pricePerCigarette ?? this.pricePerCigarette,
      currency: currency ?? this.currency,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      selectedInterventions:
          selectedInterventions ?? this.selectedInterventions,
    );
  }
}
