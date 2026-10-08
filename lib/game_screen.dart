import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Dots and Boxes - draw edges, steal boxes, hog all the turns.
class DotsAndBoxesScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const DotsAndBoxesScreen({super.key, required this.players, required this.callbacks});

  @override
  State<DotsAndBoxesScreen> createState() => _DotsAndBoxesScreenState();
}

class _Edge {
  final bool horiz;
  final int r, c;
  const _Edge(this.horiz, this.r, this.c);
}

class _DotsAndBoxesScreenState extends State<DotsAndBoxesScreen> {
  static const n = 4; // 4x4 boxes, 5x5 dots
  late List<List<int>> h; // (n+1) x n horizontal edges: owner index or -1
  late List<List<int>> v; // n x (n+1) vertical edges
  late List<List<int>> box; // n x n box owner or -1
  int turn = 0;
  bool over = false;
  bool botBusy = false;

  @override
  void initState() {
    super.initState();
    h = List.generate(n + 1, (_) => List.filled(n, -1));
    v = List.generate(n, (_) => List.filled(n + 1, -1));
    box = List.generate(n, (_) => List.filled(n, -1));
    widget.callbacks.setActivePlayer(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  int _boxEdges(int r, int c) {
    var e = 0;
    if (h[r][c] != -1) e++;
    if (h[r + 1][c] != -1) e++;
    if (v[r][c] != -1) e++;
    if (v[r][c + 1] != -1) e++;
    return e;
  }

  List<List<int>> _boxesFor(_Edge e) {
    // boxes adjacent to an edge, as [r, c] pairs
    if (e.horiz) {
      final out = <List<int>>[];
      if (e.r > 0) out.add([e.r - 1, e.c]);
      if (e.r < n) out.add([e.r, e.c]);
      return out;
    }
    final out = <List<int>>[];
    if (e.c > 0) out.add([e.r, e.c - 1]);
    if (e.c < n) out.add([e.r, e.c]);
    return out;
  }

  bool _edgeDrawn(_Edge e) => e.horiz ? h[e.r][e.c] != -1 : v[e.r][e.c] != -1;

  void _tap(_Edge e) {
    if (over || botBusy || _edgeDrawn(e) || widget.players[turn].isBot) return;
    _play(e);
  }

  void _play(_Edge e) {
    Sfx.tap();
    setState(() {
      if (e.horiz) {
        h[e.r][e.c] = turn;
      } else {
        v[e.r][e.c] = turn;
      }
      var claimed = 0;
      for (final b in _boxesFor(e)) {
        if (box[b[0]][b[1]] == -1 && _boxEdges(b[0], b[1]) == 4) {
          box[b[0]][b[1]] = turn;
          claimed++;
        }
      }
      if (claimed > 0) {
        Sfx.move();
        widget.players[turn].score += claimed;
        widget.callbacks.refreshHud();
      }
      if (box.expand((row) => row).every((o) => o != -1)) {
        _finish();
      } else if (claimed == 0) {
        turn = (turn + 1) % widget.players.length;
        widget.callbacks.setActivePlayer(turn);
      }
      // claimed > 0: same player goes again — the sweetest rule in board games
    });
    if (!over) _maybeBot();
  }

  _Edge? _botPick() {
    final free = <_Edge>[];
    for (var r = 0; r <= n; r++) {
      for (var c = 0; c < n; c++) {
        if (h[r][c] == -1) free.add(_Edge(true, r, c));
      }
    }
    for (var r = 0; r < n; r++) {
      for (var c = 0; c <= n; c++) {
        if (v[r][c] == -1) free.add(_Edge(false, r, c));
      }
    }
    if (free.isEmpty) return null;
    // 1. grab any box that's one edge away
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (box[r][c] == -1 && _boxEdges(r, c) == 3) {
          if (h[r][c] == -1) return _Edge(true, r, c);
          if (h[r + 1][c] == -1) return _Edge(true, r + 1, c);
          if (v[r][c] == -1) return _Edge(false, r, c);
          return _Edge(false, r, c + 1);
        }
      }
    }
    // 2. avoid handing boxes over: skip edges that would make a 3-walled box
    final safe = free.where((e) => _boxesFor(e).every((b) => _boxEdges(b[0], b[1]) != 2)).toList();
    final pool = safe.isNotEmpty ? safe : free;
    pool.shuffle();
    return pool.first;
  }

  void _maybeBot() {
    if (over || !widget.players[turn].isBot) return;
    botBusy = true;
    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted || over) return;
      final move = _botPick();
      botBusy = false;
      if (move == null) return;
      _play(move);
    });
  }

  void _finish() {
    over = true;
    Sfx.win();
    final best = widget.players.reduce((a, b) => a.score >= b.score ? a : b);
    final tied = widget.players.where((p) => p.score == best.score).toList();
    if (tied.length > 1) {
      widget.callbacks.finish(
        headline: 'Dead heat! 🤝',
        subline: '${tied.map((p) => p.name).join(' & ')} tied at ${best.score} boxes!',
      );
    } else {
      widget.callbacks.finish(
        winner: best,
        headline: '${best.name} rules the grid! 🏆',
        subline: '${best.score} boxes claimed. Box boss behavior. 📦',
      );
    }
  }

  int get _left => box.expand((row) => row).where((o) => o == -1).length;

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final me = widget.players[turn];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!over)
            TurnBanner(
              player: me,
              action: me.isBot ? ' is scheming… 🤖' : ', draw an edge! ✏️',
            ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Column(
                  children: [
                    for (var r = 0; r <= n; r++) ...[
                      _dotRow(r, t),
                      if (r < n) _gapRow(r, t),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('$_left boxes up for grabs 📦', style: TextStyle(color: t.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _dotRow(int r, GameTheme t) {
    return SizedBox(
      height: 26,
      child: Row(
        children: [
          for (var c = 0; c <= n; c++) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: t.text),
            ),
            if (c < n)
              Expanded(
                child: GestureDetector(
                  onTap: () => _tap(_Edge(true, r, c)),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 26,
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: h[r][c] == -1 ? 6 : 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: h[r][c] == -1
                            ? t.muted.withValues(alpha: 0.22)
                            : widget.players[h[r][c]].color,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _gapRow(int r, GameTheme t) {
    return Expanded(
      child: Row(
        children: [
          for (var c = 0; c <= n; c++) ...[
            GestureDetector(
              onTap: () => _tap(_Edge(false, r, c)),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 26,
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: v[r][c] == -1 ? 6 : 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: v[r][c] == -1
                        ? t.muted.withValues(alpha: 0.22)
                        : widget.players[v[r][c]].color,
                  ),
                ),
              ),
            ),
            if (c < n) _boxCell(r, c, t),
          ],
        ],
      ),
    );
  }

  Widget _boxCell(int r, int c, GameTheme t) {
    final owner = box[r][c];
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: owner == -1
              ? t.surface.withValues(alpha: 0.45)
              : widget.players[owner].color.withValues(alpha: 0.35),
          border: owner == -1
              ? null
              : Border.all(color: widget.players[owner].color, width: 2.5),
        ),
        child: owner == -1
            ? null
            : Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('b$r$c$owner'),
                  tween: Tween(begin: 0.2, end: 1),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.elasticOut,
                  builder: (_, v, _) => Transform.scale(
                    scale: v,
                    child: Text(widget.players[owner].emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
      ),
    );
  }
}
