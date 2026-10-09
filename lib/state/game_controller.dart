import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/audio.dart';
import '../engine/dots_boxes_engine.dart';
import '../toybox/board.dart';
import 'settings_store.dart';

/// Session state for one Dots & Boxes match. Pure ChangeNotifier wiring the
/// engine, robot opponent, audio cues, haptics and persistence together.
class GameController extends ChangeNotifier {
  final SettingsStore settings;

  late DotsBoxesEngine engine;
  GameMode mode = GameMode.vsRobot;
  Difficulty difficulty = Difficulty.medium;

  bool paused = false;
  bool gameOver = false;
  bool botThinking = false;
  int? winner; // 0 / 1 / null=tie (valid when gameOver)
  String? lastHint;

  final Random _rng = Random();
  int _botToken = 0;
  Timer? _saveDebounce;

  GameController(this.settings);

  String get player0Name => 'You';
  String get player1Name => mode == GameMode.vsRobot ? 'Robot' : 'Player 2';

  bool get isRobotTurn =>
      !gameOver && !paused && mode == GameMode.vsRobot && engine.currentPlayer == 1;

  BoardViewState? _board;
  void attachBoard(BoardViewState b) => _board = b;

  void newGame({GameMode? m, int? dots, Difficulty? d}) {
    _botToken++;
    mode = m ?? mode;
    difficulty = d ?? settings.difficulty;
    engine = DotsBoxesEngine(dots: dots ?? settings.boardDots);
    paused = false;
    gameOver = false;
    botThinking = false;
    winner = null;
    lastHint = null;
    _board?.resetAnims();
    settings.clearSavedGame();
    ToyAudio.instance.sfx('start.wav');
    notifyListeners();
    _maybeBotMove();
  }

  void continueSaved(SavedGame saved) {
    _botToken++;
    mode = saved.mode;
    difficulty = saved.difficulty;
    engine = saved.engine;
    paused = false;
    gameOver = false;
    botThinking = false;
    winner = null;
    lastHint = null;
    _board?.resetAnims();
    notifyListeners();
    _maybeBotMove();
  }

  // ---------- moves ----------

  void onEdgeTap(Edge e) {
    if (gameOver || paused || botThinking) return;
    if (mode == GameMode.vsRobot && engine.currentPlayer == 1) return;
    _draw(e, engine.currentPlayer);
  }

  void _draw(Edge e, int player) {
    MoveResult res;
    try {
      res = engine.draw(e, player);
    } on StateError {
      _board?.notifyInvalid();
      ToyAudio.instance.sfx('invalid.wav');
      _buzz(HapticFeedback.vibrate);
      lastHint = 'That line is already drawn!';
      notifyListeners();
      return;
    }
    lastHint = null;
    _board?.notifyDrawn(e);
    ToyAudio.instance.sfx('crayon.wav');
    if (res.claimed.isNotEmpty) {
      _board?.notifyClaimed(res.claimed);
      ToyAudio.instance.sfx('knock.wav');
      Future.delayed(const Duration(milliseconds: 90),
          () => ToyAudio.instance.sfx('pop.wav'));
      _buzz(HapticFeedback.mediumImpact);
    } else {
      _buzz(HapticFeedback.lightImpact);
    }
    _scheduleSave();
    if (res.gameOver) {
      _finish();
    } else {
      notifyListeners();
      _maybeBotMove();
    }
  }

  void _buzz(Future<void> Function() fb) {
    if (settings.vibrationOn) fb();
  }

  // ---------- robot ----------

  void _maybeBotMove() {
    if (!isRobotTurn) return;
    botThinking = true;
    notifyListeners();
    final token = _botToken;
    Future.delayed(const Duration(milliseconds: 750), () {
      if (token != _botToken || gameOver || paused) {
        botThinking = false;
        return;
      }
      final move = engine.botMove(difficulty, 1, _rng);
      botThinking = false;
      if (move == null) return;
      _draw(move, 1);
    });
  }

  // ---------- undo / hint ----------

  bool get canUndo => !gameOver && !botThinking && engine.moveCount > 0;

  void undo() {
    if (!canUndo) return;
    // In vs-Robot, unwind the robot's reply too so it's the human's turn.
    var guard = 0;
    do {
      engine.undo();
      guard++;
    } while (mode == GameMode.vsRobot &&
        engine.currentPlayer == 1 &&
        engine.moveCount > 0 &&
        guard < 4);
    _board?.resetAnims();
    // Re-prime draw animations for remaining edges so the board stays painted.
    ToyAudio.instance.sfx('undo.wav');
    lastHint = null;
    _scheduleSave();
    notifyListeners();
  }

  void hint() {
    if (gameOver || paused || botThinking) return;
    if (mode == GameMode.vsRobot && engine.currentPlayer == 1) return;
    final e = engine.hint(engine.currentPlayer, _rng);
    if (e == null) return;
    _board?.showHint(e);
    ToyAudio.instance.sfx('click.wav');
  }

  // ---------- pause / lifecycle ----------

  void setPaused(bool v) {
    if (gameOver || paused == v) return;
    paused = v;
    _botToken++; // cancel any in-flight robot move
    botThinking = false;
    if (v) {
      ToyAudio.instance.pauseMusic();
    } else {
      ToyAudio.instance.resumeMusic();
      _maybeBotMove();
    }
    notifyListeners();
  }

  void restart() {
    newGame();
    ToyAudio.instance.playMusic('game_music.wav');
  }

  void _finish() {
    gameOver = true;
    botThinking = false;
    settings.clearSavedGame();
    final a = engine.scores[0];
    final b = engine.scores[1];
    if (a == b) {
      winner = null;
      ToyAudio.instance.sfx('tie.wav');
    } else {
      winner = a > b ? 0 : 1;
      final humanWon = winner == 0;
      ToyAudio.instance.sfx(humanWon || mode == GameMode.twoPlayers ? 'win.wav' : 'lose.wav');
    }
    settings.recordResult(vsRobot: mode == GameMode.vsRobot, winner: winner ?? -1);
    notifyListeners();
  }

  // ---------- persistence ----------

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!gameOver) settings.saveGame(engine, mode);
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}
