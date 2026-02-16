import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';
import '../../services/haptic_service.dart';

/// Box Breathing: Haptic-guided 4-4-4-4 rhythm.
class BoxBreathingScreen extends ConsumerStatefulWidget {
  const BoxBreathingScreen({super.key});

  @override
  ConsumerState<BoxBreathingScreen> createState() => _BoxBreathingScreenState();
}

class _BoxBreathingScreenState extends ConsumerState<BoxBreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _phase = 0; // 0=inhale, 1=hold, 2=exhale, 3=hold
  int _cycles = 0;
  int _countdown = 4;
  Timer? _timer;
  bool _isActive = false;

  static const _phaseLabels = ['Breathe In', 'Hold', 'Breathe Out', 'Hold'];
  static const _phaseColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.secondaryDark,
  ];
  static const _phaseIcons = [
    Icons.air,
    Icons.pause_circle_outline,
    Icons.wind_power,
    Icons.pause_circle_outline,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isActive = true;
      _phase = 0;
      _cycles = 0;
      _countdown = 4;
    });
    _runPhase();
  }

  void _runPhase() {
    _countdown = 4;
    _animController.forward(from: 0);

    // Haptic at start of each phase
    ref.read(hapticServiceProvider).medium();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      // Light haptic each second
      ref.read(hapticServiceProvider).light();

      if (_countdown <= 0) {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    setState(() {
      _phase = (_phase + 1) % 4;
      if (_phase == 0) _cycles++;
    });

    if (_cycles >= 4) {
      _complete();
      return;
    }

    _runPhase();
  }

  void _complete() {
    _timer?.cancel();
    setState(() => _isActive = false);
    ref.read(hapticServiceProvider).heavy();
    ref.read(interventionProvider.notifier).completeIntervention();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Well Done!'),
          ],
        ),
        content: const Text(
          'You completed 4 cycles of box breathing. '
          'Your body and mind are calmer now.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Box Breathing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(interventionProvider.notifier).cancelIntervention();
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: _isActive ? _buildActiveView() : _buildStartView(),
      ),
    );
  }

  Widget _buildStartView() {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.air, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Box Breathing',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Breathe in a 4-4-4-4 pattern.\nInhale → Hold → Exhale → Hold.\nEach phase lasts 4 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _start,
            child: const Text('Begin'),
          ),
        ],
      ),
    ));
  }

  Widget _buildActiveView() {
    final phaseColor = _phaseColors[_phase];

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cycle indicator
          Text(
            'Cycle ${_cycles + 1} of 4',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Phase icon
          Icon(_phaseIcons[_phase], size: 48, color: phaseColor),
          const SizedBox(height: 16),

          // Phase label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: phaseColor,
            ),
            child: Text(_phaseLabels[_phase]),
          ),
          const SizedBox(height: 32),

          // Animated circle with countdown
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: phaseColor.withOpacity(0.3),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    width: _phase == 0
                        ? 140
                        : _phase == 2
                            ? 60
                            : 100,
                    height: _phase == 0
                        ? 140
                        : _phase == 2
                            ? 60
                            : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: phaseColor.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                          color: phaseColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),

          // Phase dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _phase == i
                      ? _phaseColors[i]
                      : _phaseColors[i].withOpacity(0.2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
