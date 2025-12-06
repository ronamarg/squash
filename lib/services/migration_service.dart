import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Migration service to standardize user documents with gamification fields.
/// 
/// Usage (call once from admin context):
/// ```dart
/// final result = await MigrationService.migrateUsersToGamification();
/// print('Migrated ${result['updated']} users');
/// ```
class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Default values for gamification fields
  static const Map<String, dynamic> gamificationDefaults = {
    'xp': 100,              // Welcome bonus for existing users
    'level': 1,
    'earnedBadges': <String>[],
    'dailyLoginStreak': 0,
    'lastDailyBonusDate': null,
    'currentStreak': 0,
    'longestStreak': 0,
    'lastPracticeDate': null,
  };

  /// Migrate all users to include gamification fields.
  /// Returns a map with migration stats.
  static Future<Map<String, int>> migrateUsersToGamification() async {
    int updated = 0;
    int skipped = 0;
    int errors = 0;

    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      debugPrint('🚀 Starting migration for ${usersSnapshot.docs.length} users...');

      final batch = _firestore.batch();
      int batchCount = 0;
      const batchLimit = 500;

      for (final doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final updates = <String, dynamic>{};
          
          // Check each field and add if missing
          for (final entry in gamificationDefaults.entries) {
            if (!data.containsKey(entry.key) || data[entry.key] == null) {
              updates[entry.key] = entry.value;
            }
          }

          if (updates.isNotEmpty) {
            debugPrint('📝 Updating ${data['email'] ?? doc.id}: ${updates.keys.join(', ')}');
            batch.update(doc.reference, updates);
            batchCount++;
            updated++;

            // Commit batch if at limit
            if (batchCount >= batchLimit) {
              await batch.commit();
              debugPrint('✅ Committed batch of $batchCount updates');
              batchCount = 0;
            }
          } else {
            debugPrint('⏭️ Skipping ${data['email'] ?? doc.id} (complete)');
            skipped++;
          }
        } catch (e) {
          debugPrint('❌ Error updating ${doc.id}: $e');
          errors++;
        }
      }

      // Commit remaining
      if (batchCount > 0) {
        await batch.commit();
        debugPrint('✅ Committed final batch of $batchCount updates');
      }

      debugPrint('════════════════════════════════════════');
      debugPrint('Migration Complete!');
      debugPrint('Updated: $updated | Skipped: $skipped | Errors: $errors');
      debugPrint('════════════════════════════════════════');

    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      errors++;
    }

    return {
      'updated': updated,
      'skipped': skipped,
      'errors': errors,
    };
  }

  /// Migrate a single user (useful for on-demand updates)
  static Future<bool> migrateUser(String userId) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final updates = <String, dynamic>{};
      
      for (final entry in gamificationDefaults.entries) {
        if (!data.containsKey(entry.key) || data[entry.key] == null) {
          updates[entry.key] = entry.value;
        }
      }

      if (updates.isNotEmpty) {
        await docRef.update(updates);
        debugPrint('✅ Migrated user $userId with fields: ${updates.keys.join(', ')}');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Failed to migrate user $userId: $e');
      return false;
    }
  }
}
