import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/audio.dart';
import '../state/game_controller.dart';
import '../state/settings_store.dart';
import '../toybox/board.dart';
import '../toybox/palette.dart';
import '../toybox/wood_widgets.dart';
import 'settings_screen.dart';

/// Gameplay: HUD score plaques, toy board, wooden control bar, pause + game-over.
class GameScreen extends StatefulWidget {
  final GameController controller;
  final SettingsStore settings;
  const GameScreen({super.key, required this.controller, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _boardKey = GlobalKey<BoardViewState>();

  GameController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    ToyAudio.instance.playMusic('game_music.wav');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = _boardKey.currentState;
      if (b != null) _c.attachBoard(b);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _pause() {
    ToyAudio.instance.sfx('click.wav');
    _c.setPaused(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: ToyPalette.scrim,
      builder: (_) => _PauseDialog(controller: _c, settings: widget.settings),
    ).then((_) {
      if (mounted && !_c.gameOver) _c.setPaused(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      child: null,
      builder: (context, _) {
        final eng = _c.engine;
        final turnName = eng.currentPlayer == 0 ? _c.player0Name : _c.player1Name;
        return Scaffold(
          backgroundColor: ToyPalette.paper,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                // ---- HUD ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      ScorePlaque(
                        name: _c.player0Name,
                        score: eng.scores[0],
                        color: ToyPalette.red,
                        active: eng.currentPlayer == 0 && !_c.gameOver,
                      ),
                      const Spacer(),
                      WoodIconButton(
                        icon: Icons.pause,
                        size: 44,
                        onTap: _c.gameOver ? null : _pause,
                      ),
                      const Spacer(),
                      ScorePlaque(
                        name: _c.player1Name,
                        score: eng.scores[1],
                        color: ToyPalette.blue,
                        active: eng.currentPlayer == 1 && !_c.gameOver,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: WoodenTag(
                    text: _c.gameOver
                        ? 'Game over'
                        : _c.botThinking
                            ? 'Robot is thinking…'
                            : '$turnName\u2019s turn',
                    color: eng.currentPlayer == 0 ? ToyPalette.red : ToyPalette.blue,
                  ),
                ),
                if (_c.lastHint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_c.lastHint!, style: ToyType.bodySm),
                  ),
                // ---- board ----
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: BoardView(
                        key: _boardKey,
                        engine: eng,
                        activePlayer: eng.currentPlayer,
                        playerColor0: ToyPalette.red,
                        playerColor1: ToyPalette.blue,
                        onEdgeTap: _c.onEdgeTap,
                      ),
                    ),
                  ),
                ),
                // ---- control bar ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlButton(
                        icon: Icons.undo,
                        label: 'Undo',
                        onTap: _c.canUndo ? _c.undo : null,
                      ),
                      _ControlButton(
                        icon: Icons.lightbulb_outline,
                        label: 'Hint',
                        onTap: _c.gameOver ? null : _c.hint,
                      ),
                      _ControlButton(
                        icon: Icons.refresh,
                        label: 'New',
                        onTap: () {
                          ToyAudio.instance.sfx('click.wav');
                          _c.restart();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_c.gameOver) GameOverOverlay(controller: _c),
        ],
      ),
    );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ControlButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WoodIconButton(icon: icon, onTap: onTap),
          const SizedBox(height: 4),
          Text(label, style: ToyType.label),
        ],
      ),
    );
  }
}

/// Pause dialog: resume / restart / settings / quit to menu.
class _PauseDialog extends StatelessWidget {
  final GameController controller;
  final SettingsStore settings;
  const _PauseDialog({required this.controller, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
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
            Text('Paused', style: ToyType.h2),
            const SizedBox(height: 18),
            WoodButton(
              label: 'Resume',
              width: 210,
              height: 54,
              icon: Icons.play_arrow,
              onTap: () => Navigator.of(context).pop(),
              color: ToyPalette.leaf,
              bevel: ToyPalette.leafDeep,
            ),
            const SizedBox(height: 12),
            WoodButton(
              label: 'Restart',
              width: 210,
              height: 54,
              icon: Icons.refresh,
              onTap: () {
                controller.restart();
                Navigator.of(context).pop();
              },
              color: ToyPalette.honey,
              bevel: ToyPalette.honeyDeep,
            ),
            const SizedBox(height: 12),
            WoodButton(
              label: 'Settings',
              width: 210,
              height: 54,
              icon: Icons.settings,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsScreen(settings: settings)),
                );
              },
              color: ToyPalette.blue,
              bevel: ToyPalette.blueDeep,
            ),
            const SizedBox(height: 12),
            WoodButton(
              label: 'Quit to Menu',
              width: 210,
              height: 54,
              icon: Icons.home,
              onTap: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // back to menu
              },
              color: ToyPalette.maple,
              bevel: ToyPalette.oak,
              edgeColor: ToyPalette.walnut,
              textStyle: ToyType.buttonLabelDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Game-over overlay: trophy plaque, gold star, confetti, score discs.
class GameOverOverlay extends StatefulWidget {
  final GameController controller;
  const GameOverOverlay({super.key, required this.controller});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _title() {
    final c = widget.controller;
    if (c.winner == null) return 'It\u2019s a Tie!';
    if (c.mode == GameMode.vsRobot) {
      return c.winner == 0 ? 'You Win!' : 'Robot Wins!';
    }
    return c.winner == 0 ? 'Red Wins!' : 'Blue Wins!';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final eng = c.engine;
    final won = c.winner == 0;
    final tied = c.winner == null;
    return Stack(
      children: [
        Container(color: ToyPalette.scrim),
        AnimatedBuilder(
          animation: _confetti,
          builder: (_, _) => CustomPaint(
            painter: _ConfettiPainter(_confetti.value),
            child: Container(),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Container(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
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
                  // trophy plaque
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                    decoration: BoxDecoration(
                      color: ToyPalette.paper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ToyPalette.walnut, width: 3),
                    ),
                    child: Column(
                      children: [
                        _GoldStar(size: 54, celebrate: won || tied),
                        const SizedBox(height: 6),
                        Text(_title(), style: ToyType.h2, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScorePlaque(
                          name: c.player0Name,
                          score: eng.scores[0],
                          color: ToyPalette.red,
                          active: won),
                      const SizedBox(width: 14),
                      ScorePlaque(
                          name: c.player1Name,
                          score: eng.scores[1],
                          color: ToyPalette.blue,
                          active: c.winner == 1),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tied
                        ? 'Nobody could break the tie.'
                        : 'Final score ${eng.scores[0]} – ${eng.scores[1]}',
                    style: ToyType.bodySm,
                  ),
                  const SizedBox(height: 20),
                  WoodButton(
                    label: 'Play Again',
                    width: 220,
                    height: 56,
                    icon: Icons.replay,
                    onTap: () => c.restart(),
                    color: ToyPalette.leaf,
                    bevel: ToyPalette.leafDeep,
                  ),
                  const SizedBox(height: 12),
                  WoodButton(
                    label: 'Menu',
                    width: 220,
                    height: 56,
                    icon: Icons.home,
                    onTap: () => Navigator.of(context).pop(),
                    color: ToyPalette.maple,
                    bevel: ToyPalette.oak,
                    edgeColor: ToyPalette.walnut,
                    textStyle: ToyType.buttonLabelDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldStar extends StatefulWidget {
  final double size;
  final bool celebrate;
  const _GoldStar({required this.size, required this.celebrate});

  @override
  State<_GoldStar> createState() => _GoldStarState();
}

class _GoldStarState extends State<_GoldStar> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _StarPainter(
          widget.celebrate ? ToyPalette.gold : ToyPalette.honey,
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawCircle(c + const Offset(0, 3), r * 0.9, Paint()..color = const Color(0x403D2614));
    canvas.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.35),
          colors: [Color(0xFFFFF3C4), ToyPalette.gold, Color(0xFFB57A1F)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = ToyPalette.walnutDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Falling paper confetti scraps.
class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final colors = [ToyPalette.red, ToyPalette.blue, ToyPalette.honey, ToyPalette.leaf, ToyPalette.gold];
    for (var i = 0; i < 46; i++) {
      final x = rng.nextDouble() * size.width;
      final speed = 0.25 + rng.nextDouble() * 0.5;
      final y = ((t * speed + rng.nextDouble()) % 1.0) * (size.height + 40) - 20;
      final rot = t * (2 + rng.nextDouble() * 4) + rng.nextDouble() * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 9, height: 6),
        Paint()..color = colors[i % colors.length].withValues(alpha: 0.9),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
