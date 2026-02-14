import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stats_model.dart';
import 'user_provider.dart';

/// Derived provider: current streak days.
final streakDaysProvider = Provider<int>((ref) {
  final user = ref.watch(userStreamProvider).valueOrNull;
  return user?.currentStreakDays ?? 0;
});

/// Derived provider: money saved.
final moneySavedProvider = Provider<double>((ref) {
  final user = ref.watch(userStreamProvider).valueOrNull;
  return user?.calculatedMoneySaved ?? 0.0;
});

/// Derived provider: cigarettes not smoked.
final cigarettesNotSmokedProvider = Provider<int>((ref) {
  final user = ref.watch(userStreamProvider).valueOrNull;
  return user?.calculatedCigarettesNotSmoked ?? 0;
});

/// Derived provider: health recovery percentage (0.0 - 1.0).
final healthRecoveryProvider = Provider<double>((ref) {
  final user = ref.watch(userStreamProvider).valueOrNull;
  if (user == null) return 0.0;

  final reference =
      user.stats.lastSmokeTimestamp ?? user.quitDate ?? user.createdAt;
  final elapsed = DateTime.now().difference(reference);

  // Calculate based on health milestones
  double progress = 0.0;
  for (final milestone in HealthMilestone.milestones) {
    if (elapsed >= milestone.timeRequired) {
      progress += 1.0 / HealthMilestone.milestones.length;
    } else {
      // Partial progress toward next milestone
      final prevDuration = HealthMilestone.milestones
          .where((m) => m.timeRequired < milestone.timeRequired)
          .fold<Duration>(Duration.zero,
              (max, m) => m.timeRequired > max ? m.timeRequired : max);
      final segmentDuration = milestone.timeRequired - prevDuration;
      final segmentElapsed = elapsed - prevDuration;
      if (segmentElapsed.inSeconds > 0) {
        progress += (segmentElapsed.inSeconds / segmentDuration.inSeconds) *
            (1.0 / HealthMilestone.milestones.length);
      }
      break;
    }
  }

  return progress.clamp(0.0, 1.0);
});

/// Derived provider: achieved health milestones.
final achievedMilestonesProvider = Provider<List<HealthMilestone>>((ref) {
  final user = ref.watch(userStreamProvider).valueOrNull;
  if (user == null) return [];

  final reference =
      user.stats.lastSmokeTimestamp ?? user.quitDate ?? user.createdAt;
  final elapsed = DateTime.now().difference(reference);

  return HealthMilestone.milestones
      .where((m) => elapsed >= m.timeRequired)
      .toList();
});

/// Derived provider: next upcoming milestone.
final nextMilestoneProvider = Provider<HealthMilestone?>((ref) {
  final user = ref.watch(userStreamProvider).valueOrNull;
  if (user == null) return null;

  final reference =
      user.stats.lastSmokeTimestamp ?? user.quitDate ?? user.createdAt;
  final elapsed = DateTime.now().difference(reference);

  for (final milestone in HealthMilestone.milestones) {
    if (elapsed < milestone.timeRequired) {
      return milestone;
    }
  }
  return null; // All milestones achieved
});

/// Cravings blocked count.
final cravingsBlockedProvider = Provider<int>((ref) {
  final user = ref.watch(userStreamProvider).valueOrNull;
  return user?.stats.cravingsBlocked ?? 0;
});
