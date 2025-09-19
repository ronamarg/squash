# Squash App

This repository contains the **Squash Flutter App**. Follow these step-by-step instructions to set up and run the app locally.

---

## 1. Project Setup
1. Clone or download this repository.  
   - The project folder should be located in a **path without spaces** to avoid build issues, e.g.:
C:\FlutterProject\Squash\squash_app

less
Copy code
2. Make sure you have **Flutter SDK** installed. Download from [flutter.dev](https://flutter.dev/docs/get-started/install/windows) and extract it to a folder without spaces, e.g.:
C:\flutter

yaml
Copy code
3. Add `C:\flutter\bin` to your **PATH** environment variable.

---

## 2. VSCode Configuration
1. Open VSCode.  
2. Open this project folder.  
3. Update `settings.json` to point to your Flutter SDK:
```json
{
    "dart.flutterSdkPath": "C:\\flutter"
}
Restart VSCode to apply changes.

3. Install Dependencies
Open the terminal in VSCode at the project root:

bash
Copy code
flutter clean
flutter pub get
This clears old builds and fetches all required dependencies for the app.

4. Start the Android Emulator
Option A: Android Studio (Recommended)

Open Android Studio → Tools → Device Manager.

Select your emulator (e.g., Medium_Phone_API_36.1) → click Play.

Wait until the home screen is fully visible.

Option B: CMD

cmd
Copy code
cd C:\Users\YourUserName\AppData\Local\Android\Sdk\emulator
start emulator -avd Medium_Phone_API_36.1
5. Verify Device Connection
Check that Flutter can detect the emulator:

bash
Copy code
cd C:\Users\YourUserName\AppData\Local\Android\Sdk\platform-tools
adb devices
Output should look like:

arduino
Copy code
List of devices attached
emulator-5554   device
If the emulator shows offline, restart ADB:

bash
Copy code
adb kill-server
adb start-server
6. Run the Flutter App
In the project root terminal, run:

bash
Copy code
flutter run
The app will build and launch on the emulator.

7. Hot Reload & Restart
While the app is running in the emulator:

Press r → Hot reload

Press R → Full restart

This allows you to see changes instantly without rebuilding the whole app.

8. Project Structure Overview
lib/ → Front-end Dart files (UI, screens, widgets)

android/ → Native Android project files (Gradle, manifest, build scripts)

ios/ → Native iOS project files (if running on macOS)

pubspec.yaml → Lists dependencies, assets, and Flutter SDK version

9. Tips & Common Pitfalls
Keep all paths without spaces (avoids Gradle errors).

Only run one emulator at a time.

Ensure Flutter SDK path is correct in VSCode.

Wait for the emulator to fully boot before running flutter run.

If you move the project folder, update the Flutter SDK path if necessary.