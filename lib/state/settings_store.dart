import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/audio.dart';
import '../engine/dots_boxes_engine.dart';

enum GameMode { vsRobot, twoPlayers }

/// Persisted settings + lifetime scores + in-progress game.
class SettingsStore extends ChangeNotifier {
  static const _kSfx = 'sfx_on';
  static const _kMusic = 'music_on';
  static const _kSfxVol = 'sfx_vol';
  static const _kMusicVol = 'music_vol';
  static const _kVib = 'vib_on';
  static const _kDots = 'board_dots';
  static const _kDiff = 'difficulty';
  static const _kWins = 'wins';
  static const _kLosses = 'losses';
  static const _kTies = 'ties';
  static const _kPlayed = 'games_played';
  static const _kSaved = 'saved_game';

  bool sfxOn = true;
  bool musicOn = true;
  double sfxVolume = 0.8;
  double musicVolume = 0.6;
  bool vibrationOn = true;
  int boardDots = 6;
  Difficulty difficulty = Difficulty.medium;
  int wins = 0, losses = 0, ties = 0, gamesPlayed = 0;

  SharedPreferences? _prefs;
  bool loaded = false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    sfxOn = p.getBool(_kSfx) ?? true;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxVolume = p.getDouble(_kSfxVol) ?? 0.8;
    musicVolume = p.getDouble(_kMusicVol) ?? 0.6;
    vibrationOn = p.getBool(_kVib) ?? true;
    boardDots = p.getInt(_kDots) ?? 6;
    difficulty = Difficulty.values[p.getInt(_kDiff) ?? 1];
    wins = p.getInt(_kWins) ?? 0;
    losses = p.getInt(_kLosses) ?? 0;
    ties = p.getInt(_kTies) ?? 0;
    gamesPlayed = p.getInt(_kPlayed) ?? 0;
    loaded = true;
    _applyAudio();
    notifyListeners();
  }

  void _applyAudio() {
    final a = ToyAudio.instance;
    a.sfxOn = sfxOn;
    a.musicOn = musicOn;
    a.sfxVolume = sfxVolume;
    a.musicVolume = musicVolume;
    a.applyVolumes();
  }

  void _put(void Function(SharedPreferences) f) {
    final p = _prefs;
    if (p == null) return;
    f(p);
  }

  void setSfx(bool v) {
    sfxOn = v;
    _put((p) => p.setBool(_kSfx, v));
    _applyAudio();
    notifyListeners();
  }

  void setMusic(bool v) {
    musicOn = v;
    _put((p) => p.setBool(_kMusic, v));
    _applyAudio();
    if (v) {
      ToyAudio.instance.resumeMusic();
    } else {
      ToyAudio.instance.pauseMusic();
    }
    notifyListeners();
  }

  void setSfxVolume(double v) {
    sfxVolume = v.clamp(0.0, 1.0);
    _put((p) => p.setDouble(_kSfxVol, sfxVolume));
    _applyAudio();
    notifyListeners();
  }

  void setMusicVolume(double v) {
    musicVolume = v.clamp(0.0, 1.0);
    _put((p) => p.setDouble(_kMusicVol, musicVolume));
    _applyAudio();
    notifyListeners();
  }

  void setVibration(bool v) {
    vibrationOn = v;
    _put((p) => p.setBool(_kVib, v));
    notifyListeners();
  }

  void setBoardDots(int v) {
    boardDots = v.clamp(5, 7);
    _put((p) => p.setInt(_kDots, boardDots));
    notifyListeners();
  }

  void setDifficulty(Difficulty d) {
    difficulty = d;
    _put((p) => p.setInt(_kDiff, d.index));
    notifyListeners();
  }

  void recordResult({required bool vsRobot, required int winner}) {
    // winner: 0 = player one, 1 = player two/robot, -1 = tie
    gamesPlayed++;
    _put((p) => p.setInt(_kPlayed, gamesPlayed));
    if (winner == -1) {
      ties++;
      _put((p) => p.setInt(_kTies, ties));
    } else if (vsRobot) {
      if (winner == 0) {
        wins++;
        _put((p) => p.setInt(_kWins, wins));
      } else {
        losses++;
        _put((p) => p.setInt(_kLosses, losses));
      }
    }
    notifyListeners();
  }

  void resetScores() {
    wins = 0;
    losses = 0;
    ties = 0;
    gamesPlayed = 0;
    _put((p) {
      p.setInt(_kWins, 0);
      p.setInt(_kLosses, 0);
      p.setInt(_kTies, 0);
      p.setInt(_kPlayed, 0);
    });
    notifyListeners();
  }

  // ---- in-progress game ----

  bool get hasSavedGame => _prefs?.getString(_kSaved) != null;

  void saveGame(DotsBoxesEngine engine, GameMode mode) {
    final payload = jsonEncode({
      'mode': mode.index,
      'diff': difficulty.index,
      'engine': engine.toJson(),
    });
    _put((p) => p.setString(_kSaved, payload));
  }

  SavedGame? loadSavedGame() {
    final raw = _prefs?.getString(_kSaved);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return SavedGame(
        mode: GameMode.values[j['mode'] as int],
        difficulty: Difficulty.values[j['diff'] as int],
        engine: DotsBoxesEngine.fromJson(
            Map<String, dynamic>.from(j['engine'] as Map)),
      );
    } catch (_) {
      return null;
    }
  }

  void clearSavedGame() => _put((p) => p.remove(_kSaved));
}

class SavedGame {
  final GameMode mode;
  final Difficulty difficulty;
  final DotsBoxesEngine engine;
  SavedGame({required this.mode, required this.difficulty, required this.engine});
}
