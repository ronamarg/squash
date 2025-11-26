import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '538384695333-171qjk7mtch8plk0mpk34n7on00g0cid.apps.googleusercontent.com',
    scopes: ['email'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _createOrUpdateUser(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailPassword(String email, String password, String username) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(username);

      if (userCredential.user != null) {
        await _createOrUpdateUserWithUsername(userCredential.user!, username);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters.');
        case 'email-already-in-use':
          throw Exception('An account already exists with this email.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        default:
          throw Exception('Sign up failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error signing up with email: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _createOrUpdateUser(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        default:
          throw Exception('Sign in failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        default:
          throw Exception('Password reset failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> _createOrUpdateUser(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();
    final now = DateTime.now();

    if (!docSnapshot.exists) {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: user.displayName ?? 'User${user.uid.substring(0, 6)}',
        photoUrl: user.photoURL,
        skillClassification: 'novice',
        progressionValue: 0,
        joinDate: now,
        lastLogin: now,
        totalQuizzesTaken: 0,
        totalScore: 0,
      );
      await docRef.set(userModel.toMap());
    } else {
      await docRef.update({'lastLogin': Timestamp.fromDate(now)});
    }
  }

  Future<void> _createOrUpdateUserWithUsername(User user, String username) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();
    final now = DateTime.now();

    if (!docSnapshot.exists) {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: username,
        photoUrl: user.photoURL,
        skillClassification: 'novice',
        progressionValue: 0,
        joinDate: now,
        lastLogin: now,
        totalQuizzesTaken: 0,
        totalScore: 0,
      );
      await docRef.set(userModel.toMap());
    } else {
      await docRef.update({'lastLogin': Timestamp.fromDate(now)});
    }
  }

  Future<void> updateSkillClassification(String uid, String skillClassification) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        // Determine initial progression target for this classification
        final lc = skillClassification.toLowerCase();
        final int targetInitial = (lc == 'novice') ? 150 : 400; // intermediate & advanced start at 400

        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          final dynamic rawPV = data['progressionValue'];
          final int currentPV = (rawPV is num) ? rawPV.toInt() : 0;
          // Only bump progressionValue upward if below the target (avoid overwriting existing progress)
          final newPV = currentPV < targetInitial ? targetInitial : currentPV;
          debugPrint('[updateSkillClassification] uid=$uid skill=$lc currentPV=$currentPV target=$targetInitial newPV=$newPV');
          transaction.update(docRef, {
            'skillClassification': lc,
            'progressionValue': newPV,
            'progressionInitialized': true,
          });
        } else {
          // Doc missing: create minimal user doc with initial progression
          final user = _auth.currentUser;
          debugPrint('[updateSkillClassification] Creating user doc for uid=$uid skill=$lc initialPV=$targetInitial');
          transaction.set(docRef, {
            'uid': uid,
            'email': user?.email ?? '',
            'username': user?.displayName ?? 'User${uid.substring(0,6)}',
            'photoUrl': user?.photoURL,
            'skillClassification': lc,
            'progressionValue': targetInitial,
            'progressionInitialized': true,
            'joinDate': Timestamp.fromDate(DateTime.now()),
            'lastLogin': Timestamp.fromDate(DateTime.now()),
            'totalQuizzesTaken': 0,
            'totalScore': 0,
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating skill classification (with progression assignment): $e');
      rethrow;
    }
  }

  /// Ensures the user's progressionValue is at least the baseline for their skillClassification.
  /// Call this after onboarding if needed.
  Future<int?> ensureProgressionBaseline(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final snap = await docRef.get();
      if (!snap.exists) return null;
      final data = snap.data() ?? {};
      final lc = (data['skillClassification'] ?? 'novice').toString().toLowerCase();
      final baseline = (lc == 'novice') ? 150 : 400;
      final dynamic rawPV = data['progressionValue'];
      final currentPV = (rawPV is num) ? rawPV.toInt() : 0;
      if (currentPV < baseline) {
        debugPrint('[ensureProgressionBaseline] Raising uid=$uid from $currentPV to baseline $baseline for skill=$lc');
        await docRef.update({'progressionValue': baseline});
        return baseline;
      }
      return currentPV;
    } catch (e) {
      debugPrint('Error ensuring progression baseline: $e');
      return null;
    }
  }

  Future<int> updateProgressionValue(String uid, int codeSimilarityScore) async {
    final docRef = _firestore.collection('users').doc(uid);
    // Scoring algorithm design:
    // - Apply a small multiplicative momentum to current value so progress feels gradual and satisfying.
    // - Amplify positive deltas (user improved) to reward progress more noticeably.
    // - Damp negative deltas so mistakes are not punishing.
    // - Add a tiny bonus proportional to similarity to feel rewarding even for small gains.
    final delta = codeSimilarityScore - 80;

    try {
      final updatedValue = await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final int currentValue = snapshot.exists ? (snapshot.data()?['progressionValue'] ?? 0) : 0;

        // Multiplicative momentum (small): helps values grow slowly over time
        const double momentum = 1.02; // 2% momentum

        // Reward/dampen logic
        double change;
        if (delta >= 0) {
          // amplify positive improvements
          change = delta * 2.0; // positive improvements count more
        } else {
          // dampen negative changes so they don't feel punishing
          change = delta * 0.3; // negative changes reduced to 30%
        }

        // Small bonus so higher absolute similarity gives a little extra satisfaction
        final double bonus = (codeSimilarityScore.clamp(0, 100) / 100.0) * 1.0; // up to +1

        // Combine momentum, change and bonus. Round to int and clamp to allowed range.
        final double raw = (currentValue * momentum) + change + bonus;
        final int newValue = raw.round().clamp(0, 1000);

        if (snapshot.exists) {
          transaction.update(docRef, {'progressionValue': newValue});
        } else {
          transaction.set(docRef, {'progressionValue': newValue}, SetOptions(merge: true));
        }

        return newValue;
      });

      return updatedValue;
    } catch (e) {
      debugPrint('Error updating progression value: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateQuizStats(String uid, int score) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final currentQuizzes = snapshot.data()?['totalQuizzesTaken'] ?? 0;
          final currentScore = snapshot.data()?['totalScore'] ?? 0;

          transaction.update(docRef, {
            'totalQuizzesTaken': currentQuizzes + 1,
            'totalScore': currentScore + score,
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating quiz stats: $e');
      rethrow;
    }
  }

  Future<bool> hasCompletedOnboarding(String uid) async {
    try {
      final userData = await getUserData(uid);
      // Consider onboarding completed if a skillClassification exists (any value)
      // This prevents re-showing onboarding even for users classified as 'novice'.
      return userData != null && (userData.skillClassification).toString().isNotEmpty;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  Future<void> updateUsername(String uid, String username) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'username': username,
      });
    } catch (e) {
      debugPrint('Error updating username: $e');
      rethrow;
    }
  }
}
