# SmartQuit Band BLE Integration

## Overview

The Flutter app now connects to the ESP32-based SmartQuit Band via Bluetooth Low Energy (BLE) to receive real-time sensor data and detect smoking events.

## Features Implemented

### ✅ 1. BLE Service (`lib/services/ble_service.dart`)

- Scans for device named "SmokeBand"
- Connects automatically when device is found
- Subscribes to notifications from characteristic: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- Parses JSON data from ESP32
- Automatic reconnection (2 attempts) on disconnection
- Clean state management

### ✅ 2. BLE Provider (`lib/providers/ble_provider.dart`)

- Riverpod state management for BLE connection
- Connection state tracking (disconnected, scanning, connecting, connected)
- Data handling and callback system
- Smoking detection logic (triggers on `prediction: 1` or `mq9_ppm > 30`)

### ✅ 3. UI Integration

- Bluetooth icon in home screen header
- Icon changes to `bluetooth_connected` when connected
- Color changes to primary color when connected
- Dialog shows connection status and retry option
- No visible loading states during connection (runs in background)

### ✅ 4. Smoking Detection

- Automatically navigates to journal entry screen with relapse event
- Pre-fills notes with "Smoking detected by SmartQuit Band"
- Relapse event type is pre-selected

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Android Permissions

Add to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>` tag):

```xml
<!-- Bluetooth permissions for Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Bluetooth permissions for older Android versions -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true"/>
```

### 3. iOS Permissions (if supporting iOS)

Add to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>SmartQuit needs Bluetooth to connect to your SmartQuit Band</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>SmartQuit needs Bluetooth to connect to your SmartQuit Band</string>
```

### 4. Test the Connection

1. **Upload ESP32 Code**
   - Make sure your ESP32 is running the provided code
   - Device advertises as "SmokeBand"
   - BLE service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`

2. **Run Flutter App**

   ```bash
   flutter run
   ```

3. **Check Connection**
   - App automatically starts scanning on home screen load
   - Bluetooth icon shows connection status
   - Tap icon to see connection details or retry

4. **Test Smoking Detection**
   - ESP32 sends JSON data every 2 seconds
   - If `prediction: 1` or `mq9_ppm > 30`, app triggers relapse entry
   - Journal entry screen opens automatically

## Data Format

The ESP32 sends JSON data like this:

```json
{
  "accX": 0.123,
  "accY": -0.456,
  "accZ": 0.789,
  "gyroX": 1.234,
  "gyroY": -2.345,
  "gyroZ": 3.456,
  "mq9_ppm": 45.67,
  "prediction": 1
}
```

### Smoking Detection Logic

The app detects smoking when:

- `prediction == 1` (SVM model on ESP32 detected smoking gesture)
- **OR** `mq9_ppm > 30` (CO concentration above threshold)

You can adjust the threshold in `ble_provider.dart`:

```dart
if (prediction == 1 || (mqPpm != null && mqPpm > 30)) {
  // Smoking detected
}
```

## Troubleshooting

### Issue: App doesn't connect to band

**Solutions:**

1. Ensure ESP32 is powered on and running
2. Check that device name is exactly "SmokeBand"
3. Verify Bluetooth permissions are granted
4. Try tapping Bluetooth icon and pressing "Retry"
5. Check Android/iOS Bluetooth is enabled
6. Restart the app

### Issue: Connection keeps dropping

**Solutions:**

1. Reduce distance between phone and ESP32
2. Check ESP32 power supply
3. Look at console logs for specific errors
4. Increase reconnection attempts in `ble_service.dart`:
   ```dart
   static const int MAX_RECONNECT_ATTEMPTS = 5; // Increase from 2
   ```

### Issue: Smoking detection not triggering

**Solutions:**

1. Check ESP32 console output for correct JSON format
2. Verify `prediction` or `mq9_ppm` values
3. Check Flutter console for "🚨 SMOKING DETECTED!" message
4. Ensure callback is set up (check `_initializeBLE()` in home_screen.dart)

### Issue: Permissions denied

**Solutions:**

1. Uninstall and reinstall app
2. Go to Settings > Apps > BreatheFree > Permissions
3. Enable Location and Bluetooth permissions
4. For Android 12+, specifically enable "Nearby devices"

## Console Logs

Watch for these messages:

**BLE Service:**

- `✅ BLE permissions granted`
- `🔍 Scanning for SmokeBand...`
- `✅ Found SmokeBand`
- `🔗 Connecting to SmokeBand...`
- `✅ Connected to SmokeBand`
- `📊 Received data: {...}`
- `🔄 Reconnection attempt X/2`
- `❌ [Error messages]`

**Smoking Detection:**

- `🚨 SMOKING DETECTED! PPM: XX, Prediction: X`

## Code Architecture

```
lib/
├── services/
│   └── ble_service.dart          # BLE connection & data handling
├── providers/
│   └── ble_provider.dart         # Riverpod state management
└── screens/
    ├── home/home_screen.dart     # BLE UI integration & initialization
    └── journal/journal_entry_screen.dart  # Accepts relapse event
```

### Key Files Modified

1. **pubspec.yaml** - Added `flutter_blue_plus` and `permission_handler`
2. **home_screen.dart** - BLE initialization, status icon, smoking callback
3. **journal_entry_screen.dart** - Accepts route arguments for event type

## Next Steps (Optional)

1. **Add Data Logging**: Store sensor data in Firestore for analysis
2. **Show Live Sensor Data**: Display real-time accelerometer/gyro/PPM values
3. **Add Calibration**: Allow users to calibrate sensors from app
4. **Battery Status**: Show ESP32 battery level in app
5. **Multiple Devices**: Support connecting to multiple bands
6. **Historical Data**: Chart sensor data over time

## Testing Checklist

- [ ] App asks for Bluetooth permissions on first launch
- [ ] Bluetooth icon appears in home screen
- [ ] Icon changes color when connected
- [ ] Tapping icon shows connection status
- [ ] ESP32 data appears in console logs
- [ ] High PPM values trigger relapse entry
- [ ] Journal entry opens with pre-filled relapse event
- [ ] Reconnection works after disconnection
- [ ] App works without band (graceful degradation)

## References

- **ESP32 Code**: See the provided Arduino sketch
- **BLE UUIDs**: 6E400001/6E400003 (Nordic UART Service compatible)
- **Flutter Blue Plus Docs**: https://pub.dev/packages/flutter_blue_plus
