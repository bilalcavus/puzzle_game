import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';

class AdventureModeView extends StatelessWidget {
  const AdventureModeView({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = List.generate(
      12,
      (index) => 'adventure.level_label'.tr(
        context: context,
        namedArgs: {'index': '${index + 1}'},
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(tr('adventure.title'))),
      body: ListView.separated(
        padding: EdgeInsets.all(context.dynamicHeight(0.05)),
        itemBuilder: (context, index) {
          final label = levels[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4B774A), Color(0xFF2C4A2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('adventure.requirement'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text(tr('common.play')),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: levels.length,
      ),
    );
  }
}
