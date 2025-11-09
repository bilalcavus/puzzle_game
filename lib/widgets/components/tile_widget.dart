import 'package:flutter/material.dart';

class TileWidget extends StatelessWidget {
  const TileWidget({
    super.key,
    required this.text,
    required this.size,
    this.highlight = false,
  });

  final String text;
  final double size;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: highlight ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: highlight ? Colors.white : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
