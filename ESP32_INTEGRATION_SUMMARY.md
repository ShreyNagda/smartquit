# ESP32 BLE Integration - Implementation Summary

## ✅ Complete Implementation

I've successfully integrated the ESP32 SmartQuit Band with your Flutter app using Bluetooth Low Energy (BLE). Here's what was implemented:

## Files Created

### 1. **BLE Service** - `lib/services/ble_service.dart`

- Manages BLE connection lifecycle
- Scans for "SmokeBand" device
- Auto-connects and subscribes to notifications
- Parses JSON data from ESP32
- Implements retry logic (2 attempts on disconnect)
- Clean error handling and logging

### 2. **BLE Provider** - `lib/providers/ble_provider.dart`

- Riverpod state management
- Connection state tracking
- Smoking detection logic
- Callback system for UI notifications

### 3. **Documentation**

- `BLE_INTEGRATION.md` - Complete setup and troubleshooting guide
- Includes testing checklist and console log references

## Files Modified

### 1. **pubspec.yaml**

Added dependencies:

- `flutter_blue_plus: ^1.32.12` - BLE communication
- `permission_handler: ^11.3.0` - Runtime permissions

### 2. **home_screen.dart**

- Added BLE initialization on screen load
- Bluetooth icon shows connection status
- Icon color changes when connected
- Dialog shows connection details
- Sets up smoking detection callback

### 3. **journal_entry_screen.dart**

- Accepts route arguments for event type
- Pre-fills relapse event when triggered by band
- Adds note "Smoking detected by SmartQuit Band"

### 4. **AndroidManifest.xml**

Added Bluetooth permissions for Android 12+ and older versions:

- BLUETOOTH_SCAN
- BLUETOOTH_CONNECT
- ACCESS_FINE_LOCATION
- And legacy permissions for older Android versions

## How It Works

### Connection Flow

1. App starts → Home screen loads
2. BLE service initializes automatically
3. Scans for "SmokeBand" device
4. Connects when found
5. Subscribes to characteristic notifications
6. Receives JSON data every 2 seconds

### Smoking Detection

The app monitors two conditions:

```dart
if (prediction == 1 || (mqPpm != null && mqPpm > 30)) {
  // Smoking detected!
  // Navigate to journal entry with relapse event
}
```

- **prediction == 1**: ESP32 SVM model detected smoking gesture
- **mq9_ppm > 30**: CO concentration exceeds threshold (typical cigarette: 30-100+ PPM)

### Automatic Recovery

- If disconnected, retries connection 2 times
- 3-second delay between attempts
- User can manually retry via Bluetooth dialog
- Connection state always visible in UI

## UI Features

### Bluetooth Icon

- **Disconnected**: Gray `bluetooth` icon
- **Connected**: Primary color `bluetooth_connected` icon
- **Tap**: Shows connection status dialog

### Connection Status Dialog

Shows:

- Current connection state (Scanning, Connecting, Connected, Disconnected)
- Status icon (checkmark or X)
- Helpful message for troubleshooting
- "Retry" button when disconnected

### No Disruption

- All connection logic runs in background
- No loading spinners or blocking UI
- Silent reconnection attempts
- User only notified of smoking events

## ESP32 Code Compatibility

Your ESP32 code sends:

```json
{
  "accX": 0.123,
  "accY": -0.456,
  "accZ": 0.789,
  "gyroX": 1.234,
  "gyroY": -2.345,
  "gyroZ": 3.456,
  "mq9_ppm": 45.67,
  "prediction": 0
}
```

The Flutter app:

- Parses all fields
- Stores in `latestData` map
- Checks `prediction` and `mq9_ppm` for smoking
- Triggers journal entry when detected

## Testing the Integration

### 1. Build and Run

```bash
flutter run
```

### 2. Grant Permissions

App will request:

- Bluetooth
- Location (required for BLE scanning on Android)
- Nearby devices (Android 12+)

### 3. Check Connection

- Look for Bluetooth icon in home screen
- Icon should turn blue/primary color when connected
- Tap icon to see status

### 4. Test Smoking Detection

Your ESP32 currently sends `"prediction": 0`, so smoking won't be detected yet. To test:

**Option A: Modify ESP32 temporarily**

```cpp
// In ESP32 loop(), change:
int prediction = 1; // Force smoking detection
```

**Option B: Blow smoke near MQ9 sensor**

- MQ9 will detect high PPM
- App triggers when `mq9_ppm > 30`

**Option C: Modify Flutter threshold for testing**

```dart
// In ble_provider.dart, line ~80:
if (prediction == 1 || (mqPpm != null && mqPpm > 5)) { // Lower threshold
  // Will trigger on any PPM above 5
}
```

### 5. Verify Console Logs

Look for:

```
✅ BLE permissions granted
🔍 Scanning for SmokeBand...
✅ Found SmokeBand
🔗 Connecting to SmokeBand...
✅ Connected to SmokeBand
📊 Received data: {"accX":...}
🚨 SMOKING DETECTED! PPM: 45.67, Prediction: 1
```

## Quick Troubleshooting

### Can't find device

1. Check ESP32 serial monitor - should show "📡 BLE advertising as 'SmokeBand_ESP32'"
2. Ensure Bluetooth is on
3. Grant all permissions
4. Device must be within range (~10m)

### Connection drops

1. Move phone closer to ESP32
2. Check ESP32 power supply
3. Increase reconnect attempts in `ble_service.dart` (currently 2)

### Smoking detection not working

1. Verify JSON format from ESP32
2. Check `prediction` value (should be 1)
3. Check `mq9_ppm` value (should be > 30)
4. Look for console message: "🚨 SMOKING DETECTED!"

## Customization

### Change Device Name

In `ble_service.dart`:

```dart
static const String TARGET_DEVICE_NAME = 'YourDeviceName';
```

### Adjust PPM Threshold

In `ble_provider.dart`:

```dart
if (prediction == 1 || (mqPpm != null && mqPpm > 50)) { // Change 30 to 50
```

### Increase Reconnect Attempts

In `ble_service.dart`:

```dart
static const int MAX_RECONNECT_ATTEMPTS = 5; // Change from 2
```

### Add Data Logging

In `ble_provider.dart`, `_checkForSmokingEvent()`:

```dart
// Store sensor data to Firestore
final user = _ref.read(userStreamProvider).valueOrNull;
if (user != null) {
  await FirebaseService().storeSensorData(user.uid, data);
}
```

## Next Steps

1. **Test thoroughly** with real ESP32 device
2. **Fine-tune thresholds** based on actual sensor readings
3. **Add battery status** from ESP32 to app
4. **Display live sensor data** in a new screen
5. **Log historical data** for analysis
6. **Add vibration alerts** when smoking detected

## Architecture Summary

```
┌─────────────────────────────────────────┐
│         Home Screen (UI)                │
│  - Bluetooth icon                       │
│  - Connection status                    │
│  - Smoking callback                     │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│      BLE Provider (State Mgmt)          │
│  - Connection state                     │
│  - Data parsing                         │
│  - Smoking detection                    │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│       BLE Service (Logic)               │
│  - Scan & connect                       │
│  - Subscribe to notifications           │
│  - Parse JSON                           │
│  - Retry on disconnect                  │
└────────────┬────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│          ESP32 Device                    │
│  - Advertise as "SmokeBand"            │
│  - Send JSON every 2s                   │
│  - MPU6050 + MQ9 data                   │
└─────────────────────────────────────────┘
```

## Dependencies Installed

```
✅ flutter_blue_plus: ^1.32.12
✅ permission_handler: ^11.3.0
```

All dependencies have been installed via `flutter pub get`.

---

**Status: ✅ READY FOR TESTING**

The integration is complete and ready to test with your ESP32 device!
