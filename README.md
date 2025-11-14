# Squash - Coding Education Platform# 🎯 Squash - Coding Education Platform



Flutter-based coding education app with AI-powered features for learning Python.A Flutter-based coding education app with AI-powered features for personalized learning.



## 🚀 Quick Start## 🚀 Quick Start



### Flutter App### New to this project?

```bash**→ Read [`docs/START_HERE.txt`](docs/START_HERE.txt)** for a complete visual overview.

flutter pub get

flutter run### Want to run the Flutter app?

```**→ See [`docs/README_FLUTTER_SETUP.md`](docs/README_FLUTTER_SETUP.md)** for detailed Flutter setup.



### ML Models (Optional - for backend features)### Want to use ML models?

```bash**→ Run `ml_menu.bat`** for an interactive menu to access all ML models.

# Interactive menu for all ML operations

ml_menu.bat### Looking for documentation?

**→ Check [`docs/`](docs/)** folder for all guides and references.

# Or manually start APIs:

cd ml_models/code_similarity && python api.py## 📁 Project Structure

```

```

## 📁 Project Structuresquash/

├── lib/              Flutter app code

```├── ml_models/        Machine learning models

squash/│   ├── skill_classifier/    Random Forest classifier

├── lib/              # Flutter app│   ├── code_similarity/     Similarity scorer

├── ml_models/        # ML models (Random Forest, CodeT5, etc.)│   ├── code_corruptor/      Deep learning bug generator

├── data/             # Datasets│   └── shared/              Common utilities

└── docs/             # Documentation├── data/             Datasets (raw & processed)

```├── docs/             📚 All documentation

└── android/ios/web/  Platform builds

## 🤖 ML Models```



| Model | Type | Purpose |## 🤖 ML Models

|-------|------|---------|

| Skill Classifier | Random Forest | Classify student proficiency || Model | Purpose | Location |

| Code Similarity | Custom Algorithm | Score code similarity ||-------|---------|----------|

| Code Corruptor | CodeT5 Transformer | Generate buggy code || **Skill Classifier** | Classify student proficiency | `ml_models/skill_classifier/` |

| **Code Similarity** | Score code similarity | `ml_models/code_similarity/` |

**See `ml_models/README.md` for detailed ML documentation.**| **Code Corruptor** | Generate buggy code (AI) | `ml_models/code_corruptor/` |



## 📚 Documentation## 📚 Documentation



Essential docs in `docs/`:- **[Start Here](docs/START_HERE.txt)** - Complete overview ⭐

- **ML_ORGANIZATION.md** - ML models overview- **[Flutter Setup](docs/README_FLUTTER_SETUP.md)** - Flutter app setup guide

- **CODE_CORRUPTION_GUIDE.md** - Deep learning guide- **[Directory Tree](docs/DIRECTORY_TREE.txt)** - Full structure map

- **QUICK_REFERENCE.txt** - Common commands- **[ML Organization](docs/ML_ORGANIZATION.md)** - ML models guide

- **DIRECTORY_TREE.txt** - Visual structure- **[Quick Reference](docs/QUICK_REFERENCE.txt)** - Command reference

- **[Code Corruptor Guide](docs/CODE_CORRUPTION_GUIDE.md)** - Deep learning tutorial

## 📦 Dependencies

See [`docs/README.md`](docs/README.md) for complete documentation index.

**Flutter:** See `pubspec.yaml`

## 🛠️ Setup

**Python:**

```bash### Flutter App

pip install -r requirements.txt        # Basic ML```bash

pip install -r requirements_dl.txt     # Deep Learning (optional)flutter pub get

```flutter run

```

## 🔧 ConfigurationSee [`docs/README_FLUTTER_SETUP.md`](docs/README_FLUTTER_SETUP.md) for detailed setup.



Edit `lib/config.dart` for API endpoints:### ML Models (Basic)

- Code Similarity: `http://10.0.2.2:5000````bash

- Code Corruptor: `http://10.0.2.2:5001`pip install -r requirements.txt

```

## 🛠️ Development

### Deep Learning (Code Corruptor)

```bash```bash

# Flutter developmentpip install -r requirements_dl.txt

flutter runcd ml_models\code_corruptor

python train.py

# Start ML backend (separate terminals)```

cd ml_models/code_similarity && python api.py

cd ml_models/code_corruptor && python api.py## 🎮 Interactive Menu

``````bash

ml_menu.bat

## 📱 Platforms```

Provides easy access to:

✅ Android • iOS • Web • Windows • Linux • macOS- Train models

- Start APIs
- View documentation
- Navigate directories

## 🔗 Quick Commands

### Train Skill Classifier
```bash
cd ml_models\skill_classifier
python train.py
```

### Run Code Similarity API
```bash
cd ml_models\code_similarity
python api.py
```

### Train Code Corruptor (Deep Learning)
```bash
cd ml_models\code_corruptor
python train.py
```

## 📊 Features

### Flutter App
- 📱 Cross-platform (Android, iOS, Web, Desktop)
- 🎓 Interactive coding challenges
- 📈 Progress tracking
- 🎯 Adaptive difficulty

### ML Backend
- 🤖 AI-powered code analysis
- 🔍 Similarity scoring
- 🐛 Automatic bug generation
- 📊 Skill level prediction

## 🏗️ Architecture

```
Flutter App (Dart)
       ↓
  HTTP APIs
       ↓
Python ML Services
       ↓
ML Models
```

Clean separation: Flutter communicates via REST APIs to Python ML backend.

## 📖 Learn More

- **[ML Models Overview](ml_models/README.md)** - Detailed model documentation
- **[Flutter Services](lib/services/README.md)** - API integration guide
- **[Organization Guide](docs/ML_ORGANIZATION.md)** - Complete organization details

---

**Need help?** Start with [`docs/START_HERE.txt`](docs/START_HERE.txt) or run `ml_menu.bat`

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