# BreatheFree Android Home Screen Widget

## Overview

The Panic Button home screen widget provides quick access to coping interventions directly from the Android home screen, without needing to open the app first.

## Features

- **Quick Access**: Tap the widget to instantly launch a random intervention activity
- **Panic Button Design**: Matches the in-app panic button with red gradient styling
- **Always Available**: Access help even when the app isn't running

## How to Add the Widget

### For Users:

1. Long-press on your Android home screen
2. Tap "Widgets" in the menu
3. Scroll to find "Breath Free" widgets
4. Long-press and drag the "Panic Button" widget to your home screen
5. Resize as needed (minimum 110dp x 110dp)

### Widget Behavior:

- **Tap**: Launches the BreatheFree app and immediately starts a random intervention activity
- **Visual Design**: Red gradient background with emergency icon and "I NEED HELP" text
- **Size**: Resizable, but designed to work best as a small square widget

## Technical Details

### Files Created:

- **Layout**: `android/app/src/main/res/layout/panic_widget.xml`
- **Widget Info**: `android/app/src/main/res/xml/panic_widget_info.xml`
- **Provider**: `android/app/src/main/kotlin/.../PanicWidgetProvider.kt`
- **Drawable Resources**:
  - `widget_background.xml` - Gradient background
  - `ic_emergency.xml` - Emergency icon
- **Strings**: `android/app/src/main/res/values/strings.xml`
- **Flutter Service**: `lib/services/widget_service.dart`

### How It Works:

1. User taps the widget on home screen
2. `PanicWidgetProvider` receives the click event
3. Sends a broadcast intent to launch the app with `launch_intervention` flag
4. `MainActivity` receives the intent and sends message through method channel
5. `WidgetService` in Flutter receives the message
6. Calls `interventionProvider` to select a random intervention
7. Navigates to the intervention screen automatically

### Customization:

- **Colors**: Edit `widget_background.xml` gradient colors to match theme
- **Size**: Modify `minWidth` and `minHeight` in `panic_widget_info.xml`
- **Text**: Update strings in `strings.xml`
- **Icon**: Replace `ic_emergency.xml` with custom vector drawable

## Testing:

1. Build and install the app: `flutter run --release`
2. Add the widget to home screen (see steps above)
3. Tap the widget to verify it launches the app and starts an intervention
4. Test with app closed, app in background, and app already open

## Notes:

- Widget updates happen automatically when added/removed
- Requires Android API 16+ (automatically satisfied by Flutter)
- Widget uses PendingIntent.FLAG_IMMUTABLE for Android 12+ compatibility
