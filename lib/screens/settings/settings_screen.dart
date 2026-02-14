import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

/// Settings screen with preferences, privacy, and account management.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montserrat',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Montserrat',
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: user.supportCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied!')),
                              );
                            },
                            child: Text(
                              'Code: ${user.supportCode}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Smoking preferences
              _sectionHeader('Smoking Preferences'),
              const SizedBox(height: 8),
              _infoTile(
                icon: Icons.smoking_rooms,
                title: 'Cigarettes / Day',
                value: '${user.preferences.cigarettesPerDay}',
                onTap: () => _editNumber(
                  context,
                  ref,
                  title: 'Cigarettes per day',
                  current: user.preferences.cigarettesPerDay,
                  onSave: (v) => ref
                      .read(userActionsProvider.notifier)
                      .updatePreferences(
                          user.preferences.copyWith(cigarettesPerDay: v)),
                ),
              ),
              _infoTile(
                icon: Icons.attach_money,
                title: 'Price / Cigarette',
                value:
                    '${user.preferences.currency}${user.preferences.pricePerCigarette.toStringAsFixed(2)}',
                onTap: () => _editPrice(
                  context,
                  ref,
                  current: user.preferences.pricePerCigarette,
                  onSave: (v) => ref
                      .read(userActionsProvider.notifier)
                      .updatePreferences(
                          user.preferences.copyWith(pricePerCigarette: v)),
                ),
              ),
              _infoTile(
                icon: Icons.calendar_today,
                title: 'Quit Date',
                value: user.quitDate != null
                    ? '${user.quitDate!.month}/${user.quitDate!.day}/${user.quitDate!.year}'
                    : 'Not set',
                onTap: () => _editQuitDate(context, ref, user.quitDate),
              ),
              const SizedBox(height: 24),

              // App preferences
              _sectionHeader('App Preferences'),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  'Haptic Feedback',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Vibrate during interventions',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                value: user.preferences.hapticFeedback,
                onChanged: (v) => ref
                    .read(userActionsProvider.notifier)
                    .updatePreferences(
                        user.preferences.copyWith(hapticFeedback: v)),
                activeColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text(
                  'Daily Reminders',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Receive daily motivation notifications',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                value: user.preferences.dailyReminders,
                onChanged: (v) => ref
                    .read(userActionsProvider.notifier)
                    .updatePreferences(
                        user.preferences.copyWith(dailyReminders: v)),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 24),

              // Account
              _sectionHeader('Account'),
              const SizedBox(height: 8),
              ListTile(
                leading:
                    const Icon(Icons.logout, color: AppColors.textSecondary),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                  ),
                ),
                onTap: () => _confirmSignOut(context, ref),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_forever, color: AppColors.error),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
              const SizedBox(height: 32),

              // App info
              const Center(
                child: Text(
                  'BreatheFree V2\nMade with 💚',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: 'Montserrat',
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      onTap: onTap,
    );
  }

  void _editNumber(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int current,
    required ValueChanged<int> onSave,
  }) {
    final controller = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '$current'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v > 0) {
                onSave(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPrice(
    BuildContext context,
    WidgetRef ref, {
    required double current,
    required ValueChanged<double> onSave,
  }) {
    final controller = TextEditingController(text: current.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Price per cigarette'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: current.toStringAsFixed(2)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) {
                onSave(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editQuitDate(
      BuildContext context, WidgetRef ref, DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(userActionsProvider.notifier).updateQuitDate(picked);
    }
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
              Navigator.pop(ctx);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone.\nAll your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // Auth service deleteAccount
              ref.read(authServiceProvider).deleteAccount();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
