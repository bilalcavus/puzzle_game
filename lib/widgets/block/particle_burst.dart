import 'dart:math';

import 'package:flutter/material.dart';

class ParticleBurst extends StatelessWidget {
  const ParticleBurst({super.key, required this.visible, required this.size});

  final bool visible;
  final double size;

  @override
  Widget build(BuildContext context) {
    // ✅ Daha hafif patlama: daha az parça, daha küçük gölge → FPS düşüşünü azaltır.
    const particleCount = 8;
    final random = Random();
    final particles = List.generate(particleCount, (index) {
      final angle = (index / particleCount) * 2 * pi;
      final radius = size * 0.32;
      final dx = radius * cos(angle) + random.nextDouble() * 8 - 4;
      final dy = radius * sin(angle) + random.nextDouble() * 8 - 4;
      return Positioned(
        left: size / 2 + dx,
        top: size / 2 + dy,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellowAccent.withValues(alpha: 0.85),
            boxShadow: const [BoxShadow(color: Colors.white38, blurRadius: 3, spreadRadius: 0.2)],
          ),
        ),
      );
    });

    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 240),
        child: Stack(children: particles),
      ),
    );
  }
}
