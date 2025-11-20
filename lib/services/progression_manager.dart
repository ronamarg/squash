import 'firebase_service.dart';

/// Helper class to manage progression score updates during quiz sessions
class ProgressionManager {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Track score changes during current session
  int _sessionScoreDelta = 0;
  
  /// Add points to the session progression score
  /// Call this after each quiz question or quiz completion
  void addPoints(int points) {
    _sessionScoreDelta += points;
  }
  
  /// Subtract points from the session progression score
  /// Call this for incorrect answers or penalties
  void subtractPoints(int points) {
    _sessionScoreDelta -= points;
  }
  
  /// Get current session score delta (not yet saved to Firebase)
  int get sessionDelta => _sessionScoreDelta;
  
  /// Save accumulated progression score to Firebase
  /// Call this at the end of each quiz or session
  Future<void> saveProgressionScore() async {
    final user = _firebaseService.currentUser;
    if (user == null) {
      print('No user logged in, cannot save progression score');
      return;
    }
    
    if (_sessionScoreDelta == 0) {
      print('No progression score changes to save');
      return;
    }
    
    try {
      // Use increment to safely update the score
      await _firebaseService.incrementProgressionScore(user.uid, _sessionScoreDelta);
      print('Progression score updated: +$_sessionScoreDelta');
      _sessionScoreDelta = 0; // Reset session delta after saving
    } catch (e) {
      print('Error saving progression score: $e');
      rethrow;
    }
  }
  
  /// Get current progression score from Firebase
  Future<int> getCurrentProgressionScore() async {
    final user = _firebaseService.currentUser;
    if (user == null) return 0;
    
    try {
      final userData = await _firebaseService.getUserData(user.uid);
      return userData?.progressionScore ?? 0;
    } catch (e) {
      print('Error fetching progression score: $e');
      return 0;
    }
  }
  
  /// Set progression score to a specific value (use with caution)
  /// Prefer using addPoints/subtractPoints and saveProgressionScore
  Future<void> setProgressionScore(int score) async {
    final user = _firebaseService.currentUser;
    if (user == null) {
      print('No user logged in, cannot set progression score');
      return;
    }
    
    try {
      await _firebaseService.updateProgressionScore(user.uid, score);
      _sessionScoreDelta = 0; // Reset session delta
      print('Progression score set to: $score');
    } catch (e) {
      print('Error setting progression score: $e');
      rethrow;
    }
  }
  
  /// Reset session score delta without saving to Firebase
  /// Call this if you want to discard session progress
  void resetSessionDelta() {
    _sessionScoreDelta = 0;
  }
}
