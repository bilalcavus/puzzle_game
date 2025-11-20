import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../providers/puzzle_provider.dart';
import '../../../widgets/components/app_button.dart';

class VictoryDialog extends StatelessWidget {
  const VictoryDialog({
    super.key,
    required this.state,
    required this.onRestart,
    required this.onNextLevel,
  });

  final PuzzleState state;
  final VoidCallback onRestart;
  final VoidCallback onNextLevel;

  static Future<void> show(
    BuildContext context,
    PuzzleState state,
    VoidCallback onRestart,
    VoidCallback onNextLevel,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VictoryDialog(
        state: state,
        onRestart: onRestart,
        onNextLevel: onNextLevel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('victory.title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              '${tr('victory.moves', namedArgs: {'value': '${state.moves}'})}\n${tr('victory.time', namedArgs: {'value': state.formattedTime})}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: tr('common.play_again'),
              onPressed: () {
                Navigator.of(context).pop();
                onRestart();
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              label: tr('common.next_level'),
              onPressed: () {
                Navigator.of(context).pop();
                onNextLevel();
              },
            ),
          ],
        ),
      ),
    );
  }
}
