import 'dart:math' as math;

import 'package:flutter/material.dart';

class BlockTile extends StatefulWidget {
  const BlockTile({
    super.key,
    required this.size,
    this.color,
    this.pulse = false,
    this.borderRadius = 5,
    this.bounceOnAppear = false,
  });

  final double size;
  final Color? color;
  final bool pulse;
  final double borderRadius;
  final bool bounceOnAppear;

  @override
  State<BlockTile> createState() => _BlockTileState();
}

class _BlockTileState extends State<BlockTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    if (widget.bounceOnAppear && widget.color != null) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final baseColor = color ?? Colors.transparent;
    final woodBase = widget.color ?? const Color(0xFF8B5A2B);
    final light = _tint(woodBase, 0.22);
    final dark = _shade(woodBase, 0.2);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounceScale = widget.bounceOnAppear ? _bounceAnimation.value : 1.0;
        final pulseScale = widget.pulse ? 1.05 : 1.0;
        final totalScale = bounceScale * pulseScale;
        
        return Transform.scale(
          scale: totalScale,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.color == null ? Border.all(color: Colors.white24, width: 1) : null,
          boxShadow: widget.color == null
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: widget.pulse ? 18 : 12,
                    offset: const Offset(0, 8),
                  ),
                ],
          gradient: widget.color == null
              ? null
              : LinearGradient(
                  colors: [
                    light,
                    woodBase,
                    dark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: widget.color == null
            ? null
            : ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: _WoodGrainPainter(
                        highlight: light,
                        shadow: dark,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: widget.size * 0.35,
                        height: widget.size * 0.35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
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

  static Color _tint(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color _shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

class _WoodGrainPainter extends CustomPainter {
  _WoodGrainPainter({required this.highlight, required this.shadow});

  final Color highlight;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = shadow.withValues(alpha: 0.35);

    final secondary = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = highlight.withValues(alpha: 0.25);

    final waveHeight = size.height * 0.18;
    final step = size.height / 4;

    for (var i = 0; i <= 4; i++) {
      final y = i * step;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 6) {
        final dy = (waveHeight * 0.5) * (i.isEven ? 1 : -1);
        final wave = math.sin((x / size.width) * math.pi * 2);
        path.lineTo(x, y + (dy * wave));
      }
      canvas.drawPath(path, i.isEven ? paint : secondary);
    }
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter oldDelegate) {
    return oldDelegate.highlight != highlight || oldDelegate.shadow != shadow;
  }
}
