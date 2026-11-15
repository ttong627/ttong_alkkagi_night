import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/splash_and_tutorial.dart';
import 'state/game_controller.dart';
import 'theme/night_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: '수호알까기 · 탄지무림 심야기습',
      debugShowCheckedModeBanner: false,
      theme: NightPalette.buildTheme(),
      home: skipSplash
          ? HomeScreen(controller: controller)
          : SplashScreen(controller: controller),
    );
  }
}
