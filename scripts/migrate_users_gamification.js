/**
 * Firebase Migration Script: Add Gamification Fields to All Users
 * 
 * This script adds the following fields to all existing user documents:
 * - xp: 0 (starting XP)
 * - level: 1 (starting level)
 * - earnedBadges: [] (empty badge list)
 * - dailyLoginStreak: 0
 * - lastDailyBonusDate: null
 * 
 * Run with: node migrate_users_gamification.js
 * 
 * Prerequisites:
 * 1. npm install firebase-admin
 * 2. Download service account key from Firebase Console
 * 3. Set GOOGLE_APPLICATION_CREDENTIALS env var or update path below
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// Option 1: Use service account file
const serviceAccount = require('../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Option 2: Use default credentials (if running on GCP or with GOOGLE_APPLICATION_CREDENTIALS)
// admin.initializeApp({
//   credential: admin.credential.applicationDefault()
// });

const db = admin.firestore();

// Default gamification values for existing users
const GAMIFICATION_DEFAULTS = {
  xp: 100,              // Give existing users a small welcome bonus
  level: 1,
  earnedBadges: [],
  dailyLoginStreak: 0,
  lastDailyBonusDate: null,
  // Also ensure streak fields exist
  currentStreak: 0,
  longestStreak: 0,
  lastPracticeDate: null,
};

async function migrateUsers() {
  console.log('🚀 Starting user migration for gamification fields...\n');
  
  try {
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();
    
    if (snapshot.empty) {
      console.log('No users found in database.');
      return;
    }
    
    console.log(`Found ${snapshot.size} users to migrate.\n`);
    
    let updated = 0;
    let skipped = 0;
    let errors = 0;
    
    const batch = db.batch();
    const batchSize = 500; // Firestore batch limit
    let batchCount = 0;
    
    for (const doc of snapshot.docs) {
      const userData = doc.data();
      const userId = doc.id;
      
      // Check which fields need to be added
      const updates = {};
      let needsUpdate = false;
      
      for (const [field, defaultValue] of Object.entries(GAMIFICATION_DEFAULTS)) {
        if (userData[field] === undefined || userData[field] === null) {
          updates[field] = defaultValue;
          needsUpdate = true;
        }
      }
      
      if (needsUpdate) {
        console.log(`📝 Updating user: ${userData.email || userId}`);
        console.log(`   Adding fields: ${Object.keys(updates).join(', ')}`);
        
        batch.update(doc.ref, updates);
        batchCount++;
        updated++;
        
        // Commit batch if we hit the limit
        if (batchCount >= batchSize) {
          await batch.commit();
          console.log(`\n✅ Committed batch of ${batchCount} updates\n`);
          batchCount = 0;
        }
      } else {
        console.log(`⏭️  Skipping user: ${userData.email || userId} (already has all fields)`);
        skipped++;
      }
    }
    
    // Commit any remaining updates
    if (batchCount > 0) {
      await batch.commit();
      console.log(`\n✅ Committed final batch of ${batchCount} updates`);
    }
    
    console.log('\n' + '='.repeat(50));
    console.log('📊 Migration Summary:');
    console.log(`   Total users: ${snapshot.size}`);
    console.log(`   Updated: ${updated}`);
    console.log(`   Skipped: ${skipped}`);
    console.log(`   Errors: ${errors}`);
    console.log('='.repeat(50));
    console.log('\n✨ Migration complete!');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
migrateUsers()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Unhandled error:', error);
    process.exit(1);
  });
