import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';

/// Urge Surfing: A 10-minute "wave" visualization.
class UrgeSurfingScreen extends ConsumerStatefulWidget {
  const UrgeSurfingScreen({super.key});

  @override
  ConsumerState<UrgeSurfingScreen> createState() => _UrgeSurfingScreenState();
}

class _UrgeSurfingScreenState extends ConsumerState<UrgeSurfingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  Timer? _timer;
  int _secondsRemaining = 600; // 10 minutes
  bool _isActive = false;
  double _waveIntensity = 1.0; // Starts high, decreases
  int _currentPhase = 0;

  static const _phases = [
    _UrgeSurfingPhase(
      title: 'The Wave Rises',
      message: 'Notice the craving building.\nDon\'t fight it — observe it.',
      duration: 120,
    ),
    _UrgeSurfingPhase(
      title: 'Peak Intensity',
      message: 'The wave is at its highest.\nRemember: it WILL pass.',
      duration: 120,
    ),
    _UrgeSurfingPhase(
      title: 'The Crest',
      message: 'You\'re riding the top.\nBreathe slowly and deeply.',
      duration: 120,
    ),
    _UrgeSurfingPhase(
      title: 'The Decline',
      message: 'Feel the intensity dropping.\nYou\'re doing amazing.',
      duration: 120,
    ),
    _UrgeSurfingPhase(
      title: 'Calm Waters',
      message: 'The wave has passed.\nYou are in control.',
      duration: 120,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _secondsRemaining--;
        // Update wave intensity
        _waveIntensity = _calculateIntensity();
        // Update phase
        _currentPhase = _calculatePhase();
      });

      if (_secondsRemaining <= 0) {
        _complete();
      }
    });
  }

  double _calculateIntensity() {
    final elapsed = 600 - _secondsRemaining;
    // Bell curve: peaks around 2-3 minutes, then declines
    final x = elapsed / 600.0;
    return (sin(x * pi) * 0.8 + 0.2).clamp(0.1, 1.0);
  }

  int _calculatePhase() {
    final elapsed = 600 - _secondsRemaining;
    return (elapsed ~/ 120).clamp(0, 4);
  }

  void _complete() {
    _timer?.cancel();
    setState(() => _isActive = false);
    ref.read(interventionProvider.notifier).completeIntervention();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🌊 Wave Passed!'),
        content: const Text(
          'You successfully surfed the urge!\n'
          'Every craving is temporary. You proved it.',
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

  String get _timeDisplay {
    final min = _secondsRemaining ~/ 60;
    final sec = _secondsRemaining % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Urge Surfing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timer?.cancel();
            ref.read(interventionProvider.notifier).cancelIntervention();
            Navigator.pop(context);
          },
        ),
      ),
      body: _isActive ? _buildActiveView() : _buildStartView(),
    );
  }

  Widget _buildStartView() {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.waves, size: 64, color: AppColors.info),
          const SizedBox(height: 24),
          const Text(
            'Urge Surfing',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cravings are like ocean waves.\n'
            'They rise, they peak, and they always pass.\n\n'
            'Spend 10 minutes riding the wave.\n'
            'Observe without acting.',
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
            child: const Text('Start Surfing'),
          ),
        ],
      ),
    ));
  }

  Widget _buildActiveView() {
    final phase = _phases[_currentPhase];

    return Column(
      children: [
        // Timer
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _timeDisplay,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.primary,
            ),
          ),
        ),

        // Phase info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                phase.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Montserrat',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phase.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Montserrat',
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Wave visualization
        Expanded(
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 200),
                painter: _WavePainter(
                  progress: _waveController.value,
                  intensity: _waveIntensity,
                ),
              );
            },
          ),
        ),

        // Intensity indicator
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Wave Intensity',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _waveIntensity,
                backgroundColor: AppColors.secondaryLight,
                color: Color.lerp(
                    AppColors.primary, AppColors.accent, _waveIntensity)!,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double intensity;

  _WavePainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.4 * intensity),
          AppColors.primary.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          sin((x / size.width * 4 * pi) + (progress * 2 * pi)) *
              (40 * intensity) +
          sin((x / size.width * 2 * pi) + (progress * pi)) * (20 * intensity);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Second wave layer
    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withOpacity(0.2 * intensity),
          AppColors.accent.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path();
    path2.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.6 +
          sin((x / size.width * 3 * pi) + (progress * 2 * pi) + 1) *
              (30 * intensity);
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}

class _UrgeSurfingPhase {
  final String title;
  final String message;
  final int duration;

  const _UrgeSurfingPhase({
    required this.title,
    required this.message,
    required this.duration,
  });
}
