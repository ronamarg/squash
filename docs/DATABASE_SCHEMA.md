# Database Schema Update - User Data

## Updated User Data Structure

The Firebase Firestore database now supports the following user data fields:

### Core Fields

1. **User Login (Authentication)**
   - Handled by Firebase Authentication
   - OAuth via Google Sign-In
   - UID automatically generated

2. **Username**
   - Type: `String`
   - User's display name
   - Defaults to Google display name or auto-generated
   - Can be updated by user
   - Field: `username`

3. **Join Date**
   - Type: `DateTime` (stored as Timestamp)
   - Set when user first signs up
   - Immutable after creation
   - Field: `joinDate`

4. **Skill Classification**
   - Type: `String` 
   - Values: `'novice'`, `'intermediate'`, `'experienced'`
   - Determined by onboarding assessment
   - Updated less frequently (after reassessment or milestones)
   - Field: `skillClassification`

5. **Progression Score**
   - Type: `int`
   - Updated every quiz session
   - Cumulative score across all quizzes
   - Used to track overall progress
   - Field: `progressionScore`

### Additional Fields (Statistics)

- **lastLogin**: `DateTime` - Updated every time user signs in
- **totalQuizzesTaken**: `int` - Total number of quizzes completed
- **totalScore**: `int` - Total points earned across all quizzes
- **email**: `String` - User's email from Google OAuth
- **photoUrl**: `String?` - Profile photo URL (optional)

## API Methods

### FirebaseService Methods

```dart
// Get user data (pulls all fields including progressionScore and skillClassification)
Future<UserModel?> getUserData(String uid)

// Update skill classification (called after assessment or reclassification)
Future<void> updateSkillClassification(String uid, String skillClassification)

// Update progression score to a specific value
Future<void> updateProgressionScore(String uid, int score)

// Increment progression score by delta amount (atomic operation)
Future<void> incrementProgressionScore(String uid, int delta)

// Update username
Future<void> updateUsername(String uid, String username)

// Update quiz statistics
Future<void> updateQuizStats(String uid, int score)
```

### ProgressionManager Helper

Use this helper class to manage progression score updates during gameplay:

```dart
import 'services/progression_manager.dart';

final progressionManager = ProgressionManager();

// During quiz:
progressionManager.addPoints(10);        // Add points for correct answer
progressionManager.subtractPoints(5);    // Subtract for incorrect answer

// At end of quiz:
await progressionManager.saveProgressionScore();  // Saves to Firebase
```

## Integration Examples

### Example 1: Update Progression Score After Quiz

```dart
// In quiz_screen.dart or code_fix_quiz_screen.dart

import 'services/progression_manager.dart';
import 'services/firebase_service.dart';

final progressionManager = ProgressionManager();
final firebaseService = FirebaseService();

// When quiz completes:
void _onQuizComplete(int quizScore) async {
  final user = firebaseService.currentUser;
  if (user != null) {
    // Add quiz score to progression
    progressionManager.addPoints(quizScore);
    
    // Save progression score to Firebase
    await progressionManager.saveProgressionScore();
    
    // Also update quiz statistics
    await firebaseService.updateQuizStats(user.uid, quizScore);
  }
}
```

### Example 2: Display Progression Score on Main Menu

```dart
// In main_menu.dart

import 'services/firebase_service.dart';
import 'services/progression_manager.dart';

final firebaseService = FirebaseService();
final progressionManager = ProgressionManager();

@override
void initState() {
  super.initState();
  _loadUserData();
}

Future<void> _loadUserData() async {
  final user = firebaseService.currentUser;
  if (user != null) {
    final userData = await firebaseService.getUserData(user.uid);
    setState(() {
      username = userData?.username ?? 'User';
      progressionScore = userData?.progressionScore ?? 0;
      skillLevel = userData?.skillClassification ?? 'novice';
    });
  }
}
```

### Example 3: Update Skill Classification After Reassessment

```dart
// In assessment_screen.dart or onboarding_screen.dart

final firebaseService = FirebaseService();

Future<void> _updateSkillLevel(String newLevel) async {
  final user = firebaseService.currentUser;
  if (user != null) {
    await firebaseService.updateSkillClassification(user.uid, newLevel);
    print('Skill classification updated to: $newLevel');
  }
}
```

## Firebase Free Tier Optimization

### Read Operations
- **Pull progressionScore**: Once per session (login)
- **Pull skillClassification**: Once per session (login)
- **Total reads per session**: ~1-2 reads

### Write Operations
- **Update progressionScore**: Once per quiz (~1-5 per session)
- **Update skillClassification**: Rarely (maybe once per week/month)
- **Total writes per session**: ~2-6 writes

### Estimated Usage (100 users/day, 3 quizzes each)
- **Reads**: ~200/day (well under 50,000 limit)
- **Writes**: ~500/day (well under 20,000 limit)
- **Storage**: ~10 KB per user × 100 = 1 MB (well under 1 GB limit)

✅ **Still well within Firebase free tier!**

## Security Rules

The Firestore security rules have been updated to:
- Prevent users from modifying `uid`, `email`, or `joinDate`
- Validate required fields on user creation
- Allow users to update their own `username`, `progressionScore`, `skillClassification`

Deploy rules from `firestore.rules` to Firebase Console.

## Backward Compatibility

The updated schema maintains backward compatibility:
- `displayName` → `username` (auto-migrated)
- `userLevel` → `skillClassification` (auto-migrated)
- `createdAt` → `joinDate` (auto-migrated)

Old field names are still supported when reading data.
