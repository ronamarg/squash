import 'package:flutter/material.dart';

/// Skill Level Badge Widget
/// 
/// Displays user's skill level with icon, color coding, and optional progress
/// 
/// Usage:
/// ```dart
/// SkillLevelBadge(
///   skillLevel: 'intermediate',
///   progressionValue: 450,
///   showProgress: true,
/// )
/// ```
class SkillLevelBadge extends StatelessWidget {
  final String skillLevel;
  final int? progressionValue;
  final bool showProgress;
  final bool compact;
  final double? size;

  const SkillLevelBadge({
    super.key,
    required this.skillLevel,
    this.progressionValue,
    this.showProgress = false,
    this.compact = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getSkillConfig(skillLevel);
    final effectiveSize = size ?? (compact ? 32.0 : 48.0);
    
    if (compact) {
      return _buildCompactBadge(config, effectiveSize);
    }
    
    return _buildFullBadge(context, config, effectiveSize);
  }

  Widget _buildCompactBadge(_SkillConfig config, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.color, config.colorLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: config.color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          config.emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildFullBadge(BuildContext context, _SkillConfig config, double iconSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.2),
            config.colorLight.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.color.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge icon
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [config.color, config.colorLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: config.color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                config.emoji,
                style: TextStyle(fontSize: iconSize * 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Level text and progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                config.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: config.color,
                ),
              ),
              if (showProgress && progressionValue != null) ...[
                const SizedBox(height: 4),
                _buildProgressIndicator(config),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(_SkillConfig config) {
    final progress = _getLevelProgress();
    final nextLevel = _getNextLevelName();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(config.color),
              minHeight: 6,
            ),
          ),
        ),
        if (nextLevel != null) ...[
          const SizedBox(height: 2),
          Text(
            '${(progress * 100).toInt()}% to $nextLevel',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }

  double _getLevelProgress() {
    if (progressionValue == null) return 0.0;
    const thresholds = [0, 150, 350, 600, 850, 1000];
    final currentIndex = _getSkillIndex();
    final start = thresholds[currentIndex];
    final end = thresholds[currentIndex + 1];
    return ((progressionValue! - start) / (end - start)).clamp(0.0, 1.0);
  }

  int _getSkillIndex() {
    const levels = ['beginner', 'novice', 'intermediate', 'advanced', 'expert'];
    final index = levels.indexOf(skillLevel.toLowerCase());
    return index >= 0 ? index : 1; // Default to novice
  }

  String? _getNextLevelName() {
    const levels = ['Beginner', 'Novice', 'Intermediate', 'Advanced', 'Expert'];
    final currentIndex = _getSkillIndex();
    if (currentIndex >= 4) return null;
    return levels[currentIndex + 1];
  }

  _SkillConfig _getSkillConfig(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return _SkillConfig(
          displayName: 'Beginner',
          emoji: '🌱',
          color: const Color(0xFF4CAF50),
          colorLight: const Color(0xFF81C784),
        );
      case 'novice':
        return _SkillConfig(
          displayName: 'Novice',
          emoji: '📚',
          color: const Color(0xFF2196F3),
          colorLight: const Color(0xFF64B5F6),
        );
      case 'intermediate':
        return _SkillConfig(
          displayName: 'Intermediate',
          emoji: '⭐',
          color: const Color(0xFF9C27B0),
          colorLight: const Color(0xFFBA68C8),
        );
      case 'advanced':
        return _SkillConfig(
          displayName: 'Advanced',
          emoji: '🚀',
          color: const Color(0xFFFF9800),
          colorLight: const Color(0xFFFFB74D),
        );
      case 'expert':
        return _SkillConfig(
          displayName: 'Expert',
          emoji: '👑',
          color: const Color(0xFFE91E63),
          colorLight: const Color(0xFFF06292),
        );
      default:
        return _SkillConfig(
          displayName: 'Novice',
          emoji: '📚',
          color: const Color(0xFF2196F3),
          colorLight: const Color(0xFF64B5F6),
        );
    }
  }
}

class _SkillConfig {
  final String displayName;
  final String emoji;
  final Color color;
  final Color colorLight;

  const _SkillConfig({
    required this.displayName,
    required this.emoji,
    required this.color,
    required this.colorLight,
  });
}

/// Animated skill level up celebration widget
class SkillLevelUpCelebration extends StatefulWidget {
  final String newLevel;
  final VoidCallback? onComplete;

  const SkillLevelUpCelebration({
    super.key,
    required this.newLevel,
    this.onComplete,
  });

  @override
  State<SkillLevelUpCelebration> createState() => _SkillLevelUpCelebrationState();
}

class _SkillLevelUpCelebrationState extends State<SkillLevelUpCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        widget.onComplete?.call();
      });
    });
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 LEVEL UP! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 16),
                SkillLevelBadge(
                  skillLevel: widget.newLevel,
                  showProgress: false,
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve reached ${_getDisplayName(widget.newLevel)}!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDisplayName(String level) {
    switch (level.toLowerCase()) {
      case 'beginner': return 'Beginner';
      case 'novice': return 'Novice';
      case 'intermediate': return 'Intermediate';
      case 'advanced': return 'Advanced';
      case 'expert': return 'Expert';
      default: return level;
    }
  }
}
