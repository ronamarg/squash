import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username; // User-chosen display name
  final String? photoUrl;
  final String skillClassification; // 'novice', 'intermediate', 'experienced'
  final int progressionValue; // Updated after each practice run
  final DateTime joinDate;
  final DateTime lastLogin;
  final int totalQuizzesTaken; // For statistics
  final int totalScore; // For statistics

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.skillClassification = 'novice',
    this.progressionValue = 0,
    required this.joinDate,
    required this.lastLogin,
    this.totalQuizzesTaken = 0,
    this.totalScore = 0,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'skillClassification': skillClassification,
      'progressionValue': progressionValue,
      'joinDate': Timestamp.fromDate(joinDate),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalScore': totalScore,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? map['displayName'] ?? 'User', // Fallback for backward compatibility
      photoUrl: map['photoUrl'],
      skillClassification: map['skillClassification'] ?? map['userLevel'] ?? 'novice', // Backward compatible
      progressionValue: (map['progressionValue'] ?? 0).clamp(0, 1000),
      joinDate: (map['joinDate'] ?? map['createdAt'] ?? Timestamp.now()).toDate(),
      lastLogin: (map['lastLogin'] ?? Timestamp.now()).toDate(),
      totalQuizzesTaken: map['totalQuizzesTaken'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? photoUrl,
    String? skillClassification,
    int? progressionValue,
    DateTime? joinDate,
    DateTime? lastLogin,
    int? totalQuizzesTaken,
    int? totalScore,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      skillClassification: skillClassification ?? this.skillClassification,
      progressionValue: progressionValue ?? this.progressionValue,
      joinDate: joinDate ?? this.joinDate,
      lastLogin: lastLogin ?? this.lastLogin,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}
