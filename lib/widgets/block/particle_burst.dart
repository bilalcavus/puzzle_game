import 'dart:math';

import 'package:flutter/material.dart';

class ParticleBurst extends StatelessWidget {
  const ParticleBurst({super.key, required this.visible, required this.size});

  final bool visible;
  final double size;

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final particles = List.generate(12, (index) {
      final angle = (index / 12) * 2 * pi;
      final radius = size * 0.4;
      final dx = radius * cos(angle) + random.nextDouble() * 12 - 6;
      final dy = radius * sin(angle) + random.nextDouble() * 12 - 6;
      return Positioned(
        left: size / 2 + dx,
        top: size / 2 + dy,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellowAccent.withValues(alpha: 0.8),
            boxShadow: const [
              BoxShadow(color: Colors.white54, blurRadius: 6),
            ],
          ),
        ),
      );
    });

    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Stack(children: particles),
      ),
    );
  }
}
