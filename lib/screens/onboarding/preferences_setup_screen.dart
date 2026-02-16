import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';

/// Preferences setup screen for new users to configure their profile.
class PreferencesSetupScreen extends ConsumerStatefulWidget {
  const PreferencesSetupScreen({super.key});

  @override
  ConsumerState<PreferencesSetupScreen> createState() =>
      _PreferencesSetupScreenState();
}

class _PreferencesSetupScreenState
    extends ConsumerState<PreferencesSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form fields
  String _displayName = '';
  int _cigarettesPerDay = 20;
  double _pricePerCigarette = 10.0;
  String _currency = '₹';
  DateTime? _quitDate;
  bool _isLoading = false;

  final List<String> _currencies = ['₹', '\$', '€', '£', '¥'];

  @override
  void initState() {
    super.initState();
    // Pre-fill with current user data if available
    final user = ref.read(userStreamProvider).valueOrNull;
    if (user != null) {
      _displayName = user.displayName;
      _cigarettesPerDay = user.preferences.cigarettesPerDay;
      _pricePerCigarette = user.preferences.pricePerCigarette;
      _currency = user.preferences.currency;
      _quitDate = user.quitDate ?? DateTime.now();
    } else {
      _quitDate = DateTime.now();
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate name input
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(userStreamProvider).valueOrNull;
      if (user == null) {
        throw Exception('User not found');
      }

      // Update display name
      await ref
          .read(userActionsProvider.notifier)
          .updateDisplayName(_displayName);

      // Update quit date
      if (_quitDate != null) {
        await ref.read(userActionsProvider.notifier).updateQuitDate(_quitDate!);
      }

      // Update preferences
      final updatedPreferences = user.preferences.copyWith(
        cigarettesPerDay: _cigarettesPerDay,
        pricePerCigarette: _pricePerCigarette,
        currency: _currency,
      );
      await ref
          .read(userActionsProvider.notifier)
          .updatePreferences(updatedPreferences);

      if (mounted) {
        // Navigate to main onboarding
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: AppColors.surface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            // Back button
            if (_currentPage > 0)
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousPage,
                ),
              )
            else
              const SizedBox(height: 48),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNamePage(),
                  _buildCigarettesPage(),
                  _buildPricePage(),
                  _buildQuitDatePage(),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
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
                  onPressed: _isLoading
                      ? null
                      : (_currentPage < 3 ? _nextPage : _finish),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_currentPage < 3 ? 'Next' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What should we call you?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: 'Montserrat',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This name will be visible to your supporters',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Montserrat',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              initialValue: _displayName,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              onSaved: (value) => _displayName = value?.trim() ?? '',
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCigarettesPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How many cigarettes do you smoke per day?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps us calculate your savings and progress',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Text(
                  '$_cigarettesPerDay',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'cigarettes / day',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Slider(
                  value: _cigarettesPerDay.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  onChanged: (value) {
                    setState(() => _cigarettesPerDay = value.toInt());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s the price per cigarette?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll show you how much money you\'re saving',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                // Currency selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _currencies.map((curr) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(curr),
                        selected: _currency == curr,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _currency = curr);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  '$_currency${_pricePerCigarette.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'per cigarette',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Slider(
                  value: _pricePerCigarette,
                  min: 0.10,
                  max: 50.0,
                  divisions: 499,
                  onChanged: (value) {
                    setState(() => _pricePerCigarette = value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuitDatePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When did you quit (or when will you)?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll track your smoke-free days from this date',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
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
                      const Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _quitDate != null
                            ? '${_quitDate!.day}/${_quitDate!.month}/${_quitDate!.year}'
                            : 'Not set',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _quitDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _quitDate = date);
                    }
                  },
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Change Date'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _quitDate = DateTime.now());
                  },
                  child: const Text('Use Today'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
