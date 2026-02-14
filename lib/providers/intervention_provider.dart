import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

/// Enum of all 10 intervention activities.
enum InterventionType {
  boxBreathing(
    'Box Breathing',
    'Haptic-guided 4-4-4-4 breathing rhythm',
    Icons.air,
    '/intervention/box-breathing',
  ),
  memoryMatch(
    'Memory Match',
    '4x4 nature-themed card flip game',
    Icons.grid_4x4,
    '/intervention/memory-match',
  ),
  grounding(
    '5-4-3-2-1 Grounding',
    'Interactive sensory input prompts',
    Icons.explore,
    '/intervention/grounding',
  ),
  urgeSurfing(
    'Urge Surfing',
    '10-minute wave visualization',
    Icons.waves,
    '/intervention/urge-surfing',
  ),
  savingsTracker(
    'Savings Tracker',
    'Real-time financial & health gains',
    Icons.savings,
    '/intervention/savings-tracker',
  ),
  whackACrave(
    'Whack-a-Crave',
    'Fast-paced tap game for motor energy',
    Icons.sports_esports,
    '/intervention/whack-a-crave',
  ),
  guidedVisualization(
    'Guided Visualization',
    '2-minute audio-visual safe space',
    Icons.landscape,
    '/intervention/guided-visualization',
  ),
  waterPrompt(
    'The Water Prompt',
    'Drink a glass of water (physical substitution)',
    Icons.water_drop,
    '/intervention/water-prompt',
  ),
  positiveReframing(
    'Positive Reframing',
    'CBT affirmation card swipe deck',
    Icons.lightbulb,
    '/intervention/positive-reframing',
  ),
  quickSketch(
    'Quick Sketch',
    '60-second doodling canvas',
    Icons.brush,
    '/intervention/quick-sketch',
  );

  final String displayName;
  final String description;
  final IconData icon;
  final String route;

  const InterventionType(
    this.displayName,
    this.description,
    this.icon,
    this.route,
  );
}

/// Intervention state.
class InterventionState {
  final InterventionType? currentIntervention;
  final bool isActive;
  final DateTime? startedAt;
  final int completedCount;

  const InterventionState({
    this.currentIntervention,
    this.isActive = false,
    this.startedAt,
    this.completedCount = 0,
  });

  InterventionState copyWith({
    InterventionType? currentIntervention,
    bool? isActive,
    DateTime? startedAt,
    int? completedCount,
  }) {
    return InterventionState(
      currentIntervention: currentIntervention ?? this.currentIntervention,
      isActive: isActive ?? this.isActive,
      startedAt: startedAt ?? this.startedAt,
      completedCount: completedCount ?? this.completedCount,
    );
  }
}

/// Intervention notifier — handles random selection and tracking.
final interventionProvider =
    StateNotifierProvider<InterventionNotifier, InterventionState>((ref) {
  return InterventionNotifier(ref);
});

class InterventionNotifier extends StateNotifier<InterventionState> {
  final Ref _ref;
  final Random _random = Random();

  InterventionNotifier(this._ref) : super(const InterventionState());

  FirebaseService get _db => _ref.read(firebaseServiceProvider);

  String? get _uid {
    final auth = _ref.read(authStateProvider);
    return auth.valueOrNull?.uid;
  }

  /// Randomly select an intervention (Panic Button pressed).
  InterventionType launchRandomIntervention() {
    final interventions = InterventionType.values;
    final selected = interventions[_random.nextInt(interventions.length)];

    state = InterventionState(
      currentIntervention: selected,
      isActive: true,
      startedAt: DateTime.now(),
      completedCount: state.completedCount,
    );

    return selected;
  }

  /// Select a specific intervention.
  void launchIntervention(InterventionType type) {
    state = InterventionState(
      currentIntervention: type,
      isActive: true,
      startedAt: DateTime.now(),
      completedCount: state.completedCount,
    );
  }

  /// Mark the current intervention as completed.
  Future<void> completeIntervention() async {
    final current = state.currentIntervention;
    if (current == null) return;

    // Record usage in Firestore
    final uid = _uid;
    if (uid != null) {
      await _db.recordInterventionUsed(uid, current.displayName);
    }

    state = InterventionState(
      currentIntervention: null,
      isActive: false,
      completedCount: state.completedCount + 1,
    );
  }

  /// Cancel the current intervention.
  void cancelIntervention() {
    state = InterventionState(
      currentIntervention: null,
      isActive: false,
      completedCount: state.completedCount,
    );
  }
}
