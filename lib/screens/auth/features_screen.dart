import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and CTA buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    '🌿',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SmartQuit',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Montserrat',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Research-Based Smoking Cessation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/login');
                          },
                          child: const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/register');
                          },
                          child: const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: const [
                  SizedBox(height: 16),
                  Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Montserrat',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20),
                  _FeatureCard(
                    icon: '🆘',
                    title: 'Panic Button',
                    description:
                        'Instant access to evidence-based interventions when cravings strike.',
                  ),
                  _FeatureCard(
                    icon: '🧘',
                    title: '10 Evidence-Based Interventions',
                    description:
                        'Box breathing, grounding exercises, visualization, mindfulness, and more.',
                  ),
                  _FeatureCard(
                    icon: '📊',
                    title: 'Progress Dashboard',
                    description:
                        'Track your smoke-free time, money saved, and health milestones.',
                  ),
                  _FeatureCard(
                    icon: '📈',
                    title: 'Statistics & Analytics',
                    description:
                        'Understand your patterns with detailed craving and success tracking.',
                  ),
                  _FeatureCard(
                    icon: '📱',
                    title: 'SmartQuit Band Integration',
                    description:
                        'Connect to ESP32-based wearable with real-time smoke and gesture detection.',
                  ),
                  _FeatureCard(
                    icon: '🎯',
                    title: 'Personalized Experience',
                    description:
                        'Customize interventions, notifications, and settings to fit your journey.',
                  ),
                  _FeatureCard(
                    icon: '🔔',
                    title: 'Smart Notifications',
                    description:
                        'Get motivational reminders and milestone celebrations at the right time.',
                  ),
                  _FeatureCard(
                    icon: '🤝',
                    title: 'Support Circle',
                    description:
                        'Connect with family, friends, and consultants for additional support.',
                  ),
                  _FeatureCard(
                    icon: '💾',
                    title: 'Cloud Sync',
                    description:
                        'Your progress is backed up and synced across all your devices.',
                  ),
                  _FeatureCard(
                    icon: '🔬',
                    title: 'Research-Driven',
                    description:
                        'Built on WHO guidelines, CBT principles, and MBSR techniques.',
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    color: AppColors.textSecondary,
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
