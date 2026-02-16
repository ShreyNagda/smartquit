# Firestore Google Login Debug Guide

## Issue

Firebase Auth account is created successfully during Google login, but the Firestore user collection document is not being created.

## Fixed Code Changes

### 1. Enhanced Error Handling in auth_provider.dart

Added comprehensive error handling and logging to the `signInWithGoogle()` method:

- Separate try-catch for Firestore user creation
- Console logging for debugging
- Sign out Firebase Auth if Firestore creation fails
- Better error messages to user

### 2. Enhanced Login/Register Screens

Added error display via SnackBar when Google login fails.

## How to Debug

### Step 1: Check Console Logs

When you attempt Google login, watch for these console messages:

- `✅ Firestore user document created for [uid]` - Success
- `✅ Existing user found: [uid]` - User already exists
- `❌ Error creating Firestore user document: [error]` - Firestore creation failed
- `❌ FirebaseAuthException: [code] - [message]` - Auth error
- `❌ Unexpected error in signInWithGoogle: [error]` - Other error

### Step 2: Check Firestore Security Rules

Make sure your Firestore security rules allow user document creation. Example:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to create and read their own documents
    match /users/{userId} {
      allow create: if request.auth != null;
      allow read, update, delete: if request.auth != null && request.auth.uid == userId;

      // Allow reading supporter documents
      allow read: if request.auth != null;

      // Subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Step 3: Check Firebase Console

1. Go to Firebase Console > Authentication
2. Verify the user was created with Google provider
3. Go to Firestore Database
4. Check if `users` collection exists
5. Look for the user document with the UID from Authentication

### Step 4: Common Issues

#### Issue: Firestore rules deny write access

**Solution**: Update Firestore security rules to allow authenticated users to create their own documents.

#### Issue: Network connectivity

**Solution**: Ensure device has stable internet connection for Firestore operations.

#### Issue: Missing Firestore initialization

**Solution**: Verify Firebase is initialized in main.dart before any Firestore operations.

#### Issue: Wrong project configuration

**Solution**: Ensure google-services.json (Android) and GoogleService-Info.plist (iOS) are from the correct Firebase project.

### Step 5: Manual Testing

1. Delete any existing test user from Firebase Authentication
2. Delete corresponding Firestore document if it exists
3. Clear app data / reinstall app
4. Attempt Google login again
5. Check console logs and Firebase Console

### Step 6: Verify Firestore Structure

The user document should have this structure:

```json
{
  "display_name": "User Name",
  "email": "user@example.com",
  "photo_url": "https://...",
  "support_code": "BF-1234",
  "supporters": [],
  "supporting": [],
  "stats": {
    "streak_days": 0,
    "cravings_blocked": 0,
    // ... other stats
  },
  "privacy_settings": { ... },
  "preferences": {
    "cigarettes_per_day": 20,
    "price_per_cigarette": 0.50,
    // ... other preferences
  },
  "created_at": Timestamp,
  "quit_date": Timestamp,
  "role": "user"
}
```

## Testing Commands

### Enable Flutter debug logging

```bash
flutter run --verbose
```

### Check Firebase logs in Android

```bash
adb logcat -s FirebaseAuth FirebaseFirestore
```

## Next Steps After Fix

1. Test with a fresh Google account
2. Test with existing Google account
3. Verify data shows up in Firestore Console
4. Verify app can read the created user document
5. Test app functionality that depends on user data

## Code References

- [auth_provider.dart](lib/providers/auth_provider.dart#L107) - signInWithGoogle() method
- [firebase_service.dart](lib/services/firebase_service.dart#L22) - createUser() method
- [user_model.dart](lib/models/user_model.dart) - User data structure
