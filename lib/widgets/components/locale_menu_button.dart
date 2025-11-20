import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/views/settings/language_selection_view.dart';

/// Displays a badge that opens the full language selection screen.
class LocaleMenuButton extends StatelessWidget {
  const LocaleMenuButton({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.padding,
  });

  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode.toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        backgroundColor ?? colorScheme.surfaceVariant.withOpacity(0.7);
    final fgColor = textColor ?? colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: context.border.highBorderRadius,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LanguageSelectionView()),
        );
      },
      child: Tooltip(
        message: tr('common.language_hint'),
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: context.border.highBorderRadius,
            border: Border.all(color: fgColor.withOpacity(0.25)),
          ),
          child: Text(
            localeCode,
            style:
                Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                  letterSpacing: 0.8,
                ) ??
                TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                  letterSpacing: 0.8,
                ),
          ),
        ),
      ),
    );
  }
}
