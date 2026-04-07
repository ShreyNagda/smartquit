import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/ai_insights.dart';
import '../../providers/insights_provider.dart';
import '../../services/gemini_service.dart';

/// Screen displaying AI-generated insights from journal entries
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(latestInsightsProvider);
    final eligibility = ref.watch(insightsEligibilityProvider);
    final generatorState = ref.watch(insightsGeneratorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          if (insightsAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: generatorState.isGenerating
                  ? null
                  : () => _generateInsights(ref, context),
              tooltip: 'Regenerate insights',
            ),
        ],
      ),
      body: insightsAsync.when(
        data: (insights) {
          if (insights == null || insights.isEmpty) {
            return _buildNoInsightsView(
              context,
              ref,
              eligibility,
              generatorState,
            );
          }
          return _buildInsightsView(context, insights, generatorState, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading insights',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(latestInsightsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoInsightsView(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<InsightsEligibility> eligibility,
    InsightsGeneratorState generatorState,
  ) {
    final theme = Theme.of(context);
    final geminiAvailable = GeminiService.instance.isAvailable;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              size: 60,
              color: AppColors.primary,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOut).fadeIn(),
          const SizedBox(height: 32),
          Text(
            'AI-Powered Insights',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          if (!geminiAvailable) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Insights Not Available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    GeminiService.instance.errorMessage ?? 
                        'Gemini API key not configured.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To enable AI insights:\n'
                    '1. Get an API key from makersuite.google.com\n'
                    '2. Create a .env file in the project root\n'
                    '3. Add: GEMINI_API_KEY=your_key_here\n'
                    '4. Restart the app',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ] else ...[
            eligibility.when(
              data: (elig) {
                if (elig.isEligible) {
                  return Column(
                    children: [
                      Text(
                        'You have ${elig.entryCount} journal entries.\n'
                        'Generate personalized insights about your patterns!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (generatorState.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            generatorState.error!,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: generatorState.isGenerating
                              ? null
                              : () => _generateInsights(ref, context),
                          icon: generatorState.isGenerating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            generatorState.isGenerating
                                ? 'Analyzing...'
                                : 'Generate Insights',
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms);
                } else {
                  return Column(
                    children: [
                      Text(
                        'Log ${elig.entriesNeeded} more journal entries '
                        'to unlock AI insights about your patterns.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Progress indicator
                      LinearProgressIndicator(
                        value: elig.entryCount / elig.requiredCount,
                        backgroundColor: AppColors.surfaceVariant,
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${elig.entryCount} / ${elig.requiredCount} entries',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms);
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error checking eligibility'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsView(
    BuildContext context,
    AIInsights insights,
    InsightsGeneratorState generatorState,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with timestamp
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Based on ${insights.journalEntriesAnalyzed} entries',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(insights.generatedAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary
          if (insights.summary != null) ...[
            _buildSectionCard(
              context,
              icon: Icons.summarize,
              title: 'Summary',
              child: Text(
                insights.summary!,
                style: theme.textTheme.bodyLarge,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 16),
          ],

          // Top Triggers
          if (insights.topTriggers.isNotEmpty) ...[
            _buildSectionCard(
              context,
              icon: Icons.psychology_alt,
              title: 'Your Top Triggers',
              child: Column(
                children: insights.topTriggers.map((trigger) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            trigger.trigger,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: LinearProgressIndicator(
                            value: trigger.percentage,
                            backgroundColor: AppColors.surfaceVariant,
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(trigger.percentage * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 16),
          ],

          // Time Patterns
          if (insights.timePatterns.isNotEmpty) ...[
            _buildSectionCard(
              context,
              icon: Icons.schedule,
              title: 'Time Patterns',
              child: Column(
                children: insights.timePatterns.map((pattern) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getTimeIcon(pattern.timeOfDay),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimeOfDay(pattern.timeOfDay),
                              style: theme.textTheme.titleSmall,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pattern.count} events',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (pattern.insight != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            pattern.insight!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 16),
          ],

          // Emotional Patterns
          if (insights.emotionalPatterns.isNotEmpty) ...[
            _buildSectionCard(
              context,
              icon: Icons.mood,
              title: 'Emotional Patterns',
              child: Column(
                children: insights.emotionalPatterns.map((pattern) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getEmotionEmoji(pattern.emotion),
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pattern.emotion,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              '${(pattern.percentage * 100).toInt()}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        if (pattern.copingStrategy != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pattern.copingStrategy!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 16),
          ],

          // Recommendations
          if (insights.recommendations.isNotEmpty) ...[
            _buildSectionCard(
              context,
              icon: Icons.tips_and_updates,
              title: 'Personalized Recommendations',
              child: Column(
                children: insights.recommendations.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),
          ],

          const SizedBox(height: 32),

          // Regenerate button
          if (generatorState.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                generatorState.error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),

          Center(
            child: OutlinedButton.icon(
              onPressed: generatorState.isGenerating
                  ? null
                  : () => _generateInsights(ref, context),
              icon: generatorState.isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                generatorState.isGenerating
                    ? 'Analyzing...'
                    : 'Regenerate Insights',
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _getTimeIcon(String timeOfDay) {
    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return const Icon(Icons.wb_sunny, color: AppColors.warning, size: 20);
      case 'afternoon':
        return const Icon(Icons.light_mode,
            color: AppColors.secondary, size: 20);
      case 'evening':
        return const Icon(Icons.nights_stay, color: AppColors.accent, size: 20);
      case 'night':
        return const Icon(Icons.bedtime,
            color: AppColors.primaryDark, size: 20);
      default:
        return const Icon(Icons.schedule,
            color: AppColors.textSecondary, size: 20);
    }
  }

  String _formatTimeOfDay(String timeOfDay) {
    return timeOfDay[0].toUpperCase() + timeOfDay.substring(1).toLowerCase();
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'stressed':
        return '😰';
      case 'anxious':
        return '😟';
      case 'bored':
        return '😐';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'frustrated':
        return '😤';
      case 'lonely':
        return '😔';
      case 'happy':
        return '😊';
      case 'relaxed':
        return '😌';
      case 'tired':
        return '😴';
      case 'overwhelmed':
        return '🤯';
      default:
        return '🙂';
    }
  }

  Future<void> _generateInsights(WidgetRef ref, BuildContext context) async {
    final success =
        await ref.read(insightsGeneratorProvider.notifier).generateInsights();

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New insights generated! ✨'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
