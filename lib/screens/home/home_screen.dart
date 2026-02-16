import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/ble_provider.dart';
import '../../services/ble_service.dart';
import '../../widgets/panic_button.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/stats_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _bleInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize BLE on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBLE();
    });
  }

  Future<void> _initializeBLE() async {
    if (_bleInitialized) return;
    _bleInitialized = true;

    // Set up smoking detection callback
    ref.read(smokingDetectedCallbackProvider.notifier).state = () {
      _handleSmokingDetected();
    };

    // Set up device not found callback
    ref.read(deviceNotFoundCallbackProvider.notifier).state = () {
      _showDeviceNotFoundSnackBar();
    };

    // Initialize BLE connection
    await ref.read(bleNotifierProvider.notifier).initialize();
  }

  void _showDeviceNotFoundSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SmartQuit Band not found'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSmokingDetected() {
    // Navigate to journal entry with relapse event
    Navigator.of(context).pushNamed(
      '/journal/new',
      arguments: {'eventType': 'relapse'},
    );
  }

  void _showBluetoothDialog(BleState bleState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SmartQuit Band'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  bleState.isConnected ? Icons.check_circle : Icons.cancel,
                  color: bleState.isConnected
                      ? AppColors.primary
                      : AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  bleState.isConnected
                      ? 'Connected'
                      : _getStatusText(bleState.connectionState),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
            if (!bleState.isConnected) ...[
              const SizedBox(height: 16),
              const Text(
                'Make sure your SmartQuit Band is powered on and nearby.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (!bleState.isConnected)
            ElevatedButton(
              onPressed: () {
                ref.read(bleNotifierProvider.notifier).startConnection();
                Navigator.pop(ctx);
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  String _getStatusText(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.scanning:
        return 'Scanning...';
      case BleConnectionState.connecting:
        return 'Connecting...';
      case BleConnectionState.connected:
        return 'Connected';
      case BleConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStreamProvider).valueOrNull;
    final streakDays = ref.watch(streakDaysProvider);
    final moneySaved = ref.watch(moneySavedProvider);
    final cigarettesAvoided = ref.watch(cigarettesNotSmokedProvider);
    final cravingsBlocked = ref.watch(cravingsBlockedProvider);
    final healthRecovery = ref.watch(healthRecoveryProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final bleState = ref.watch(bleNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montserrat',
                              color: AppColors.textPrimary,
                            ),
                            children: [
                              TextSpan(
                                  text:
                                      'Hey, ${user?.displayName ?? 'Friend'}'),
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    Icons.waving_hand,
                                    color: AppColors.secondary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            bleState.isConnected
                                ? Icons.bluetooth_connected_rounded
                                : Icons.bluetooth_rounded,
                            color: bleState.isConnected
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                          onPressed: () {
                            _showBluetoothDialog(bleState);
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Every breath counts.',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Streak Card
              StreakCard(
                streakDays: streakDays,
                cravingsBlocked: cravingsBlocked,
              ),

              const SizedBox(height: 32),

              // PANIC BUTTON — Most prominent element
              const Center(
                child: PanicButton(),
              ),

              const SizedBox(height: 12),
              const Text(
                'Tap when a craving hits',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // Quick stats grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Money Saved',
                        value: currencyFormat.format(moneySaved),
                        subtitle: 'Keep going!',
                        icon: Icons.savings_rounded,
                        gradient: AppColors.warmGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: 'Not Smoked',
                        value: '$cigarettesAvoided',
                        subtitle: 'cigarettes',
                        icon: Icons.smoke_free_rounded,
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Health Recovery',
                        value: '${(healthRecovery * 100).toStringAsFixed(1)}%',
                        subtitle: 'Body healing',
                        icon: Icons.favorite_rounded,
                        gradient: AppColors.accentGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatsCard(
                        title: 'Interventions',
                        value: '${user?.stats.totalInterventionsUsed ?? 0}',
                        subtitle: 'activities completed',
                        icon: Icons.psychology_rounded,
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Motivation quote
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Text('💬', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '"The secret of getting ahead is getting started."',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
