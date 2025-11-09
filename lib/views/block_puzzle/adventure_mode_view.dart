import 'package:flutter/material.dart';

class AdventureModeView extends StatelessWidget {
  const AdventureModeView({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = List.generate(12, (index) => 'Jungle ${index + 1}');
    return Scaffold(
      appBar: AppBar(title: const Text('Adventure Mode')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
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
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Clear 5 lines to unlock the next jungle.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Play'),
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
