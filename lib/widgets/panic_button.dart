import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/intervention_provider.dart';

/// The most prominent UI element — pulsating Panic Button.
class PanicButton extends ConsumerStatefulWidget {
  final VoidCallback? onInterventionLaunched;

  const PanicButton({super.key, this.onInterventionLaunched});

  @override
  ConsumerState<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends ConsumerState<PanicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();

    // Continuous pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Press animation
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTap() {
    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Press animation
    _pressController.forward().then((_) {
      _pressController.reverse();
    });

    // Launch random intervention
    final intervention =
        ref.read(interventionProvider.notifier).launchRandomIntervention();

    widget.onInterventionLaunched?.call();

    // Navigate to the intervention
    Navigator.of(context).pushNamed(intervention.route);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _pressAnimation]),
      builder: (context, child) {
        final scale = _pulseAnimation.value * _pressAnimation.value;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _onTap,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                AppColors.accent,
                AppColors.panicOuter,
              ],
              center: Alignment.center,
              radius: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.panicGlow,
                blurRadius: 30,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFF8A65),
                  AppColors.accent,
                ],
                center: Alignment(-0.2, -0.2),
                radius: 0.9,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 4),
                Text(
                  'I NEED\nHELP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    height: 1.2,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
