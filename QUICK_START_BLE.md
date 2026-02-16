# 🚀 Quick Start - ESP32 BLE Integration

## Ready to Test!

Your SmartQuit app is now fully integrated with the ESP32 Band. Follow these steps to test the connection:

## Step 1: Flash ESP32 ✅

Make sure your ESP32 is running the BLE code you provided. It should show:

```
📡 BLE advertising as 'SmokeBand_ESP32'
```

## Step 2: Run the App 📱

```bash
flutter run
```

## Step 3: Grant Permissions ✅

When prompted, grant:

- ✅ Bluetooth
- ✅ Location (required for BLE on Android)
- ✅ Nearby devices (Android 12+)

## Step 4: Check Connection 🔗

1. Go to Home screen
2. Look at top-right corner for Bluetooth icon
3. Icon should change from gray to blue/primary color when connected
4. Tap the icon to see connection status

## Step 5: Test Smoking Detection 🚬

Since your ESP32 currently sends `"prediction": 0`, temporarily modify the ESP32 code:

```cpp
// In loop(), change this line:
int prediction = 1; // Was 0, now 1 for testing
```

Or modify Flutter to lower the threshold:

```dart
// In lib/providers/ble_provider.dart, line ~80:
if (prediction == 1 || (mqPpm != null && mqPpm > 5)) { // Was 30, now 5
```

Then blow near the MQ9 sensor or wait for high PPM readings.

## Expected Behavior

### When Connected

- ✅ Bluetooth icon turns blue
- ✅ Console shows: `✅ Connected to SmokeBand`
- ✅ Data received every 2 seconds

### When Smoking Detected

- ✅ Console shows: `🚨 SMOKING DETECTED! PPM: XX, Prediction: X`
- ✅ App automatically navigates to journal entry
- ✅ Relapse event is pre-selected
- ✅ Notes field says "Smoking detected by SmartQuit Band"

## Console Logs to Watch For

```
✅ BLE permissions granted
🔍 Scanning for SmokeBand...
✅ Found SmokeBand
🔗 Connecting to SmokeBand...
✅ Connected to SmokeBand
✅ Found target service
✅ Found target characteristic
📊 Received data: {"accX":0.123,"accY":-0.456,...}
🚨 SMOKING DETECTED! PPM: 45.67, Prediction: 1
```

## Troubleshooting

| Issue                | Solution                                                                                                         |
| -------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Can't find device    | 1. Check ESP32 is powered on<br>2. Verify "SmokeBand" name<br>3. Restart app                                     |
| Permissions denied   | 1. Uninstall app<br>2. Reinstall<br>3. Grant all permissions                                                     |
| Connection drops     | 1. Move phone closer<br>2. Check ESP32 power<br>3. Look at console for errors                                    |
| No smoking detection | 1. Check ESP32 sends correct JSON<br>2. Verify `prediction: 1` or high PPM<br>3. Lower threshold in Flutter code |

## Testing Checklist

- [ ] ESP32 powered on and advertising
- [ ] Flutter app running
- [ ] Permissions granted
- [ ] Bluetooth icon visible
- [ ] Icon turns blue when connected
- [ ] Can tap icon to see status
- [ ] Data appears in console logs
- [ ] Smoking detection triggers journal entry

## Files You Can Modify

### To change device name:

`lib/services/ble_service.dart` line 8

### To adjust PPM threshold:

`lib/providers/ble_provider.dart` line ~80

### To increase reconnect attempts:

`lib/services/ble_service.dart` line 16

## Need Help?

Check these files:

- **Setup Guide**: [BLE_INTEGRATION.md](BLE_INTEGRATION.md)
- **Full Summary**: [ESP32_INTEGRATION_SUMMARY.md](ESP32_INTEGRATION_SUMMARY.md)
- **Deploy Firestore Rules**: [DEPLOY_FIRESTORE_RULES.md](DEPLOY_FIRESTORE_RULES.md)

---

**Everything is set up! Just run the app and power on your ESP32.** 🎉
