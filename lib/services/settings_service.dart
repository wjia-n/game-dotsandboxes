import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/dots_boxes_engine.dart';
import '../theme/toybox_themes.dart';

/// Persisted settings + stats for Dots & Boxes. Survives app restarts.
///
/// Stores: audio toggles, player names (4 renameable slots), theme / line
/// style / paper accent choices (incl. custom theme colors), mode setup
/// (2-4 players, which seats are bots, difficulty, board size), Pro unlock
/// state, lifetime stats, and the in-progress game.
class ToyboxSettings extends ChangeNotifier {
  static const _p = 'dbx_';
  static const _kMusic = '${_p}music_on';
  static const _kSfx = '${_p}sfx_on';
  static const _kVolume = '${_p}volume';
  static const _kVib = '${_p}vib_on';
  static const _kDots = '${_p}board_dots';
  static const _kDiff = '${_p}difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kPlayers = '${_p}player_count'; // 2..4
  static const _kBotSeats = '${_p}bot_seats'; // StringList of seat indices
  static const _kNames = '${_p}player_names'; // StringList, 4 entries
  static const _kTheme = '${_p}theme_id';
  static const _kLineStyle = '${_p}line_style';
  static const _kPaper = '${_p}paper_accent';
  static const _kWins = '${_p}wins';
  static const _kLosses = '${_p}losses';
  static const _kTies = '${_p}ties';
  static const _kPlayed = '${_p}games_played';
  static const _kIsPro = '${_p}is_pro';
  static const _kSaved = '${_p}saved_game';
  static const _kCustomPrefix = '${_p}custom_';

  static const defaultNames = ['You', 'Robot', 'Player 3', 'Player 4'];

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  bool vibrationOn = true;
  int boardDots = 6; // 5, 6 or 7 dots per side
  int difficulty = 1; // medium default
  int playerCount = 2;
  List<int> botSeats = [1]; // seat indices that are bots
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int lineStyle = 0;
  int paperAccent = 0;
  int wins = 0, losses = 0, ties = 0, gamesPlayed = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Toybox.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'paper': 0xFFFBF6ED,
    'channel': 0xFFEADCC8,
    'wood': 0xFFE5A93C,
    'woodDark': 0xFF8B5A2B,
    'peg': 0xFF5C3A21,
    'text': 0xFF2F1502,
    'pc0': 0xFFE24A4A,
    'pc1': 0xFF3B9FE2,
    'pc2': 0xFF7CB342,
    'pc3': 0xFFE8A93C,
  };

  /// Builds the user-designed custom theme from stored colors.
  ToyThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    final pcs = [c('pc0'), c('pc1'), c('pc2'), c('pc3')];
    return ToyThemeDef(
      id: 'custom',
      name: 'My Creation',
      paper: c('paper'),
      paperEdge: c('woodDark').withValues(alpha: 0.35),
      channel: c('channel'),
      speck: c('peg').withValues(alpha: 0.1),
      pegLight: Color.lerp(c('peg'), Colors.white, 0.45)!,
      pegMid: Color.lerp(c('peg'), Colors.white, 0.18)!,
      pegDark: c('peg'),
      pegDeep: Color.lerp(c('peg'), Colors.black, 0.35)!,
      wood: c('wood'),
      woodDark: c('woodDark'),
      woodLight: Color.lerp(c('wood'), Colors.white, 0.55)!,
      text: c('text'),
      felt: pegDeepSafe().withValues(alpha: 0.4),
      playerColors: pcs,
      playerDeeps:
          pcs.map((p) => Color.lerp(p, Colors.black, 0.35)!).toList(),
      playerColorNames: const ['One', 'Two', 'Three', 'Four'],
    );
  }

  Color pegDeepSafe() => Color(customColors['peg'] ?? 0xFF5C3A21);

  ToyThemeDef get theme =>
      ToyThemes.byId(themeId, custom: customTheme);

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = (p.getDouble(_kVolume) ?? 0.8).clamp(0.0, 1.0);
    vibrationOn = p.getBool(_kVib) ?? true;
    boardDots = (p.getInt(_kDots) ?? 6).clamp(5, 7);
    difficulty = (p.getInt(_kDiff) ?? 1).clamp(0, 2);
    playerCount = (p.getInt(_kPlayers) ?? 2).clamp(2, 4);
    botSeats = _readSeats(p);
    final names = p.getStringList(_kNames);
    if (names != null && names.length == 4) {
      playerNames = [
        for (int i = 0; i < 4; i++)
          names[i].trim().isEmpty ? defaultNames[i] : names[i].trim()
      ];
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    lineStyle = (p.getInt(_kLineStyle) ?? 0).clamp(0, LineStyles.names.length - 1);
    paperAccent =
        (p.getInt(_kPaper) ?? 0).clamp(0, PaperAccents.names.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    losses = p.getInt(_kLosses) ?? 0;
    ties = p.getInt(_kTies) ?? 0;
    gamesPlayed = p.getInt(_kPlayed) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  List<int> _readSeats(SharedPreferences p) {
    final raw = p.getStringList(_kBotSeats);
    if (raw == null) return [1];
    final out = <int>[];
    for (final s in raw) {
      final i = int.tryParse(s);
      if (i != null && i >= 0 && i < playerCount && !out.contains(i)) {
        out.add(i);
      }
    }
    return out;
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setBool(_kVib, vibrationOn);
    await p.setInt(_kDots, boardDots);
    await p.setInt(_kDiff, difficulty);
    await p.setInt(_kPlayers, playerCount);
    await p.setStringList(
        _kBotSeats, [for (final s in botSeats) s.toString()]);
    await p.setStringList(_kNames, playerNames);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kLineStyle, lineStyle);
    await p.setInt(_kPaper, paperAccent);
    await p.setInt(_kWins, wins);
    await p.setInt(_kLosses, losses);
    await p.setInt(_kTies, ties);
    await p.setInt(_kPlayed, gamesPlayed);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (ToyThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (LineStyles.isPro(lineStyle)) {
      lineStyle = 0;
      changed = true;
    }
    if (PaperAccents.isPro(paperAccent)) {
      paperAccent = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setVibration(bool v) async {
    vibrationOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setBoardDots(int v) async {
    boardDots = v.clamp(5, 7);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int d) async {
    d = d.clamp(0, 2);
    if (!isPro && d > 1) return; // Hard is a Pro feature; UI shows lock.
    difficulty = d;
    notifyListeners();
    await _save();
  }

  /// Full mode setup: [players] 2..4 seats, [seats] = bot seat indices,
  /// [difficulty] 0/1/2. At least one seat must stay human.
  Future<void> setSetup({
    required int players,
    required List<int> seats,
    required int difficulty,
  }) async {
    playerCount = players.clamp(2, 4);
    botSeats = [
      for (final s in seats)
        if (s >= 0 && s < playerCount) s
    ];
    if (botSeats.length >= playerCount) {
      botSeats = botSeats.sublist(0, playerCount - 1);
    }
    var d = difficulty.clamp(0, 2);
    if (!isPro && d > 1) d = 1;
    this.difficulty = d;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 3) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && ToyThemes.isProTheme(id)) return; // UI shows lock.
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setLineStyle(int v) async {
    v = v.clamp(0, LineStyles.names.length - 1);
    if (!isPro && LineStyles.isPro(v)) return;
    lineStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPaperAccent(int v) async {
    v = v.clamp(0, PaperAccents.names.length - 1);
    if (!isPro && PaperAccents.isPro(v)) return;
    paperAccent = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  /// Record a finished game. [humanWon] true if any human seat won.
  Future<void> recordResult({
    required bool humanWon,
    required bool tied,
  }) async {
    gamesPlayed++;
    if (tied) {
      ties++;
    } else if (humanWon) {
      wins++;
    } else {
      losses++;
    }
    notifyListeners();
    await _save();
  }

  Future<void> resetStats() async {
    wins = 0;
    losses = 0;
    ties = 0;
    gamesPlayed = 0;
    notifyListeners();
    await _save();
  }

  // ---- in-progress game ----

  bool get hasSavedGame => _prefs?.getString(_kSaved) != null;

  void saveGame(SavedMatch m) {
    final payload = jsonEncode(m.toJson());
    final p = _prefs;
    if (p == null) return;
    p.setString(_kSaved, payload);
  }

  SavedMatch? loadSavedGame() {
    final raw = _prefs?.getString(_kSaved);
    if (raw == null) return null;
    try {
      return SavedMatch.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void clearSavedGame() {
    _prefs?.remove(_kSaved);
  }
}

/// Serializable in-progress match: engine + seat setup.
class SavedMatch {
  final DotsBoxesEngine engine;
  final List<String> names;
  final List<int> botSeats;
  final Difficulty difficulty;
  final String themeId;
  final int lineStyle;
  final int paperAccent;

  SavedMatch({
    required this.engine,
    required this.names,
    required this.botSeats,
    required this.difficulty,
    required this.themeId,
    required this.lineStyle,
    required this.paperAccent,
  });

  Map<String, dynamic> toJson() => {
        'engine': engine.toJson(),
        'names': names,
        'botSeats': botSeats,
        'diff': difficulty.index,
        'theme': themeId,
        'lineStyle': lineStyle,
        'paper': paperAccent,
      };

  static SavedMatch fromJson(Map<String, dynamic> j) => SavedMatch(
        engine: DotsBoxesEngine.fromJson(
            Map<String, dynamic>.from(j['engine'] as Map)),
        names: [
          for (final n in (j['names'] as List? ?? const [])) n as String
        ],
        botSeats: [
          for (final s in (j['botSeats'] as List? ?? const [])) s as int
        ],
        difficulty:
            Difficulty.values[(j['diff'] as int?) ?? 1],
        themeId: (j['theme'] as String?) ?? 'classic',
        lineStyle: (j['lineStyle'] as int?) ?? 0,
        paperAccent: (j['paper'] as int?) ?? 0,
      );
}
