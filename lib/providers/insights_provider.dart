import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_insights.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import 'auth_provider.dart';
import 'journal_provider.dart';

/// Provider for the latest AI insights
final latestInsightsProvider = FutureProvider<AIInsights?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(firebaseServiceProvider);

  final user = authState.valueOrNull;
  if (user == null) return null;

  return db.getLatestInsights(user.uid);
});

/// Stream of all insights for the current user
final insightsStreamProvider = StreamProvider<List<AIInsights>>((ref) {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(firebaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return db.streamInsights(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Provider to check if user has enough entries for insights
final insightsEligibilityProvider =
    Provider<AsyncValue<InsightsEligibility>>((ref) {
  final journalEntries = ref.watch(journalStreamProvider);

  return journalEntries.when(
    data: (entries) {
      final count = entries.length;
      final eligible = count >= kMinEntriesForInsights;
      return AsyncValue.data(InsightsEligibility(
        entryCount: count,
        requiredCount: kMinEntriesForInsights,
        isEligible: eligible,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Insights eligibility status
class InsightsEligibility {
  final int entryCount;
  final int requiredCount;
  final bool isEligible;

  const InsightsEligibility({
    required this.entryCount,
    required this.requiredCount,
    required this.isEligible,
  });

  int get entriesNeeded => requiredCount - entryCount;
}

/// Insights generation notifier
final insightsGeneratorProvider =
    StateNotifierProvider<InsightsGeneratorNotifier, InsightsGeneratorState>(
        (ref) {
  return InsightsGeneratorNotifier(ref);
});

class InsightsGeneratorState {
  final bool isGenerating;
  final String? error;
  final AIInsights? lastGenerated;

  const InsightsGeneratorState({
    this.isGenerating = false,
    this.error,
    this.lastGenerated,
  });

  InsightsGeneratorState copyWith({
    bool? isGenerating,
    String? error,
    AIInsights? lastGenerated,
  }) {
    return InsightsGeneratorState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      lastGenerated: lastGenerated ?? this.lastGenerated,
    );
  }
}

class InsightsGeneratorNotifier extends StateNotifier<InsightsGeneratorState> {
  final Ref _ref;

  InsightsGeneratorNotifier(this._ref) : super(const InsightsGeneratorState());

  FirebaseService get _db => _ref.read(firebaseServiceProvider);
  GeminiService get _gemini => GeminiService.instance;

  String? get _uid {
    final auth = _ref.read(authStateProvider);
    return auth.valueOrNull?.uid;
  }

  /// Generate new insights from journal entries
  Future<bool> generateInsights() async {
    final uid = _uid;
    if (uid == null) return false;

    if (!_gemini.isAvailable) {
      state = state.copyWith(
          error: _gemini.errorMessage ?? 
              'AI service not available. Please configure your Gemini API key.');
      return false;
    }

    state = state.copyWith(isGenerating: true, error: null);

    try {
      // Get journal entries
      final entries = await _db.getRecentJournal(uid, limit: 50);

      if (entries.length < kMinEntriesForInsights) {
        state = state.copyWith(
          isGenerating: false,
          error:
              'Need at least $kMinEntriesForInsights journal entries for insights',
        );
        return false;
      }

      // Generate insights using Gemini
      final insights = await _gemini.generateInsights(entries);

      if (insights == null) {
        state = state.copyWith(
          isGenerating: false,
          error: 'Failed to generate insights. Please try again.',
        );
        return false;
      }

      // Save to Firestore
      await _db.saveInsights(uid, insights);

      // Prune old insights
      await _db.pruneInsights(uid);

      state = state.copyWith(
        isGenerating: false,
        lastGenerated: insights,
      );

      // Refresh the insights providers
      _ref.invalidate(latestInsightsProvider);
      _ref.invalidate(insightsStreamProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Error generating insights: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
