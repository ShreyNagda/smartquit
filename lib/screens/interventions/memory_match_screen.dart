import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';

/// Memory Match: 4x4 nature-themed card flip game.
class MemoryMatchScreen extends ConsumerStatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  ConsumerState<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends ConsumerState<MemoryMatchScreen> {
  static const _natureEmojis = [
    '🌲',
    '🌻',
    '🦋',
    '🌈',
    '🍃',
    '🌸',
    '🐦',
    '🌊',
  ];

  late List<String> _cards;
  late List<bool> _revealed;
  late List<bool> _matched;
  int? _firstIndex;
  int? _secondIndex;
  bool _isChecking = false;
  int _moves = 0;
  int _matchesFound = 0;
  Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _cards = [..._natureEmojis, ..._natureEmojis]..shuffle(Random());
    _revealed = List.filled(16, false);
    _matched = List.filled(16, false);
    _firstIndex = null;
    _secondIndex = null;
    _isChecking = false;
    _moves = 0;
    _matchesFound = 0;
    _stopwatch = Stopwatch()..start();
  }

  void _onCardTap(int index) {
    if (_isChecking || _revealed[index] || _matched[index]) return;

    HapticFeedback.lightImpact();

    setState(() {
      _revealed[index] = true;
    });

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _secondIndex = index;
      _moves++;
      _isChecking = true;

      // Check for match
      if (_cards[_firstIndex!] == _cards[_secondIndex!]) {
        // Match found!
        HapticFeedback.heavyImpact();
        setState(() {
          _matched[_firstIndex!] = true;
          _matched[_secondIndex!] = true;
          _matchesFound++;
          _firstIndex = null;
          _secondIndex = null;
          _isChecking = false;
        });

        if (_matchesFound == 8) {
          _stopwatch.stop();
          _complete();
        }
      } else {
        // No match — flip back after delay
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _revealed[_firstIndex!] = false;
              _revealed[_secondIndex!] = false;
              _firstIndex = null;
              _secondIndex = null;
              _isChecking = false;
            });
          }
        });
      }
    }
  }

  void _complete() {
    ref.read(interventionProvider.notifier).completeIntervention();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('All Matched!'),
          ],
        ),
        content: Text(
          'You found all pairs in $_moves moves!\n'
          'Time: ${_stopwatch.elapsed.inSeconds} seconds\n\n'
          'Your craving focus shifted successfully.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _initializeGame());
            },
            child: const Text('Play Again'),
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
        title: const Text('Memory Match'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(interventionProvider.notifier).cancelIntervention();
            Navigator.pop(context);
          },
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Moves: $_moves',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: _matchesFound / 8,
              backgroundColor: AppColors.secondaryLight,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              '$_matchesFound / 8 pairs found',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Montserrat',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // 4x4 Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  return _buildCard(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    final isRevealed = _revealed[index] || _matched[index];
    final isMatched = _matched[index];

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isMatched
              ? AppColors.primaryLight.withOpacity(0.3)
              : isRevealed
                  ? AppColors.surface
                  : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMatched
                ? AppColors.primary
                : isRevealed
                    ? AppColors.secondaryLight
                    : AppColors.primaryDark,
            width: 2,
          ),
          boxShadow: isRevealed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isRevealed
                ? Text(
                    _cards[index],
                    key: ValueKey('revealed_$index'),
                    style: const TextStyle(fontSize: 32),
                  )
                : const Icon(
                    Icons.eco,
                    key: ValueKey('hidden'),
                    color: Colors.white54,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}
