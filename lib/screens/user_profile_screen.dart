import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../main.dart'; // For AuthWrapper after logout
import 'assessment_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final bool useDark;

  const UserProfileScreen({super.key, this.useDark = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      final userData = await _firebaseService.getUserData(user.uid);
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _firebaseService.signOut();
        if (mounted) {
          // Return to AuthWrapper so the auth state stream drives navigation
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.useDark ? AppColors.background : const Color(0xFFFFFBF5);
    final appBarColor = widget.useDark ? AppColors.background : const Color(0xFFFF8A3D);
    final textPrimary = widget.useDark ? Colors.white : const Color(0xFF424242);
    final textSecondary = widget.useDark ? AppColors.textMuted : Colors.grey[600];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: appBarColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _userData == null
                ? const Center(child: Text('No user data found'))
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Profile Picture
                        CircleAvatar(
                        radius: 60,
                        backgroundColor: widget.useDark ? AppColors.card : Colors.orange.shade100,
                        backgroundImage: _userData!.photoUrl != null
                          ? NetworkImage(_userData!.photoUrl!)
                          : null,
                        child: _userData!.photoUrl == null
                          ? Icon(Icons.person, size: 60, color: widget.useDark ? Colors.white : Colors.orange)
                          : null,
                        ),
                      const SizedBox(height: 24),

                      // Username
                      Text(
                        _userData!.username,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Email
                      Text(
                        _userData!.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Stats Cards
                      _buildStatsCard(
                        'Skill Level',
                        _userData!.skillClassification.toUpperCase(),
                        Icons.star,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),

                      _buildStatsCard(
                        'Practice Progression',
                        '${_userData!.progressionValue}',
                        Icons.code,
                        Colors.teal,
                      ),
                      const SizedBox(height: 16),

                      _buildStatsCard(
                        'Quizzes Completed',
                        '${_userData!.totalQuizzesTaken}',
                        Icons.quiz,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),

                      _buildStatsCard(
                        'Total Score',
                        '${_userData!.totalScore}',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                      const SizedBox(height: 16),

                      _buildStatsCard(
                        'Member Since',
                        _formatDate(_userData!.joinDate),
                        Icons.calendar_today,
                        Colors.purple,
                      ),
                      const SizedBox(height: 32),

                      // Retake Assessment Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssessmentScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assessment),
                          label: const Text(
                            'Retake Skill Assessment',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appBarColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Logout',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: widget.useDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.useDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: widget.useDark ? 0.25 : 0.2),
                  color.withValues(alpha: widget.useDark ? 0.12 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.useDark ? AppColors.textMuted : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.useDark ? Colors.white : const Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
