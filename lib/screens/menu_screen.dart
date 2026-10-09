import 'package:flutter/material.dart';

import '../engine/dots_boxes_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../state/game_controller.dart';
import '../theme/toybox_themes.dart';
import '../toybox/widgets.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'themes_screen.dart';

/// Main menu: wooden hanging sign, mode buttons, full match setup
/// (2-4 players, bot seats, difficulty, board size), and navigation.
class MenuScreen extends StatefulWidget {
  final ToyboxAudio audio;
  final ToyboxSettings settings;
  final StoreService store;
  final GameController controller;

  const MenuScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.controller,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late int _players;
  late List<int> _botSeats;
  late int _difficulty;
  late int _dots;

  @override
  void initState() {
    super.initState();
    _players = widget.settings.playerCount;
    _botSeats = List.of(widget.settings.botSeats);
    _difficulty = widget.settings.difficulty;
    _dots = widget.settings.boardDots;
    widget.audio.startMenuMusic();
  }

  ToyThemeDef get _t => widget.settings.theme;

  void _saveSetup() {
    widget.settings.setSetup(
      players: _players,
      seats: _botSeats,
      difficulty: _difficulty,
    );
    widget.settings.setBoardDots(_dots);
  }

  void _start() {
    widget.audio.click();
    _saveSetup();
    widget.controller.newGame(
      playerCount: _players,
      botSeats: _botSeats,
      difficulty: Difficulty.values[_difficulty],
      dots: _dots,
      names: widget.settings.playerNames,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
          controller: widget.controller,
        ),
      ),
    );
  }

  void _continue() {
    final saved = widget.settings.loadSavedGame();
    if (saved == null) return;
    widget.audio.click();
    // restore the saved setup into the menu state
    _players = saved.engine.players;
    _botSeats = List.of(saved.botSeats);
    _difficulty = saved.difficulty.index;
    _dots = saved.engine.dots;
    widget.settings.setSetup(
        players: _players, seats: _botSeats, difficulty: _difficulty);
    widget.settings.setBoardDots(_dots);
    widget.controller.continueSaved(saved);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
          controller: widget.controller,
        ),
      ),
    );
  }

  void _showHelp() {
    widget.audio.click();
    final t = _t;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ToyCard(
          theme: t,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to play', style: toyHeadline(22, t)),
                const SizedBox(height: 10),
                _helpLine(t,
                    'Take turns drawing one line between two neighboring dots.'),
                _helpLine(t,
                    'Finish the 4th side of a square to claim it — then draw again!'),
                _helpLine(t,
                    'One line can complete two squares at once — both are yours.'),
                _helpLine(
                    t, 'When every square is claimed, most squares wins.'),
                _helpLine(t,
                    'On 5×5 and 7×7 dot boards a tie is possible; the 6×6 board always has a winner.'),
                const SizedBox(height: 12),
                Center(
                  child: ToyButton(
                    label: 'Got it!',
                    small: true,
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _helpLine(ToyThemeDef t, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: toyBody(15, t)),
            Expanded(child: Text(s, style: toyBody(15, t))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return Scaffold(
      body: ToyBackdrop(
        theme: t,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  // hanging wooden sign
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.woodDark, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x553D2614),
                          offset: Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/dotsandboxes_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Text('Dots & Boxes', style: toyHeadline(34, t)),
                  Text(
                    'THE WOODEN TOYBOX EDITION',
                    style: toyBody(12, t,
                        color: t.text.withValues(alpha: 0.65)),
                  ),
                  const SizedBox(height: 18),
                  // primary actions
                  ToyButton(
                    label: 'Play vs Robot',
                    icon: Icons.smart_toy,
                    color: const Color(0xFF7CB342),
                    onTap: () {
                      _players = 2;
                      _botSeats = [1];
                      _start();
                    },
                  ),
                  const SizedBox(height: 12),
                  ToyButton(
                    label: 'Pass & Play',
                    icon: Icons.people,
                    color: const Color(0xFF3B9FE2),
                    onTap: () {
                      _botSeats = [];
                      _start();
                    },
                  ),
                  if (s.hasSavedGame) ...[
                    const SizedBox(height: 12),
                    ToyButton(
                      label: 'Continue game',
                      icon: Icons.play_arrow,
                      onTap: _continue,
                    ),
                  ],
                  const SizedBox(height: 20),
                  // match setup
                  ToyCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: SectionLabel(
                                theme: t, text: 'MATCH SETUP')),
                        const SizedBox(height: 12),
                        Text('Players', style: toyBody(14, t)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var n = 2; n <= 4; n++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _Token(
                                  theme: t,
                                  label: '$n',
                                  selected: _players == n,
                                  onTap: () {
                                    widget.audio.click();
                                    setState(() {
                                      _players = n;
                                      _botSeats = _botSeats
                                          .where((s) => s < n)
                                          .toList();
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Who is a robot? (tap seats)',
                            style: toyBody(14, t)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (var i = 0; i < _players; i++)
                              GestureDetector(
                                onTap: () {
                                  widget.audio.click();
                                  setState(() {
                                    if (_botSeats.contains(i)) {
                                      _botSeats.remove(i);
                                    } else if (_botSeats.length <
                                        _players - 1) {
                                      _botSeats.add(i);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _botSeats.contains(i)
                                        ? t.wood
                                        : t.paper,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: t.woodDark, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: t.playerColor(i),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _botSeats.contains(i)
                                            ? '${s.playerNames[i]} 🤖'
                                            : s.playerNames[i],
                                        style: toyBody(
                                            13,
                                            t,
                                            color: _botSeats.contains(i)
                                                ? Colors.white
                                                : null),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Robot skill', style: toyBody(14, t)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var d = 0; d < 3; d++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _Token(
                                  theme: t,
                                  label: [
                                    'Easy',
                                    'Medium',
                                    'Hard${s.isPro ? '' : ' 🔒'}'
                                  ][d],
                                  selected: _difficulty == d,
                                  onTap: () {
                                    widget.audio.click();
                                    if (d == 2 && !s.isPro) {
                                      _goPro();
                                      return;
                                    }
                                    setState(() => _difficulty = d);
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Board size', style: toyBody(14, t)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final n in [5, 6, 7])
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _Token(
                                  theme: t,
                                  label: '$n×$n',
                                  selected: _dots == n,
                                  onTap: () {
                                    widget.audio.click();
                                    setState(() => _dots = n);
                                  },
                                ),
                              ),
                          ],
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${(_dots - 1) * (_dots - 1)} squares to claim',
                              style: toyBody(12, t,
                                  color: t.text.withValues(alpha: 0.6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // secondary nav
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ToyIconButton(
                          icon: Icons.palette,
                          tooltip: 'Themes',
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ThemesScreen(
                                    audio: widget.audio,
                                    settings: s,
                                    store: widget.store)));
                          }),
                      ToyIconButton(
                          icon: Icons.settings,
                          tooltip: 'Settings',
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => SettingsScreen(
                                    audio: widget.audio, settings: s)));
                          }),
                      ToyIconButton(
                          icon: Icons.workspace_premium,
                          tooltip: 'Pro',
                          color: const Color(0xFFE8B93C),
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ProScreen(
                                    audio: widget.audio,
                                    settings: s,
                                    store: widget.store)));
                          }),
                      ToyIconButton(
                          icon: Icons.help_outline,
                          tooltip: 'How to play',
                          onTap: _showHelp),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wins ${s.wins} · Losses ${s.losses} · Ties ${s.ties}',
                    style: toyBody(12, t,
                        color: t.text.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goPro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }
}

/// Round wooden selector token.
class _Token extends StatelessWidget {
  final ToyThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Token({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? theme.wood : theme.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.woodDark, width: selected ? 2.5 : 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: theme.woodDark.withValues(alpha: 0.4),
                      offset: const Offset(0, 3),
                      blurRadius: 0)
                ]
              : null,
        ),
        child: Text(
          label,
          style: toyBody(14, theme,
              color: selected ? Colors.white : null),
        ),
      ),
    );
  }
}
