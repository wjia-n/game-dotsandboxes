import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'engine/audio.dart';
import 'screens/menu_screen.dart';
import 'state/settings_store.dart';
import 'toybox/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await ToyAudio.instance.init();
  final settings = SettingsStore();
  await settings.load();
  runApp(DotsAndBoxesApp(settings: settings));
}

class DotsAndBoxesApp extends StatefulWidget {
  final SettingsStore settings;
  const DotsAndBoxesApp({super.key, required this.settings});

  @override
  State<DotsAndBoxesApp> createState() => _DotsAndBoxesAppState();
}

class _DotsAndBoxesAppState extends State<DotsAndBoxesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ToyAudio.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle: duck the music, never leak audio.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        ToyAudio.instance.pauseMusic();
      case AppLifecycleState.resumed:
        ToyAudio.instance.resumeMusic();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dots and Boxes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: ToyPalette.paper,
        fontFamily: 'Quicksand',
        colorScheme: ColorScheme.fromSeed(
          seedColor: ToyPalette.honey,
          surface: ToyPalette.paper,
        ),
        textTheme: TextTheme(
          displayLarge: ToyType.h1,
          displayMedium: ToyType.h2,
          headlineMedium: ToyType.h3,
          bodyLarge: ToyType.bodyLg,
          bodyMedium: ToyType.bodyMd,
          bodySmall: ToyType.bodySm,
          labelLarge: ToyType.label,
        ),
        useMaterial3: true,
      ),
      home: MenuScreen(settings: widget.settings),
    );
  }
}
