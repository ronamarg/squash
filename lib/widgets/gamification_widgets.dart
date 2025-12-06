import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/gamification_service.dart';

/// Gamification XP Progress Bar with level display
class GamificationXPBar extends StatelessWidget {
  final int currentXp;
  final int level;
  final bool compact;
  final Color? accentColor;

  const GamificationXPBar({
    super.key,
    required this.currentXp,
    required this.level,
    this.compact = false,
    this.accentColor,
  });

  int _xpForNextLevel() {
    return (100 * ((level + 1) * 1.2)).round();
  }

  int _xpInCurrentLevel() {
    int totalForLevel = 0;
    for (int i = 1; i < level; i++) {
      totalForLevel += (100 * (i * 1.2)).round();
    }
    return (currentXp - totalForLevel).clamp(0, 999999);
  }

  String _getLevelTitle() {
    if (level >= 40) return 'Grandmaster';
    if (level >= 30) return 'Master';
    if (level >= 20) return 'Expert';
    if (level >= 15) return 'Skilled';
    if (level >= 10) return 'Apprentice';
    if (level >= 5) return 'Learner';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    final xpForNext = _xpForNextLevel();
    final xpInLevel = _xpInCurrentLevel();
    final progress = xpForNext > 0 ? (xpInLevel / xpForNext).clamp(0.0, 1.0) : 1.0;
    final color = accentColor ?? const Color(0xFFFF8A3D);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lv.$level',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getLevelTitle(),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentXp XP',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$xpInLevel / $xpForNext XP to Level ${level + 1}',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge display widget
class BadgeDisplay extends StatelessWidget {
  final BadgeDefinition badge;
  final bool earned;
  final double size;
  final VoidCallback? onTap;

  const BadgeDisplay({
    super.key,
    required this.badge,
    required this.earned,
    this.size = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: earned ? _getCategoryColor().withValues(alpha: 0.2) : Colors.grey.shade800,
          border: Border.all(
            color: earned ? _getCategoryColor() : Colors.grey.shade700,
            width: 2,
          ),
          boxShadow: earned
              ? [
                  BoxShadow(
                    color: _getCategoryColor().withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: earned
              ? Text(
                  badge.emoji,
                  style: TextStyle(fontSize: size * 0.5),
                )
              : Icon(
                  badge.isSecret ? Icons.help_outline : Icons.lock_outline,
                  color: Colors.grey.shade600,
                  size: size * 0.4,
                ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (badge.category) {
      case 'streak':
        return Colors.orange;
      case 'mastery':
        return Colors.blue;
      case 'milestone':
        return Colors.purple;
      case 'secret':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// Badge grid showing all badges
class BadgeGrid extends StatelessWidget {
  final List<String> earnedBadgeIds;
  final bool showSecretLocked;
  final Function(BadgeDefinition badge, bool earned)? onBadgeTap;

  const BadgeGrid({
    super.key,
    required this.earnedBadgeIds,
    this.showSecretLocked = true,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    final badges = GamificationService.allBadges.where((b) {
      if (b.isSecret && !earnedBadgeIds.contains(b.id) && !showSecretLocked) {
        return false;
      }
      return true;
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final earned = earnedBadgeIds.contains(badge.id);
        
        return BadgeDisplay(
          badge: badge,
          earned: earned,
          size: 56,
          onTap: () => onBadgeTap?.call(badge, earned),
        );
      },
    );
  }
}

/// XP gain animation popup
class XPGainPopup extends StatefulWidget {
  final int xpGained;
  final VoidCallback? onComplete;

  const XPGainPopup({
    super.key,
    required this.xpGained,
    this.onComplete,
  });

  @override
  State<XPGainPopup> createState() => _XPGainPopupState();
}

class _XPGainPopupState extends State<XPGainPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
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
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A3D), Color(0xFFB347FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A3D).withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.xpGained} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Level up celebration dialog
class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final List<BadgeDefinition> newBadges;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    this.newBadges = const [],
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFF8A3D).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti-like particles
            SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 60),
                    painter: _ConfettiPainter(progress: _confettiController.value),
                  );
                },
              ),
            ),

            // Level up text
            const Text(
              '🎉 LEVEL UP! 🎉',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Level number with pulse animation
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A3D), Color(0xFFB347FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A3D).withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${widget.newLevel}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Level title
            Text(
              _getLevelTitle(widget.newLevel),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),

            // Bonus XP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '+100 Bonus XP!',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // New badges
            if (widget.newBadges.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'New Badges Earned!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: widget.newBadges.map((badge) {
                  return Column(
                    children: [
                      Text(
                        badge.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge.name,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A3D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelTitle(int level) {
    if (level >= 40) return 'Grandmaster';
    if (level >= 30) return 'Master';
    if (level >= 20) return 'Expert';
    if (level >= 15) return 'Skilled';
    if (level >= 10) return 'Apprentice';
    if (level >= 5) return 'Learner';
    return 'Beginner';
  }
}

/// Simple confetti painter
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final math.Random _random = math.Random(42);

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.pink,
      Colors.yellow,
    ];

    for (int i = 0; i < 30; i++) {
      final x = _random.nextDouble() * size.width;
      final startY = -20.0 + (_random.nextDouble() * 20);
      final y = startY + (progress * (size.height + 40));
      
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: (1 - progress).clamp(0.3, 1.0))
        ..style = PaintingStyle.fill;

      final particleSize = 4 + _random.nextDouble() * 4;
      
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Badge unlock notification
class BadgeUnlockNotification extends StatefulWidget {
  final BadgeDefinition badge;
  final VoidCallback? onDismiss;

  const BadgeUnlockNotification({
    super.key,
    required this.badge,
    this.onDismiss,
  });

  @override
  State<BadgeUnlockNotification> createState() => _BadgeUnlockNotificationState();
}

class _BadgeUnlockNotificationState extends State<BadgeUnlockNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getCategoryColor()),
          boxShadow: [
            BoxShadow(
              color: _getCategoryColor().withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCategoryColor().withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  widget.badge.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎖️ Badge Unlocked!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    widget.badge.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.badge.description,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
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

  Color _getCategoryColor() {
    switch (widget.badge.category) {
      case 'streak':
        return Colors.orange;
      case 'mastery':
        return Colors.blue;
      case 'milestone':
        return Colors.purple;
      case 'secret':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// Daily bonus card
class DailyBonusCard extends StatelessWidget {
  final int consecutiveDays;
  final int xpAwarded;
  final bool alreadyClaimed;
  final VoidCallback? onClaim;

  const DailyBonusCard({
    super.key,
    required this.consecutiveDays,
    required this.xpAwarded,
    required this.alreadyClaimed,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: alreadyClaimed
            ? LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade700])
            : const LinearGradient(colors: [Color(0xFFFF8A3D), Color(0xFFB347FF)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            alreadyClaimed ? Icons.check_circle : Icons.card_giftcard,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alreadyClaimed ? 'Daily Bonus Claimed!' : 'Daily Bonus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  alreadyClaimed
                      ? 'Come back tomorrow!'
                      : '+$xpAwarded XP (Day $consecutiveDays streak)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!alreadyClaimed)
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF8A3D),
              ),
              child: const Text('Claim'),
            ),
        ],
      ),
    );
  }
}
