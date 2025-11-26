// Environment configuration example
// Copy this file to env_config.dart and fill in your actual values

class EnvConfig {
  // ML API Base URL
  // DEVELOPMENT:
  // - Windows/Desktop -> 'http://localhost:5001' or 'http://127.0.0.1:5001'
  // - Android emulator -> 'http://10.0.2.2:5001'
  // - iOS simulator -> 'http://127.0.0.1:5001'
  // - Physical device -> 'http://<your-machine-lan-ip>:5001'
  // 
  // PRODUCTION:
  // - Use your deployed API URL (e.g., 'https://your-app.onrender.com')
  static const String mlApiBaseUrl = 'YOUR_ML_API_BASE_URL_HERE';
  
  // Ollama Cloud API Base URL (usually not needed, API handles this)
  static const String ollamaApiBaseUrl = 'https://api.cloud.ollama.ai';
  
  // Firebase Configuration
  // Get these values from Firebase Console -> Project Settings
  
  // Web
  static const String firebaseWebApiKey = 'YOUR_FIREBASE_WEB_API_KEY_HERE';
  static const String firebaseWebAppId = 'YOUR_FIREBASE_WEB_APP_ID_HERE';
  static const String firebaseWebMessagingSenderId = 'YOUR_MESSAGING_SENDER_ID_HERE';
  static const String firebaseProjectId = 'YOUR_PROJECT_ID_HERE';
  static const String firebaseAuthDomain = 'YOUR_AUTH_DOMAIN_HERE';
  static const String firebaseStorageBucket = 'YOUR_STORAGE_BUCKET_HERE';
  
  // Android
  static const String firebaseAndroidApiKey = 'YOUR_FIREBASE_ANDROID_API_KEY_HERE';
  static const String firebaseAndroidAppId = 'YOUR_FIREBASE_ANDROID_APP_ID_HERE';
  
  // iOS/macOS
  static const String firebaseIosApiKey = 'YOUR_FIREBASE_IOS_API_KEY_HERE';
  static const String firebaseIosAppId = 'YOUR_FIREBASE_IOS_APP_ID_HERE';
  static const String firebaseIosBundleId = 'YOUR_IOS_BUNDLE_ID_HERE';
  
  // Windows
  static const String firebaseWindowsApiKey = 'YOUR_FIREBASE_WINDOWS_API_KEY_HERE';
  static const String firebaseWindowsAppId = 'YOUR_FIREBASE_WINDOWS_APP_ID_HERE';
}

