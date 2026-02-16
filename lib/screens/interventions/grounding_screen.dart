import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';
import '../../services/haptic_service.dart';

/// 5-4-3-2-1 Grounding: Interactive sensory input prompts.
class GroundingScreen extends ConsumerStatefulWidget {
  const GroundingScreen({super.key});

  @override
  ConsumerState<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends ConsumerState<GroundingScreen> {
  int _currentStep = 0;
  final List<TextEditingController> _controllers = [];
  final List<_GroundingStep> _steps = const [
    _GroundingStep(
      count: 5,
      sense: 'SEE',
      emoji: '👁️',
      prompt: 'Name 5 things you can SEE right now.',
      color: AppColors.primary,
    ),
    _GroundingStep(
      count: 4,
      sense: 'TOUCH',
      emoji: '✋',
      prompt: 'Name 4 things you can TOUCH right now.',
      color: AppColors.secondary,
    ),
    _GroundingStep(
      count: 3,
      sense: 'HEAR',
      emoji: '👂',
      prompt: 'Name 3 things you can HEAR right now.',
      color: AppColors.accent,
    ),
    _GroundingStep(
      count: 2,
      sense: 'SMELL',
      emoji: '👃',
      prompt: 'Name 2 things you can SMELL right now.',
      color: AppColors.primaryDark,
    ),
    _GroundingStep(
      count: 1,
      sense: 'TASTE',
      emoji: '👅',
      prompt: 'Name 1 thing you can TASTE right now.',
      color: AppColors.secondaryDark,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Create controllers for max items (5)
    for (int i = 0; i < 5; i++) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    ref.read(hapticServiceProvider).medium();

    // Clear controllers for next step
    for (final c in _controllers) {
      c.clear();
    }

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }

  void _complete() {
    ref.read(hapticServiceProvider).heavy();
    ref.read(interventionProvider.notifier).completeIntervention();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.explore, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Grounded!'),
          ],
        ),
        content: const Text(
          'You\'ve reconnected with all 5 senses.\n'
          'You are present. You are in control.\n'
          'The craving has passed.',
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

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('5-4-3-2-1 Grounding'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(interventionProvider.notifier).cancelIntervention();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i <= _currentStep ? 40 : 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? _steps[i].color
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Step display
            Text(step.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              step.sense,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                fontFamily: 'Montserrat',
                color: step.color,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              step.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Input fields
            ...List.generate(step.count, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: '${step.sense} ${i + 1}',
                    prefixIcon: Icon(Icons.circle, color: step.color, size: 12),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              );
            }),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: step.color,
                ),
                child: Text(
                  _currentStep < _steps.length - 1
                      ? 'Next Sense →'
                      : 'Complete ✓',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroundingStep {
  final int count;
  final String sense;
  final String emoji;
  final String prompt;
  final Color color;

  const _GroundingStep({
    required this.count,
    required this.sense,
    required this.emoji,
    required this.prompt,
    required this.color,
  });
}
