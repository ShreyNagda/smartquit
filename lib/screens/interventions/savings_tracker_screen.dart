import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';
import '../../providers/stats_provider.dart';
import '../../models/stats_model.dart';

/// Savings Tracker: Real-time financial/health gains display.
class SavingsTrackerScreen extends ConsumerWidget {
  const SavingsTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moneySaved = ref.watch(moneySavedProvider);
    final cigarettesAvoided = ref.watch(cigarettesNotSmokedProvider);
    ref.watch(streakDaysProvider);
    final healthRecovery = ref.watch(healthRecoveryProvider);
    final achievedMilestones = ref.watch(achievedMilestonesProvider);
    final nextMilestone = ref.watch(nextMilestoneProvider);
    final currencyFmt = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Savings & Health'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(interventionProvider.notifier).completeIntervention();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Money saved hero
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text(
                    '💰',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Money Saved',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    currencyFmt.format(moneySaved),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$cigarettesAvoided cigarettes not smoked',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Montserrat',
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Time saved
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 36, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time Reclaimed',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Montserrat',
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(cigarettesAvoided * 5 / 60).toStringAsFixed(1)} hours',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Health recovery
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '❤️ Health Recovery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: healthRecovery,
                      backgroundColor: AppColors.secondaryLight,
                      color: AppColors.primary,
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(healthRecovery * 100).toStringAsFixed(1)}% recovered',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Montserrat',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Milestones achieved
            const Text(
              'Health Milestones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...HealthMilestone.milestones.map((milestone) {
              final isAchieved = achievedMilestones.contains(milestone);
              final isNext = milestone == nextMilestone;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isAchieved
                      ? AppColors.primaryLight.withOpacity(0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: isNext
                      ? Border.all(color: AppColors.accent, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      milestone.icon,
                      style: TextStyle(
                        fontSize: 28,
                        color: isAchieved ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montserrat',
                              color: isAchieved
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            milestone.description,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Montserrat',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    isAchieved
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : isNext
                            ? const Text('Next! →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                  color: AppColors.accent,
                                ))
                            : const Icon(Icons.circle_outlined,
                                color: AppColors.textLight),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
