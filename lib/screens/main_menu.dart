import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import '../services/spaced_repetition_service.dart';
import '../widgets/animated_shapes.dart';
import '../widgets/gamification_widgets.dart';
import '../widgets/sr_widgets.dart';
import 'code_fix_quiz_screen.dart';
import 'lessons_screen.dart';
import 'review_screen.dart';
import 'run_code_screen.dart';
import 'user_profile_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final String level;
  final List<Map<String, dynamic>> questionsToLoad;

  const MainMenuScreen({super.key, required this.level, required this.questionsToLoad});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final bool _isDark = true; // Always dark mode

  _MenuPalette get _palette => _MenuPalette.dark();

  @override
  void initState() {
    super.initState();
  }

  /// Get SR stats (streak and due cards) and gamification data for display
  Future<Map<String, dynamic>> _getSRStats() async {
    try {
      final firebase = FirebaseService();
      final user = firebase.currentUser;
      if (user == null) return {'streak': 0, 'dueCards': 0, 'xp': 0, 'level': 1};
      
      final srService = SpacedRepetitionService();
      final dueCards = await srService.getDueCards(user.uid);
      final userData = await firebase.getUserData(user.uid);
      final streak = userData?.currentStreak ?? 0;
      final xp = userData?.xp ?? 0;
      final level = userData?.level ?? 1;
      
      // Process daily login bonus
      final gamification = GamificationService();
      final bonus = await gamification.processDailyLogin(user.uid);
      
      return {
        'streak': streak, 
        'dueCards': dueCards.length,
        'xp': xp + bonus.xpAwarded,
        'level': level,
        'dailyBonusAwarded': bonus.isFirstToday,
        'dailyBonusXp': bonus.xpAwarded,
      };
    } catch (e) {
      return {'streak': 0, 'dueCards': 0, 'xp': 0, 'level': 1};
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebase = FirebaseService();
    final user = firebase.currentUser;
    final fallbackLevel = widget.level.isEmpty ? 'novice' : widget.level;
    final totalLessons = allLessons.length;
    final palette = _palette;

    Widget buildScaffold({
      required String level,
      required String lessonProgressLabel,
      required String pvLabel,
    }) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'Squash',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: palette.accent,
              fontFamily: 'Helvetica',
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.account_circle, size: 28, color: palette.accent),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserProfileScreen(useDark: _isDark)),
                    );
                    if (mounted) setState(() {});
                  },
                  tooltip: 'Profile',
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(gradient: palette.backgroundGradient),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -50,
                          right: -30,
                          child: Opacity(
                            opacity: 0.18,
                            child: RotatingOrb(
                              color: palette.accent.withValues(alpha: 0.65),
                              size: 180,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: palette.badgeBorder),
                            boxShadow: [
                              BoxShadow(
                                color: palette.shadow,
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: palette.card,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: palette.shadow,
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.person, size: 40, color: palette.accent),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your Level',
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                level.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: palette.accent,
                                  letterSpacing: 1.5,
                                  fontFamily: 'Helvetica',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildBadge(palette: palette, icon: Icons.menu_book, label: lessonProgressLabel),
                                  const SizedBox(width: 12),
                                  _buildBadge(palette: palette, icon: Icons.bolt, label: pvLabel),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Spaced Repetition widgets
                              FutureBuilder<Map<String, dynamic>>(
                                future: _getSRStats(),
                                builder: (context, srSnapshot) {
                                  final streak = srSnapshot.data?['streak'] ?? 0;
                                  final dueCards = srSnapshot.data?['dueCards'] ?? 0;
                                  final xp = srSnapshot.data?['xp'] ?? 0;
                                  final level = srSnapshot.data?['level'] ?? 1;
                                  final dailyBonusAwarded = srSnapshot.data?['dailyBonusAwarded'] ?? false;
                                  final dailyBonusXp = srSnapshot.data?['dailyBonusXp'] ?? 0;
                                  
                                  // Show daily bonus toast when first loaded
                                  if (dailyBonusAwarded && srSnapshot.connectionState == ConnectionState.done) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber),
                                              const SizedBox(width: 8),
                                              Text('Daily bonus! +$dailyBonusXp XP 🎉'),
                                            ],
                                          ),
                                          backgroundColor: palette.surface,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    });
                                  }
                                  
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          StreakDisplay(
                                            currentStreak: streak,
                                            compact: true,
                                          ),
                                          const SizedBox(width: 16),
                                          DueCardsCounter(
                                            dueCount: dueCards,
                                            compact: true,
                                            onTap: dueCards > 0 ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const ReviewScreen(),
                                                ),
                                              ).then((_) {
                                                if (mounted) setState(() {});
                                              });
                                            } : null,
                                          ),
                                          const SizedBox(width: 16),
                                          // XP/Level compact display
                                          GamificationXPBar(
                                            currentXp: xp,
                                            level: level,
                                            compact: true,
                                            accentColor: palette.accent,
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    StaggeredListItem(
                      index: 0,
                      child: BounceButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => CodeFixQuizScreen(
                                    difficulty: level,
                                    useDark: _isDark,
                                  ),
                                ),
                              )
                              .then((_) {
                                if (mounted) setState(() {});
                              });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFB347FF)]),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8A3D).withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(68),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            onPressed: null,
                            icon: const Icon(Icons.code, size: 28, color: Colors.white),
                            label: const Text('Start Practice'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    StaggeredListItem(
                      index: 1,
                      child: BounceButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => LessonsScreen()))
                              .then((_) {
                                if (mounted) setState(() {});
                              });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(colors: [Color(0xFFFFA94D), Color(0xFF8F5BFF)]),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8F5BFF).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            onPressed: null,
                            icon: const Icon(Icons.menu_book, size: 26, color: Colors.white),
                            label: const Text('Lessons'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StaggeredListItem(
                      index: 2,
                      child: BounceButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const RunCodeScreen(),
                                ),
                              )
                              .then((_) {
                                if (mounted) setState(() {});
                              });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFF5F4B8B)]),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5F4B8B).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            onPressed: null,
                            icon: const Icon(Icons.play_arrow, size: 26, color: Colors.white),
                            label: const Text('Run Code'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Fix buggy Python code and improve your debugging skills!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.textMuted, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(context, palette: palette, icon: Icons.smart_toy, label: 'AI-Generated', value: 'Bugs'),
                        _buildStatCard(context, palette: palette, icon: Icons.speed, label: 'Real-time', value: 'Scoring'),
                        _buildStatCard(context, palette: palette, icon: Icons.trending_up, label: 'Adaptive', value: 'Learning'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (user == null) {
      final lessonsLabel = '0 / $totalLessons lessons';
      return buildScaffold(level: fallbackLevel, lessonProgressLabel: lessonsLabel, pvLabel: 'PV 0');
    }

    return FutureBuilder<UserModel?>(
      future: firebase.getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: palette.background,
            body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        final data = snapshot.data;
        final progress = data?.lessonProgress ?? const {};
        final completedLessons = progress.values
            .where((entry) => (entry is Map && (entry['completed'] ?? false) == true))
            .length;
        final lessonsLabel = '$completedLessons / $totalLessons lessons';
        final pvLabel = 'PV ${data?.progressionValue ?? 0}';
        final level = (data?.skillClassification ?? fallbackLevel).isEmpty
            ? fallbackLevel
            : data!.skillClassification;

        return buildScaffold(level: level, lessonProgressLabel: lessonsLabel, pvLabel: pvLabel);
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required _MenuPalette palette,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: palette.accent, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({required _MenuPalette palette, required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.badgeFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.badgeBorder),
        boxShadow: [
          BoxShadow(color: palette.shadow, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuPalette {
  final Color background;
  final Gradient backgroundGradient;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color badgeBorder;
  final Color badgeFill;
  final Color shadow;
  final Color accent;
  final Color accentSecondary;

  const _MenuPalette({
    required this.background,
    required this.backgroundGradient,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.badgeBorder,
    required this.badgeFill,
    required this.shadow,
    required this.accent,
    required this.accentSecondary,
  });

  factory _MenuPalette.dark() => _MenuPalette(
        background: const Color(0xFF0F1016),
        backgroundGradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C0D13), Color(0xFF141725)],
        ),
        surface: const Color(0xFF171A25),
        card: const Color(0xFF181B25),
        textPrimary: Colors.white,
        textSecondary: Colors.white,
        textMuted: const Color(0x99FFFFFF),
        badgeBorder: const Color(0x22FFFFFF),
        badgeFill: const Color(0xFF0F1016),
        shadow: Colors.black.withValues(alpha: 0.35),
        accent: AppColors.accent,
        accentSecondary: AppColors.accentSecondary,
      );
}
