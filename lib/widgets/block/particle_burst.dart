import 'dart:math' as math;

import 'package:flutter/material.dart';

class ParticleBurst extends StatelessWidget {
  const ParticleBurst({super.key, required this.visible, required this.size});

  final bool visible;
  final double size;

  @override
  Widget build(BuildContext context) {
    final particles = List.generate(8, (index) {
      final angle = (index / 8) * 6.283185307179586;
      final radius = size * 0.32;
      final dx = radius * math.cos(angle);
      final dy = radius * math.sin(angle);
      return Positioned(
        left: size / 2 + dx,
        top: size / 2 + dy,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellowAccent.withValues(alpha: 0.8),
            boxShadow: const [BoxShadow(color: Colors.white38, blurRadius: 3)],
          ),
        ),
      );
    });

    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: RepaintBoundary(child: Stack(children: particles)),
      ),
    );
  }
}
