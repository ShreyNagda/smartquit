import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

/// Streams the current user's full profile.
final userStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(firebaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return db.streamUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// User profile actions notifier.
final userActionsProvider =
    StateNotifierProvider<UserActionsNotifier, AsyncValue<void>>((ref) {
  return UserActionsNotifier(ref);
});

class UserActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  UserActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  FirebaseService get _db => _ref.read(firebaseServiceProvider);

  String? get _uid {
    final auth = _ref.read(authStateProvider);
    return auth.valueOrNull?.uid;
  }

  /// Update user preferences.
  Future<void> updatePreferences(UserPreferences prefs) async {
    final uid = _uid;
    if (uid == null) return;

    state = const AsyncValue.loading();
    try {
      await _db.updateUser(uid, {'preferences': prefs.toMap()});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update quit date.
  Future<void> updateQuitDate(DateTime date) async {
    final uid = _uid;
    if (uid == null) return;

    state = const AsyncValue.loading();
    try {
      await _db.updateUser(uid, {
        'quit_date': Timestamp.fromDate(date),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update FCM token.
  Future<void> updateFcmToken(String token) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.updateFcmToken(uid, token);
  }

  /// Update display name.
  Future<void> updateDisplayName(String name) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.updateUser(uid, {'display_name': name});
  }
}
