import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';

/// Positive Reframing: CBT affirmation card-swipe deck.
class PositiveReframingScreen extends ConsumerStatefulWidget {
  const PositiveReframingScreen({super.key});

  @override
  ConsumerState<PositiveReframingScreen> createState() =>
      _PositiveReframingScreenState();
}

class _PositiveReframingScreenState
    extends ConsumerState<PositiveReframingScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  static const _affirmations = [
    _CbtCard(
      negative: 'I can\'t do this without a cigarette.',
      reframe:
          'I\'ve handled difficult moments before without smoking. I can do it again.',
      emoji: '💪',
      color: AppColors.primary,
    ),
    _CbtCard(
      negative: 'Just one won\'t hurt.',
      reframe:
          'One leads to two, leads to twenty. I\'ve worked too hard to restart.',
      emoji: '🛡️',
      color: AppColors.accent,
    ),
    _CbtCard(
      negative: 'I\'m too stressed not to smoke.',
      reframe:
          'Smoking doesn\'t reduce stress — it just delays it. Deep breaths actually help.',
      emoji: '🌬️',
      color: AppColors.secondary,
    ),
    _CbtCard(
      negative: 'Everyone around me smokes.',
      reframe:
          'Their choices don\'t control mine. I\'m choosing health for myself.',
      emoji: '🌟',
      color: AppColors.primaryDark,
    ),
    _CbtCard(
      negative: 'I\'ll gain weight if I quit.',
      reframe:
          'My lungs, heart, and skin are healing. I can manage weight with healthy habits.',
      emoji: '❤️',
      color: AppColors.error,
    ),
    _CbtCard(
      negative: 'I\'ve already failed before.',
      reframe:
          'Each attempt taught me something. This time, I\'m better prepared.',
      emoji: '📈',
      color: AppColors.primary,
    ),
    _CbtCard(
      negative: 'I\'ll never feel normal again.',
      reframe:
          'Withdrawal is temporary. Every day without smoking rewires my brain toward freedom.',
      emoji: '🧠',
      color: AppColors.info,
    ),
    _CbtCard(
      negative: 'Smoking is my only way to relax.',
      reframe: 'I\'m discovering new ways to relax that don\'t poison my body.',
      emoji: '🧘',
      color: AppColors.secondary,
    ),
    _CbtCard(
      negative: 'The damage is already done.',
      reframe:
          'My body starts healing within 20 minutes of my last cigarette. It\'s never too late.',
      emoji: '🌱',
      color: AppColors.primary,
    ),
    _CbtCard(
      negative: 'I don\'t deserve to feel this good.',
      reframe:
          'I absolutely deserve health, happiness, and clean air in my lungs.',
      emoji: '✨',
      color: AppColors.accent,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSwipe(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);

    if (index >= _affirmations.length - 1) {
      // Last card
      Future.delayed(const Duration(seconds: 1), () {
        ref.read(interventionProvider.notifier).completeIntervention();
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.lightbulb, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Mind Refreshed!'),
                ],
              ),
              content: const Text(
                'You\'ve reframed 10 negative thoughts.\n'
                'Remember: thoughts are not facts.\n'
                'You have the power to choose what you believe.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Positive Reframing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(interventionProvider.notifier).cancelIntervention();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_currentIndex + 1} / ${_affirmations.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _affirmations.length,
                    backgroundColor: AppColors.secondaryLight,
                    color: AppColors.primary,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Swipe to reframe →',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Montserrat',
              color: AppColors.textLight,
            ),
          ),

          // Card swipe
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onSwipe,
              itemCount: _affirmations.length,
              itemBuilder: (context, index) {
                final card = _affirmations[index];
                return _buildCard(card);
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard(_CbtCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Negative thought
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.error.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '❌ Negative Thought',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"${card.negative}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Icon(Icons.arrow_downward, color: card.color, size: 28),
          const SizedBox(height: 16),

          // Reframed thought
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: card.color.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(card.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'Reframed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                        color: card.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  card.reframe,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat',
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CbtCard {
  final String negative;
  final String reframe;
  final String emoji;
  final Color color;

  const _CbtCard({
    required this.negative,
    required this.reframe,
    required this.emoji,
    required this.color,
  });
}
