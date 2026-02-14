import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/intervention_provider.dart';

/// Service to handle communication with Android home screen widget
class WidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.smartquit.breathfree/widget');

  /// Initialize widget communication channel
  static void initialize(
      WidgetRef ref, GlobalKey<NavigatorState> navigatorKey) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'launchIntervention') {
        // Launch a random intervention from the widget
        final intervention =
            ref.read(interventionProvider.notifier).launchRandomIntervention();

        // Navigate to the intervention screen
        navigatorKey.currentState?.pushNamed(intervention.route);
      }
    });
  }
}
