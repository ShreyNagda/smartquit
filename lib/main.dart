import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/features_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/preferences_setup_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/journal/journal_screen.dart';
import 'screens/journal/journal_entry_screen.dart';
import 'screens/circle/circle_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/settings/settings_screen.dart';

// Intervention screens
import 'screens/interventions/box_breathing_screen.dart';
import 'screens/interventions/memory_match_screen.dart';
import 'screens/interventions/grounding_screen.dart';
import 'screens/interventions/urge_surfing_screen.dart';
import 'screens/interventions/savings_tracker_screen.dart';
import 'screens/interventions/whack_a_crave_screen.dart';
import 'screens/interventions/guided_visualization_screen.dart';
import 'screens/interventions/water_prompt_screen.dart';
import 'screens/interventions/positive_reframing_screen.dart';
import 'screens/interventions/quick_sketch_screen.dart';

// Shell
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize notifications
  await NotificationService().initialize();

  runApp(const ProviderScope(child: BreatheFreeApp()));
}

class BreatheFreeApp extends ConsumerStatefulWidget {
  const BreatheFreeApp({super.key});

  @override
  ConsumerState<BreatheFreeApp> createState() => _BreatheFreeAppState();
}

class _BreatheFreeAppState extends ConsumerState<BreatheFreeApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _widgetInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Initialize widget service once
    if (!_widgetInitialized) {
      _widgetInitialized = true;
      WidgetService.initialize(ref, _navigatorKey);
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'BreatheFree',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case '/':
        page = const SplashScreen();
        break;
      case '/auth-gate':
        page = const _AuthGate();
        break;
      case '/features':
        page = const FeaturesScreen();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/register':
        page = const RegisterScreen();
        break;
      case '/preferences-setup':
        page = const PreferencesSetupScreen();
        break;
      case '/onboarding':
        page = const OnboardingScreen();
        break;
      case '/home':
        page = const AppShell();
        break;
      case '/journal':
        page = const JournalScreen();
        break;
      case '/journal/new':
        page = const JournalEntryScreen();
        break;
      case '/circle':
        page = const CircleScreen();
        break;
      case '/stats':
        page = const StatsScreen();
        break;
      case '/settings':
        page = const SettingsScreen();
        break;

      // Interventions
      case '/intervention/box-breathing':
        page = const BoxBreathingScreen();
        break;
      case '/intervention/memory-match':
        page = const MemoryMatchScreen();
        break;
      case '/intervention/grounding':
        page = const GroundingScreen();
        break;
      case '/intervention/urge-surfing':
        page = const UrgeSurfingScreen();
        break;
      case '/intervention/savings-tracker':
        page = const SavingsTrackerScreen();
        break;
      case '/intervention/whack-a-crave':
        page = const WhackACraveScreen();
        break;
      case '/intervention/guided-visualization':
        page = const GuidedVisualizationScreen();
        break;
      case '/intervention/water-prompt':
        page = const WaterPromptScreen();
        break;
      case '/intervention/positive-reframing':
        page = const PositiveReframingScreen();
        break;
      case '/intervention/quick-sketch':
        page = const QuickSketchScreen();
        break;

      default:
        page = const SplashScreen();
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}

/// Auth gate — decides whether to show features or home.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const AppShell();
        }
        return const FeaturesScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const FeaturesScreen(),
    );
  }
}
