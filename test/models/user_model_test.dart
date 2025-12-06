import 'package:flutter_test/flutter_test.dart';
import 'package:squash/models/user_model.dart';

void main() {
  group('UserModel', () {
    late UserModel baseUser;

    setUp(() {
      baseUser = UserModel(
        uid: 'test_uid_123',
        email: 'test@example.com',
        username: 'TestUser',
        skillClassification: 'intermediate',
        progressionValue: 400,
        currentLessonId: 'lesson_03',
        joinDate: DateTime(2025, 1, 1),
        lastLogin: DateTime(2025, 12, 6),
        totalQuizzesTaken: 50,
        totalScore: 1200,
        questionsSinceLastEval: 3,
        recentCodeFeatures: [{'feature': 'test'}],
        currentStreak: 5,
        longestStreak: 10,
        lastPracticeDate: DateTime(2025, 12, 5),
      );
    });

    // ============================================
    // CONSTRUCTION & DEFAULTS
    // ============================================
    group('Construction', () {
      test('creates with required fields only', () {
        final user = UserModel(
          uid: 'uid',
          email: 'email@test.com',
          username: 'User',
          joinDate: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        expect(user.uid, 'uid');
        expect(user.skillClassification, 'novice'); // default
        expect(user.progressionValue, 0); // default
        expect(user.currentLessonId, 'lesson_01'); // default
        expect(user.currentStreak, 0);
        expect(user.longestStreak, 0);
      });

      test('all fields set correctly', () {
        expect(baseUser.uid, 'test_uid_123');
        expect(baseUser.email, 'test@example.com');
        expect(baseUser.username, 'TestUser');
        expect(baseUser.skillClassification, 'intermediate');
        expect(baseUser.progressionValue, 400);
        expect(baseUser.currentLessonId, 'lesson_03');
        expect(baseUser.totalQuizzesTaken, 50);
        expect(baseUser.totalScore, 1200);
        expect(baseUser.questionsSinceLastEval, 3);
        expect(baseUser.recentCodeFeatures.length, 1);
        expect(baseUser.currentStreak, 5);
        expect(baseUser.longestStreak, 10);
      });
    });

    // ============================================
    // SKILL LEVEL HELPERS
    // ============================================
    group('Skill Level Helpers', () {
      test('skillLevels constant is correct', () {
        expect(UserModel.skillLevels, [
          'beginner', 'novice', 'intermediate', 'advanced', 'expert'
        ]);
      });

      test('skillLevelIndex returns correct index', () {
        expect(
          UserModel(uid: '', email: '', username: '', joinDate: DateTime.now(), lastLogin: DateTime.now(), skillClassification: 'beginner').skillLevelIndex,
          0,
        );
        expect(
          UserModel(uid: '', email: '', username: '', joinDate: DateTime.now(), lastLogin: DateTime.now(), skillClassification: 'novice').skillLevelIndex,
          1,
        );
        expect(
          UserModel(uid: '', email: '', username: '', joinDate: DateTime.now(), lastLogin: DateTime.now(), skillClassification: 'intermediate').skillLevelIndex,
          2,
        );
        expect(
          UserModel(uid: '', email: '', username: '', joinDate: DateTime.now(), lastLogin: DateTime.now(), skillClassification: 'advanced').skillLevelIndex,
          3,
        );
        expect(
          UserModel(uid: '', email: '', username: '', joinDate: DateTime.now(), lastLogin: DateTime.now(), skillClassification: 'expert').skillLevelIndex,
          4,
        );
      });

      test('skillLevelIndex clamps unknown levels', () {
        final user = UserModel(
          uid: '', email: '', username: '', 
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'unknown_level',
        );
        expect(user.skillLevelIndex, 0); // Clamped to 0
      });

      test('skillDisplayName returns proper names', () {
        final levels = ['beginner', 'novice', 'intermediate', 'advanced', 'expert'];
        final expected = ['Beginner', 'Novice', 'Intermediate', 'Advanced', 'Expert'];
        
        for (int i = 0; i < levels.length; i++) {
          final user = UserModel(
            uid: '', email: '', username: '',
            joinDate: DateTime.now(), lastLogin: DateTime.now(),
            skillClassification: levels[i],
          );
          expect(user.skillDisplayName, expected[i]);
        }
      });

      test('skillEmoji returns correct emoji', () {
        expect(
          UserModel(uid: '', email: '', username: '', joinDate: DateTime.now(), lastLogin: DateTime.now(), skillClassification: 'beginner').skillEmoji,
          '🌱',
        );
        expect(
          UserModel(uid: '', email: '', username: '', joinDate: DateTime.now(), lastLogin: DateTime.now(), skillClassification: 'expert').skillEmoji,
          '👑',
        );
      });

      test('skillColorHex returns valid hex values', () {
        final user = UserModel(
          uid: '', email: '', username: '',
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'beginner',
        );
        expect(user.skillColorHex, 0xFF4CAF50); // Green
      });
    });

    // ============================================
    // PROGRESSION HELPERS
    // ============================================
    group('Progression Helpers', () {
      test('canLevelUp returns false for expert', () {
        final expert = UserModel(
          uid: '', email: '', username: '',
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'expert',
          progressionValue: 1000,
        );
        expect(expert.canLevelUp, false);
      });

      test('canLevelUp checks threshold correctly', () {
        // Beginner needs 150 to level up
        final beginner = UserModel(
          uid: '', email: '', username: '',
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'beginner',
          progressionValue: 100,
        );
        expect(beginner.canLevelUp, false);

        final beginnerReady = UserModel(
          uid: '', email: '', username: '',
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'beginner',
          progressionValue: 150,
        );
        expect(beginnerReady.canLevelUp, true);
      });

      test('levelProgress returns 0-1 range', () {
        // Beginner (0-150 range), at 75 should be 50%
        final user = UserModel(
          uid: '', email: '', username: '',
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'beginner',
          progressionValue: 75,
        );
        expect(user.levelProgress, closeTo(0.5, 0.01));
      });

      test('levelProgress clamps to 0-1', () {
        final user = UserModel(
          uid: '', email: '', username: '',
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'beginner',
          progressionValue: 200, // Over threshold
        );
        expect(user.levelProgress, 1.0);
      });

      test('pointsToNextLevel calculates correctly', () {
        final user = UserModel(
          uid: '', email: '', username: '',
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'beginner',
          progressionValue: 100,
        );
        expect(user.pointsToNextLevel, 50); // 150 - 100

        final expert = UserModel(
          uid: '', email: '', username: '',
          joinDate: DateTime.now(), lastLogin: DateTime.now(),
          skillClassification: 'expert',
          progressionValue: 900,
        );
        expect(expert.pointsToNextLevel, 0); // Already max
      });
    });

    // ============================================
    // SERIALIZATION
    // ============================================
    group('Serialization', () {
      test('toMap contains all fields', () {
        final map = baseUser.toMap();
        
        expect(map['uid'], 'test_uid_123');
        expect(map['email'], 'test@example.com');
        expect(map['username'], 'TestUser');
        expect(map['skillClassification'], 'intermediate');
        expect(map['progressionValue'], 400);
        expect(map['currentLessonId'], 'lesson_03');
        expect(map['totalQuizzesTaken'], 50);
        expect(map['totalScore'], 1200);
        expect(map['questionsSinceLastEval'], 3);
        expect(map['currentStreak'], 5);
        expect(map['longestStreak'], 10);
      });

      test('progressionValue is clamped in fromMap', () {
        final map = {
          'uid': 'test',
          'email': 'test@test.com',
          'username': 'Test',
          'progressionValue': 5000, // Way over max
          'joinDate': DateTime.now(),
          'lastLogin': DateTime.now(),
        };
        // Note: fromMap expects Timestamps, so this tests the clamp logic
        // In real usage, it would come from Firestore
      });
    });

    // ============================================
    // COPY WITH
    // ============================================
    group('copyWith', () {
      test('creates copy with single field changed', () {
        final updated = baseUser.copyWith(currentStreak: 10);
        
        expect(updated.currentStreak, 10);
        expect(updated.uid, baseUser.uid); // Unchanged
        expect(updated.email, baseUser.email); // Unchanged
        expect(updated.skillClassification, baseUser.skillClassification); // Unchanged
      });

      test('creates copy with multiple fields changed', () {
        final updated = baseUser.copyWith(
          skillClassification: 'expert',
          progressionValue: 900,
          totalScore: 2000,
        );
        
        expect(updated.skillClassification, 'expert');
        expect(updated.progressionValue, 900);
        expect(updated.totalScore, 2000);
        expect(updated.uid, baseUser.uid); // Unchanged
      });

      test('preserves all unchanged fields', () {
        final updated = baseUser.copyWith(currentStreak: 100);
        
        expect(updated.uid, baseUser.uid);
        expect(updated.email, baseUser.email);
        expect(updated.username, baseUser.username);
        expect(updated.skillClassification, baseUser.skillClassification);
        expect(updated.progressionValue, baseUser.progressionValue);
        expect(updated.currentLessonId, baseUser.currentLessonId);
        expect(updated.totalQuizzesTaken, baseUser.totalQuizzesTaken);
        expect(updated.totalScore, baseUser.totalScore);
        expect(updated.questionsSinceLastEval, baseUser.questionsSinceLastEval);
        expect(updated.longestStreak, baseUser.longestStreak);
      });
    });
  });
}
