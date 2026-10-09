import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../state/game_controller.dart';
import '../toybox/widgets.dart';
import 'menu_screen.dart';

/// Launch splash: game logo + name, animated loading line, and credits.
/// (Single splash only — no separate company moment.)
class SplashScreen extends StatefulWidget {
  final ToyboxAudio audio;
  final ToyboxSettings settings;
  final StoreService store;
  final GameController controller;

  const SplashScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.controller,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    widget.store.init(); // fire-and-forget; Pro screen reads it later
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    return Scaffold(
      body: ToyBackdrop(
        theme: theme,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.woodDark, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x553D2614),
                      offset: Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/dotsandboxes_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text('Dots & Boxes', style: toyHeadline(40, theme)),
              const SizedBox(height: 6),
              Text(
                'THE WOODEN TOYBOX EDITION',
                style: toyBody(13, theme,
                    color: theme.text.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 30),
              LoadingLine(theme: theme, progress: _loader),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _loader,
                builder: (_, _) => Text(
                  _loader.value < 1 ? 'Sharpening the crayons…' : 'Ready!',
                  style: toyBody(13, theme,
                      color: theme.text.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text('Credits: WAJIHA',
                      style: toyBody(14, theme)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
