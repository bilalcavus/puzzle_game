import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/views/splash/splash_view.dart';

/// Displays a small language badge that opens a locale picker menu.
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
    final supportedLocales = context.supportedLocales;
    final locale = context.locale;
    final localeCode = locale.languageCode.toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        backgroundColor ?? colorScheme.surfaceVariant.withOpacity(0.7);
    final fgColor = textColor ?? colorScheme.onSurfaceVariant;

    Future<void> handleSelection(String code) async {
      final target = supportedLocales.firstWhere(
        (loc) => loc.languageCode == code,
        orElse: () => supportedLocales.first,
      );
      if (target == locale) return;
      await context.setLocale(target);
      final navigator = Navigator.of(context, rootNavigator: true);
      if (!navigator.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashView()),
        (_) => false,
      );
    }

    return PopupMenuButton<String>(
      tooltip: tr('common.language_hint'),
      onSelected: (code) => handleSelection(code),
      itemBuilder: (context) => supportedLocales
          .map(
            (locale) => PopupMenuItem<String>(
              value: locale.languageCode,
              child: Text(tr('common.language_names.${locale.languageCode}')),
            ),
          )
          .toList(),
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }
}
