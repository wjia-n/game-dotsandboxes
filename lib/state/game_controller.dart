import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/dots_boxes_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/toybox_themes.dart';

/// Turn phases. The ENGINE (this controller) owns every phase transition —
/// the UI never advances turns on its own timers. Every timed phase has a
/// live [_phaseTimer]; the watchdog recovers any timed phase found without
/// one. Stuck states are impossible by construction.
enum TurnPhase {
  idle,
  awaitingInput, // a human seat must tap a line
  botThinking, // a bot seat is "thinking" (visible pause)
  animatingLine, // a committed line is being drawn visibly
  animatingClaims, // claimed boxes pop in one by one
  gameOver,
}

/// One seat at the table.
class Seat {
  String name;
  bool isBot;
  Seat({required this.name, required this.isBot});
}

/// An edge committed to the engine but still being drawn visibly.
class PendingDraw {
  final Edge edge;
  final int player;
  double progress; // 0..1
  PendingDraw({required this.edge, required this.player, this.progress = 0});
}

/// A box claimed by the engine, waiting its turn to pop visibly.
class PendingClaim {
  final Point<int> box;
  final int player;
  double progress; // 0..1
  bool started;
  PendingClaim({required this.box, required this.player})
      : progress = 0,
        started = false;
}

class GameController extends ChangeNotifier {
  final ToyboxSettings settings;
  final ToyboxAudio audio;

  late DotsBoxesEngine engine = DotsBoxesEngine(dots: 6, players: 2);
  List<Seat> seats = [];
  Difficulty difficulty = Difficulty.medium;

  TurnPhase phase = TurnPhase.idle;
  bool paused = false;
  String narration = '';
  PendingDraw? pendingDraw;
  List<PendingClaim> pendingClaims = [];
  List<int> winnerSeats = []; // valid when phase == gameOver
  bool get isTie => phase == TurnPhase.gameOver && winnerSeats.length > 1;
  int watchdogRecoveries = 0;

  final Random _rng = Random();
  Timer? _phaseTimer; // the ONE live engine timer for the current phase
  Timer? _tickTimer; // 50ms animation ticker during animating phases
  Timer? _watchdog;
  Timer? _saveDebounce;
  DateTime _phaseEnteredAt = DateTime.now();
  MoveResult? _lastResult;
  Edge? _hintEdge;
  DateTime? _hintUntil;
  int invalidTapSeq = 0; // bumped on every illegal tap; board shakes on change

  static const _tick = Duration(milliseconds: 50);
  static const _humanLineMs = 380;
  static const _botLineMs = 780;
  static const _claimStepMs = 420;
  static const _botThinkMs = 950;

  GameController({required this.settings, required this.audio});

  // ------------------------------------------------------------- lifecycle
  void _ensureWatchdog() {
    _watchdog ??= Timer.periodic(const Duration(seconds: 2), (_) => _watch());
  }

  /// The watchdog: any timed phase must have a live engine timer and must
  /// not sit longer than 10s. If violated, the animation is force-completed
  /// and the turn resolves — the game can never freeze mid-turn.
  void _watch() {
    if (phase == TurnPhase.awaitingInput ||
        phase == TurnPhase.idle ||
        phase == TurnPhase.gameOver ||
        paused) {
      return;
    }
    final stuckNoTimer = _phaseTimer == null && _tickTimer == null;
    final stuckTooLong =
        DateTime.now().difference(_phaseEnteredAt) > const Duration(seconds: 10);
    if (stuckNoTimer || stuckTooLong) {
      watchdogRecoveries++;
      _forceCompleteAnimation();
      _advanceTurn();
    }
    // Game-over must always surface, even if _finish was somehow skipped.
    if (engine.isGameOver && phase != TurnPhase.gameOver) {
      _finish();
    }
  }

  // ------------------------------------------------------------- setup
  void newGame({
    required int playerCount,
    required List<int> botSeats,
    required Difficulty difficulty,
    required int dots,
    required List<String> names,
  }) {
    _cancelTimers();
    _ensureWatchdog();
    this.difficulty = difficulty;
    engine = DotsBoxesEngine(dots: dots, players: playerCount);
    seats = [
      for (var i = 0; i < playerCount; i++)
        Seat(
          name: names[i].trim().isEmpty
              ? ToyboxSettings.defaultNames[i]
              : names[i].trim(),
          isBot: botSeats.contains(i),
        ),
    ];
    pendingDraw = null;
    pendingClaims = [];
    winnerSeats = [];
    paused = false;
    phase = TurnPhase.idle;
    audio.gameStart();
    _saveNow(clear: true);
    _beginTurn(first: true);
    notifyListeners();
  }

  void continueSaved(SavedMatch saved) {
    _cancelTimers();
    engine = saved.engine;
    difficulty = saved.difficulty;
    final n = engine.players;
    seats = [
      for (var i = 0; i < n; i++)
        Seat(
          name: (i < saved.names.length && saved.names[i].trim().isNotEmpty)
              ? saved.names[i].trim()
              : ToyboxSettings.defaultNames[i],
          isBot: saved.botSeats.contains(i),
        ),
    ];
    pendingDraw = null;
    pendingClaims = [];
    winnerSeats = [];
    paused = false;
    phase = TurnPhase.idle;
    audio.startGameMusic();
    _beginTurn(first: true, resumed: true);
    notifyListeners();
  }

  String seatName(int i) => seats[i].name;
  bool isBotSeat(int i) => seats[i].isBot;
  int get activeSeat => engine.currentPlayer;
  bool get isHumanTurn =>
      phase == TurnPhase.awaitingInput && !seats[activeSeat].isBot;

  ToyThemeDef get theme => settings.theme;
  Color seatColor(int i) => theme.playerColor(i);
  Color seatDeep(int i) => theme.playerDeep(i);

  // ------------------------------------------------------------- turn flow
  void _enterPhase(TurnPhase p) {
    phase = p;
    _phaseEnteredAt = DateTime.now();
  }

  void _beginTurn({bool first = false, bool resumed = false}) {
    if (engine.isGameOver) {
      _finish();
      return;
    }
    final seat = seats[engine.currentPlayer];
    if (seat.isBot) {
      _scheduleBot();
    } else {
      _enterPhase(TurnPhase.awaitingInput);
      narration = resumed
          ? '${seat.name} to play — welcome back!'
          : first
              ? '${seat.name} goes first — tap a line!'
              : "${seat.name}'s turn — tap a line!";
      _phaseTimer = null;
      notifyListeners();
    }
  }

  /// Bot turn, fully visible: a thinking beat with narration, then a
  /// visibly-animated line draw, then box-by-box claim pops.
  void _scheduleBot() {
    _enterPhase(TurnPhase.botThinking);
    final seat = seats[engine.currentPlayer];
    narration = '${seat.name} is thinking…';
    notifyListeners();
    _phaseTimer?.cancel();
    _phaseTimer = Timer(
      Duration(milliseconds: _botThinkMs + _rng.nextInt(450)),
      () {
        _phaseTimer = null;
        if (paused || phase != TurnPhase.botThinking) return;
        final player = engine.currentPlayer;
        final move = engine.botMove(difficulty, player, _rng);
        if (move == null) {
          // No legal edges but the game isn't over — impossible by the
          // rules; the watchdog would recover, but handle it directly.
          _finish();
          return;
        }
        narration = '${seats[player].name} draws a line…';
        _commitMove(move, player, lineMs: _botLineMs);
      },
    );
  }

  /// Human tap on the board. Illegal taps shake + hint, consume no turn.
  void onEdgeTap(Edge e) {
    if (paused || phase != TurnPhase.awaitingInput) return;
    if (seats[engine.currentPlayer].isBot) return;
    if (!engine.isLegal(e)) {
      audio.invalid();
      _buzz(HapticFeedback.vibrate);
      invalidTapSeq++;
      narration = 'That line is already drawn — try another!';
      notifyListeners();
      return;
    }
    _commitMove(e, engine.currentPlayer, lineMs: _humanLineMs);
  }

  /// Commits [edge] to the engine immediately (state is never half-drawn),
  /// then plays the visible draw + claim animations on engine-owned timers.
  void _commitMove(Edge edge, int player, {required int lineMs}) {
    MoveResult res;
    try {
      res = engine.draw(edge, player);
    } on StateError {
      audio.invalid();
      narration = 'That line is already drawn — try another!';
      notifyListeners();
      return;
    }
    _lastResult = res;
    _hintEdge = null;
    pendingDraw = PendingDraw(edge: edge, player: player);
    audio.stroke();
    if (settings.vibrationOn) HapticFeedback.lightImpact();
    _enterPhase(TurnPhase.animatingLine);
    narration = '${seats[player].name} draws a line…';
    _startTicks(lineMs: lineMs);
    notifyListeners();
  }

  void _startTicks({required int lineMs}) {
    _tickTimer?.cancel();
    var elapsed = 0;
    _tickTimer = Timer.periodic(_tick, (t) {
      if (paused) return;
      elapsed += _tick.inMilliseconds;
      final draw = pendingDraw;
      if (phase == TurnPhase.animatingLine && draw != null) {
        draw.progress = (elapsed / lineMs).clamp(0.0, 1.0);
        if (draw.progress >= 1.0) {
          final claims = _lastResult?.claimed ?? const <Point<int>>[];
          pendingDraw = null;
          if (claims.isEmpty) {
            t.cancel();
            _tickTimer = null;
            _advanceTurn();
          } else {
            _enterPhase(TurnPhase.animatingClaims);
            pendingClaims = [
              for (final b in claims)
                PendingClaim(box: b, player: draw.player),
            ];
            elapsed = 0;
            var claimIdx = 0;
            // stagger: each claim starts when the previous is ~45% done
            _tickTimer?.cancel();
            _tickTimer = Timer.periodic(_tick, (t2) {
              if (paused) return;
              var done = 0;
              for (var i = 0; i < pendingClaims.length; i++) {
                final c = pendingClaims[i];
                if (i <= claimIdx) {
                  if (!c.started) {
                    c.started = true;
                    audio.pop();
                    if (settings.vibrationOn) {
                      HapticFeedback.mediumImpact();
                    }
                  }
                  c.progress =
                      ((elapsed - i * _claimStepMs * 0.55) / _claimStepMs)
                          .clamp(0.0, 1.0);
                  if (c.progress >= 1.0) done++;
                  if (c.progress >= 0.45 && claimIdx < i) claimIdx = i;
                }
              }
              if (claimIdx < pendingClaims.length - 1 &&
                  pendingClaims[claimIdx].progress >= 0.45) {
                claimIdx++;
              }
              elapsed += _tick.inMilliseconds;
              if (done == pendingClaims.length) {
                t2.cancel();
                _tickTimer = null;
                _advanceTurn();
              }
              notifyListeners();
            });
          }
        }
      }
      notifyListeners();
    });
  }

  /// Instantly completes any in-flight animation (watchdog / pause path).
  void _forceCompleteAnimation() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    if (pendingDraw != null) pendingDraw!.progress = 1.0;
    for (final c in pendingClaims) {
      c.started = true;
      c.progress = 1.0;
    }
    pendingDraw = null;
    pendingClaims = [];
  }

  void _advanceTurn() {
    _forceCompleteAnimation();
    final res = _lastResult;
    _lastResult = null;
    if (engine.isGameOver) {
      _finish();
      return;
    }
    final player = engine.currentPlayer;
    final seat = seats[player];
    if (res != null && res.bonusTurn) {
      final n = res.claimed.length;
      narration = n == 1
          ? '${seat.name} claimed a box! Draw again!'
          : '${seat.name} claimed $n boxes! Draw again!';
    }
    _scheduleSave();
    if (seat.isBot) {
      _scheduleBot();
    } else {
      _enterPhase(TurnPhase.awaitingInput);
      if (res == null || !res.bonusTurn) {
        narration = "${seat.name}'s turn — tap a line!";
      }
      notifyListeners();
    }
  }

  void _finish() {
    _cancelTimers();
    _forceCompleteAnimation();
    _enterPhase(TurnPhase.gameOver);
    winnerSeats = engine.winners();
    settings.clearSavedGame();
    final tied = winnerSeats.length > 1;
    final humanWon = winnerSeats.any((s) => !seats[s].isBot);
    if (tied) {
      narration = "It's a tie!";
      audio.tie();
    } else {
      final w = seats[winnerSeats.first];
      narration = '${w.name} wins!';
      audio.win();
    }
    settings.recordResult(humanWon: humanWon, tied: tied);
    notifyListeners();
  }

  // ------------------------------------------------------------- actions
  bool get canUndo =>
      !paused &&
      phase == TurnPhase.awaitingInput &&
      engine.moveCount > 0;

  /// Undo the last move(s) until it is a human seat's turn again.
  void undo() {
    if (!canUndo) return;
    var guard = 0;
    do {
      engine.undo();
      guard++;
    } while (guard <= seats.length &&
        seats[engine.currentPlayer].isBot &&
        engine.moveCount > 0);
    _hintEdge = null;
    audio.undo();
    narration = "${seats[engine.currentPlayer].name}'s turn — tap a line!";
    _scheduleSave();
    notifyListeners();
  }

  Edge? get hintEdge =>
      (_hintEdge != null &&
              _hintUntil != null &&
              DateTime.now().isBefore(_hintUntil!))
          ? _hintEdge
          : null;

  void hint() {
    if (paused || phase != TurnPhase.awaitingInput) return;
    if (seats[engine.currentPlayer].isBot) return;
    final e = engine.hint(engine.currentPlayer, _rng);
    if (e == null) return;
    _hintEdge = e;
    _hintUntil = DateTime.now().add(const Duration(milliseconds: 2200));
    audio.click();
    notifyListeners();
  }

  void setPaused(bool v) {
    if (phase == TurnPhase.gameOver || paused == v) return;
    paused = v;
    if (v) {
      // Freeze the engine mid-phase: cancel timers; the watchdog ignores
      // paused state. On resume we re-arm from a safe point.
      _phaseTimer?.cancel();
      _phaseTimer = null;
      _tickTimer?.cancel();
      _tickTimer = null;
      audio.onAppPaused();
    } else {
      audio.onAppResumed();
      if (phase == TurnPhase.botThinking) {
        _scheduleBot(); // re-arm the bot beat
      } else if (phase == TurnPhase.animatingLine ||
          phase == TurnPhase.animatingClaims) {
        _forceCompleteAnimation();
        _advanceTurn();
      }
    }
    notifyListeners();
  }

  void _buzz(Future<void> Function() fb) {
    if (settings.vibrationOn) fb();
  }

  // ------------------------------------------------------------- persistence
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _saveNow);
  }

  void _saveNow({bool clear = false}) {
    if (clear || phase == TurnPhase.gameOver) {
      settings.clearSavedGame();
      return;
    }
    settings.saveGame(SavedMatch(
      engine: engine,
      names: [for (final s in seats) s.name],
      botSeats: [
        for (var i = 0; i < seats.length; i++)
          if (seats[i].isBot) i
      ],
      difficulty: difficulty,
      themeId: settings.themeId,
      lineStyle: settings.lineStyle,
      paperAccent: settings.paperAccent,
    ));
  }

  void _cancelTimers() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    _saveDebounce?.cancel();
  }

  /// Rename a seat (persisted via settings); refreshes trays + narration.
  void renameSeat(int seat, String name) {
    if (seat < 0 || seat >= seats.length) return;
    seats[seat].name = name;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimers();
    _watchdog?.cancel();
    super.dispose();
  }
}
