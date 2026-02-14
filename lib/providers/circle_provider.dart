import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/supporter_model.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

/// Provider for Circle (family monitoring) operations.
final circleProvider =
    StateNotifierProvider<CircleNotifier, CircleState>((ref) {
  return CircleNotifier(ref);
});

/// Stream of supported users (for supporters viewing their people).
final supportedUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final db = ref.watch(firebaseServiceProvider);

  final user = auth.valueOrNull;
  if (user == null) return [];

  return db.getSupportedUsers(user.uid);
});

/// Stream of nudges for the current user.
final nudgesStreamProvider = StreamProvider<List<NudgeMessage>>((ref) {
  final auth = ref.watch(authStateProvider);
  final db = ref.watch(firebaseServiceProvider);

  return auth.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return db.streamNudges(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ─── Circle State ───────────────────────────────────────────────

class CircleState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<SupporterModel> supporters;

  const CircleState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.supporters = const [],
  });

  CircleState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<SupporterModel>? supporters,
  }) {
    return CircleState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      supporters: supporters ?? this.supporters,
    );
  }
}

// ─── Circle Notifier ────────────────────────────────────────────

class CircleNotifier extends StateNotifier<CircleState> {
  final Ref _ref;

  CircleNotifier(this._ref) : super(const CircleState());

  FirebaseService get _db => _ref.read(firebaseServiceProvider);

  String? get _uid {
    final auth = _ref.read(authStateProvider);
    return auth.valueOrNull?.uid;
  }

  /// Join someone's circle using their support code.
  Future<bool> joinCircle(String supportCode) async {
    final uid = _uid;
    if (uid == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final targetUser = await _db.findUserBySupportCode(supportCode);
      if (targetUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No user found with that support code.',
        );
        return false;
      }

      if (targetUser.uid == uid) {
        state = state.copyWith(
          isLoading: false,
          error: "You can't join your own circle.",
        );
        return false;
      }

      await _db.addSupporter(targetUser.uid, uid);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Joined ${targetUser.displayName}\'s circle!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join circle. Please try again.',
      );
      return false;
    }
  }

  /// Load supporters for the current user.
  Future<void> loadSupporters() async {
    final uid = _uid;
    if (uid == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final supporters = await _db.getSupporters(uid);
      state = state.copyWith(
        isLoading: false,
        supporters: supporters,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load supporters.',
      );
    }
  }

  /// Remove a supporter from the circle.
  Future<void> removeSupporter(String supporterUid) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db.removeSupporter(uid, supporterUid);
      await loadSupporters();
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove supporter.');
    }
  }

  /// Send a nudge ("Send Strength") to a user being supported.
  Future<bool> sendStrength({
    required String toUid,
    String emoji = '💪',
    String message = 'You got this! Stay strong! 🌟',
  }) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      final currentUser = await _db.getUser(uid);
      if (currentUser == null) return false;

      final nudge = NudgeMessage(
        fromUid: uid,
        fromName: currentUser.displayName,
        emoji: emoji,
        message: message,
        sentAt: DateTime.now(),
      );

      await _db.sendNudge(toUid, nudge);

      // TODO: Trigger FCM push notification via Cloud Function
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update privacy settings.
  Future<void> updatePrivacy(PrivacySettings settings) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.updatePrivacySettings(uid, settings);
  }

  /// Clear messages.
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}
