import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';

/// Onboarding flow with welcome, tips, and supporter invitation.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      emoji: '🌿',
      title: 'Welcome to BreatheFree',
      description: 'You\'ve taken the most important step. '
          'This app is your companion on the journey to a smoke-free life.',
    ),
    _OnboardingPage(
      emoji: '🆘',
      title: 'Your Panic Button',
      description:
          'When a craving hits, press the big button on your home screen. '
          'We\'ll launch a random distraction activity to help you ride it out.',
    ),
    _OnboardingPage(
      emoji: '📓',
      title: 'Track Your Journey',
      description: 'Log your cravings, near-misses, and milestones. '
          'Understanding your triggers is key to staying smoke-free.',
    ),
    _OnboardingPage(
      emoji: '👨‍👩‍👧‍👦',
      title: 'Build Your Circle',
      description: 'Invite family & friends to support you. '
          'They can see your progress and send you strength when you need it most.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStreamProvider).valueOrNull;

    // Total pages = info pages + invite page
    final totalPages = _pages.length + 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _buildInfoPage(_pages[index]);
                  } else {
                    return _buildInvitePage(user?.supportCode ?? '...');
                  }
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primary
                          : AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _currentPage < totalPages - 1 ? _nextPage : _finish,
                  child: Text(
                    _currentPage < totalPages - 1 ? 'Next' : 'Get Started',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            page.emoji,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
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
    );
  }

  Widget _buildInvitePage(String supportCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🤝',
            style: TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 32),
          const Text(
            'Invite a Supporter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share your Support Code with a family member or friend. '
            'They can join your circle and cheer you on.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Support code display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Your Support Code',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  supportCode,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () {
              // Share the support code
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Share this code with your supporter: $supportCode'),
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Code'),
          ),

          const SizedBox(height: 12),
          const Text(
            'You can always invite supporters later from Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Montserrat',
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
