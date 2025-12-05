import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

/// Morphing blob background using CustomPainter.
class MorphingBlob extends StatefulWidget {
  final Color color;
  final Duration duration;

  const MorphingBlob({
    super.key,
    required this.color,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<MorphingBlob> createState() => _MorphingBlobState();
}

class _MorphingBlobState extends State<MorphingBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: BlobPainter(
            progress: _animation.value,
            color: widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class BlobPainter extends CustomPainter {
  final double progress;
  final Color color;

  BlobPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseRadius = size.width * 0.25;

    // Morphing blob using sine wave for smooth distortion
    final path = Path();
    const int points = 8;
    for (int i = 0; i <= points * 4; i++) {
      final angle = (i / points) * 2 * 3.14159;
      final distortion = 0.3 * (0.5 + 0.5 * sin(angle * 3 + progress * 6.28));
      final radius = baseRadius * (1 + distortion);
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BlobPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Animated gradient that shifts colors smoothly.
class AnimatedGradientBg extends StatefulWidget {
  final List<Color> colors;
  final Duration duration;
  final Widget child;

  const AnimatedGradientBg({
    super.key,
    required this.colors,
    this.duration = const Duration(seconds: 5),
    required this.child,
  });

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.98, end: 1.02).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.colors.length >= 2
                ? [widget.colors[0], widget.colors[widget.colors.length - 1]]
                : [widget.colors[0], widget.colors[0]],
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Rotating orb effect with layers.
class RotatingOrb extends StatefulWidget {
  final Color color;
  final double size;

  const RotatingOrb({
    super.key,
    required this.color,
    this.size = 100,
  });

  @override
  State<RotatingOrb> createState() => _RotatingOrbState();
}

class _RotatingOrbState extends State<RotatingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
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
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              widget.color,
              widget.color.withValues(alpha: 0.5),
              widget.color,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wavy divider using CustomPainter.
class WavyDivider extends StatelessWidget {
  final Color color;
  final double height;
  final double waveAmplitude;
  final double waveFrequency;

  const WavyDivider({
    super.key,
    required this.color,
    this.height = 40,
    this.waveAmplitude = 8,
    this.waveFrequency = 0.02,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WavyPainter(
        color: color,
        amplitude: waveAmplitude,
        frequency: waveFrequency,
      ),
      size: Size(double.infinity, height),
    );
  }
}

class WavyPainter extends CustomPainter {
  final Color color;
  final double amplitude;
  final double frequency;

  WavyPainter({
    required this.color,
    required this.amplitude,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x += 5) {
      final y = size.height * 0.5 +
          amplitude * sin(x * frequency * 3.14159);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(WavyPainter oldDelegate) => false;
}

/// Glassmorphic container with frosted effect and depth.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color tintColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final bool addShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.tintColor = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.addShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: addShadow ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tintColor.withValues(alpha: 0.12),
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.8,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Staggered list item animation.
class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration staggerDuration;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerDuration = const Duration(milliseconds: 100),
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(
      Duration(milliseconds: widget.index * 100),
      () => _controller.forward(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Bounce button animation on tap.
class BounceButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Duration duration;

  const BounceButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
