import 'package:flutter/material.dart';

/// Streak display widget with flame animation
/// 
/// Shows current streak with animated fire icon
/// 
/// Usage:
/// ```dart
/// StreakDisplay(
///   currentStreak: 7,
///   longestStreak: 14,
/// )
/// ```
class StreakDisplay extends StatefulWidget {
  final int currentStreak;
  final int? longestStreak;
  final bool showLongest;
  final double iconSize;
  final bool compact;

  const StreakDisplay({
    super.key,
    required this.currentStreak,
    this.longestStreak,
    this.showLongest = false,
    this.iconSize = 32,
    this.compact = false,
  });

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.currentStreak > 0) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreakDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStreak > 0 && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.currentStreak == 0 && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasStreak = widget.currentStreak > 0;
    final effectiveIconSize = widget.compact ? 20.0 : widget.iconSize;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated flame icon
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: hasStreak ? _scaleAnimation.value : 1.0,
              child: Icon(
                Icons.local_fire_department,
                color: hasStreak ? _getFlameColor() : Colors.grey,
                size: effectiveIconSize,
              ),
            );
          },
        ),
        SizedBox(width: widget.compact ? 4 : 8),
        
        // Streak text
        if (widget.compact)
          Text(
            '${widget.currentStreak}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: hasStreak ? Colors.white : Colors.grey,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.currentStreak} day${widget.currentStreak == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: effectiveIconSize * 0.5,
                  fontWeight: FontWeight.bold,
                  color: hasStreak ? Colors.white : Colors.grey,
                ),
              ),
              if (widget.showLongest && widget.longestStreak != null)
                Text(
                  'Best: ${widget.longestStreak}',
                  style: TextStyle(
                    fontSize: effectiveIconSize * 0.35,
                    color: Colors.grey[400],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Color _getFlameColor() {
    // Intensify color based on streak length
    if (widget.currentStreak >= 30) return Colors.red;
    if (widget.currentStreak >= 14) return Colors.deepOrange;
    if (widget.currentStreak >= 7) return Colors.orange;
    return Colors.amber;
  }
}

/// Due cards counter widget
/// 
/// Shows number of cards due for review today
/// 
/// Usage:
/// ```dart
/// DueCardsCounter(
///   dueCount: 15,
///   onTap: () => Navigator.push(...),
/// )
/// ```
class DueCardsCounter extends StatelessWidget {
  final int dueCount;
  final VoidCallback? onTap;
  final bool showIcon;
  final Color? backgroundColor;
  final bool compact;

  const DueCardsCounter({
    super.key,
    required this.dueCount,
    this.onTap,
    this.showIcon = true,
    this.backgroundColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDue = dueCount > 0;
    final iconSize = compact ? 16.0 : 20.0;
    final padding = compact 
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? 
              (hasDue ? Colors.blue.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(compact ? 12 : 20),
          border: Border.all(
            color: hasDue ? Colors.blue : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.school,
                color: hasDue ? Colors.blue : Colors.grey,
                size: iconSize,
              ),
              SizedBox(width: compact ? 4 : 6),
            ],
            Text(
              compact 
                  ? (hasDue ? '$dueCount' : '✓')
                  : (hasDue ? '$dueCount due' : 'All done!'),
              style: TextStyle(
                color: hasDue ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12 : 14,
              ),
            ),
            if (hasDue && !compact) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// XP Progress bar widget
/// 
/// Shows progress within current level
/// 
/// Usage:
/// ```dart
/// XPProgressBar(
///   currentXP: 450,
///   level: 2,
/// )
/// ```
class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int level;
  final bool showLabels;
  final double height;

  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.level,
    this.showLabels = true,
    this.height = 8,
  });

  // XP thresholds for each level
  static const List<int> levelThresholds = [0, 150, 350, 600, 850, 1000];
  static const List<String> levelNames = [
    'Beginner', 'Novice', 'Intermediate', 'Advanced', 'Expert'
  ];

  int get _levelStart => levelThresholds[level.clamp(0, 4)];
  int get _levelEnd => levelThresholds[(level + 1).clamp(1, 5)];
  int get _xpInLevel => (currentXP - _levelStart).clamp(0, _levelEnd - _levelStart);
  int get _xpNeeded => _levelEnd - _levelStart;
  double get _progress => _xpInLevel / _xpNeeded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level $level - ${levelNames[level.clamp(0, 4)]}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$_xpInLevel / $_xpNeeded XP',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        
        // Progress bar
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Stack(
              children: [
                // Progress fill
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getLevelColor(level),
                          _getLevelColor(level).withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Shimmer effect
                if (_progress > 0 && _progress < 1)
                  Positioned.fill(
                    child: _ShimmerEffect(progress: _progress),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0: return const Color(0xFF4CAF50);  // Green
      case 1: return const Color(0xFF2196F3);  // Blue
      case 2: return const Color(0xFF9C27B0);  // Purple
      case 3: return const Color(0xFFFF9800);  // Orange
      case 4: return const Color(0xFFE91E63);  // Pink
      default: return const Color(0xFF2196F3);
    }
  }
}

class _ShimmerEffect extends StatefulWidget {
  final double progress;

  const _ShimmerEffect({required this.progress});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            width: double.infinity * widget.progress,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// SR Stats summary card
/// 
/// Shows overview of spaced repetition progress
/// 
/// Usage:
/// ```dart
/// SRStatsCard(
///   dueToday: 15,
///   streak: 7,
///   totalReviews: 234,
/// )
/// ```
class SRStatsCard extends StatelessWidget {
  final int dueToday;
  final int streak;
  final int totalReviews;
  final int? longestStreak;
  final VoidCallback? onStartReview;

  const SRStatsCard({
    super.key,
    required this.dueToday,
    required this.streak,
    required this.totalReviews,
    this.longestStreak,
    this.onStartReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StreakDisplay(
                  currentStreak: streak,
                  longestStreak: longestStreak,
                  showLongest: false,
                  iconSize: 24,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.pending_actions,
                  value: dueToday.toString(),
                  label: 'Due Today',
                  color: dueToday > 0 ? Colors.blue : Colors.green,
                ),
                _StatItem(
                  icon: Icons.check_circle_outline,
                  value: totalReviews.toString(),
                  label: 'Total Reviews',
                  color: Colors.purple,
                ),
                if (longestStreak != null)
                  _StatItem(
                    icon: Icons.emoji_events,
                    value: longestStreak.toString(),
                    label: 'Best Streak',
                    color: Colors.amber,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Start review button
            if (dueToday > 0 && onStartReview != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStartReview,
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Review $dueToday Cards'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else if (dueToday == 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'All caught up! 🎉',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

/// Skill level badge widget
/// 
/// Displays user's current skill level with icon
/// 
/// Usage:
/// ```dart
/// SkillLevelBadge(
///   level: 'intermediate',
///   size: SkillBadgeSize.medium,
/// )
/// ```
enum SkillBadgeSize { small, medium, large }

class SkillLevelBadge extends StatelessWidget {
  final String level;
  final SkillBadgeSize size;
  final bool showLabel;

  const SkillLevelBadge({
    super.key,
    required this.level,
    this.size = SkillBadgeSize.medium,
    this.showLabel = true,
  });

  double get _iconSize {
    switch (size) {
      case SkillBadgeSize.small: return 20;
      case SkillBadgeSize.medium: return 32;
      case SkillBadgeSize.large: return 48;
    }
  }

  double get _fontSize {
    switch (size) {
      case SkillBadgeSize.small: return 10;
      case SkillBadgeSize.medium: return 14;
      case SkillBadgeSize.large: return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelData = _getLevelData(level.toLowerCase());
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _iconSize * 0.4,
        vertical: _iconSize * 0.2,
      ),
      decoration: BoxDecoration(
        color: levelData.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(_iconSize),
        border: Border.all(color: levelData.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            levelData.emoji,
            style: TextStyle(fontSize: _iconSize * 0.8),
          ),
          if (showLabel) ...[
            SizedBox(width: _iconSize * 0.2),
            Text(
              levelData.name,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: levelData.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({String name, String emoji, Color color}) _getLevelData(String level) {
    switch (level) {
      case 'beginner':
        return (name: 'Beginner', emoji: '🌱', color: const Color(0xFF4CAF50));
      case 'novice':
        return (name: 'Novice', emoji: '📚', color: const Color(0xFF2196F3));
      case 'intermediate':
        return (name: 'Intermediate', emoji: '⭐', color: const Color(0xFF9C27B0));
      case 'advanced':
        return (name: 'Advanced', emoji: '🚀', color: const Color(0xFFFF9800));
      case 'expert':
        return (name: 'Expert', emoji: '👑', color: const Color(0xFFE91E63));
      default:
        return (name: 'Novice', emoji: '📚', color: const Color(0xFF2196F3));
    }
  }
}

/// Review Session Summary Widget
/// 
/// Shows summary after completing a review session
/// 
/// Usage:
/// ```dart
/// ReviewSessionSummary(
///   cardsReviewed: 15,
///   correctCount: 12,
///   avgQuality: 4.2,
///   streakDay: 7,
/// )
/// ```
class ReviewSessionSummary extends StatelessWidget {
  final int cardsReviewed;
  final int correctCount;
  final double avgQuality;
  final int streakDay;

  const ReviewSessionSummary({
    super.key,
    required this.cardsReviewed,
    required this.correctCount,
    required this.avgQuality,
    required this.streakDay,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = cardsReviewed > 0 
        ? (correctCount / cardsReviewed * 100).round() 
        : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryStatItem(
                icon: Icons.style,
                value: '$cardsReviewed',
                label: 'Cards',
                color: Colors.blue,
              ),
              _SummaryStatItem(
                icon: Icons.check_circle,
                value: '$accuracy%',
                label: 'Accuracy',
                color: accuracy >= 80 ? Colors.green : (accuracy >= 60 ? Colors.orange : Colors.red),
              ),
              _SummaryStatItem(
                icon: Icons.star,
                value: avgQuality.toStringAsFixed(1),
                label: 'Avg Quality',
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Streak display
          if (streakDay > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '$streakDay day streak!',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
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

class _SummaryStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
