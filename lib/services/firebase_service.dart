import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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
        progressionScore: 0,
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
        progressionScore: 0,
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
      await _firestore.collection('users').doc(uid).update({
        'skillClassification': skillClassification,
      });
    } catch (e) {
      debugPrint('Error updating skill classification: $e');
      rethrow;
    }
  }

  Future<int> updateProgressionValue(String uid, int codeSimilarityScore) async {
    final docRef = _firestore.collection('users').doc(uid);
    final delta = codeSimilarityScore - 80;

    try {
      final updatedValue = await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final currentValue = snapshot.exists ? (snapshot.data()?['progressionValue'] ?? 0) : 0;
        final newValue = currentValue + delta;
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

  Future<void> updateProgressionScore(String uid, int score) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'progressionScore': score,
      });
    } catch (e) {
      debugPrint('Error updating progression score: $e');
      rethrow;
    }
  }

  Future<void> incrementProgressionScore(String uid, int delta) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final currentScore = snapshot.data()?['progressionScore'] ?? 0;
          transaction.update(docRef, {
            'progressionScore': currentScore + delta,
          });
        }
      });
    } catch (e) {
      debugPrint('Error incrementing progression score: $e');
      rethrow;
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
      return userData != null && userData.skillClassification != 'novice';
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
