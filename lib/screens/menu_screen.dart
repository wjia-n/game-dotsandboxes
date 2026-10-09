import 'package:flutter/material.dart';

import '../engine/audio.dart';
import '../state/game_controller.dart';
import '../state/settings_store.dart';
import '../toybox/palette.dart';
import '../toybox/wood_widgets.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Main menu: hanging wooden sign, mini-board preview, chunky toy buttons.
class MenuScreen extends StatefulWidget {
  final SettingsStore settings;
  const MenuScreen({super.key, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    ToyAudio.instance.playMusic('menu_music.wav');
  }

  void _start(GameMode mode) {
    ToyAudio.instance.sfx('click.wav');
    final ctrl = GameController(widget.settings)
      ..newGame(m: mode, dots: widget.settings.boardDots);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(controller: ctrl, settings: widget.settings)),
    ).then((_) {
      ToyAudio.instance.playMusic('menu_music.wav');
      setState(() {});
    });
  }

  void _continue() {
    final saved = widget.settings.loadSavedGame();
    if (saved == null) return;
    ToyAudio.instance.sfx('click.wav');
    final ctrl = GameController(widget.settings)..continueSaved(saved);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(controller: ctrl, settings: widget.settings)),
    ).then((_) {
      ToyAudio.instance.playMusic('menu_music.wav');
      setState(() {});
    });
  }

  void _openSettings() {
    ToyAudio.instance.sfx('click.wav');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsScreen(settings: widget.settings)),
    ).then((_) => setState(() {}));
  }

  void _showHelp() {
    ToyAudio.instance.sfx('click.wav');
    showDialog(
      context: context,
      barrierColor: ToyPalette.scrim,
      builder: (_) => const _HelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ToyPalette.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _HangingSign(),
                const SizedBox(height: 18),
                const _MiniBoardPreview(),
                const SizedBox(height: 24),
                if (widget.settings.hasSavedGame) ...[
                  WoodButton(
                    label: 'Continue',
                    icon: Icons.play_arrow,
                    onTap: _continue,
                    color: ToyPalette.honey,
                    bevel: ToyPalette.honeyDeep,
                  ),
                  const SizedBox(height: 14),
                ],
                WoodButton(
                  label: 'Play vs Robot',
                  icon: Icons.smart_toy,
                  onTap: () => _start(GameMode.vsRobot),
                  color: ToyPalette.leaf,
                  bevel: ToyPalette.leafDeep,
                ),
                const SizedBox(height: 14),
                WoodButton(
                  label: 'Two Players',
                  icon: Icons.people,
                  onTap: () => _start(GameMode.twoPlayers),
                  color: ToyPalette.blue,
                  bevel: ToyPalette.blueDeep,
                ),
                const SizedBox(height: 22),
                Text('Board size', style: ToyType.label),
                const SizedBox(height: 8),
                _BoardSizeTokens(settings: widget.settings),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WoodIconButton(icon: Icons.settings, onTap: _openSettings),
                    const SizedBox(width: 18),
                    WoodIconButton(icon: Icons.help_outline, onTap: _showHelp),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.settings.gamesPlayed > 0
                      ? 'Played ${widget.settings.gamesPlayed} · Won ${widget.settings.wins}'
                      : 'Fresh out of the toy box',
                  style: ToyType.bodySm.copyWith(color: ToyPalette.ink.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wooden hanging sign with the game title.
class _HangingSign extends StatelessWidget {
  const _HangingSign();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ropes
        SizedBox(
          height: 26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 3, height: 26, color: ToyPalette.walnut.withValues(alpha: 0.7)),
              const SizedBox(width: 150),
              Container(width: 3, height: 26, color: ToyPalette.walnut.withValues(alpha: 0.7)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          decoration: BoxDecoration(
            color: ToyPalette.maple,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ToyPalette.walnut, width: 4),
            boxShadow: ToyPalette.plaqueShadow(),
          ),
          child: Stack(
            children: [
              const Positioned(left: -14, top: -8, child: Thumbtack(size: 22)),
              const Positioned(right: -14, top: -8, child: Thumbtack(size: 22)),
              Column(
                children: [
                  Text('Dots & Boxes', style: ToyType.h1),
                  const SizedBox(height: 4),
                  Text('the wooden toy box edition',
                      style: ToyType.bodySm.copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Static decorative mini-board: pegs, crayon edges, two washed boxes.
class _MiniBoardPreview extends StatelessWidget {
  const _MiniBoardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        color: ToyPalette.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ToyPalette.oak, width: 2),
        boxShadow: ToyPalette.plaqueShadow(),
      ),
      child: CustomPaint(painter: _MiniBoardPainter()),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dots = 4;
    const pad = 30.0;
    final s = (size.width - pad * 2) / (dots - 1);
    Offset dot(int r, int c) => Offset(pad + c * s, pad + r * s);

    void stroke(int r1, int c1, int r2, int c2, Color col) {
      canvas.drawLine(
        dot(r1, c1),
        dot(r2, c2),
        Paint()
          ..color = col
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }

    // a few red + blue edges
    stroke(0, 0, 0, 1, ToyPalette.red);
    stroke(0, 1, 0, 2, ToyPalette.red);
    stroke(1, 0, 2, 0, ToyPalette.blue);
    stroke(2, 2, 2, 3, ToyPalette.blue);
    stroke(1, 2, 2, 2, ToyPalette.red);
    stroke(1, 1, 1, 2, ToyPalette.red);
    stroke(0, 1, 1, 1, ToyPalette.red); // completes a red box
    stroke(2, 1, 2, 2, ToyPalette.blue);
    stroke(2, 0, 2, 1, ToyPalette.blue);
    stroke(3, 0, 3, 1, ToyPalette.blue);
    stroke(2, 1, 3, 1, ToyPalette.blue); // completes a blue box

    void wash(int r, int c, Color col) {
      final rect = Rect.fromPoints(dot(r, c), dot(r + 1, c + 1)).deflate(5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = col.withValues(alpha: 0.25),
      );
    }

    wash(0, 1, ToyPalette.red);
    wash(2, 0, ToyPalette.blue);

    // pegs
    for (var r = 0; r < dots; r++) {
      for (var c = 0; c < dots; c++) {
        final p = dot(r, c);
        canvas.drawCircle(
          p,
          8,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-0.35, -0.4),
              colors: [Color(0xFFB07B45), ToyPalette.oak, ToyPalette.walnutDeep],
              stops: [0.0, 0.55, 1.0],
            ).createShader(Rect.fromCircle(center: p, radius: 8)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5x5 / 6x6 / 7x7 wooden board-size tokens.
class _BoardSizeTokens extends StatelessWidget {
  final SettingsStore settings;
  const _BoardSizeTokens({required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [5, 6, 7].map((d) {
          final selected = settings.boardDots == d;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {
                ToyAudio.instance.sfx('click.wav');
                settings.setBoardDots(d);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.translationValues(0, selected ? 3.0 : 0.0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? ToyPalette.honey : ToyPalette.maple,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ToyPalette.oak, width: 2),
                  boxShadow: selected ? ToyPalette.pressedShadow() : ToyPalette.plaqueShadow(),
                ),
                child: Text(
                  '${d}x$d',
                  style: ToyType.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : ToyPalette.ink,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: ToyPalette.maple,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ToyPalette.walnut, width: 3),
          boxShadow: ToyPalette.plaqueShadow(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Thumbtack(),
            const SizedBox(height: 10),
            Text('How to play', style: ToyType.h2),
            const SizedBox(height: 12),
            Text(
              'Take turns drawing lines between neighboring wooden pegs.\n\n'
              'Close all four sides of a square and it is yours — painted in your crayon color, plus you get another turn!\n\n'
              'When every square is claimed, the player with the most squares wins.',
              style: ToyType.bodyMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            WoodButton(
              label: 'Got it',
              width: 160,
              height: 52,
              onTap: () => Navigator.of(context).pop(),
              color: ToyPalette.blue,
              bevel: ToyPalette.blueDeep,
            ),
          ],
        ),
      ),
    );
  }
}
