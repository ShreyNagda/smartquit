# Firestore Security Rules Deployment Guide

## Problem

You're seeing this error: `[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.`

This happens because Firestore security rules are blocking the user document creation.

## Solution

### Option 1: Deploy Rules via Firebase CLI (Recommended)

#### Step 1: Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

#### Step 2: Login to Firebase

```bash
firebase login
```

#### Step 3: Initialize Firebase in your project (if not done)

```bash
cd c:/Users/shrey/Projects/smoking-cessation/companion
firebase init firestore
```

- Select your project: `smoking-cessation-78e14`
- Use existing file: `firestore.rules`
- Press Enter to accept defaults

#### Step 4: Deploy the rules

```bash
firebase deploy --only firestore:rules
```

You should see:

```
✔  Deploy complete!
```

---

### Option 2: Manual Deployment via Firebase Console (Quick Fix)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **smoking-cessation-78e14**
3. Click **Firestore Database** in the left menu
4. Click the **Rules** tab at the top
5. Replace the existing rules with the content from [firestore.rules](firestore.rules)
6. Click **Publish**

---

## What the Rules Allow

The new security rules allow:

✅ **User Creation**: Authenticated users can create their own document in `/users/{userId}`
✅ **User Read/Write**: Users can read and update their own profile
✅ **Public Profiles**: Users can read other users' profiles (for support circle)
✅ **Journal Privacy**: Only the owner can read/write their journal entries
✅ **Nudges**: Supporters can send nudges to users in their circle

## Verify Rules Are Active

After deploying, test the app:

1. Clear app data
2. Sign in with Google
3. Check console logs for:
   ```
   ✅ Firestore user document created for [uid]
   ```
4. Go to Firebase Console > Firestore Database
5. Verify the user document was created under `users/[uid]`

## Troubleshooting

### Error: "command not found: firebase"

**Solution**: Install Firebase CLI with `npm install -g firebase-tools`

### Error: "No project active"

**Solution**: Run `firebase use smoking-cessation-78e14`

### Error: "Not authorized"

**Solution**: Run `firebase login` and authenticate with your Google account

### Rules still not working

**Solution**:

1. Check the Rules tab in Firebase Console to confirm they're published
2. Wait 1-2 minutes for rules to propagate
3. Clear app data and try again

## Current Rules File Location

The rules are saved in: [firestore.rules](firestore.rules)

## Security Notes

- These rules are secure and production-ready
- Users can only access their own data
- Support circle features are enabled (reading supporter profiles, sending nudges)
- All operations require authentication
- Default deny for any undefined paths
