import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Represents a journal entry for craving events, relapses, or near misses.
class JournalEntry {
  final String id;
  final DateTime timestamp;
  final JournalEventType eventType;
  final String? triggerType;
  final int intensityLevel; // 1-10
  final String? notes;
  final String? interventionUsed;
  final bool wasResisted;

  const JournalEntry({
    required this.id,
    required this.timestamp,
    required this.eventType,
    this.triggerType,
    this.intensityLevel = 5,
    this.notes,
    this.interventionUsed,
    this.wasResisted = true,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map, String docId) {
    return JournalEntry(
      id: docId,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      eventType: JournalEventType.fromString(map['event_type'] ?? 'craving'),
      triggerType: map['trigger_type'] as String?,
      intensityLevel: (map['intensity_level'] as num?)?.toInt() ?? 5,
      notes: map['notes'] as String?,
      interventionUsed: map['intervention_used'] as String?,
      wasResisted: map['was_resisted'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'event_type': eventType.value,
      'trigger_type': triggerType,
      'intensity_level': intensityLevel,
      'notes': notes,
      'intervention_used': interventionUsed,
      'was_resisted': wasResisted,
    };
  }

  JournalEntry copyWith({
    String? id,
    DateTime? timestamp,
    JournalEventType? eventType,
    String? triggerType,
    int? intensityLevel,
    String? notes,
    String? interventionUsed,
    bool? wasResisted,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      triggerType: triggerType ?? this.triggerType,
      intensityLevel: intensityLevel ?? this.intensityLevel,
      notes: notes ?? this.notes,
      interventionUsed: interventionUsed ?? this.interventionUsed,
      wasResisted: wasResisted ?? this.wasResisted,
    );
  }
}

enum JournalEventType {
  craving('craving'),
  relapse('relapse'),
  nearMiss('near_miss'),
  milestone('milestone');

  final String value;
  const JournalEventType(this.value);

  static JournalEventType fromString(String value) {
    return JournalEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => JournalEventType.craving,
    );
  }

  String get displayName {
    switch (this) {
      case JournalEventType.craving:
        return 'Craving';
      case JournalEventType.relapse:
        return 'Relapse Event';
      case JournalEventType.nearMiss:
        return 'Near Miss';
      case JournalEventType.milestone:
        return 'Milestone';
    }
  }

  IconData get icon {
    switch (this) {
      case JournalEventType.craving:
        return Icons.waves;
      case JournalEventType.relapse:
        return Icons.refresh;
      case JournalEventType.nearMiss:
        return Icons.warning_amber_rounded;
      case JournalEventType.milestone:
        return Icons.emoji_events;
    }
  }
}

/// Common smoking triggers
class SmokingTriggers {
  static const List<String> all = [
    'Work Stress',
    'Social Situation',
    'After a Meal',
    'Morning Routine',
    'Alcohol',
    'Boredom',
    'Emotional Distress',
    'Driving',
    'Coffee/Tea',
    'Seeing Others Smoke',
    'Anxiety',
    'Celebration',
    'Habit/Automatic',
    'Other',
  ];
}
