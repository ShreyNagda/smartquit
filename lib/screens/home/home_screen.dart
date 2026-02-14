import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/panic_button.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/stats_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final streakDays = ref.watch(streakDaysProvider);
    final moneySaved = ref.watch(moneySavedProvider);
    final cigarettesAvoided = ref.watch(cigarettesNotSmokedProvider);
    final cravingsBlocked = ref.watch(cravingsBlockedProvider);
    final healthRecovery = ref.watch(healthRecoveryProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hey, ${user?.displayName ?? 'Friend'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Montserrat',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.waving_hand,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Every breath counts.',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Streak Card
              StreakCard(
                streakDays: streakDays,
                cravingsBlocked: cravingsBlocked,
              ),

              const SizedBox(height: 32),

              // PANIC BUTTON — Most prominent element
              const Center(
                child: PanicButton(),
              ),

              const SizedBox(height: 12),
              const Text(
                'Tap when a craving hits',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // Quick stats grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Money Saved',
                        value: currencyFormat.format(moneySaved),
                        subtitle: 'Keep going!',
                        icon: Icons.savings_rounded,
                        gradient: AppColors.warmGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: 'Not Smoked',
                        value: '$cigarettesAvoided',
                        subtitle: 'cigarettes',
                        icon: Icons.smoke_free_rounded,
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Health Recovery',
                        value: '${(healthRecovery * 100).toStringAsFixed(1)}%',
                        subtitle: 'Body healing',
                        icon: Icons.favorite_rounded,
                        gradient: AppColors.accentGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: 'Interventions',
                        value: '${user?.stats.totalInterventionsUsed ?? 0}',
                        subtitle: 'activities completed',
                        icon: Icons.psychology_rounded,
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Motivation quote
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Text('💬', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '"The secret of getting ahead is getting started."',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
