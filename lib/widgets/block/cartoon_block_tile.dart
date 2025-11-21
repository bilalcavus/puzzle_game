import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Cartoon tarzında blok tile widget'ı
/// Flame paketi ile gelişmiş animasyonlar ve efektler
class CartoonBlockTile extends StatefulWidget {
  const CartoonBlockTile({
    super.key,
    required this.size,
    this.color,
    this.pulse = false,
    this.borderRadius = 8,
    this.showShine = true,
    this.bounceOnAppear = false,
  });

  final double size;
  final Color? color;
  final bool pulse;
  final double borderRadius;
  final bool showShine;
  final bool bounceOnAppear;

  @override
  State<CartoonBlockTile> createState() => _CartoonBlockTileState();
}

class _CartoonBlockTileState extends State<CartoonBlockTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shineAnimation;

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

    _shineAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

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
    if (widget.color == null) {
      return _buildEmptyCell();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.bounceOnAppear ? _bounceAnimation.value : 1.0;
        final pulseScale = widget.pulse ? 1.05 : 1.0;
        
        return Transform.scale(
          scale: scale * pulseScale,
          child: child,
        );
      },
      child: _buildCartoonBlock(),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
    );
  }

  Widget _buildCartoonBlock() {
    final baseColor = widget.color!;
    final light = _adjustBrightness(baseColor, 0.3);
    final dark = _adjustBrightness(baseColor, -0.2);
    final outline = _adjustBrightness(baseColor, -0.4);

    return Container(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Gölge katmanı (daha belirgin cartoon gölge)
          Positioned(
            left: widget.size * 0.08,
            top: widget.size * 0.08,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
          
          // Ana blok gövdesi
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: outline,
                width: widget.size * 0.05,
              ),
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 1.2,
                colors: [
                  light,
                  baseColor,
                  dark,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: widget.pulse ? 20 : 14,
                  offset: Offset(0, widget.size * 0.08),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: outline.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          // İç highlight (parlak alan)
          Positioned(
            left: widget.size * 0.15,
            top: widget.size * 0.15,
            child: Container(
              width: widget.size * 0.4,
              height: widget.size * 0.3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius * 0.8),
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Alt vurgu (3D efekti için)
          Positioned(
            left: widget.size * 0.1,
            bottom: widget.size * 0.1,
            right: widget.size * 0.1,
            child: Container(
              height: widget.size * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius * 0.5),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    dark.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),

          // Parlama efekti (animasyonlu)
          if (widget.showShine)
            AnimatedBuilder(
              animation: _shineAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _ShinePainter(
                    progress: _shineAnimation.value,
                    borderRadius: widget.borderRadius,
                  ),
                );
              },
            ),

          // Hafif cartoon texture (minimal)
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CartoonTexturePainter(
              baseColor: baseColor,
              borderRadius: widget.borderRadius,
            ),
          ),

          // Üst kenar parlama (son dokunuş)
          Positioned(
            left: widget.size * 0.2,
            top: widget.size * 0.05,
            child: Container(
              width: widget.size * 0.3,
              height: widget.size * 0.08,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _adjustBrightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// Parlama efekti painter
class _ShinePainter extends CustomPainter {
  _ShinePainter({
    required this.progress,
    required this.borderRadius,
  });

  final double progress;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: [
          (progress - 0.2).clamp(0.0, 1.0),
          progress,
          (progress + 0.2).clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.overlay;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Cartoon texture painter (nokta desenleri)
class _CartoonTexturePainter extends CustomPainter {
  _CartoonTexturePainter({
    required this.baseColor,
    required this.borderRadius,
  });

  final Color baseColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Sabit seed ile tutarlı pattern
    
    // Minimal noktalar (ahşap çizgileri baskın)
    for (var i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 0.8 + 0.4;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        random.nextBool() ? paint : darkPaint,
      );
    }

    // Çok hafif highlight noktaları
    for (var i = 0; i < 2; i++) {
      final x = size.width * 0.3 + random.nextDouble() * size.width * 0.4;
      final y = size.height * 0.3 + random.nextDouble() * size.height * 0.3;
      final radius = random.nextDouble() * 1.2 + 0.6;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CartoonTexturePainter oldDelegate) {
    return false; // Statik pattern
  }
}

