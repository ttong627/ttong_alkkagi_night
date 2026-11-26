import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'audio/night_audio.dart';
import 'i18n/l10n.dart';
import 'screens/home_screen.dart';
import 'screens/splash_and_tutorial.dart';
import 'state/game_controller.dart';
import 'theme/night_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NightAudioController.instance.init();
  await L10n.use(await NightLanguage.resolve());
  final controller = GameController();
  await controller.loadFromDisk();
  runApp(SuhoAlkkagiNightApp(controller: controller));
}

class SuhoAlkkagiNightApp extends StatelessWidget {
  const SuhoAlkkagiNightApp({
    super.key,
    required this.controller,
    this.skipSplash = false,
  });

  final GameController controller;
  final bool skipSplash;

  @override
  Widget build(BuildContext context) {
    final startLang = L10n.lang.value;
    return ValueListenableBuilder<String>(
      valueListenable: L10n.lang,
      builder: (context, lang, _) {
        // 언어를 바꾸면 화면 전체를 새로 그린다(첫 화면 연출은 처음 켤 때만).
        final showSplash = !skipSplash && lang == startLang;
        return MaterialApp(
          key: ValueKey(lang),
          onGenerateTitle: (_) => tr('수호알까기 · 탄지무림 심야기습'),
          debugShowCheckedModeBanner: false,
          theme: NightPalette.buildTheme(),
          locale: L10n.localeOf(lang),
          supportedLocales: [for (final (code, _) in kNightLanguages) L10n.localeOf(code)],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: showSplash
              ? SplashScreen(controller: controller)
              : HomeScreen(controller: controller),
        );
      },
    );
  }
}
