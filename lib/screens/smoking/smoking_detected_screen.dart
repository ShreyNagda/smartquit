import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';

/// Screen arguments for SmokingDetectedScreen
class SmokingDetectedArgs {
  final double? mq9Ppm;
  final int? prediction;
  final DateTime detectedAt;

  const SmokingDetectedArgs({
    this.mq9Ppm,
    this.prediction,
    required this.detectedAt,
  });
}

/// Screen shown when SmokeBand detects a smoking event.
/// Prompts user to reflect and log the event in their journal.
class SmokingDetectedScreen extends ConsumerStatefulWidget {
  final SmokingDetectedArgs? args;

  const SmokingDetectedScreen({super.key, this.args});

  @override
  ConsumerState<SmokingDetectedScreen> createState() =>
      _SmokingDetectedScreenState();
}

class _SmokingDetectedScreenState extends ConsumerState<SmokingDetectedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _proceedToJournal() {
    Navigator.of(context).pushReplacementNamed(
      '/journal/new',
      arguments: {
        'eventType': 'relapse',
        'fromSmokeBand': true,
        'detectedAt': widget.args?.detectedAt ?? DateTime.now(),
        'mq9Ppm': widget.args?.mq9Ppm,
      },
    );
  }

  void _showDismissDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Journaling?'),
        content: const Text(
          'Reflecting on what happened can help you understand your triggers '
          'and make better choices next time. Are you sure you want to skip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close this screen
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Skip Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = widget.args;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Animated alert icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error
                              .withOpacity(0.3 * _pulseController.value),
                          blurRadius: 30 + (20 * _pulseController.value),
                          spreadRadius: 10 * _pulseController.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smoking_rooms,
                      size: 70,
                      color: AppColors.error,
                    ),
                  );
                },
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 32),

              // Title
              Text(
                'Smoking Event Detected',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Your SmokeBand detected smoking activity.\nTake a moment to reflect on what happened.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),

              // Sensor data card (if available)
              if (args?.mq9Ppm != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sensors,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CO Level Detected',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${args!.mq9Ppm!.toStringAsFixed(1)} PPM',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

              const Spacer(flex: 2),

              // Encouragement message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Setbacks are part of the journey. '
                        'Understanding your triggers helps you grow stronger.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _proceedToJournal,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Reflect & Log Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _showDismissDialog,
                child: Text(
                  'Not now',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
