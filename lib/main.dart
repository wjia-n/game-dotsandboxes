import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';
import 'state/game_controller.dart';
import 'toybox/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = ToyboxSettings();
  await settings.load();
  final audio = ToyboxAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  final store = StoreService();
  final controller = GameController(settings: settings, audio: audio);
  runApp(DotsAndBoxesApp(
    settings: settings,
    audio: audio,
    store: store,
    controller: controller,
  ));
}

class DotsAndBoxesApp extends StatefulWidget {
  final ToyboxSettings settings;
  final ToyboxAudio audio;
  final StoreService store;
  final GameController controller;

  const DotsAndBoxesApp({
    super.key,
    required this.settings,
    required this.audio,
    required this.store,
    required this.controller,
  });

  @override
  State<DotsAndBoxesApp> createState() => _DotsAndBoxesAppState();
}

class _DotsAndBoxesAppState extends State<DotsAndBoxesApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_applyAudio);
  }

  void _applyAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_applyAudio);
    widget.audio.dispose();
    widget.store.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the game controller additionally freezes its engine.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        widget.audio.onAppPaused();
        widget.controller.setPaused(true);
      case AppLifecycleState.resumed:
        widget.audio.onAppResumed();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => ToyThemeScope(
        theme: widget.settings.theme,
        child: MaterialApp(
          title: 'Dots and Boxes',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: widget.settings.theme.paper,
            fontFamily: 'Quicksand',
            colorScheme: ColorScheme.fromSeed(
              seedColor: widget.settings.theme.wood,
            ),
            useMaterial3: true,
          ),
          home: SplashScreen(
            audio: widget.audio,
            settings: widget.settings,
            store: widget.store,
            controller: widget.controller,
          ),
        ),
      ),
    );
  }
}
