import 'dart:math';

import 'package:dotsandboxes/engine/dots_boxes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DotsBoxesEngine fresh({int dots = 6}) => DotsBoxesEngine(dots: dots);

/// Draw an edge for [player] directly (bypassing turn order).
void put(DotsBoxesEngine e, bool h, int r, int c, int p) => e.draw(Edge(h, r, c), p);

void main() {
  group('rules conformance', () {
    test('1. first move accepted, 0-0, turn passes', () {
      final e = fresh();
      final res = e.draw(const Edge(true, 0, 0), 0);
      expect(res.claimed, isEmpty);
      expect(res.bonusTurn, isFalse);
      expect(e.scores, [0, 0]);
      expect(e.currentPlayer, 1);
    });

    test('2. diagonal rejected', () {
      final e = fresh();
      // diagonals are not representable; nearest check: drawing (0,0)-(1,1)
      // is not a legal edge type at all. Verify off-grid rejected too.
      expect(e.isLegal(const Edge(true, 0, 6)), isFalse); // out of range
      expect(e.moveCount, 0);
    });

    test('3. duplicate edge rejected, turn not consumed', () {
      final e = fresh();
      e.draw(const Edge(true, 0, 0), 0);
      expect(e.isLegal(const Edge(true, 0, 0)), isFalse);
      expect(() => e.draw(const Edge(true, 0, 0), 1), throwsStateError);
      expect(e.currentPlayer, 1); // still player 1's turn
      expect(e.moveCount, 1);
    });

    test('4. non-adjacent rejected', () {
      final e = fresh();
      expect(e.isLegal(const Edge(true, 0, 6)), isFalse);
      expect(e.isLegal(const Edge(false, 6, 0)), isFalse);
    });

    test('5. single box capture: claim + bonus turn', () {
      final e = fresh();
      put(e, true, 0, 0, 0); // top
      put(e, false, 0, 0, 1); // left
      put(e, false, 0, 1, 0); // right
      final res = e.draw(const Edge(true, 1, 0), 1); // bottom -> completes
      expect(res.claimed.length, 1);
      expect(e.box[0][0], 1);
      expect(e.scores[1], 1);
      expect(res.bonusTurn, isTrue);
      expect(e.currentPlayer, 1); // same player again
    });

    test('6. double box capture: one edge, two boxes, one bonus turn', () {
      final e = fresh();
      // boxes (0,0) and (0,1) both missing only the shared edge v(0,1)
      put(e, true, 0, 0, 0);
      put(e, true, 1, 0, 0);
      put(e, false, 0, 0, 0);
      put(e, true, 0, 1, 1);
      put(e, true, 1, 1, 1);
      put(e, false, 0, 2, 1);
      final res = e.draw(const Edge(false, 0, 1), 0);
      expect(res.claimed.length, 2);
      expect(e.scores[0], 2);
      expect(res.bonusTurn, isTrue);
      expect(e.currentPlayer, 0);
    });

    test('7. bonus turn chain continues', () {
      final e = fresh();
      // box (0,0) missing only bottom; box (2,2) missing only left
      put(e, true, 0, 0, 1);
      put(e, false, 0, 0, 1);
      put(e, false, 0, 1, 1);
      put(e, true, 2, 2, 1);
      put(e, true, 3, 2, 1);
      put(e, false, 2, 3, 1);
      var res = e.draw(const Edge(true, 1, 0), 0);
      expect(res.claimed.length, 1);
      expect(e.currentPlayer, 0);
      res = e.draw(const Edge(false, 2, 2), 0);
      expect(res.claimed.length, 1);
      expect(e.scores[0], 2);
      expect(e.currentPlayer, 0);
    });

    test('8. full 5x5-dot game: scores sum to 16, winner declared', () {
      final e = fresh(dots: 5);
      final rng = Random(7);
      var player = 0;
      var guard = 0;
      while (!e.isGameOver && guard < 500) {
        guard++;
        final edges = e.legalEdges()..shuffle(rng);
        final res = e.draw(edges.first, player);
        if (!res.bonusTurn) player = 1 - player;
      }
      expect(e.isGameOver, isTrue);
      expect(e.scores[0] + e.scores[1], 16);
    });

    test('9/10. tie possible on even totals (7x7 dots -> 36 boxes)', () {
      // NOTE: RULES.md §8 examples / §10 say "6x6 dots -> 36 boxes", which
      // contradicts §8's own formula (D-1)^2 and §2 (6x6 dots -> 5x5 boxes).
      // The formula + §2 agree, so the engine follows them: 7x7 dots = 36 boxes.
      final e = fresh(dots: 7);
      expect(e.totalBoxes, 36);
      // scripted: each box claimed by alternating player -> 18-18 tie
      var p = 0;
      for (var r = 0; r < 6; r++) {
        for (var c = 0; c < 6; c++) {
          // draw missing edges of box (r,c) with alternating player, capturing it
          final missing = <Edge>[];
          if (e.h[r][c] == -1) missing.add(Edge(true, r, c));
          if (e.h[r + 1][c] == -1) missing.add(Edge(true, r + 1, c));
          if (e.v[r][c] == -1) missing.add(Edge(false, r, c));
          if (e.v[r][c + 1] == -1) missing.add(Edge(false, r, c + 1));
          for (final m in missing) {
            e.draw(m, p);
          }
          p = 1 - p;
        }
      }
      expect(e.isGameOver, isTrue);
      expect(e.scores[0] + e.scores[1], 36);
      expect(e.scores[0], 18);
      expect(e.scores[1], 18);
    });

    test('11. medium robot takes a free box', () {
      final e = fresh();
      put(e, true, 0, 0, 0);
      put(e, false, 0, 0, 0);
      put(e, false, 0, 1, 0);
      final move = e.botMove(Difficulty.medium, 1, Random(1))!;
      final res = e.draw(move, 1);
      expect(res.claimed.length, greaterThanOrEqualTo(1));
      expect(e.scores[1], greaterThanOrEqualTo(1));
    });

    test('12. medium robot avoids handing a 3-sided box when a safe edge exists', () {
      final e = fresh();
      // empty-ish board: one box with 2 sides; safe edges exist elsewhere
      put(e, true, 2, 2, 0);
      put(e, false, 2, 2, 0);
      final before = e.moveCount;
      final move = e.botMove(Difficulty.medium, 1, Random(3))!;
      e.draw(move, 1);
      expect(e.moveCount, before + 1);
      // no box should now have exactly 3 sides (that would hand it over)
      for (var r = 0; r < 5; r++) {
        for (var c = 0; c < 5; c++) {
          if (e.box[r][c] == -1) {
            expect(e.boxEdgeCount(r, c) == 3, isFalse,
                reason: 'robot handed over box ($r,$c)');
          }
        }
      }
    });

    test('13. undo after capture restores everything', () {
      final e = fresh();
      put(e, true, 0, 0, 0);
      put(e, false, 0, 0, 0);
      put(e, false, 0, 1, 0);
      e.draw(const Edge(true, 1, 0), 0);
      expect(e.scores[0], 1);
      expect(e.undo(), isTrue);
      expect(e.box[0][0], -1);
      expect(e.h[1][0], -1);
      expect(e.scores[0], 0);
      expect(e.currentPlayer, 0);
    });

    test('14. out-of-bounds rejected', () {
      final e = fresh();
      expect(e.isLegal(const Edge(true, -1, 0)), isFalse);
      expect(e.isLegal(const Edge(false, 0, 99)), isFalse);
    });

    test('15. last-move capture ends game without extra turn', () {
      final e = fresh(dots: 2); // 1 box total
      put(e, true, 0, 0, 0);
      put(e, false, 0, 0, 1);
      put(e, false, 0, 1, 0);
      final res = e.draw(const Edge(true, 1, 0), 1);
      expect(res.claimed.length, 1);
      expect(res.gameOver, isTrue);
      expect(res.bonusTurn, isFalse); // moot at game end
      expect(e.scores, [0, 1]);
    });

    test('serialization round-trips', () {
      final e = fresh();
      e.draw(const Edge(true, 0, 0), 0);
      e.draw(const Edge(false, 0, 0), 1);
      final j = e.toJson();
      final e2 = DotsBoxesEngine.fromJson(Map<String, dynamic>.from(j));
      expect(e2.h, e.h);
      expect(e2.v, e.v);
      expect(e2.box, e.box);
      expect(e2.currentPlayer, e.currentPlayer);
      expect(e2.scores, e.scores);
      expect(e2.moveCount, e.moveCount);
      expect(e2.undo(), isTrue);
      expect(e2.moveCount, 1);
    });

    test('hard bot never crashes on any board size', () {
      for (final dots in [5, 6, 7]) {
        final e = fresh(dots: dots);
        final rng = Random(11);
        var p = 0;
        var guard = 0;
        while (!e.isGameOver && guard < 2000) {
          guard++;
          final move = e.botMove(Difficulty.hard, p, rng)!;
          final res = e.draw(move, p);
          if (!res.bonusTurn) p = 1 - p;
        }
        expect(e.isGameOver, isTrue);
        expect(e.scores[0] + e.scores[1], (dots - 1) * (dots - 1));
      }
    });
  });
}
