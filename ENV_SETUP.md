# Environment Setup Instructions

## For Collaborators

This project uses environment variables to store sensitive configuration like API keys and Firebase credentials. These are **not** committed to the repository for security reasons.

### Setup Steps

1. **Copy the example environment file:**
   ```bash
   cp lib/env_config.example.dart lib/env_config.dart
   ```

2. **Fill in your configuration values in `lib/env_config.dart`:**

   - **ML API Base URL**: Set this based on your development environment:
     - Windows/Desktop: `http://localhost:5001` or `http://127.0.0.1:5001`
     - Android emulator: `http://10.0.2.2:5001`
     - iOS simulator: `http://127.0.0.1:5001`
     - Physical device: `http://<your-machine-lan-ip>:5001`

   - **Firebase Credentials**: Get these from the Firebase Console (https://console.firebase.google.com)
     - Go to Project Settings → General → Your apps
     - For each platform (Web, Android, iOS, Windows), copy the configuration values
     - Fill in the corresponding fields in `env_config.dart`

3. **Never commit `lib/env_config.dart`** - This file is in `.gitignore` and should remain untracked

### Firebase Setup

If you need to set up Firebase from scratch:

1. Go to https://console.firebase.google.com
2. Create a new project or use the existing `squash-bc287` project
3. Enable Authentication → Email/Password and Google Sign-In
4. Create a Firestore Database
5. Set up Firestore Security Rules (see `firestore.rules` if available)
6. Add your app for each platform (Web, Android, iOS, Windows)
7. Copy the configuration values to `env_config.dart`

### ML API Setup

The ML API should be running on port 5001. Make sure:
- The Python Flask server is running (`python ml_models/unified_api.py`)
- The API is accessible from your development device
- Configure the correct URL in `env_config.dart` based on your setup

### Verification

Run the app to verify your configuration:
```bash
flutter run
```

If you encounter authentication or API errors, double-check your `env_config.dart` values.

## Contact

For access to the actual Firebase project or if you need help with setup, contact the project maintainers.
