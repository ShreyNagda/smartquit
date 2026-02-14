import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';
import '../../services/haptic_service.dart';

/// Whack-a-Crave: A fast-paced tap game to redirect motor energy.
class WhackACraveScreen extends ConsumerStatefulWidget {
  const WhackACraveScreen({super.key});

  @override
  ConsumerState<WhackACraveScreen> createState() => _WhackACraveScreenState();
}

class _WhackACraveScreenState extends ConsumerState<WhackACraveScreen> {
  static const _gameDuration = 30; // seconds
  final Random _random = Random();

  int _score = 0;
  int _timeLeft = _gameDuration;
  bool _isPlaying = false;
  Timer? _gameTimer;
  Timer? _spawnTimer;

  // Grid: 3x4 of mole positions
  List<bool> _activePositions = List.filled(12, false);
  List<bool> _isSmoke = List.filled(12, false); // true = cigarette (bad)

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = _gameDuration;
      _isPlaying = true;
      _activePositions = List.filled(12, false);
      _isSmoke = List.filled(12, false);
    });

    // Game countdown
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _endGame();
    });

    // Spawn cravings
    _spawnCravings();
  }

  void _spawnCravings() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!_isPlaying) return;

      setState(() {
        // Clear old
        _activePositions = List.filled(12, false);
        _isSmoke = List.filled(12, false);

        // Spawn 1-3 targets
        final count = _random.nextInt(3) + 1;
        for (int i = 0; i < count; i++) {
          final pos = _random.nextInt(12);
          _activePositions[pos] = true;
          _isSmoke[pos] = _random.nextDouble() > 0.3; // 70% cigarettes
        }
      });
    });
  }

  void _onTap(int index) {
    if (!_isPlaying || !_activePositions[index]) return;

    ref.read(hapticServiceProvider).medium();

    setState(() {
      if (_isSmoke[index]) {
        _score += 10; // Hit a cigarette craving!
      } else {
        _score -= 5; // Oops, hit a flower
      }
      _activePositions[index] = false;
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    setState(() => _isPlaying = false);

    ref.read(interventionProvider.notifier).completeIntervention();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🔨 Game Over!'),
        content: Text(
          'You smashed $_score points worth of cravings!\n\n'
          'Your motor energy was redirected successfully.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startGame();
            },
            child: const Text('Play Again'),
          ),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Whack-a-Crave'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _gameTimer?.cancel();
            _spawnTimer?.cancel();
            ref.read(interventionProvider.notifier).cancelIntervention();
            Navigator.pop(context);
          },
        ),
      ),
      body: _isPlaying ? _buildGame() : _buildStart(),
    );
  }

  Widget _buildStart() {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_esports, size: 64, color: AppColors.accent),
          const SizedBox(height: 24),
          const Text(
            'Whack-a-Crave',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap the 🚬 cigarettes to smash them!\n'
            'Avoid the 🌸 flowers.\n\n'
            'Redirect that craving energy!',
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
            onPressed: _startGame,
            child: const Text('Start Whacking!'),
          ),
        ],
      ),
    ));
  }

  Widget _buildGame() {
    return Column(
      children: [
        // Score & time bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score: $_score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Montserrat',
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeft <= 10
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⏰ $_timeLeft s',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                    color:
                        _timeLeft <= 10 ? AppColors.error : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: _timeLeft / _gameDuration,
            backgroundColor: AppColors.secondaryLight,
            color: _timeLeft <= 10 ? AppColors.error : AppColors.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),

        const SizedBox(height: 24),

        // 3x4 game grid
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    return _buildCell(index);
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          '🚬 = +10 pts   🌸 = -5 pts',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Montserrat',
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCell(int index) {
    final isActive = _activePositions[index];
    final isCig = _isSmoke[index];

    return GestureDetector(
      onTap: () => _onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? (isCig
                  ? AppColors.error.withOpacity(0.15)
                  : AppColors.primaryLight.withOpacity(0.15))
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? (isCig ? AppColors.error : AppColors.primary)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: isActive
                ? Text(
                    isCig ? '🚬' : '🌸',
                    key: ValueKey('active_$index'),
                    style: const TextStyle(fontSize: 40),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ),
    );
  }
}
