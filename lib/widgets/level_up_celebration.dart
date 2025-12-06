import 'dart:math';

import 'package:flutter/material.dart';

/// Confetti celebration widget for level-up events
/// 
/// Usage:
/// ```dart
/// LevelUpCelebration.show(
///   context,
///   oldLevel: 'novice',
///   newLevel: 'intermediate',
/// );
/// ```

class LevelUpCelebration extends StatefulWidget {
  final String oldLevel;
  final String newLevel;
  final VoidCallback? onComplete;

  const LevelUpCelebration({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    this.onComplete,
  });

  /// Show the level up celebration as an overlay
  static void show(
    BuildContext context, {
    required String oldLevel,
    required String newLevel,
    VoidCallback? onComplete,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return LevelUpCelebration(
          oldLevel: oldLevel,
          newLevel: newLevel,
          onComplete: onComplete,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _textController;
  late Animation<double> _scaleAnimation;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );
    
    // Generate confetti particles
    _generateParticles();
    
    // Start animations
    _confettiController.forward();
    _textController.forward();
    
    // Auto-dismiss after animation
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete?.call();
      }
    });
  }

  void _generateParticles() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
    ];
    
    for (int i = 0; i < 100; i++) {
      _particles.add(ConfettiParticle(
        color: colors[_random.nextInt(colors.length)],
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.3,
        velocityX: (_random.nextDouble() - 0.5) * 0.02,
        velocityY: 0.005 + _random.nextDouble() * 0.01,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        size: 8 + _random.nextDouble() * 8,
      ));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _textController.dispose();
    super.dispose();
  }

  String _getLevelEmoji(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return '🌱';
      case 'novice':
        return '📚';
      case 'intermediate':
        return '⚡';
      case 'advanced':
        return '🚀';
      case 'expert':
        return '👑';
      default:
        return '🐍';
    }
  }

  String _getLevelTitle(String level) {
    return level[0].toUpperCase() + level.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
              );
            },
          ),
          
          // Content layer
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple.shade800,
                      Colors.purple.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stars/sparkles
                    const Text(
                      '✨ 🎉 ✨',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    const Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Level transition
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Old level
                        Column(
                          children: [
                            Text(
                              _getLevelEmoji(widget.oldLevel),
                              style: const TextStyle(fontSize: 36),
                            ),
                            Text(
                              _getLevelTitle(widget.oldLevel),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        
                        // Arrow
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                        
                        // New level
                        Column(
                          children: [
                            Text(
                              _getLevelEmoji(widget.newLevel),
                              style: const TextStyle(fontSize: 48),
                            ),
                            Text(
                              _getLevelTitle(widget.newLevel),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Motivational message
                    Text(
                      _getMotivationalMessage(widget.newLevel),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tap to dismiss hint
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                widget.onComplete?.call();
              },
              child: Text(
                'Tap anywhere to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(String level) {
    switch (level.toLowerCase()) {
      case 'novice':
        return 'You\'re building a solid foundation! Keep practicing!';
      case 'intermediate':
        return 'Great progress! You\'re mastering the fundamentals!';
      case 'advanced':
        return 'Impressive skills! You\'re becoming a Python pro!';
      case 'expert':
        return 'Outstanding! You\'ve achieved Python mastery! 🏆';
      default:
        return 'Keep up the great work!';
    }
  }
}

/// Individual confetti particle
class ConfettiParticle {
  Color color;
  double x;
  double y;
  double velocityX;
  double velocityY;
  double rotation;
  double rotationSpeed;
  double size;

  ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
  });
}

/// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update position based on progress
      final x = (particle.x + particle.velocityX * progress * 100) * size.width;
      final y = (particle.y + particle.velocityY * progress * 100 + 
                 0.5 * 0.001 * progress * progress * 10000) * size.height;
      final rotation = particle.rotation + particle.rotationSpeed * progress * 10;
      
      // Skip if off screen
      if (y > size.height + 50) continue;
      
      // Draw particle
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress * 0.3)
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation * 3.14159 / 180);
      
      // Draw rectangle (confetti shape)
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}
