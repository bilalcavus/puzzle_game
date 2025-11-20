import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
        Locale('ja'),
        Locale('ko'),
        Locale('zh'),
        Locale('id'),
        Locale('ms'),
        Locale('th'),
        Locale('es'),
        Locale('pt'),
        Locale('vi'),
        Locale('ar'),
        Locale('ru'),
        Locale('hi'),
        Locale('fr'),
        Locale('sv'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: PuzzleApp()),
    ),
  );
}
