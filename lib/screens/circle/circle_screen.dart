import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/supporter_model.dart';
import '../../providers/circle_provider.dart';
import '../../providers/user_provider.dart';

/// The Circle — family/supporter monitoring screen.
class CircleScreen extends ConsumerStatefulWidget {
  const CircleScreen({super.key});

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('The Circle'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Supporters'),
            Tab(text: 'Invite & Privacy'),
          ],
          labelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _SupportersTab(),
              _InvitePrivacyTab(supportCode: user.supportCode),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Tab showing linked supporters and incoming nudges.
class _SupportersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleState = ref.watch(circleProvider);
    final nudgesAsync = ref.watch(nudgesStreamProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(circleProvider.notifier).loadSupporters();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Send Strength section
          _buildSendStrengthCard(context, ref),
          const SizedBox(height: 16),

          // Nudges received
          nudgesAsync.when(
            data: (nudges) {
              if (nudges.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💌 Messages of Strength',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...nudges.take(5).map((n) => _buildNudgeCard(n)),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Supporters list
          const Text(
            '👥 Your Supporters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (circleState.supporters.isEmpty)
            _buildNoSupportersCard()
          else
            ...circleState.supporters
                .map((s) => _buildSupporterCard(context, ref, s)),
        ],
      ),
    );
  }

  Widget _buildSendStrengthCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            '🤝',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send Strength',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Let your supporters know you\'re thinking of them',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showSendStrengthDialog(context, ref),
            child: const Text('Send 💪'),
          ),
        ],
      ),
    );
  }

  void _showSendStrengthDialog(BuildContext context, WidgetRef ref) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Strength'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your supporters will receive a notification with your message.',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Montserrat',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'I\'m staying strong today!',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = messageController.text.isNotEmpty
                  ? messageController.text
                  : 'Sending strength your way! 💪';
              final supporters = ref.read(circleProvider).supporters;
              for (final s in supporters) {
                await ref.read(circleProvider.notifier).sendStrength(
                      toUid: s.uid,
                      message: message,
                    );
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Strength sent! 💪')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildNudgeCard(NudgeMessage nudge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Text('💌', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nudge.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'from ${nudge.fromName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    color: AppColors.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSupportersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Text('👥', style: TextStyle(fontSize: 40)),
          SizedBox(height: 8),
          Text(
            'No supporters yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Share your support code from the\nInvite tab to connect with family & friends.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Montserrat',
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupporterCard(
      BuildContext context, WidgetRef ref, SupporterModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              s.displayName.isNotEmpty ? s.displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  s.role == SupporterRole.supporter ? 'Supporter' : 'User',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.textLight),
            onPressed: () => _confirmRemove(context, ref, s),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, SupporterModel s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Supporter'),
        content: Text('Remove ${s.displayName} from your circle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(circleProvider.notifier).removeSupporter(s.uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// Tab for invite code sharing and privacy controls.
class _InvitePrivacyTab extends ConsumerStatefulWidget {
  final String supportCode;
  const _InvitePrivacyTab({required this.supportCode});

  @override
  ConsumerState<_InvitePrivacyTab> createState() => _InvitePrivacyTabState();
}

class _InvitePrivacyTabState extends ConsumerState<_InvitePrivacyTab> {
  final _joinCodeController = TextEditingController();

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circleState = ref.watch(circleProvider);
    final userAsync = ref.watch(userStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Your support code
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Your Support Code',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.supportCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.supportCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support code copied!')),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text(
                  'Copy Code',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share this code with family & friends\nso they can join your circle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Join someone's circle
        const Text(
          'Join Someone\'s Circle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _joinCodeController,
                decoration: const InputDecoration(
                  hintText: 'Enter support code (BF-XXXX)',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: circleState.isLoading
                  ? null
                  : () async {
                      final code = _joinCodeController.text.trim();
                      if (code.isEmpty) return;
                      final success = await ref
                          .read(circleProvider.notifier)
                          .joinCircle(code);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Joined circle! 🎉'
                                : 'Code not found. Try again.'),
                          ),
                        );
                        if (success) _joinCodeController.clear();
                      }
                    },
              child: circleState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Join'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Privacy controls
        const Text(
          '🔒 Privacy Controls',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose what your supporters can see.',
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Montserrat',
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        userAsync.when(
          data: (user) {
            if (user == null) return const SizedBox.shrink();
            final privacy = user.privacySettings;
            return Column(
              children: [
                _privacyTile(
                  title: 'Share Streak',
                  subtitle: 'Supporters see your smoke-free days',
                  value: privacy.shareStreak,
                  onChanged: (v) => _updatePrivacy(
                    privacy.copyWith(shareStreak: v),
                  ),
                ),
                _privacyTile(
                  title: 'Share Money Saved',
                  subtitle: 'Supporters see your savings progress',
                  value: privacy.shareMoneySaved,
                  onChanged: (v) => _updatePrivacy(
                    privacy.copyWith(shareMoneySaved: v),
                  ),
                ),
                _privacyTile(
                  title: 'Share Journal',
                  subtitle: 'Supporters see craving/relapse entries',
                  value: privacy.shareJournalEntries,
                  onChanged: (v) => _updatePrivacy(
                    privacy.copyWith(shareJournalEntries: v),
                  ),
                ),
                _privacyTile(
                  title: 'Share Panic Alerts',
                  subtitle:
                      'Supporters get notified when you hit the Panic Button',
                  value: privacy.sharePanicAlerts,
                  onChanged: (v) => _updatePrivacy(
                    privacy.copyWith(sharePanicAlerts: v),
                  ),
                ),
                _privacyTile(
                  title: 'Share Health Progress',
                  subtitle: 'Supporters see your health recovery %',
                  value: privacy.shareHealthProgress,
                  onChanged: (v) => _updatePrivacy(
                    privacy.copyWith(shareHealthProgress: v),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
        const SizedBox(height: 16),

        // Quick presets
        const Text(
          'Quick Privacy Presets',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updatePrivacy(PrivacySettings.streaksOnly),
                child: const Text('Streaks Only'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updatePrivacy(PrivacySettings.shareAll),
                child: const Text('Share All'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _privacyTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'Montserrat',
          color: AppColors.textLight,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  void _updatePrivacy(PrivacySettings updated) {
    ref.read(circleProvider.notifier).updatePrivacy(updated);
  }
}
