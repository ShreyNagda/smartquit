import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for AI-generated insights based on journal entries
class AIInsights {
  final String id;
  final DateTime generatedAt;
  final int journalEntriesAnalyzed;
  final List<TriggerPattern> topTriggers;
  final List<TimePattern> timePatterns;
  final List<EmotionalPattern> emotionalPatterns;
  final List<String> recommendations;
  final String? summary;

  const AIInsights({
    required this.id,
    required this.generatedAt,
    required this.journalEntriesAnalyzed,
    required this.topTriggers,
    required this.timePatterns,
    required this.emotionalPatterns,
    required this.recommendations,
    this.summary,
  });

  factory AIInsights.fromMap(Map<String, dynamic> map, String docId) {
    return AIInsights(
      id: docId,
      generatedAt: (map['generated_at'] as Timestamp).toDate(),
      journalEntriesAnalyzed: map['journal_entries_analyzed'] as int? ?? 0,
      topTriggers: (map['top_triggers'] as List<dynamic>?)
              ?.map((e) => TriggerPattern.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      timePatterns: (map['time_patterns'] as List<dynamic>?)
              ?.map((e) => TimePattern.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      emotionalPatterns: (map['emotional_patterns'] as List<dynamic>?)
              ?.map((e) => EmotionalPattern.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (map['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      summary: map['summary'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'generated_at': Timestamp.fromDate(generatedAt),
      'journal_entries_analyzed': journalEntriesAnalyzed,
      'top_triggers': topTriggers.map((e) => e.toMap()).toList(),
      'time_patterns': timePatterns.map((e) => e.toMap()).toList(),
      'emotional_patterns': emotionalPatterns.map((e) => e.toMap()).toList(),
      'recommendations': recommendations,
      'summary': summary,
    };
  }

  /// Creates empty insights when not enough data
  factory AIInsights.empty() {
    return AIInsights(
      id: '',
      generatedAt: DateTime.now(),
      journalEntriesAnalyzed: 0,
      topTriggers: [],
      timePatterns: [],
      emotionalPatterns: [],
      recommendations: [],
      summary: null,
    );
  }

  bool get isEmpty => journalEntriesAnalyzed == 0;
}

/// Pattern representing a common trigger
class TriggerPattern {
  final String trigger;
  final int count;
  final double percentage;

  const TriggerPattern({
    required this.trigger,
    required this.count,
    required this.percentage,
  });

  factory TriggerPattern.fromMap(Map<String, dynamic> map) {
    return TriggerPattern(
      trigger: map['trigger'] as String? ?? 'Unknown',
      count: map['count'] as int? ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trigger': trigger,
      'count': count,
      'percentage': percentage,
    };
  }
}

/// Pattern representing time-based trends
class TimePattern {
  final String timeOfDay; // morning, afternoon, evening, night
  final int count;
  final double percentage;
  final String? insight;

  const TimePattern({
    required this.timeOfDay,
    required this.count,
    required this.percentage,
    this.insight,
  });

  factory TimePattern.fromMap(Map<String, dynamic> map) {
    return TimePattern(
      timeOfDay: map['time_of_day'] as String? ?? 'Unknown',
      count: map['count'] as int? ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      insight: map['insight'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time_of_day': timeOfDay,
      'count': count,
      'percentage': percentage,
      'insight': insight,
    };
  }
}

/// Pattern representing emotional state trends
class EmotionalPattern {
  final String emotion;
  final int count;
  final double percentage;
  final String? copingStrategy;

  const EmotionalPattern({
    required this.emotion,
    required this.count,
    required this.percentage,
    this.copingStrategy,
  });

  factory EmotionalPattern.fromMap(Map<String, dynamic> map) {
    return EmotionalPattern(
      emotion: map['emotion'] as String? ?? 'Unknown',
      count: map['count'] as int? ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      copingStrategy: map['coping_strategy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emotion': emotion,
      'count': count,
      'percentage': percentage,
      'coping_strategy': copingStrategy,
    };
  }
}

/// Minimum number of journal entries required before AI analysis
const int kMinEntriesForInsights = 5;
