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

  // Enhanced fields for SmokeBand-detected events
  final bool fromSmokeBand;
  final String? location;
  final String? emotionalState;
  final String? companions; // Who they were with
  final String? activity; // What they were doing
  final double? mq9Ppm; // CO sensor reading if from SmokeBand

  const JournalEntry({
    required this.id,
    required this.timestamp,
    required this.eventType,
    this.triggerType,
    this.intensityLevel = 5,
    this.notes,
    this.interventionUsed,
    this.wasResisted = true,
    this.fromSmokeBand = false,
    this.location,
    this.emotionalState,
    this.companions,
    this.activity,
    this.mq9Ppm,
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
      fromSmokeBand: map['from_smoke_band'] as bool? ?? false,
      location: map['location'] as String?,
      emotionalState: map['emotional_state'] as String?,
      companions: map['companions'] as String?,
      activity: map['activity'] as String?,
      mq9Ppm: (map['mq9_ppm'] as num?)?.toDouble(),
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
      'from_smoke_band': fromSmokeBand,
      if (location != null) 'location': location,
      if (emotionalState != null) 'emotional_state': emotionalState,
      if (companions != null) 'companions': companions,
      if (activity != null) 'activity': activity,
      if (mq9Ppm != null) 'mq9_ppm': mq9Ppm,
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
    bool? fromSmokeBand,
    String? location,
    String? emotionalState,
    String? companions,
    String? activity,
    double? mq9Ppm,
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
      fromSmokeBand: fromSmokeBand ?? this.fromSmokeBand,
      location: location ?? this.location,
      emotionalState: emotionalState ?? this.emotionalState,
      companions: companions ?? this.companions,
      activity: activity ?? this.activity,
      mq9Ppm: mq9Ppm ?? this.mq9Ppm,
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

/// Common emotional states for journal entries
class EmotionalStates {
  static const List<String> all = [
    'Stressed',
    'Anxious',
    'Bored',
    'Sad',
    'Angry',
    'Frustrated',
    'Lonely',
    'Happy',
    'Relaxed',
    'Tired',
    'Overwhelmed',
    'Neutral',
  ];
}

/// Common locations for smoking events
class SmokingLocations {
  static const List<String> all = [
    'Home',
    'Work',
    'Car',
    'Bar/Restaurant',
    'Friend\'s Place',
    'Outdoors',
    'Party/Event',
    'Other',
  ];
}

/// Common companion situations
class CompanionSituations {
  static const List<String> all = [
    'Alone',
    'With Friends',
    'With Coworkers',
    'With Family',
    'With Partner',
    'At a Social Gathering',
    'Other',
  ];
}

/// Common activities during smoking
class SmokingActivities {
  static const List<String> all = [
    'Taking a Break',
    'After Eating',
    'Drinking Coffee/Tea',
    'Drinking Alcohol',
    'Socializing',
    'Working',
    'Driving',
    'Watching TV',
    'On the Phone',
    'Waiting',
    'Other',
  ];
}
