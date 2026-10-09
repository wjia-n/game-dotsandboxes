import 'dart:math';

/// Pure, deterministic Dots & Boxes engine.
///
/// Rules source of truth: stitch-batch4/dotsandboxes/RULES.md.
///
/// Board: [dots] x [dots] pegs (5, 6 or 7). Boxes = (dots-1)^2 exactly.
/// Edges record the drawing player (0..players-1). Boxes record the claiming
/// player. Supports 2-4 players (pass-and-play / mixed human+bot seats).
///
/// Turn rules (RULES.md §3, §6): drawing the 4th side of a box claims it and
/// grants ONE bonus turn (even when two boxes are claimed at once). The turn
/// otherwise advances to the next seat in order.
class Edge {
  final bool horizontal;
  final int r;
  final int c;
  const Edge(this.horizontal, this.r, this.c);

  @override
  bool operator ==(Object other) =>
      other is Edge &&
      horizontal == other.horizontal &&
      r == other.r &&
      c == other.c;
  @override
  int get hashCode => Object.hash(horizontal, r, c);
  @override
  String toString() => 'Edge(${horizontal ? 'h' : 'v'},$r,$c)';
}

class MoveResult {
  final List<Point<int>> claimed; // [r, c] of captured boxes
  final bool bonusTurn;
  final bool gameOver;
  const MoveResult(
      {required this.claimed, required this.bonusTurn, required this.gameOver});
}

class _MoveRecord {
  final Edge edge;
  final int player;
  final List<Point<int>> claimed;
  _MoveRecord(this.edge, this.player, this.claimed);

  Map<String, dynamic> toJson() => {
        'h': edge.horizontal,
        'r': edge.r,
        'c': edge.c,
        'p': player,
        'b': claimed.map((p) => [p.x, p.y]).toList(),
      };
  static _MoveRecord fromJson(Map<String, dynamic> j) => _MoveRecord(
        Edge(j['h'] as bool, j['r'] as int, j['c'] as int),
        j['p'] as int,
        (j['b'] as List)
            .map((e) => Point<int>(e[0] as int, e[1] as int))
            .toList(),
      );
}

enum Difficulty { easy, medium, hard }

class DotsBoxesEngine {
  final int dots;
  final int players;
  late List<List<int>> h; // dots x (dots-1): horizontal edge owner or -1
  late List<List<int>> v; // (dots-1) x dots: vertical edge owner or -1
  late List<List<int>> box; // (dots-1) x (dots-1): box owner or -1
  int currentPlayer = 0;
  late List<int> scores;
  final List<_MoveRecord> _history = [];

  DotsBoxesEngine({this.dots = 6, this.players = 2}) {
    assert(dots >= 2);
    assert(players >= 2 && players <= 4);
    reset();
  }

  void reset() {
    h = List.generate(dots, (_) => List.filled(dots - 1, -1));
    v = List.generate(dots - 1, (_) => List.filled(dots, -1));
    box = List.generate(dots - 1, (_) => List.filled(dots - 1, -1));
    currentPlayer = 0;
    scores = List.filled(players, 0);
    _history.clear();
  }

  int get boxesPerSide => dots - 1;

  /// Exact box count for a dots×dots peg grid. RULES.md §8: (dots-1)².
  int get totalBoxes => (dots - 1) * (dots - 1);

  int get boxesLeft =>
      box.expand((row) => row).where((o) => o == -1).length;

  bool get isGameOver => boxesLeft == 0;
  int get moveCount => _history.length;

  /// Total edges on the board: dots*(dots-1) horizontal + (dots-1)*dots vertical.
  int get totalEdges => 2 * dots * (dots - 1);

  bool isLegal(Edge e) {
    if (e.horizontal) {
      if (e.r < 0 || e.r >= dots || e.c < 0 || e.c >= dots - 1) return false;
      return h[e.r][e.c] == -1;
    }
    if (e.r < 0 || e.r >= dots - 1 || e.c < 0 || e.c >= dots) return false;
    return v[e.r][e.c] == -1;
  }

  List<Point<int>> _boxesFor(Edge e) {
    final out = <Point<int>>[];
    if (e.horizontal) {
      if (e.r > 0) out.add(Point(e.r - 1, e.c));
      if (e.r < boxesPerSide) out.add(Point(e.r, e.c));
    } else {
      if (e.c > 0) out.add(Point(e.r, e.c - 1));
      if (e.c < boxesPerSide) out.add(Point(e.r, e.c));
    }
    return out;
  }

  int boxEdgeCount(int r, int c) {
    var n = 0;
    if (h[r][c] != -1) n++;
    if (h[r + 1][c] != -1) n++;
    if (v[r][c] != -1) n++;
    if (v[r][c + 1] != -1) n++;
    return n;
  }

  /// Draws [edge] for [player]. Throws [StateError] on illegal moves.
  ///
  /// Box claims: every box whose 4th side was just drawn is claimed by
  /// [player] (0, 1 or 2 boxes). A claim grants exactly one bonus turn;
  /// otherwise the turn advances to the next seat.
  MoveResult draw(Edge edge, int player) {
    if (!isLegal(edge)) throw StateError('Illegal edge: $edge');
    if (isGameOver) throw StateError('Game is over');
    if (player < 0 || player >= players) {
      throw StateError('Bad player: $player');
    }
    if (edge.horizontal) {
      h[edge.r][edge.c] = player;
    } else {
      v[edge.r][edge.c] = player;
    }
    final claimed = <Point<int>>[];
    for (final b in _boxesFor(edge)) {
      if (box[b.x][b.y] == -1 && boxEdgeCount(b.x, b.y) == 4) {
        box[b.x][b.y] = player;
        claimed.add(b);
      }
    }
    scores[player] += claimed.length;
    _history.add(_MoveRecord(edge, player, claimed));
    final over = isGameOver;
    final bonus = claimed.isNotEmpty && !over;
    if (!bonus && !over) {
      currentPlayer = (player + 1) % players;
    } else {
      currentPlayer = player;
    }
    return MoveResult(claimed: claimed, bonusTurn: bonus, gameOver: over);
  }

  /// Undo the most recent edge (un-claims boxes it completed, restores the
  /// turn to the player who drew it). Returns false if nothing to undo.
  bool undo() {
    if (_history.isEmpty) return false;
    final rec = _history.removeLast();
    if (rec.edge.horizontal) {
      h[rec.edge.r][rec.edge.c] = -1;
    } else {
      v[rec.edge.r][rec.edge.c] = -1;
    }
    for (final b in rec.claimed) {
      box[b.x][b.y] = -1;
      scores[rec.player]--;
    }
    currentPlayer = rec.player;
    return true;
  }

  /// Seats tied for the highest box count (1 winner, or 2+ on a tie).
  /// RULES.md §10: a tie needs the top score shared; possible on any grid
  /// with 3+ players, or on even box counts with 2 players.
  List<int> winners() {
    final top = scores.reduce(max);
    final out = <int>[];
    for (var i = 0; i < players; i++) {
      if (scores[i] == top) out.add(i);
    }
    return out;
  }

  List<Edge> legalEdges() {
    final out = <Edge>[];
    for (var r = 0; r < dots; r++) {
      for (var c = 0; c < dots - 1; c++) {
        if (h[r][c] == -1) out.add(Edge(true, r, c));
      }
    }
    for (var r = 0; r < dots - 1; r++) {
      for (var c = 0; c < dots; c++) {
        if (v[r][c] == -1) out.add(Edge(false, r, c));
      }
    }
    return out;
  }

  // ---------------- AI ----------------

  /// Simulates drawing [edge] for [player] on scratch state; returns boxes claimed.
  int _simClaimCount(Edge e, int player, List<List<int>> hh, List<List<int>> vv,
      List<List<int>> bb) {
    if (e.horizontal) {
      hh[e.r][e.c] = player;
    } else {
      vv[e.r][e.c] = player;
    }
    var n = 0;
    for (final b in _boxesFor(e)) {
      if (bb[b.x][b.y] == -1) {
        var cnt = 0;
        if (hh[b.x][b.y] != -1) cnt++;
        if (hh[b.x + 1][b.y] != -1) cnt++;
        if (vv[b.x][b.y] != -1) cnt++;
        if (vv[b.x][b.y + 1] != -1) cnt++;
        if (cnt == 4) {
          bb[b.x][b.y] = player;
          n++;
        }
      }
    }
    return n;
  }

  List<List<int>> _copy(List<List<int>> m) =>
      m.map((r) => List<int>.from(r)).toList();

  /// Greedy claim chain for [player] on scratch state: keep taking the move
  /// that claims the most boxes until none claims. Returns total claimed.
  int _greedyChain(int player, List<List<int>> hh, List<List<int>> vv,
      List<List<int>> bb, Random rng) {
    var total = 0;
    while (true) {
      Edge? best;
      var bestN = 0;
      for (var r = 0; r < dots; r++) {
        for (var c = 0; c < dots - 1; c++) {
          if (hh[r][c] != -1) continue;
          final e = Edge(true, r, c);
          final n = _simClaimCount(e, player, _copy(hh), _copy(vv), _copy(bb));
          if (n > bestN) {
            bestN = n;
            best = e;
          }
        }
      }
      for (var r = 0; r < dots - 1; r++) {
        for (var c = 0; c < dots; c++) {
          if (vv[r][c] != -1) continue;
          final e = Edge(false, r, c);
          final n = _simClaimCount(e, player, _copy(hh), _copy(vv), _copy(bb));
          if (n > bestN) {
            bestN = n;
            best = e;
          }
        }
      }
      if (best == null) break;
      total += _simClaimCount(best, player, hh, vv, bb);
    }
    return total;
  }

  /// The next seat's best immediate greedy reply value after we play [edge]:
  /// the max boxes the next player could claim on their next move.
  int _nextReplyValue(Edge e, int me) {
    final hh = _copy(h);
    final vv = _copy(v);
    final bb = _copy(box);
    _simClaimCount(e, me, hh, vv, bb);
    final opp = (me + 1) % players;
    var best = 0;
    for (var r = 0; r < dots; r++) {
      for (var c = 0; c < dots - 1; c++) {
        if (hh[r][c] != -1) continue;
        best = max(
            best,
            _simClaimCount(
                Edge(true, r, c), opp, _copy(hh), _copy(vv), _copy(bb)));
      }
    }
    for (var r = 0; r < dots - 1; r++) {
      for (var c = 0; c < dots; c++) {
        if (vv[r][c] != -1) continue;
        best = max(
            best,
            _simClaimCount(
                Edge(false, r, c), opp, _copy(hh), _copy(vv), _copy(bb)));
      }
    }
    return best;
  }

  /// Number of boxes that are exactly 3-sided (free for the taking).
  int _freeBoxCount() {
    var n = 0;
    for (var r = 0; r < boxesPerSide; r++) {
      for (var c = 0; c < boxesPerSide; c++) {
        if (box[r][c] == -1 && boxEdgeCount(r, c) == 3) n++;
      }
    }
    return n;
  }

  Edge? botMove(Difficulty diff, int player, Random rng) {
    final free = legalEdges();
    if (free.isEmpty) return null;
    switch (diff) {
      case Difficulty.easy:
        return free[rng.nextInt(free.length)];
      case Difficulty.medium:
        return _mediumMove(free, player, rng);
      case Difficulty.hard:
        return _hardMove(free, player, rng);
    }
  }

  /// Medium: take free boxes; else play a safe edge (never hands a 3-sided
  /// box when one exists); else sacrifice the fewest boxes.
  Edge _mediumMove(List<Edge> free, int player, Random rng) {
    if (_freeBoxCount() > 0) {
      Edge? best;
      var bestN = 0;
      for (final e in free) {
        final n = _simClaimCount(e, player, _copy(h), _copy(v), _copy(box));
        if (n > bestN) {
          bestN = n;
          best = e;
        }
      }
      if (best != null) return best;
    }
    // Safe edges: drawing them creates no 3-sided box for the next player.
    final safe = free.where((e) {
      final hh = _copy(h), vv = _copy(v), bb = _copy(box);
      _simClaimCount(e, player, hh, vv, bb);
      for (final b in _boxesFor(e)) {
        if (bb[b.x][b.y] == -1) {
          var cnt = 0;
          if (hh[b.x][b.y] != -1) cnt++;
          if (hh[b.x + 1][b.y] != -1) cnt++;
          if (vv[b.x][b.y] != -1) cnt++;
          if (vv[b.x][b.y + 1] != -1) cnt++;
          if (cnt == 3) return false;
        }
      }
      return true;
    }).toList();
    if (safe.isNotEmpty) return safe[rng.nextInt(safe.length)];
    // Forced sacrifice: give away the fewest boxes.
    var best = free.first;
    var bestCost = 1 << 30;
    for (final e in free) {
      final cost = _nextReplyValue(e, player);
      if (cost < bestCost) {
        bestCost = cost;
        best = e;
      }
    }
    return best;
  }

  /// Hard: Medium's instincts plus lookahead — score every candidate by
  /// (own greedy chain) minus (next player's greedy reply chain), take max.
  Edge _hardMove(List<Edge> free, int player, Random rng) {
    var best = free.first;
    var bestNet = -(1 << 30);
    final order = List<Edge>.from(free)..shuffle(rng);
    for (final e in order) {
      final hh = _copy(h), vv = _copy(v), bb = _copy(box);
      var mine = _simClaimCount(e, player, hh, vv, bb);
      mine += _greedyChain(player, hh, vv, bb, rng);
      final opp = (player + 1) % players;
      final theirs = _greedyChain(opp, hh, vv, bb, rng);
      final net = mine - theirs;
      if (net > bestNet) {
        bestNet = net;
        best = e;
      }
    }
    return best;
  }

  /// A good suggested edge for the human (uses hard evaluation).
  Edge? hint(int player, Random rng) => botMove(Difficulty.hard, player, rng);

  // ---------------- Persistence ----------------

  Map<String, dynamic> toJson() => {
        'dots': dots,
        'players': players,
        'h': h,
        'v': v,
        'box': box,
        'turn': currentPlayer,
        'scores': scores,
        'hist': _history.map((m) => m.toJson()).toList(),
      };

  static DotsBoxesEngine fromJson(Map<String, dynamic> j) {
    final e = DotsBoxesEngine(
      dots: (j['dots'] as int?) ?? 6,
      players: ((j['players'] as int?) ?? 2).clamp(2, 4),
    );
    List<List<int>> cast(dynamic m) => (m as List)
        .map((r) => (r as List).map((x) => x as int).toList())
        .toList();
    e.h = cast(j['h']);
    e.v = cast(j['v']);
    e.box = cast(j['box']);
    e.currentPlayer = (j['turn'] as int?) ?? 0;
    final sc = (j['scores'] as List?) ?? [0, 0];
    for (var i = 0; i < e.players && i < sc.length; i++) {
      e.scores[i] = sc[i] as int;
    }
    e._history
      ..clear()
      ..addAll((j['hist'] as List? ?? const []).map((m) =>
          _MoveRecord.fromJson(Map<String, dynamic>.from(m as Map))));
    return e;
  }
}
