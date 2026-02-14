# Google Sign-In Setup Guide

## ✅ What's Already Done

- `google_sign_in` package added to `pubspec.yaml`
- `AuthService` updated with Google Sign-In functionality
- `AuthNotifier` provider updated with `signInWithGoogle()` method
- Login and Register screens updated with "Continue with Google" buttons

## � Prerequisites

### Generate Platform Folders (if not done yet)

If the `android/` and `ios/` directories don't exist:

```bash
cd "c:\Users\shrey\Projects\smoking-cessation\companion"
flutter create . --platforms=android,ios,web
```

This will generate the necessary platform-specific files while preserving your `lib/` code.

## �🔧 Firebase Console Setup

### 1. Enable Google Sign-In in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **BreatheFree**
3. Navigate to **Authentication** > **Sign-in method**
4. Click on **Google** provider
5. Toggle **Enable** switch
6. Add your **support email** (required)
7. Click **Save**

### 2. Configure SHA-1 Certificate (Android)

For Google Sign-In to work on Android, you need to add your SHA-1 certificate fingerprint:

#### Get SHA-1 Debug Certificate:

```bash
cd android
./gradlew signingReport
```

Look for the **SHA-1** fingerprint under `Variant: debug` → `Task: :app:signingReport`

#### Add to Firebase:

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll to **Your apps** section
3. Select your Android app
4. Click **Add fingerprint**
5. Paste the SHA-1 fingerprint
6. Click **Save**

**Note:** For release builds, you'll also need to add the release SHA-1 fingerprint.

### 3. Download Updated google-services.json

After adding SHA-1 fingerprints:

1. In Firebase Console → **Project Settings** → Your Android app
2. Click **Download google-services.json**
3. Replace the file at: `android/app/google-services.json`

### 4. Verify Android Configuration

Ensure these files have the correct configuration:

#### `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### `android/app/build.gradle`:

At the very bottom of the file:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## 📱 Testing Google Sign-In

### Run the App:

```bash
flutter pub get
flutter run
```

### Test Flow:

1. Open the app → **Login Screen**
2. Tap **"Continue with Google"**
3. Select a Google account
4. First-time users:
   - User document created automatically in Firestore
   - Default preferences set (20 cigarettes/day, $0.50/cigarette)
   - Redirected to onboarding
5. Returning users:
   - Existing user data loaded
   - Redirected to home screen

## 🔐 How It Works

### First-Time Google Sign-In:

```dart
signInWithGoogle()
  → User authenticates with Google
  → Check if user document exists in Firestore
  → If not exists:
     - Generate unique support code (BF-XXXX)
     - Create UserModel with defaults
     - Save to Firestore
  → Navigate to /onboarding
```

### Returning User Sign-In:

```dart
signInWithGoogle()
  → User authenticates with Google
  → User document found in Firestore
  → Load existing profile
  → Navigate to /home
```

## 🎨 UI Features

- **Google logo** displayed on button (with fallback icon)
- **"OR" divider** separating email/password from Google Sign-In
- **Loading state** shared between email and Google sign-in
- **Error handling** for canceled sign-in or failures
- **Consistent styling** with existing auth screens

## 🐛 Troubleshooting

### "Sign-in failed" on Android:

- Verify SHA-1 fingerprint is added to Firebase Console
- Download fresh `google-services.json` after adding SHA-1
- Rebuild app: `flutter clean && flutter run`

### User cancels sign-in:

- App gracefully handles cancellation (returns to login screen)
- No error message shown

### Email already exists with password:

- Firebase automatically links accounts if email matches
- User can sign in with either method

## 📚 Additional Resources

- [Firebase Google Sign-In Docs](https://firebase.google.com/docs/auth/flutter/federated-auth#google)
- [google_sign_in Package](https://pub.dev/packages/google_sign_in)
- [SHA Certificate Guide](https://developers.google.com/android/guides/client-auth)
