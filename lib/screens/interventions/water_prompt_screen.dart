import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';
import '../../services/haptic_service.dart';

/// The Water Prompt: Interactive reminder to drink water (physical substitution).
class WaterPromptScreen extends ConsumerStatefulWidget {
  const WaterPromptScreen({super.key});

  @override
  ConsumerState<WaterPromptScreen> createState() => _WaterPromptScreenState();
}

class _WaterPromptScreenState extends ConsumerState<WaterPromptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillController;
  int _sips = 0;
  static const _targetSips = 8; // One full glass
  bool _isComplete = false;
  Timer? _autoSipTimer;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _startAutoSips();
  }

  @override
  void dispose() {
    _autoSipTimer?.cancel();
    _fillController.dispose();
    super.dispose();
  }

  void _startAutoSips() {
    _autoSipTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isComplete) {
        timer.cancel();
        return;
      }
      _takeSip();
    });
  }

  void _takeSip() {
    if (_isComplete) return;

    ref.read(hapticServiceProvider).light();
    setState(() {
      _sips++;
      _fillController.animateTo(
        _sips / _targetSips,
        curve: Curves.easeInOut,
      );
    });

    if (_sips >= _targetSips) {
      _complete();
    }
  }

  void _complete() {
    setState(() => _isComplete = true);
    ref.read(hapticServiceProvider).heavy();
    ref.read(interventionProvider.notifier).completeIntervention();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.water_drop, color: AppColors.info),
              SizedBox(width: 8),
              Text('Hydrated!'),
            ],
          ),
          content: const Text(
            'You drank a full glass of water!\n\n'
            'Drinking water helps reduce cravings by:\n'
            '• Keeping your hands busy\n'
            '• Flushing out toxins\n'
            '• Reducing oral fixation',
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final fillPercent = (_sips / _targetSips * 100).toInt();

    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Water Prompt'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(interventionProvider.notifier).cancelIntervention();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: AppColors.info,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Drink a glass of water',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sips are added automatically every 2 seconds',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Glass visualization
                  GestureDetector(
                    onTap: _takeSip,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Glass outline
                        Container(
                          width: 120,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.4),
                              width: 3,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        // Water fill
                        AnimatedBuilder(
                          animation: _fillController,
                          builder: (context, _) {
                            return Container(
                              width: 114,
                              height: 194 * _fillController.value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.info.withOpacity(0.5),
                                    AppColors.info.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sip counter
                  Text(
                    '$_sips / $_targetSips sips',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$fillPercent% full',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (!_isComplete)
                    ElevatedButton.icon(
                      onPressed: _takeSip,
                      icon: const Icon(Icons.water_drop),
                      label: const Text('Take a Sip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                      ),
                    ),

                  if (_isComplete)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.primary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Glass complete!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Montserrat',
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ));
  }
}
