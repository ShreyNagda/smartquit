import 'package:cloud_firestore/cloud_firestore.dart';

/// User statistics model tracking cessation progress.
class UserStats {
  final DateTime? lastSmokeTimestamp;
  final int cravingsBlocked;
  final int totalCravingsResisted;
  final int streakDays;
  final double healthRecoveryPercentage;
  final double moneySaved;
  final int cigarettesNotSmoked;
  final int totalInterventionsUsed;
  final Map<String, int> interventionBreakdown;

  const UserStats({
    this.lastSmokeTimestamp,
    this.cravingsBlocked = 0,
    this.totalCravingsResisted = 0,
    this.streakDays = 0,
    this.healthRecoveryPercentage = 0.0,
    this.moneySaved = 0.0,
    this.cigarettesNotSmoked = 0,
    this.totalInterventionsUsed = 0,
    this.interventionBreakdown = const {},
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      lastSmokeTimestamp: map['last_smoke_timestamp'] != null
          ? (map['last_smoke_timestamp'] as Timestamp).toDate()
          : null,
      cravingsBlocked: (map['cravings_blocked'] as num?)?.toInt() ?? 0,
      totalCravingsResisted:
          (map['total_cravings_resisted'] as num?)?.toInt() ?? 0,
      streakDays: (map['streak_days'] as num?)?.toInt() ?? 0,
      healthRecoveryPercentage:
          (map['health_recovery_percentage'] as num?)?.toDouble() ?? 0.0,
      moneySaved: (map['money_saved'] as num?)?.toDouble() ?? 0.0,
      cigarettesNotSmoked: (map['cigarettes_not_smoked'] as num?)?.toInt() ?? 0,
      totalInterventionsUsed:
          (map['total_interventions_used'] as num?)?.toInt() ?? 0,
      interventionBreakdown:
          Map<String, int>.from(map['intervention_breakdown'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'last_smoke_timestamp': lastSmokeTimestamp != null
          ? Timestamp.fromDate(lastSmokeTimestamp!)
          : null,
      'cravings_blocked': cravingsBlocked,
      'total_cravings_resisted': totalCravingsResisted,
      'streak_days': streakDays,
      'health_recovery_percentage': healthRecoveryPercentage,
      'money_saved': moneySaved,
      'cigarettes_not_smoked': cigarettesNotSmoked,
      'total_interventions_used': totalInterventionsUsed,
      'intervention_breakdown': interventionBreakdown,
    };
  }

  UserStats copyWith({
    DateTime? lastSmokeTimestamp,
    int? cravingsBlocked,
    int? totalCravingsResisted,
    int? streakDays,
    double? healthRecoveryPercentage,
    double? moneySaved,
    int? cigarettesNotSmoked,
    int? totalInterventionsUsed,
    Map<String, int>? interventionBreakdown,
  }) {
    return UserStats(
      lastSmokeTimestamp: lastSmokeTimestamp ?? this.lastSmokeTimestamp,
      cravingsBlocked: cravingsBlocked ?? this.cravingsBlocked,
      totalCravingsResisted:
          totalCravingsResisted ?? this.totalCravingsResisted,
      streakDays: streakDays ?? this.streakDays,
      healthRecoveryPercentage:
          healthRecoveryPercentage ?? this.healthRecoveryPercentage,
      moneySaved: moneySaved ?? this.moneySaved,
      cigarettesNotSmoked: cigarettesNotSmoked ?? this.cigarettesNotSmoked,
      totalInterventionsUsed:
          totalInterventionsUsed ?? this.totalInterventionsUsed,
      interventionBreakdown:
          interventionBreakdown ?? this.interventionBreakdown,
    );
  }
}

/// Health recovery milestones after quitting smoking.
class HealthMilestone {
  final String title;
  final String description;
  final Duration timeRequired;
  final String icon;

  const HealthMilestone({
    required this.title,
    required this.description,
    required this.timeRequired,
    required this.icon,
  });

  static const List<HealthMilestone> milestones = [
    HealthMilestone(
      title: 'Heart Rate Normalizes',
      description: 'Your heart rate drops to a normal level.',
      timeRequired: Duration(minutes: 20),
      icon: '❤️',
    ),
    HealthMilestone(
      title: 'CO Levels Drop',
      description: 'Carbon monoxide in blood drops to normal.',
      timeRequired: Duration(hours: 12),
      icon: '🫁',
    ),
    HealthMilestone(
      title: 'Circulation Improves',
      description: 'Your blood circulation begins to improve.',
      timeRequired: Duration(days: 14),
      icon: '🩸',
    ),
    HealthMilestone(
      title: 'Lung Function Increases',
      description: 'Lung function increases up to 30%.',
      timeRequired: Duration(days: 90),
      icon: '💨',
    ),
    HealthMilestone(
      title: 'Coughing Decreases',
      description: 'Coughing and shortness of breath decrease.',
      timeRequired: Duration(days: 270),
      icon: '🌬️',
    ),
    HealthMilestone(
      title: 'Heart Disease Risk Halved',
      description: 'Risk of coronary heart disease is half that of a smoker.',
      timeRequired: Duration(days: 365),
      icon: '🏥',
    ),
    HealthMilestone(
      title: 'Stroke Risk Reduced',
      description: 'Risk of stroke reduced to that of a non-smoker.',
      timeRequired: Duration(days: 1825),
      icon: '🧠',
    ),
    HealthMilestone(
      title: 'Lung Cancer Risk Halved',
      description: 'Risk of lung cancer drops to about half.',
      timeRequired: Duration(days: 3650),
      icon: '🎗️',
    ),
  ];
}
