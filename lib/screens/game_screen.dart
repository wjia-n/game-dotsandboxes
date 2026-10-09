import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../state/game_controller.dart';
import '../theme/toybox_themes.dart';
import '../toybox/board.dart';
import '../toybox/widgets.dart';

/// Gameplay screen: per-side player trays, narration tag, the board,
/// and the action bar. Game-over and pause overlays included.
class GameScreen extends StatefulWidget {
  final ToyboxAudio audio;
  final ToyboxSettings settings;
  final StoreService store;
  final GameController controller;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.controller,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController get c => widget.controller;
  ToyThemeDef get t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    widget.audio.startMenuMusic();
    super.dispose();
  }

  void _renameSeat(int seat) {
    final s = widget.settings;
    final ctl = TextEditingController(text: c.seats[seat].name);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ToyCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name this player', style: toyHeadline(20, t)),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                autofocus: true,
                maxLength: 16,
                style: toyBody(16, t),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: t.woodDark),
                  ),
                ),
                onSubmitted: (_) => _saveName(s, seat, ctl.text),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToyButton(
                      label: 'Cancel',
                      small: true,
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop();
                      }),
                  const SizedBox(width: 10),
                  ToyButton(
                      label: 'Save',
                      small: true,
                      color: const Color(0xFF7CB342),
                      onTap: () => _saveName(s, seat, ctl.text)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveName(ToyboxSettings s, int seat, String name) {
    widget.audio.click();
    s.setPlayerName(seat, name);
    c.renameSeat(seat, s.playerNames[seat]);
    Navigator.of(context).pop();
  }

  void _confirmNewGame() {
    widget.audio.click();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ToyCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start over?', style: toyHeadline(20, t)),
              const SizedBox(height: 8),
              Text('The current game will be lost.',
                  style: toyBody(15, t)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToyButton(
                      label: 'Keep playing',
                      small: true,
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop();
                      }),
                  const SizedBox(width: 10),
                  ToyButton(
                      label: 'New game',
                      small: true,
                      color: const Color(0xFF7CB342),
                      onTap: () {
                        Navigator.of(context).pop();
                        c.newGame(
                          playerCount: widget.settings.playerCount,
                          botSeats: widget.settings.botSeats,
                          difficulty: c.difficulty,
                          dots: widget.settings.boardDots,
                          names: widget.settings.playerNames,
                        );
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (_, _) {
        final over = c.phase == TurnPhase.gameOver;
        final seatBusy = [
          for (var i = 0; i < c.seats.length; i++)
            (c.phase == TurnPhase.botThinking ||
                    c.phase == TurnPhase.animatingLine ||
                    c.phase == TurnPhase.animatingClaims) &&
                c.activeSeat == i &&
                c.seats[i].isBot,
        ];
        return Scaffold(
          body: ToyBackdrop(
            theme: t,
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // top bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Row(
                          children: [
                            ToyIconButton(
                              icon: Icons.arrow_back,
                              size: 44,
                              tooltip: 'Menu',
                              onTap: () {
                                widget.audio.click();
                                Navigator.of(context).pop();
                              },
                            ),
                            Expanded(
                              child: Center(
                                child: Text('Dots & Boxes',
                                    style: toyHeadline(20, t)),
                              ),
                            ),
                            ToyIconButton(
                              icon: c.paused
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              size: 44,
                              tooltip: c.paused ? 'Resume' : 'Pause',
                              onTap: () {
                                widget.audio.click();
                                c.setPaused(!c.paused);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // per-side trays
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: TrayStrip(
                          theme: t,
                          names: [for (final s in c.seats) s.name],
                          isBot: [for (final s in c.seats) s.isBot],
                          scores: c.engine.scores,
                          activeSeat: over ? -1 : c.activeSeat,
                          seatBusy: seatBusy,
                          onEditName: _renameSeat,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // narration tag
                      Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: t.wood,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: t.woodDark, width: 1.5),
                        ),
                        child: Text(
                          c.paused ? 'Paused' : c.narration,
                          style: toyBody(14, t, color: Colors.white),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // board
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: BoardView(controller: c),
                          ),
                        ),
                      ),
                      // action bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            ToyIconButton(
                              icon: Icons.undo,
                              tooltip: 'Undo',
                              onTap: c.canUndo
                                  ? () => c.undo()
                                  : null,
                            ),
                            ToyIconButton(
                              icon: Icons.lightbulb_outline,
                              tooltip: 'Hint',
                              onTap: (c.phase ==
                                          TurnPhase.awaitingInput &&
                                      !c.paused &&
                                      !c.seats[c.activeSeat].isBot)
                                  ? () => c.hint()
                                  : null,
                            ),
                            ToyIconButton(
                              icon: Icons.refresh,
                              tooltip: 'New game',
                              onTap: _confirmNewGame,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (c.paused && !over) _pauseOverlay(),
                  if (over) _gameOverOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pauseOverlay() {
    return Container(
      color: t.felt,
      child: Center(
        child: ToyCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: toyHeadline(26, t)),
              const SizedBox(height: 14),
              ToyButton(
                label: 'Resume',
                icon: Icons.play_arrow,
                color: const Color(0xFF7CB342),
                onTap: () {
                  widget.audio.click();
                  c.setPaused(false);
                },
              ),
              const SizedBox(height: 10),
              ToyButton(
                label: 'Quit to menu',
                small: true,
                onTap: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameOverOverlay() {
    final tied = c.isTie;
    final winnerName =
        tied ? null : c.seats[c.winnerSeats.first].name;
    final scores = c.engine.scores;
    final ranked = [
      for (var i = 0; i < c.seats.length; i++) i
    ]..sort((a, b) => scores[b].compareTo(scores[a]));
    return Container(
      color: t.felt,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ToyCard(
            theme: t,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('★', style: toyHeadline(44, t)),
                Text(
                  tied ? "It's a Tie!" : '$winnerName Wins!',
                  style: toyHeadline(28, t),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.engine.totalBoxes} squares claimed',
                  style: toyBody(13, t,
                      color: t.text.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 14),
                for (final i in ranked)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.playerColor(i),
                            border: Border.all(
                                color: t.pegDeep, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(c.seats[i].name, style: toyBody(16, t)),
                        const SizedBox(width: 8),
                        Text('${scores[i]}',
                            style: toyHeadline(20, t)),
                        if (c.winnerSeats.contains(i))
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text('👑',
                                style: TextStyle(fontSize: 18)),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                ToyButton(
                  label: 'Play Again',
                  icon: Icons.replay,
                  color: const Color(0xFF7CB342),
                  onTap: () {
                    widget.audio.click();
                    c.newGame(
                      playerCount: widget.settings.playerCount,
                      botSeats: widget.settings.botSeats,
                      difficulty: c.difficulty,
                      dots: widget.settings.boardDots,
                      names: widget.settings.playerNames,
                    );
                  },
                ),
                const SizedBox(height: 10),
                ToyButton(
                  label: 'Menu',
                  small: true,
                  onTap: () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
