import 'package:flutter/material.dart';

import '../../../core/extension/dynamic_size.dart';

class BlockPuzzleBackground extends StatelessWidget {
  const BlockPuzzleBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 24, 77, 55), Color(0xFF1E1F26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: context.dynamicHeight(0.04) * -0.05,
            left: context.dynamicWidth(0.7),
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/image.png',
                width: context.dynamicWidth(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: context.dynamicHeight(0.01) * -1,
            right: context.dynamicWidth(0.3),
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/images/campfire1.png',
                width: context.dynamicWidth(0.4),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
