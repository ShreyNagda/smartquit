import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ble_service.dart';
import '../services/ble_logs_service.dart';
import '../models/ble_log_entry.dart';

/// BLE service provider (singleton).
final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// BLE state notifier for managing connection and data.
final bleNotifierProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  return BleNotifier(ref);
});

// ─── BLE State ──────────────────────────────────────────────────

class BleState {
  final BleConnectionState connectionState;
  final Map<String, dynamic>? latestData;
  final String? error;

  const BleState({
    this.connectionState = BleConnectionState.disconnected,
    this.latestData,
    this.error,
  });

  BleState copyWith({
    BleConnectionState? connectionState,
    Map<String, dynamic>? latestData,
    String? error,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      latestData: latestData ?? this.latestData,
      error: error,
    );
  }

  bool get isConnected => connectionState == BleConnectionState.connected;
}

// ─── BLE Notifier ───────────────────────────────────────────────

class BleNotifier extends StateNotifier<BleState> {
  final Ref _ref;
  late final BleService _bleService;
  final BleLogsService _logsService = BleLogsService();
  bool _initialConnectionAttempted = false;

  BleNotifier(this._ref) : super(const BleState()) {
    _bleService = _ref.read(bleServiceProvider);
    _setupCallbacks();
  }

  /// Setup BLE service callbacks.
  void _setupCallbacks() {
    _bleService.onConnectionStateChanged = (connectionState) {
      state = state.copyWith(connectionState: connectionState);
    };

    _bleService.onDataReceived = (data) {
      state = state.copyWith(latestData: data);
      // Log the data
      try {
        final logEntry = BleLogEntry.fromJson(data, DateTime.now());
        _logsService.addLog(logEntry);
      } catch (e) {
        print('❌ Error logging BLE data: $e');
      }
      _checkForSmokingEvent(data);
    };

    _bleService.onDeviceNotFound = () {
      _ref.read(deviceNotFoundCallbackProvider)?.call();
    };
  }

  /// Initialize BLE permissions only (called once on app launch).
  Future<bool> initializePermissions() async {
    try {
      final initialized = await _bleService.initialize();
      if (!initialized) {
        state = state.copyWith(error: 'BLE initialization failed');
      }
      return initialized;
    } catch (e) {
      state = state.copyWith(error: 'Initialization error: $e');
      return false;
    }
  }

  /// Attempt initial connection (called once on app launch).
  Future<void> attemptInitialConnection() async {
    if (_initialConnectionAttempted) return;
    _initialConnectionAttempted = true;

    try {
      await _bleService.startConnection();
    } catch (e) {
      print('❌ Initial connection failed: $e');
      // Don't show error for initial auto-connect failure
    }
  }

  /// Initialize BLE and attempt initial connection (legacy method).
  Future<void> initialize() async {
    final success = await initializePermissions();
    if (success) {
      await attemptInitialConnection();
    }
  }

  /// Start BLE connection (for manual retry via button).
  Future<void> startConnection() async {
    try {
      // Reset reconnect attempts and enable auto-reconnect
      await _bleService.enableAutoReconnectAndConnect();
    } catch (e) {
      state = state.copyWith(error: 'Connection error: $e');
    }
  }

  /// Disconnect from device.
  Future<void> disconnect() async {
    try {
      await _bleService.disconnect(disableAutoReconnect: true);
    } catch (e) {
      state = state.copyWith(error: 'Disconnect error: $e');
    }
  }

  /// Check if smoking event was detected in the data.
  void _checkForSmokingEvent(Map<String, dynamic> data) {
    // Check if prediction indicates smoking
    // Your ESP32 sends "prediction": 1 for smoking detected
    final prediction = data['prediction'] as int?;
    final mqPpm = data['mq9_ppm'] as double?;

    // You can also check PPM threshold as additional validation
    // Typical cigarette smoke CO: 30-100+ PPM
    if (prediction == 1 || (mqPpm != null && mqPpm > 30)) {
      print('🚨 SMOKING DETECTED! PPM: $mqPpm, Prediction: $prediction');
      // Trigger callback to navigate to journal entry
      _ref.read(smokingDetectedCallbackProvider)?.call();
    }
  }

  /// Clear error.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for smoking detection callback (set by UI layer).
final smokingDetectedCallbackProvider =
    StateProvider<VoidCallback?>((ref) => null);

/// Provider for device not found callback (set by UI layer).
final deviceNotFoundCallbackProvider =
    StateProvider<VoidCallback?>((ref) => null);
