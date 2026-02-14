import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';
import '../../services/haptic_service.dart';

/// Guided Visualization: A 2-minute audio-visual "safe space" builder.
class GuidedVisualizationScreen extends ConsumerStatefulWidget {
  const GuidedVisualizationScreen({super.key});

  @override
  ConsumerState<GuidedVisualizationScreen> createState() =>
      _GuidedVisualizationScreenState();
}

class _GuidedVisualizationScreenState
    extends ConsumerState<GuidedVisualizationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  int _secondsRemaining = 120; // 2 minutes
  int _currentScene = 0;
  bool _isActive = false;

  static const _scenes = [
    _Scene(
      emoji: '🌅',
      title: 'Close Your Eyes',
      instruction: 'Take a deep breath.\nImagine yourself in a peaceful place.',
      bgColor: Color(0xFFFFF3E0),
      duration: 20,
    ),
    _Scene(
      emoji: '🏔️',
      title: 'Build Your Space',
      instruction:
          'Imagine a mountain meadow.\nFeel the soft grass beneath your feet.',
      bgColor: Color(0xFFE8F5E9),
      duration: 20,
    ),
    _Scene(
      emoji: '🌤️',
      title: 'Feel the Warmth',
      instruction:
          'The sun warms your face.\nA gentle breeze carries away all tension.',
      bgColor: Color(0xFFFFF8E1),
      duration: 20,
    ),
    _Scene(
      emoji: '🌊',
      title: 'Hear the Water',
      instruction:
          'A stream flows nearby.\nIts rhythm matches your calm heartbeat.',
      bgColor: Color(0xFFE3F2FD),
      duration: 20,
    ),
    _Scene(
      emoji: '🦋',
      title: 'Release the Craving',
      instruction:
          'Watch the craving float away like a butterfly.\nIt has no power over you here.',
      bgColor: Color(0xFFF3E5F5),
      duration: 20,
    ),
    _Scene(
      emoji: '🌟',
      title: 'Return Refreshed',
      instruction:
          'Slowly open your eyes.\nBring this peace with you.\nYou are strong.',
      bgColor: Color(0xFFFFF9C4),
      duration: 20,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  Future<void> _playTransitionSound() async {
    try {
      // Play a soft chime sound for scene transitions
      await _audioPlayer.play(AssetSource('audio/chime.mp3'), volume: 0.5);
    } catch (e) {
      // Silently fail if audio file doesn't exist
      debugPrint('Audio playback error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isActive = true;
      _currentScene = 0;
      _secondsRemaining = 120;
    });

    int previousScene = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _secondsRemaining--;
        _currentScene = (120 - _secondsRemaining) ~/ 20;
        if (_currentScene >= _scenes.length) {
          _currentScene = _scenes.length - 1;
        }

        // Trigger feedback on scene change
        if (_currentScene != previousScene) {
          ref.read(hapticServiceProvider).light();
          _playTransitionSound();
          previousScene = _currentScene;
        }
      });

      if (_secondsRemaining <= 0) {
        _complete();
      }
    });
  }

  void _complete() {
    _timer?.cancel();
    setState(() => _isActive = false);
    ref.read(hapticServiceProvider).heavy();
    _playTransitionSound();
    ref.read(interventionProvider.notifier).completeIntervention();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.landscape, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Safe Space Complete'),
          ],
        ),
        content: const Text(
          'You took 2 minutes to center yourself.\n'
          'Remember, you can return to this space anytime.',
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Safe Space'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timer?.cancel();
            ref.read(interventionProvider.notifier).cancelIntervention();
            Navigator.pop(context);
          },
        ),
      ),
      body: _isActive ? _buildVisualization() : _buildStart(),
    );
  }

  Widget _buildStart() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏔️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text(
            'Guided Visualization',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Spend 2 minutes building a calming mental safe space.\n\n'
            'Find a quiet spot, close your eyes, and follow the prompts.',
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
            child: const Text('Begin Journey'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualization() {
    final scene = _scenes[_currentScene];
    final min = _secondsRemaining ~/ 60;
    final sec = _secondsRemaining % 60;

    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        return AnimatedContainer(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scene.bgColor,
                scene.bgColor.withOpacity(0.5 + _bgController.value * 0.3),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer
                  Text(
                    '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),

                  // Scene
                  AnimatedSwitcher(
                    duration: const Duration(seconds: 1),
                    child: Column(
                      key: ValueKey(_currentScene),
                      children: [
                        Text(scene.emoji, style: const TextStyle(fontSize: 72)),
                        const SizedBox(height: 24),
                        Text(
                          scene.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Montserrat',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          scene.instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Montserrat',
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_scenes.length, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentScene == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i <= _currentScene
                              ? AppColors.primary
                              : AppColors.textLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Scene {
  final String emoji;
  final String title;
  final String instruction;
  final Color bgColor;
  final int duration;

  const _Scene({
    required this.emoji,
    required this.title,
    required this.instruction,
    required this.bgColor,
    required this.duration,
  });
}
