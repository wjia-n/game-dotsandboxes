import 'dart:math';

import 'package:dotsandboxes/engine/dots_boxes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DotsBoxesEngine fresh({int dots = 6, int players = 2}) =>
    DotsBoxesEngine(dots: dots, players: players);

/// Draw an edge for [player] directly (bypassing turn order).
void put(DotsBoxesEngine e, bool h, int r, int c, int p) =>
    e.draw(Edge(h, r, c), p);

void main() {
  group('box count exactness (RULES.md authoritative)', () {
    test('5x5 dots -> exactly 16 boxes', () {
      expect(fresh(dots: 5).totalBoxes, 16);
    });
    test('6x6 dots -> exactly 25 boxes', () {
      expect(fresh(dots: 6).totalBoxes, 25);
    });
    test('7x7 dots -> exactly 36 boxes', () {
      expect(fresh(dots: 7).totalBoxes, 36);
    });
    test('N dots -> (N-1)^2 for N in 2..9', () {
      for (var n = 2; n <= 9; n++) {
        expect(DotsBoxesEngine(dots: n).totalBoxes, (n - 1) * (n - 1));
      }
    });
    test('total edges = 2*dots*(dots-1)', () {
      for (var n = 5; n <= 7; n++) {
        final e = fresh(dots: n);
        expect(e.legalEdges().length, 2 * n * (n - 1));
        expect(e.totalEdges, 2 * n * (n - 1));
      }
    });
  });

  group('rules conformance (RULES.md section 13)', () {
    test('1. first move accepted, 0-0, turn passes', () {
      final e = fresh();
      final res = e.draw(const Edge(true, 0, 0), 0);
      expect(res.claimed, isEmpty);
      expect(res.bonusTurn, isFalse);
      expect(e.scores, [0, 0]);
      expect(e.currentPlayer, 1);
    });

    test('2. diagonal rejected (not representable; off-grid rejected)', () {
      final e = fresh();
      expect(e.isLegal(const Edge(true, 0, 6)), isFalse);
      expect(e.moveCount, 0);
    });

    test('3. duplicate edge rejected, turn not consumed', () {
      final e = fresh();
      e.draw(const Edge(true, 0, 0), 0);
      expect(e.isLegal(const Edge(true, 0, 0)), isFalse);
      expect(() => e.draw(const Edge(true, 0, 0), 1), throwsStateError);
      expect(e.currentPlayer, 1);
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
      put(e, true, 0, 0, 1);
      put(e, false, 0, 0, 1);
      put(e, false, 0, 1, 1);
      put(e, true, 2, 2, 1);
      put(e, false, 2, 2, 1);
      put(e, true, 3, 2, 1);
      // box (0,0) needs bottom h(1,0); box (2,2) needs right v(2,3)
      var res = e.draw(const Edge(true, 1, 0), 0);
      expect(res.claimed.length, 1);
      expect(res.bonusTurn, isTrue);
      res = e.draw(const Edge(false, 2, 3), 0);
      expect(res.claimed.length, 1);
      expect(res.bonusTurn, isTrue);
      expect(e.scores[0], 2);
      expect(e.currentPlayer, 0);
    });

    test('8. full 5x5 game: scores sum to 16, winner declared', () {
      final e = fresh(dots: 5);
      final rng = Random(42);
      var guard = 0;
      while (!e.isGameOver && guard < 1000) {
        final player = e.currentPlayer;
        final move = e.botMove(Difficulty.medium, player, rng)!;
        final res = e.draw(move, player);
        if (!res.bonusTurn && !res.gameOver) {
          // ordinary move: turn passes; on the final edge the game ends
          // instead (RULES.md §7, §12) and the turn does not pass.
          expect(e.currentPlayer, 1 - player);
        }
        guard++;
      }
      expect(e.isGameOver, isTrue);
      expect(e.scores[0] + e.scores[1], 16);
      expect(e.winners(), isNotEmpty); // 16 is even: an 8-8 tie is legal
      expect(e.moveCount, e.totalEdges);
    });

    test('9. draw detection: tied top scores -> winners lists both', () {
      final e = fresh(dots: 6);
      e.scores[0] = 18;
      e.scores[1] = 18;
      expect(e.winners(), [0, 1]);
    });

    test('10. no draw possible on the 6x6 board (25 is odd)', () {
      final e = fresh(dots: 6);
      expect(25 % 2, 1);
      for (var a = 0; a <= 25; a++) {
        e.scores[0] = a;
        e.scores[1] = 25 - a;
        expect(e.winners().length, 1);
      }
    });

    test('11. robot medium takes a free box', () {
      final e = fresh();
      put(e, true, 0, 0, 0);
      put(e, false, 0, 0, 0);
      put(e, false, 0, 1, 0);
      final move = e.botMove(Difficulty.medium, 1, Random(7));
      expect(move, const Edge(true, 1, 0));
    });

    test('12. robot medium moves are always legal', () {
      final e = fresh();
      final rng = Random(1234);
      put(e, true, 0, 0, 0);
      put(e, true, 2, 2, 1);
      put(e, false, 3, 3, 0);
      for (var i = 0; i < 12; i++) {
        final move = e.botMove(Difficulty.medium, i % 2, rng)!;
        expect(e.isLegal(move), isTrue);
        e.draw(move, i % 2);
        expect(e.isLegal(move), isFalse); // now drawn
      }
    });

    test('13. undo after capture restores everything', () {
      final e = fresh();
      put(e, true, 0, 0, 0);
      put(e, false, 0, 0, 1);
      put(e, false, 0, 1, 0);
      final res = e.draw(const Edge(true, 1, 0), 1);
      expect(res.claimed.length, 1);
      expect(e.undo(), isTrue);
      expect(e.box[0][0], -1);
      expect(e.scores[1], 0);
      expect(e.isLegal(const Edge(true, 1, 0)), isTrue);
      expect(e.currentPlayer, 1); // turn restored to the mover
    });

    test('14. out-of-bounds rejected', () {
      final e = fresh();
      expect(e.isLegal(const Edge(true, -1, 0)), isFalse);
      expect(e.isLegal(const Edge(false, 0, 7)), isFalse);
      expect(() => e.draw(const Edge(true, -1, 0), 0), throwsStateError);
    });

    test('15. last-move capture ends game without extra turn', () {
      final e = fresh(dots: 3); // 4 boxes, 12 edges
      final rng = Random(9);
      MoveResult? last;
      while (!e.isGameOver) {
        final player = e.currentPlayer;
        final move = e.botMove(Difficulty.medium, player, rng)!;
        last = e.draw(move, player);
      }
      expect(e.scores[0] + e.scores[1], 4);
      expect(last!.gameOver, isTrue);
    });

    test('16. four-seat game: scores sum to total, winner(s) declared', () {
      final e = fresh(dots: 6, players: 4);
      final rng = Random(2026);
      var guard = 0;
      while (!e.isGameOver && guard < 2000) {
        final p = e.currentPlayer;
        final move = e.botMove(Difficulty.easy, p, rng)!;
        e.draw(move, p);
        guard++;
      }
      expect(e.isGameOver, isTrue);
      expect(e.scores.reduce((a, b) => a + b), 25); // 6x6 dots -> 25 boxes
      expect(e.winners(), isNotEmpty);
      expect(e.moveCount, e.totalEdges);
    });

    test('17. turn order cycles 0->1->2->3->0 with 4 seats', () {
      final e = fresh(players: 4);
      final seen = <int>[];
      for (var i = 0; i < 8; i++) {
        seen.add(e.currentPlayer);
        final move = e.legalEdges().first;
        final res = e.draw(move, e.currentPlayer);
        expect(res.bonusTurn, isFalse); // first edges claim nothing
      }
      expect(seen, [0, 1, 2, 3, 0, 1, 2, 3]);
    });
  });

  group('bot-vs-bot simulation: no stuck states', () {
    // Hard does full lookahead: keep it on 5x5 only (7x7 is too slow for
    // a unit test); easy/medium cover all board sizes.
    final matrix = [
      for (final dots in [5, 6, 7])
        for (final diff in [Difficulty.easy, Difficulty.medium]) (diff, dots),
      (Difficulty.hard, 5),
    ];
    for (final (diff, dots) in matrix) {
      test('${diff.name} vs ${diff.name} on ${dots}x$dots completes', () {
        final e = fresh(dots: dots);
        final rng = Random(1000 + diff.index * 97 + dots);
        var guard = 0;
        final maxMoves = e.totalEdges + 10;
        while (!e.isGameOver) {
          expect(guard < maxMoves, isTrue,
              reason: 'stuck: moves exceeded total edges');
          final p = e.currentPlayer;
          final move = e.botMove(diff, p, rng);
          // A bot must ALWAYS have a legal move while the game runs.
          expect(move, isNotNull,
              reason: 'bot returned null with edges remaining');
          expect(e.isLegal(move!), isTrue);
          e.draw(move, p);
          guard++;
        }
        expect(e.moveCount, e.totalEdges);
        expect(e.scores.reduce((a, b) => a + b), (dots - 1) * (dots - 1));
      });
    }

    test('mixed difficulties 4-seat game completes', () {
      final e = fresh(dots: 6, players: 4);
      final diffs = [
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard,
        Difficulty.medium
      ];
      final rng = Random(555);
      var guard = 0;
      while (!e.isGameOver && guard < 5000) {
        final p = e.currentPlayer;
        final move = e.botMove(diffs[p], p, rng)!;
        e.draw(move, p);
        guard++;
      }
      expect(e.isGameOver, isTrue);
      expect(e.scores.reduce((a, b) => a + b), 25); // 6x6 dots -> 25 boxes
    });

    test('undo never corrupts invariants in a long game', () {
      final e = fresh(dots: 6);
      final rng = Random(77);
      var guard = 0;
      while (!e.isGameOver && guard < 3000) {
        final p = e.currentPlayer;
        e.draw(e.botMove(Difficulty.medium, p, rng)!, p);
        if (e.moveCount % 15 == 0 && e.moveCount > 0) {
          final before = e.moveCount;
          expect(e.undo(), isTrue);
          expect(e.moveCount, before - 1);
        }
        guard++;
      }
      expect(e.moveCount, e.totalEdges - e.legalEdges().length);
      expect(e.scores.reduce((a, b) => a + b),
          e.boxesLeft == 0 ? 25 : lessThan(25));
    });
  });

  group('persistence round-trip', () {
    test('toJson/fromJson preserves a mid-game with 3 players', () {
      final e = fresh(dots: 6, players: 3);
      final rng = Random(11);
      for (var i = 0; i < 20; i++) {
        final p = e.currentPlayer;
        e.draw(e.botMove(Difficulty.easy, p, rng)!, p);
      }
      final json = Map<String, dynamic>.from(e.toJson());
      final e2 = DotsBoxesEngine.fromJson(json);
      expect(e2.dots, 6);
      expect(e2.players, 3);
      expect(e2.scores, e.scores);
      expect(e2.currentPlayer, e.currentPlayer);
      expect(e2.moveCount, e.moveCount);
      expect(e2.box, e.box);
    });
  });
}
