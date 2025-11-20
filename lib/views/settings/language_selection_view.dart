import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_game/views/splash/splash_view.dart';

class LanguageSelectionView extends StatelessWidget {
  const LanguageSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final locales = context.supportedLocales;
    final current = context.locale;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('common.language')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              tr('common.language_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: locales.length,
        itemBuilder: (context, index) {
          final locale = locales[index];
          final isSelected = locale == current;
          final title = tr('common.language_names.${locale.languageCode}');
          final subtitle = locale.countryCode != null
              ? '${locale.languageCode.toUpperCase()}-${locale.countryCode}'
              : locale.languageCode.toUpperCase();
          return ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: isSelected ? const Icon(Icons.check_rounded) : null,
            onTap: () => _handleSelection(context, locale, isSelected),
          );
        },
      ),
    );
  }

  Future<void> _handleSelection(
    BuildContext context,
    Locale locale,
    bool isSelected,
  ) async {
    if (isSelected) {
      Navigator.of(context).pop();
      return;
    }
    await context.setLocale(locale);
    final navigator = Navigator.of(context, rootNavigator: true);
    if (!navigator.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashView()),
      (_) => false,
    );
  }
}
