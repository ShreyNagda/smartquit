// ignore_for_file: constant_identifier_names, unused_field

import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// BLE service for connecting to SmartQuit Band (ESP32).
class BleService {
  static const String TARGET_DEVICE_NAME = 'SmokeBand';
  static const String SERVICE_UUID = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String CHARACTERISTIC_UUID =
      '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _adapterStateSubscription;

  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  bool _shouldAutoReconnect = true; // For persistent connection
  Timer? _reconnectTimer;
  bool _permissionsGranted = false;

  // Callbacks
  Function(BleConnectionState)? onConnectionStateChanged;
  Function(Map<String, dynamic>)? onDataReceived;
  Function()? onDeviceNotFound;

  BleConnectionState _currentState = BleConnectionState.disconnected;

  BleConnectionState get currentState => _currentState;
  bool get isConnected => _currentState == BleConnectionState.connected;

  /// Initialize BLE and request permissions.
  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        print('❌ Bluetooth not supported on this device');
        return false;
      }

      // Request permissions
      final bluetoothPermission = await Permission.bluetooth.request();
      final bluetoothScanPermission = await Permission.bluetoothScan.request();
      final bluetoothConnectPermission =
          await Permission.bluetoothConnect.request();
      final locationPermission = await Permission.locationWhenInUse.request();

      if (bluetoothPermission.isGranted &&
          bluetoothScanPermission.isGranted &&
          bluetoothConnectPermission.isGranted &&
          locationPermission.isGranted) {
        print('✅ BLE permissions granted');
        _permissionsGranted = true;

        // Listen to Bluetooth adapter state for auto-reconnect when Bluetooth is turned back on
        _adapterStateSubscription =
            FlutterBluePlus.adapterState.listen((state) {
          if (state == BluetoothAdapterState.on &&
              _shouldAutoReconnect &&
              !isConnected &&
              !_isConnecting) {
            print('📶 Bluetooth turned on, attempting to reconnect...');
            _scheduleReconnect();
          }
        });

        return true;
      } else {
        print('❌ BLE permissions denied');
        return false;
      }
    } catch (e) {
      print('❌ BLE initialization error: $e');
      return false;
    }
  }

  /// Start scanning and connecting to SmartQuit Band.
  Future<void> startConnection() async {
    if (_isConnecting || isConnected) return;

    _isConnecting = true;
    _updateState(BleConnectionState.scanning);

    try {
      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('❌ Bluetooth is off');
        _updateState(BleConnectionState.disconnected);
        _isConnecting = false;
        return;
      }

      print('🔍 Scanning for $TARGET_DEVICE_NAME...');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          for (var result in results) {
            if (result.device.platformName == TARGET_DEVICE_NAME) {
              print('✅ Found $TARGET_DEVICE_NAME');
              await FlutterBluePlus.stopScan();
              await _connectToDevice(result.device);
              break;
            }
          }
        },
        onError: (error) {
          print('❌ Scan error: $error');
          _updateState(BleConnectionState.disconnected);
          _isConnecting = false;
        },
      );

      // Timeout handling
      await Future.delayed(const Duration(seconds: 10));
      if (!isConnected && _isConnecting) {
        await FlutterBluePlus.stopScan();
        print('⏱️ Scan timeout - device not found');
        _updateState(BleConnectionState.disconnected);
        _isConnecting = false;
        onDeviceNotFound?.call();
      }
    } catch (e) {
      print('❌ Connection start error: $e');
      _updateState(BleConnectionState.disconnected);
      _isConnecting = false;
    }
  }

  /// Connect to the device and discover services.
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _connectedDevice = device;
      _updateState(BleConnectionState.connecting);

      print('🔗 Connecting to $TARGET_DEVICE_NAME...');
      await device.connect(autoConnect: false);

      // Listen to connection state
      _connectionSubscription = device.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.connected) {
            print('✅ Connected to $TARGET_DEVICE_NAME');
            _discoverServices();
          } else if (state == BluetoothConnectionState.disconnected) {
            print('📴 Disconnected from $TARGET_DEVICE_NAME');
            _handleDisconnection();
          }
        },
      );
    } catch (e) {
      print('❌ Connection error: $e');
      _updateState(BleConnectionState.disconnected);
      _isConnecting = false;
    }
  }

  /// Discover services and subscribe to notifications.
  Future<void> _discoverServices() async {
    try {
      if (_connectedDevice == null) return;

      print('🔍 Discovering services...');
      final services = await _connectedDevice!.discoverServices();

      for (var service in services) {
        if (service.uuid.toString().toUpperCase() ==
            SERVICE_UUID.toUpperCase()) {
          print('✅ Found target service');

          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() ==
                CHARACTERISTIC_UUID.toUpperCase()) {
              print('✅ Found target characteristic');
              _characteristic = characteristic;

              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              _dataSubscription = characteristic.lastValueStream.listen(
                (value) {
                  _handleData(value);
                },
                onError: (error) {
                  print('❌ Data stream error: $error');
                },
              );

              _updateState(BleConnectionState.connected);
              _reconnectAttempts = 0;
              _isConnecting = false;
              return;
            }
          }
        }
      }

      print('❌ Target service/characteristic not found');
      await disconnect();
    } catch (e) {
      print('❌ Service discovery error: $e');
      await disconnect();
    }
  }

  /// Handle incoming data from ESP32.
  void _handleData(List<int> value) {
    try {
      final jsonString = utf8.decode(value);
      print('📊 Received data: $jsonString');

      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Call callback with parsed data
      onDataReceived?.call(data);
    } catch (e) {
      print('❌ Data parsing error: $e');
    }
  }

  /// Handle disconnection with retry logic.
  Future<void> _handleDisconnection() async {
    _updateState(BleConnectionState.disconnected);
    _isConnecting = false;
    _connectedDevice = null;
    _characteristic = null;

    // Only auto-reconnect if enabled
    if (_shouldAutoReconnect) {
      if (_reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
        _reconnectAttempts++;
        print(
            '🔄 Reconnection attempt $_reconnectAttempts/$MAX_RECONNECT_ATTEMPTS');
        _scheduleReconnect();
      } else {
        print(
            '❌ Max reconnection attempts reached, will retry on next manual connection');
        _reconnectAttempts = 0;
      }
    }
  }

  /// Schedule a reconnection attempt with delay.
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (_shouldAutoReconnect && !isConnected && !_isConnecting) {
        await startConnection();
      }
    });
  }

  /// Disconnect from device.
  Future<void> disconnect({bool disableAutoReconnect = false}) async {
    try {
      if (disableAutoReconnect) {
        _shouldAutoReconnect = false;
      }

      _reconnectTimer?.cancel();
      await _scanSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _dataSubscription?.cancel();

      if (_characteristic != null) {
        try {
          await _characteristic!.setNotifyValue(false);
        } catch (_) {}
      }

      if (_connectedDevice != null) {
        try {
          await _connectedDevice!.disconnect();
        } catch (_) {}
      }

      _connectedDevice = null;
      _characteristic = null;
      _updateState(BleConnectionState.disconnected);
      _isConnecting = false;
      _reconnectAttempts = 0;

      print('✅ Disconnected');
    } catch (e) {
      print('❌ Disconnect error: $e');
    }
  }

  /// Enable auto-reconnect and start connection.
  Future<void> enableAutoReconnectAndConnect() async {
    _shouldAutoReconnect = true;
    _reconnectAttempts = 0;
    await startConnection();
  }

  /// Update connection state and notify listeners.
  void _updateState(BleConnectionState newState) {
    _currentState = newState;
    onConnectionStateChanged?.call(newState);
  }

  /// Clean up resources.
  Future<void> dispose() async {
    _shouldAutoReconnect = false;
    _reconnectTimer?.cancel();
    await _adapterStateSubscription?.cancel();
    await disconnect(disableAutoReconnect: true);
  }
}

/// BLE connection states.
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}
