import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a supporter (family member/friend) in "The Circle."
class SupporterModel {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? fcmToken;
  final DateTime joinedAt;
  final SupporterRole role;

  const SupporterModel({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.fcmToken,
    required this.joinedAt,
    this.role = SupporterRole.supporter,
  });

  factory SupporterModel.fromMap(Map<String, dynamic> map, String docId) {
    return SupporterModel(
      uid: docId,
      displayName: map['display_name'] as String? ?? 'Supporter',
      photoUrl: map['photo_url'] as String?,
      fcmToken: map['fcm_token'] as String?,
      joinedAt: (map['joined_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: SupporterRole.fromString(map['role'] as String? ?? 'supporter'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'photo_url': photoUrl,
      'fcm_token': fcmToken,
      'joined_at': Timestamp.fromDate(joinedAt),
      'role': role.value,
    };
  }
}

enum SupporterRole {
  user('user'),
  supporter('supporter');

  final String value;
  const SupporterRole(this.value);

  static SupporterRole fromString(String value) {
    return SupporterRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SupporterRole.supporter,
    );
  }
}

/// Privacy sharing preferences for The Circle.
class PrivacySettings {
  final bool shareStreak;
  final bool shareMoneySaved;
  final bool shareJournalEntries;
  final bool sharePanicAlerts;
  final bool shareHealthProgress;

  const PrivacySettings({
    this.shareStreak = true,
    this.shareMoneySaved = true,
    this.shareJournalEntries = false,
    this.sharePanicAlerts = true,
    this.shareHealthProgress = true,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      shareStreak: map['share_streak'] as bool? ?? true,
      shareMoneySaved: map['share_money_saved'] as bool? ?? true,
      shareJournalEntries: map['share_journal_entries'] as bool? ?? false,
      sharePanicAlerts: map['share_panic_alerts'] as bool? ?? true,
      shareHealthProgress: map['share_health_progress'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'share_streak': shareStreak,
      'share_money_saved': shareMoneySaved,
      'share_journal_entries': shareJournalEntries,
      'share_panic_alerts': sharePanicAlerts,
      'share_health_progress': shareHealthProgress,
    };
  }

  PrivacySettings copyWith({
    bool? shareStreak,
    bool? shareMoneySaved,
    bool? shareJournalEntries,
    bool? sharePanicAlerts,
    bool? shareHealthProgress,
  }) {
    return PrivacySettings(
      shareStreak: shareStreak ?? this.shareStreak,
      shareMoneySaved: shareMoneySaved ?? this.shareMoneySaved,
      shareJournalEntries: shareJournalEntries ?? this.shareJournalEntries,
      sharePanicAlerts: sharePanicAlerts ?? this.sharePanicAlerts,
      shareHealthProgress: shareHealthProgress ?? this.shareHealthProgress,
    );
  }

  /// Quick presets for privacy
  static const PrivacySettings streaksOnly = PrivacySettings(
    shareStreak: true,
    shareMoneySaved: false,
    shareJournalEntries: false,
    sharePanicAlerts: false,
    shareHealthProgress: false,
  );

  static const PrivacySettings shareAll = PrivacySettings(
    shareStreak: true,
    shareMoneySaved: true,
    shareJournalEntries: true,
    sharePanicAlerts: true,
    shareHealthProgress: true,
  );
}

/// A nudge message sent from a supporter.
class NudgeMessage {
  final String fromUid;
  final String fromName;
  final String emoji;
  final String message;
  final DateTime sentAt;

  const NudgeMessage({
    required this.fromUid,
    required this.fromName,
    this.emoji = '💪',
    this.message = 'You got this!',
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'from_uid': fromUid,
      'from_name': fromName,
      'emoji': emoji,
      'message': message,
      'sent_at': Timestamp.fromDate(sentAt),
    };
  }

  factory NudgeMessage.fromMap(Map<String, dynamic> map) {
    return NudgeMessage(
      fromUid: map['from_uid'] as String? ?? '',
      fromName: map['from_name'] as String? ?? 'Supporter',
      emoji: map['emoji'] as String? ?? '💪',
      message: map['message'] as String? ?? 'You got this!',
      sentAt: (map['sent_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
