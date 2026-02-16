import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

/// Auth service provider (singleton).
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Firebase service provider (singleton).
final firebaseServiceProvider =
    Provider<FirebaseService>((ref) => FirebaseService());

/// Auth state stream provider.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Auth state notifier for login/signup actions.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// ─── Auth State ──────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;
  final bool isNewUser;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isNewUser = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
    bool? isNewUser,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}

// ─── Auth Notifier ───────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  AuthService get _auth => _ref.read(authServiceProvider);
  FirebaseService get _db => _ref.read(firebaseServiceProvider);

  /// Sign up and create user profile.
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    int cigarettesPerDay = 20,
    double pricePerCigarette = 0.50,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _auth.signUp(
        email: email,
        password: password,
      );

      await _auth.updateDisplayName(displayName);

      // Generate unique support code
      final supportCode = await _db.generateSupportCode();

      // Create user document
      final user = UserModel(
        uid: credential.user!.uid,
        displayName: displayName,
        email: email,
        supportCode: supportCode,
        createdAt: DateTime.now(),
        quitDate: DateTime.now(),
        preferences: UserPreferences(
          cigarettesPerDay: cigarettesPerDay,
          pricePerCigarette: pricePerCigarette,
        ),
      );

      await _db.createUser(user);

      state = state.copyWith(isLoading: false, user: credential.user);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred.');
      return false;
    }
  }

  /// Sign in existing user.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _auth.signIn(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, user: credential.user);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred.');
      return false;
    }
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null, isNewUser: false);

    try {
      final credential = await _auth.signInWithGoogle();

      if (credential == null) {
        // User canceled
        state = state.copyWith(isLoading: false);
        return false;
      }

      final user = credential.user!;
      bool isNewUser = false;

      // Check if user document exists
      final existingUser = await _db.getUser(user.uid);

      if (existingUser == null) {
        // First time Google sign-in - create user document with defaults
        try {
          final supportCode = await _db.generateSupportCode();

          final newUser = UserModel(
            uid: user.uid,
            displayName: user.displayName ?? 'User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            supportCode: supportCode,
            createdAt: DateTime.now(),
            quitDate: DateTime.now(),
            preferences: const UserPreferences(
              cigarettesPerDay: 20,
              pricePerCigarette: 10.0,
              currency: '₹',
            ),
          );

          await _db.createUser(newUser);
          isNewUser = true;
          print('✅ Firestore user document created for ${user.uid}');
        } catch (e) {
          print('❌ Error creating Firestore user document: $e');
          // Sign out the user from Firebase Auth if Firestore creation fails
          await _auth.signOut();
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to create user profile. Please try again.',
          );
          return false;
        }
      } else {
        print('✅ Existing user found: ${existingUser.uid}');
      }

      state = state.copyWith(
        isLoading: false,
        user: user,
        isNewUser: isNewUser,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      print('❌ Unexpected error in signInWithGoogle: $e');
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred: $e');
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState();
  }

  /// Reset password.
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to send reset email.');
      return false;
    }
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear new user flag after onboarding.
  void clearNewUserFlag() {
    state = state.copyWith(isNewUser: false);
  }
}
