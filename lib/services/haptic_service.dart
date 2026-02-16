import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';

/// Centralized haptic feedback service.
/// Respects user preferences and provides consistent haptic patterns.
class HapticService {
  final Ref _ref;

  HapticService(this._ref);

  /// Check if haptic feedback is enabled in user preferences
  bool get _isEnabled {
    final user = _ref.read(userStreamProvider).valueOrNull;
    return user?.preferences.hapticFeedback ?? true;
  }

  /// Light haptic - for subtle feedback (card flips, selections)
  Future<void> light() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.light);
    }
  }

  /// Medium haptic - for moderate feedback (button presses, transitions)
  Future<void> medium() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.medium);
    }
  }

  /// Heavy haptic - for strong feedback (completions, important actions)
  Future<void> heavy() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.heavy);
    }
  }

  /// Success haptic - for positive outcomes
  Future<void> success() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.success);
    }
  }

  /// Warning haptic - for alerts or cautions
  Future<void> warning() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.warning);
    }
  }

  /// Error haptic - for failures or errors
  Future<void> error() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.error);
    }
  }

  /// Selection haptic - for UI selections
  Future<void> selection() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.selection);
    }
  }

  /// Rigid haptic - for rigid/stiff feedback
  Future<void> rigid() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.rigid);
    }
  }

  /// Soft haptic - for soft/gentle feedback
  Future<void> soft() async {
    if (_isEnabled) {
      await Haptics.vibrate(HapticsType.soft);
    }
  }
}

/// Provider for haptic service
final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService(ref);
});
