import 'dart:math';

import 'package:flutter/material.dart';

class BlockShatterEffect extends StatefulWidget {
  const BlockShatterEffect({
    super.key,
    required this.size,
    required this.color,
    required this.seed,
  });

  final double size;
  final Color color;
  final int seed;

  @override
  State<BlockShatterEffect> createState() => _BlockShatterEffectState();
}

class _BlockShatterEffectState extends State<BlockShatterEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Shard> _shards;

  @override
  void initState() {
    super.initState();
    final random = Random(widget.seed & 0x7fffffff);
    _shards = List.generate(8, (index) {
      final angle = random.nextDouble() * pi * 2;
      final direction = Offset(cos(angle), sin(angle));
      final distance = widget.size * (0.3 + random.nextDouble() * 0.4);
      final shardSize = widget.size * (0.15 + random.nextDouble() * 0.12);
      final rotation = random.nextDouble() * pi;
      return _Shard(
        direction: direction,
        distance: distance,
        size: shardSize.clamp(6, widget.size * 0.35),
        rotation: rotation,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = Curves.easeOutCubic.transform(_controller.value);
          final fade = 1 - Curves.easeIn.transform(_controller.value);
          return Opacity(
            opacity: fade,
            child: Stack(
              clipBehavior: Clip.none,
              children: _shards.map((shard) {
                final offset = shard.direction * (shard.distance * progress);
                final scale = 1 - (progress * 0.35);
                final rotation = shard.rotation + (progress * 0.6);
                return Positioned(
                  left: (widget.size - shard.size) / 2 + offset.dx,
                  top: (widget.size - shard.size) / 2 + offset.dy,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale.clamp(0.6, 1.0),
                      child: Container(
                        width: shard.size,
                        height: shard.size,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(shard.size * 0.3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          );
        },
      ),
    );
  }
}

class _Shard {
  const _Shard({
    required this.direction,
    required this.distance,
    required this.size,
    required this.rotation,
  });

  final Offset direction;
  final double distance;
  final double size;
  final double rotation;
}
