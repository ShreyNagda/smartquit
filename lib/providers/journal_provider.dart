import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

/// Stream of journal entries for the current user.
final journalStreamProvider = StreamProvider<List<JournalEntry>>((ref) {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(firebaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return db.streamJournal(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Journal actions notifier.
final journalActionsProvider =
    StateNotifierProvider<JournalActionsNotifier, JournalActionState>((ref) {
  return JournalActionsNotifier(ref);
});

class JournalActionState {
  final bool isSubmitting;
  final String? error;
  final String? lastEntryId;

  const JournalActionState({
    this.isSubmitting = false,
    this.error,
    this.lastEntryId,
  });
}

class JournalActionsNotifier extends StateNotifier<JournalActionState> {
  final Ref _ref;

  JournalActionsNotifier(this._ref) : super(const JournalActionState());

  FirebaseService get _db => _ref.read(firebaseServiceProvider);

  String? get _uid {
    final auth = _ref.read(authStateProvider);
    return auth.valueOrNull?.uid;
  }

  /// Log a craving event (resisted).
  Future<bool> logCraving({
    required String triggerType,
    required int intensity,
    String? notes,
    String? interventionUsed,
  }) async {
    return _addEntry(
      eventType: JournalEventType.craving,
      triggerType: triggerType,
      intensity: intensity,
      notes: notes,
      interventionUsed: interventionUsed,
      wasResisted: true,
    );
  }

  /// Log a near miss (almost relapsed).
  Future<bool> logNearMiss({
    required String triggerType,
    required int intensity,
    String? notes,
    String? interventionUsed,
  }) async {
    return _addEntry(
      eventType: JournalEventType.nearMiss,
      triggerType: triggerType,
      intensity: intensity,
      notes: notes,
      interventionUsed: interventionUsed,
      wasResisted: true,
    );
  }

  /// Log a relapse event (captures the "Why").
  Future<bool> logRelapse({
    required String triggerType,
    required int intensity,
    required String notes, // Required for relapse — captures "Why"
  }) async {
    return _addEntry(
      eventType: JournalEventType.relapse,
      triggerType: triggerType,
      intensity: intensity,
      notes: notes,
      wasResisted: false,
    );
  }

  /// Log a milestone event.
  Future<bool> logMilestone({
    required String notes,
  }) async {
    return _addEntry(
      eventType: JournalEventType.milestone,
      intensity: 0,
      notes: notes,
      wasResisted: true,
    );
  }

  Future<bool> _addEntry({
    required JournalEventType eventType,
    String? triggerType,
    required int intensity,
    String? notes,
    String? interventionUsed,
    required bool wasResisted,
  }) async {
    final uid = _uid;
    if (uid == null) return false;

    state = const JournalActionState(isSubmitting: true);

    try {
      final entry = JournalEntry(
        id: '', // Will be set by Firestore
        timestamp: DateTime.now(),
        eventType: eventType,
        triggerType: triggerType,
        intensityLevel: intensity,
        notes: notes,
        interventionUsed: interventionUsed,
        wasResisted: wasResisted,
      );

      final docId = await _db.addJournalEntry(uid, entry);
      state = JournalActionState(lastEntryId: docId);
      return true;
    } catch (e) {
      state = JournalActionState(error: e.toString());
      return false;
    }
  }
}
