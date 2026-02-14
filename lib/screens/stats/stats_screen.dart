import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/stats_model.dart';
import '../../providers/stats_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/stats_card.dart';

/// Stats screen showing health recovery milestones, savings, and progress.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakDaysProvider);
    final moneySaved = ref.watch(moneySavedProvider);
    final cigarettes = ref.watch(cigarettesNotSmokedProvider);
    final healthPct = ref.watch(healthRecoveryProvider);
    final achieved = ref.watch(achievedMilestonesProvider);
    final next = ref.watch(nextMilestoneProvider);
    final blocked = ref.watch(cravingsBlockedProvider);
    final userAsync = ref.watch(userStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Your Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero streak
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  '🔥 Current Streak',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$streak',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'smoke-free days',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats grid
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  icon: Icons.savings,
                  // iconColor: AppColors.secondary,
                  value: '₹${moneySaved.toStringAsFixed(2)}',
                  title: 'Money Saved',
                  subtitle:
                      moneySaved > 0 ? 'Keep it up!' : 'Start saving today',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  icon: Icons.smoke_free,
                  // iconColor: AppColors.primary,
                  value: '$cigarettes',
                  title: 'Cigs Not Smoked',
                  subtitle: cigarettes > 0
                      ? 'Great job!'
                      : 'Start your journey today',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  icon: Icons.shield,
                  // iconColor: AppColors.accent,
                  value: '$blocked',
                  title: 'Cravings Blocked', subtitle: '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  icon: Icons.auto_awesome,
                  // iconColor: Colors.amber,
                  value: userAsync.valueOrNull?.stats.totalInterventionsUsed
                          .toString() ??
                      '0',
                  title: 'Interventions', subtitle: 'Used',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Health recovery
          const Text(
            '💚 Health Recovery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Recovery',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(healthPct * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montserrat',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: healthPct,
                    minHeight: 10,
                    backgroundColor: AppColors.secondaryLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Next milestone
          if (next != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('⏭️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Milestone',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Montserrat',
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          next.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          next.description,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Montserrat',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Milestone timeline
          const Text(
            '🏆 Milestones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...HealthMilestone.milestones.map((m) {
            final isAchieved = achieved.any((a) => a.title == m.title);
            return _buildMilestoneRow(m, isAchieved);
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(HealthMilestone m, bool isAchieved) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAchieved
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isAchieved
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAchieved ? AppColors.primary : AppColors.secondaryLight,
            ),
            child: Icon(
              isAchieved ? Icons.check : Icons.schedule,
              color: isAchieved ? Colors.white : AppColors.textLight,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                    color:
                        isAchieved ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  m.description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isAchieved) const Text('✅', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
