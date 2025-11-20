# Firebase OAuth Authentication Setup

## Overview
Google OAuth authentication has been successfully integrated into the Squash Quiz app. Users must sign in with their Google account before accessing the onboarding and quiz features.

## Features Implemented

### 1. **Google OAuth Sign-In**
- Users authenticate using their Google account
- Seamless sign-in flow with the official Google Sign-In SDK
- Automatic user profile creation in Firestore

### 2. **User Profile Management**
- User data stored in Firestore under `users` collection
- Each user document includes:
  - UID, email, display name, photo URL
  - User skill level (novice, intermediate, experienced)
  - Quiz statistics (total quizzes taken, total score)
  - Account creation and last login timestamps

### 3. **Authentication Flow**
1. **First Time**: User sees auth screen → Signs in with Google → Onboarding assessment → Main menu
2. **Returning User**: Auto-signs in → Loads user level → Main menu

### 4. **Onboarding Integration**
- After assessment, user level is saved to both:
  - Firebase Firestore (cloud)
  - SharedPreferences (local backup)
- Level determines quiz difficulty

## Firebase Free Tier Compliance ✅

### What's Used (All Free):
- **Firebase Authentication**: 
  - No cost for any number of users
  - Google OAuth is completely free
  
- **Cloud Firestore**:
  - ✅ Up to 50,000 document reads/day
  - ✅ Up to 20,000 document writes/day
  - ✅ Up to 20,000 document deletes/day
  - ✅ 1 GB storage
  
### Optimization for Free Tier:
1. **Minimal Writes**: Only 3-4 writes per user lifetime
   - User creation (1 write)
   - Last login update (1 write per session)
   - Level update after onboarding (1 write)
   - Quiz stats updates (1 write per quiz)

2. **Minimal Reads**: 
   - User profile loaded once per session
   - No real-time listeners (no continuous reads)

3. **No Cloud Functions**: All logic runs client-side

### Estimated Usage (100 active users/day):
- **Writes**: ~200/day (well under 20,000 limit)
- **Reads**: ~300/day (well under 50,000 limit)
- **Storage**: <1 MB (well under 1 GB limit)

## Files Modified/Created

### New Files:
- `lib/auth_screen.dart` - Google OAuth sign-in UI
- `lib/services/firebase_service.dart` - Firebase operations
- `lib/models/user_model.dart` - User data model
- `lib/firebase_options.dart` - Firebase configuration (auto-generated)

### Modified Files:
- `lib/main.dart` - Added auth state management and routing
- `lib/onboarding_screen.dart` - Save user level to Firebase after assessment
- `pubspec.yaml` - Added Firebase and Google Sign-In packages

## Setup Requirements

### For Development/Testing:
✅ Already completed during setup

### For Production (Android):
You'll need to:
1. Add SHA-1 fingerprint to Firebase Console
2. Download updated `google-services.json`
3. Place in `android/app/` directory

Get SHA-1 with:
```bash
cd android
./gradlew signingReport
```

### For Production (iOS):
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to Xcode project in `ios/Runner/`

### For Production (Web):
Already configured automatically by FlutterFire CLI

## Testing

To test locally:
```bash
flutter run
```

The app will:
1. Show auth screen
2. Prompt for Google sign-in
3. After sign-in, show onboarding (first time) or main menu (returning)

## Security Notes

- User authentication is handled entirely by Firebase
- OAuth tokens are managed securely by Google Sign-In SDK
- No passwords stored in app
- Firestore security rules should be configured in Firebase Console for production

### Recommended Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Future Enhancements (Still Free Tier)

Possible additions that stay within free limits:
- Email/password authentication (also free)
- Anonymous sign-in for trial users
- Social leaderboards (cached daily to minimize reads)
- User preferences and settings
- Quiz history (stored in user document as array)

## Support

For Firebase setup issues:
- Firebase Console: https://console.firebase.google.com/
- FlutterFire Documentation: https://firebase.flutter.dev/
