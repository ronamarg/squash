# Firebase Console Configuration Guide

## Step 1: Enable Google Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **squash-bc287**
3. Click **Authentication** in the left sidebar
4. Click **Get Started** (if first time) or **Sign-in method** tab
5. Find **Google** in the providers list
6. Click **Google** → Click **Enable** toggle
7. Set a **Project support email** (your email)
8. Click **Save**

✅ **Done!** Google OAuth is now enabled for all platforms.

## Step 2: Deploy Firestore Security Rules

1. In Firebase Console, click **Firestore Database** in the left sidebar
2. Click **Rules** tab at the top
3. Replace the rules with the content from `firestore.rules` in your project
4. Click **Publish**

Or deploy via command line:
```bash
firebase deploy --only firestore:rules
```

## Step 3: Android Configuration (Production Only)

### For Debug Builds:
The FlutterFire CLI already configured debug signing automatically.

### For Release Builds:
1. Get your release SHA-1 fingerprint:
```bash
cd android
./gradlew signingReport
```

2. In Firebase Console:
   - Go to **Project Settings** (gear icon)
   - Select your Android app
   - Click **Add fingerprint**
   - Paste your SHA-1 fingerprint
   - Click **Save**

3. Download the updated `google-services.json`
4. Replace `android/app/google-services.json` with the new file

## Step 4: iOS Configuration (If Building for iOS)

### Already configured by FlutterFire CLI!
The `GoogleService-Info.plist` is already in your project.

### If you need to regenerate:
1. In Firebase Console, go to **Project Settings**
2. Select your iOS app
3. Download `GoogleService-Info.plist`
4. Add it to your Xcode project:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into the `Runner` folder
   - Check "Copy items if needed"

## Step 5: Test Authentication

Run your app:
```bash
flutter run
```

### Expected Flow:
1. ✅ Auth screen appears with "Sign in with Google" button
2. ✅ Click button → Google sign-in popup appears
3. ✅ Select Google account → Sign in
4. ✅ Redirects to Onboarding screen (first time users)
5. ✅ Complete assessment → Level saved to Firebase
6. ✅ Navigate to Main Menu

### Verify in Firebase Console:
1. Go to **Authentication** → **Users** tab
2. You should see your user listed with:
   - UID
   - Email
   - Sign-in provider: Google
   - Creation date

3. Go to **Firestore Database** → **Data** tab
4. Check `users` collection → Your UID document
5. Verify fields: email, displayName, userLevel, etc.

## Troubleshooting

### "Sign in failed: PlatformException"
- **Android**: Make sure SHA-1 fingerprint is added to Firebase Console
- **iOS**: Ensure `GoogleService-Info.plist` is in the project
- **Web**: Clear browser cache and try again

### "User canceled sign-in"
- This is normal if user clicks "Cancel" or closes the popup
- No action needed

### Firestore permission denied
- Deploy the security rules from `firestore.rules`
- Make sure user is authenticated before trying to read/write

### Authentication works but user not created in Firestore
- Check Firebase Console → Firestore → Data tab
- Look for error messages in Flutter console
- Verify Firestore is enabled (not in trial mode)

## Production Checklist

Before releasing to production:

- [ ] Google OAuth enabled in Firebase Console
- [ ] Firestore security rules deployed
- [ ] Android release SHA-1 fingerprint added
- [ ] iOS `GoogleService-Info.plist` added to Xcode
- [ ] Test sign-in on all target platforms
- [ ] Verify user data is saved to Firestore
- [ ] Check Firebase quota usage (should be minimal)
- [ ] Add privacy policy and terms of service links

## Firebase Free Tier Monitoring

Monitor your usage to stay within free limits:

1. Go to Firebase Console
2. Click **Usage and billing** → **Details**
3. Check:
   - Firestore reads/writes/deletes per day
   - Storage usage
   - Authentication sign-ins

**Free Tier Limits:**
- Authentication: Unlimited users ✅
- Firestore: 50k reads, 20k writes, 1GB storage per day ✅

Your app should use:
- ~2-4 writes per user per day
- ~1-2 reads per user per session
- <1KB per user document

= Supports **thousands** of daily active users on free tier! 🎉
