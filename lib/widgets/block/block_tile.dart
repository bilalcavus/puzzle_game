import 'package:flutter/material.dart';

class BlockTile extends StatelessWidget {
  const BlockTile({
    super.key,
    required this.size,
    this.color,
    this.pulse = false,
    this.borderRadius = 10,
  });

  final double size;
  final Color? color;
  final bool pulse;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Colors.transparent;
    return AnimatedScale(
      scale: pulse ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: baseColor == Colors.transparent ? baseColor : baseColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(borderRadius),
          border: color == null ? Border.all(color: Colors.white24, width: 1) : null,
          boxShadow: color == null
              ? null
              : [
                  BoxShadow(
                    color: Colors.brown.withValues(alpha: 0.4),
                    blurRadius: pulse ? 20 : 12,
                    offset: const Offset(0, 6),
                  ),
                ],
          gradient: color == null
              ? null
              : LinearGradient(
                  colors: [
                    baseColor.withValues(alpha: 0.9),
                    baseColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: color == null
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: RadialGradient(
                    colors: [
                    Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
