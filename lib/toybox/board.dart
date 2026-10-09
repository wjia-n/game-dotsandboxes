import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../engine/dots_boxes_engine.dart';
import '../state/game_controller.dart';
import '../theme/toybox_themes.dart';

/// Shared geometry: dot positions, edge lookup, touch mapping.
class BoardGeometry {
  final int dots;
  final double size;
  final double pad;
  late final double spacing;

  BoardGeometry({required this.dots, required this.size, this.pad = 26}) {
    spacing = (size - pad * 2) / (dots - 1);
  }

  Offset dot(int r, int c) => Offset(pad + c * spacing, pad + r * spacing);

  double get pegRadius => (spacing * 0.16).clamp(7.0, 15.0);

  /// Nearest legal-tappable edge to [p], or null if too far from any slot.
  Edge? edgeAt(Offset p) {
    Edge? best;
    var bestDist = spacing * 0.42;
    // horizontal edges: row r in 0..dots-1, col c in 0..dots-2
    final rh = (p.dy - pad) / spacing;
    final r = rh.round();
    if (r >= 0 && r < dots) {
      final c = ((p.dx - pad) / spacing).floor();
      if (c >= 0 && c < dots - 1) {
        final d = (p.dy - (pad + r * spacing)).abs();
        if (d < bestDist) {
          bestDist = d;
          best = Edge(true, r, c);
        }
      }
    }
    // vertical edges
    final cv = (p.dx - pad) / spacing;
    final c = cv.round();
    if (c >= 0 && c < dots) {
      final r2 = ((p.dy - pad) / spacing).floor();
      if (r2 >= 0 && r2 < dots - 1) {
        final d = (p.dx - (pad + c * spacing)).abs();
        if (d < bestDist) {
          bestDist = d;
          best = Edge(false, r2, c);
        }
      }
    }
    return best;
  }
}

class _Anim {
  DateTime at;
  _Anim(this.at);
}

/// Interactive toy board: paper card, wooden pegs, crayon edges.
/// All drawing state comes from the [GameController] (engine-owned); this
/// widget only renders. Line style + theme come from settings.
class BoardView extends StatefulWidget {
  final GameController controller;

  const BoardView({super.key, required this.controller});

  @override
  State<BoardView> createState() => BoardViewState();
}

class BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  final Map<Point<int>, _Anim> _claimed = {};
  Edge? _preview;
  double _shakeT = -1; // animation start (seconds), -1 = idle
  late Ticker _ticker;
  double _now = 0;
  int _lastInvalidSeq = 0;
  DotsBoxesEngine? _lastEngine;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _now = elapsed.inMilliseconds / 1000.0;
      if (mounted) setState(() {});
      if (!_animsActive()) _ticker.stop();
    });
    _lastInvalidSeq = widget.controller.invalidTapSeq;
  }

  bool _animsActive() {
    if (widget.controller.hintEdge != null) return true;
    if (_preview != null) return true;
    if (_shakeT >= 0 && _now - _shakeT < 0.45) return true;
    return false;
  }

  void _kick() {
    if (!_ticker.isActive) _ticker.start();
  }

  /// Clear transient animation state (e.g. on new game).
  void resetAnims() {
    _claimed.clear();
    _preview = null;
    _shakeT = -1;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    // new engine (new/continued game) -> drop all transient anim state
    if (!identical(_lastEngine, c.engine)) {
      _lastEngine = c.engine;
      _claimed.clear();
      _preview = null;
      _shakeT = -1;
    }
    // illegal-tap shake
    if (c.invalidTapSeq != _lastInvalidSeq) {
      _lastInvalidSeq = c.invalidTapSeq;
      _shakeT = _now;
      _kick();
    }
    // claim pops: start a pop the first time a pending claim is seen
    final now = DateTime.now();
    for (final pc in c.pendingClaims) {
      if (pc.started && !_claimed.containsKey(pc.box)) {
        _claimed[pc.box] = _Anim(now);
      }
    }
    // prune finished pops
    _claimed.removeWhere(
        (_, a) => now.difference(a.at).inMilliseconds > 600);

    final theme = c.theme;
    final style = LineStyles.byId(c.settings.lineStyle);
    final paperAccent = c.settings.paperAccent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final geo = BoardGeometry(dots: c.engine.dots, size: size);
        double dx = 0;
        if (_shakeT >= 0) {
          final t = _now - _shakeT;
          if (t < 0.45) dx = sin(t * 40) * 7 * (1 - t / 0.45);
        }
        final canTap = c.phase == TurnPhase.awaitingInput &&
            !c.seats[c.activeSeat].isBot &&
            !c.paused;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: GestureDetector(
            onTapDown: (d) {
              if (!canTap) return;
              final box = context.findRenderObject() as RenderBox;
              final p = box.globalToLocal(d.globalPosition);
              final e = geo.edgeAt(p);
              if (e != null && c.engine.isLegal(e)) {
                setState(() => _preview = e);
                _kick();
              }
            },
            onTapUp: (_) {
              final e = _preview;
              setState(() => _preview = null);
              if (e != null && canTap && c.engine.isLegal(e)) {
                c.onEdgeTap(e);
              }
            },
            onTapCancel: () => setState(() => _preview = null),
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _BoardPainter(
                  controller: c,
                  geo: geo,
                  theme: theme,
                  style: style,
                  paperAccent: paperAccent,
                  claimed: _claimed,
                  preview: canTap ? _preview : null,
                  previewColor: theme.playerColor(c.activeSeat),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _BoardPainter extends CustomPainter {
  final GameController controller;
  final BoardGeometry geo;
  final ToyThemeDef theme;
  final LineStyleDef style;
  final int paperAccent;
  final Map<Point<int>, _Anim> claimed;
  final Edge? preview;
  final Color previewColor;

  _BoardPainter({
    required this.controller,
    required this.geo,
    required this.theme,
    required this.style,
    required this.paperAccent,
    required this.claimed,
    required this.preview,
    required this.previewColor,
  });

  DotsBoxesEngine get engine => controller.engine;

  @override
  void paint(Canvas canvas, Size size) {
    _paintPaper(canvas, size);
    _paintBoxes(canvas);
    _paintEdges(canvas);
    final hint = controller.hintEdge;
    if (hint != null) _paintHint(canvas, hint);
    if (preview != null) _paintPreview(canvas, preview!);
    _paintPegs(canvas);
    _paintPencilTip(canvas);
  }

  // ---------- paper ----------

  void _paintPaper(Canvas canvas, Size size) {
    final bg =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22));
    canvas.drawRRect(
      bg.shift(const Offset(0, 8)),
      Paint()..color = const Color(0x2E3D2614),
    );
    canvas.drawRRect(bg, Paint()..color = theme.paper);
    canvas.drawRRect(
      bg,
      Paint()
        ..color = theme.paperEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final rng = Random(77 + paperAccent * 131);
    if (paperAccent == 1) {
      // linen crosshatch
      final p = Paint()
        ..color = theme.speck
        ..strokeWidth = 1;
      for (double x = 8; x < size.width; x += 9) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      }
      for (double y = 8; y < size.height; y += 9) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      }
    } else if (paperAccent == 4) {
      // denim twill: diagonal lines
      final p = Paint()
        ..color = theme.speck
        ..strokeWidth = 1.4;
      for (double d = -size.height; d < size.width; d += 8) {
        canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), p);
      }
    } else if (paperAccent == 5) {
      // cork blotches
      for (var i = 0; i < 46; i++) {
        canvas.drawCircle(
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          3 + rng.nextDouble() * 9,
          Paint()..color = theme.speck,
        );
      }
    } else {
      // craft / kraft / felt: fiber specks
      final dense = paperAccent == 3;
      final speck = Paint()..color = theme.speck;
      for (var i = 0; i < (dense ? 320 : 130); i++) {
        final p = Offset(
            rng.nextDouble() * size.width, rng.nextDouble() * size.height);
        canvas.drawCircle(p, 0.8 + rng.nextDouble() * 1.2, speck);
      }
    }
    // warm ambient occlusion in corners
    final ao = Paint()
      ..color = theme.pegDeep.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (final cc in [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      canvas.drawCircle(cc, 34, ao);
    }
  }

  // ---------- boxes ----------

  void _paintBoxes(Canvas canvas) {
    final now = DateTime.now();
    for (var r = 0; r < engine.boxesPerSide; r++) {
      for (var c = 0; c < engine.boxesPerSide; c++) {
        final owner = engine.box[r][c];
        if (owner == -1) continue;
        final tl = geo.dot(r, c);
        final br = geo.dot(r + 1, c + 1);
        final rect = Rect.fromPoints(tl, br).deflate(geo.spacing * 0.12);
        final anim = claimed[Point(r, c)];
        double scale = 1.0;
        if (anim != null) {
          final t = now.difference(anim.at).inMilliseconds / 420.0;
          if (t < 1) scale = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
        }
        final color = theme.playerColor(owner);
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.scale(scale, scale);
        canvas.translate(-rect.center.dx, -rect.center.dy);
        final wash = RRect.fromRectAndRadius(
            rect, Radius.circular(geo.spacing * 0.12));
        canvas.drawRRect(wash, Paint()..color = color.withValues(alpha: 0.22));
        final rng = Random(r * 131 + c * 17 + 5);
        final scrib = Paint()
          ..color = color.withValues(alpha: 0.13)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 5; i++) {
          final y = rect.top + rect.height * (0.2 + 0.6 * rng.nextDouble());
          final x0 = rect.left + rect.width * 0.15 * rng.nextDouble();
          final x1 = rect.right - rect.width * 0.15 * rng.nextDouble();
          canvas.drawLine(
            Offset(x0, y + (rng.nextDouble() - 0.5) * 4),
            Offset(x1, y + (rng.nextDouble() - 0.5) * 4),
            scrib,
          );
        }
        final sc = rect.center;
        final sr = geo.spacing * 0.20;
        canvas.drawCircle(
          sc + const Offset(0, 3),
          sr,
          Paint()..color = const Color(0x403D2614),
        );
        _paintStar(canvas, sc, sr, theme.playerDeep(owner));
        canvas.restore();
      }
    }
  }

  void _paintStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 1.2,
          colors: [
            Colors.white.withValues(alpha: 0.35),
            color,
            theme.pegDeep.withValues(alpha: 0.4)
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = theme.pegDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ---------- edges ----------

  Offset _edgeA(Edge e) => geo.dot(e.r, e.c);
  Offset _edgeB(Edge e) =>
      e.horizontal ? geo.dot(e.r, e.c + 1) : geo.dot(e.r + 1, e.c);

  List<double> _wobble(Edge e, double amp) {
    final seed = (e.horizontal ? 100003 : 200011) + e.r * 911 + e.c * 37;
    final rng = Random(seed);
    return List.generate(9, (_) => (rng.nextDouble() - 0.5) * 2 * amp);
  }

  void _paintEdges(Canvas canvas) {
    final dots = engine.dots;
    final pending = controller.pendingDraw;
    for (var r = 0; r < dots; r++) {
      for (var c = 0; c < dots - 1; c++) {
        final e = Edge(true, r, c);
        final owner = engine.h[r][c];
        if (owner == -1) {
          _paintSlot(canvas, e);
        } else {
          final frac = (pending != null && pending.edge == e)
              ? pending.progress
              : 1.0;
          _paintStroke(canvas, e, theme.playerColor(owner), frac);
        }
      }
    }
    for (var r = 0; r < dots - 1; r++) {
      for (var c = 0; c < dots; c++) {
        final e = Edge(false, r, c);
        final owner = engine.v[r][c];
        if (owner == -1) {
          _paintSlot(canvas, e);
        } else {
          final frac = (pending != null && pending.edge == e)
              ? pending.progress
              : 1.0;
          _paintStroke(canvas, e, theme.playerColor(owner), frac);
        }
      }
    }
  }

  void _paintSlot(Canvas canvas, Edge e) {
    final a = _edgeA(e);
    final b = _edgeB(e);
    final w = geo.spacing * 0.30;
    final rect = _slotRect(a, b, w);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(w / 2)),
      Paint()..color = theme.channel,
    );
    canvas.drawLine(
      Offset(rect.left + 3, rect.top + 1.5),
      Offset(rect.right - 3, rect.top + 1.5),
      Paint()
        ..color = theme.pegDeep.withValues(alpha: 0.16)
        ..strokeWidth = 1.5,
    );
  }

  Rect _slotRect(Offset a, Offset b, double w) {
    final mid = (a + b) / 2;
    final len = (b - a).distance;
    final horiz = (a.dy - b.dy).abs() < 0.01;
    if (horiz) {
      return Rect.fromCenter(center: mid, width: len * 0.94, height: w);
    }
    return Rect.fromCenter(center: mid, width: w, height: len * 0.94);
  }

  /// Paint a claimed edge in [style], drawn up to [frac] (0..1) of its length.
  void _paintStroke(Canvas canvas, Edge e, Color color, double frac) {
    if (frac <= 0) return;
    final a = _edgeA(e);
    final b = _edgeB(e);
    final wob = _wobble(e, style.wobble);
    final ab = b - a;
    final len = ab.distance;
    final dir = len > 0 ? ab / len : const Offset(1, 0);
    final nrm = Offset(-dir.dy, dir.dx);
    final segs = 8;
    final baseW = geo.spacing * style.widthFactor;

    for (var pass = 0; pass < style.passes; pass++) {
      final w = pass == 0
          ? baseW
          : baseW * (style.soft ? 1.35 : 0.55); // halo / sketch pass
      final alpha = pass == 0
          ? 1.0
          : (style.soft ? 0.35 : 0.5);
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round;
      final upto = (segs * frac).ceil().clamp(1, segs);
      for (var i = 0; i < upto; i++) {
        final t0 = i / segs;
        final t1 = min((i + 1) / segs, frac);
        if (t1 <= t0) break;
        final off = pass == 0 ? 0.0 : (pass.isOdd ? 1.6 : -1.6);
        final p0 = a + (b - a) * t0 + nrm * (wob[i] + off);
        final p1 = a + (b - a) * t1 + nrm * (wob[i + 1] + off);
        canvas.drawLine(p0, p1, paint);
      }
    }
    // sheen core
    if (style.sheen > 0) {
      final sheen = Paint()
        ..color = Colors.white.withValues(alpha: style.sheen)
        ..strokeWidth = baseW * 0.35
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        a + nrm * -1.5 + dir * 3 * frac,
        a + (b - a) * frac + nrm * -1.5 - dir * 3,
        sheen,
      );
    }
    // wax texture speckles
    if (style.speckles > 0) {
      final rng = Random((e.horizontal ? 7 : 13) + e.r * 101 + e.c * 31);
      final speck = Paint()
        ..color = Colors.white.withValues(alpha: style.soft ? 0.18 : 0.10);
      for (var i = 0; i < style.speckles; i++) {
        final t = rng.nextDouble() * frac;
        final p = a + (b - a) * t + nrm * (rng.nextDouble() - 0.5) * 5;
        canvas.drawCircle(p, 1.1, speck);
      }
    }
  }

  void _paintHint(Canvas canvas, Edge e) {
    final a = _edgeA(e);
    final b = _edgeB(e);
    final dash = Paint()
      ..color = theme.playerColor(controller.activeSeat)
          .withValues(alpha: 0.75)
      ..strokeWidth = geo.spacing * 0.13
      ..strokeCap = StrokeCap.round;
    const dashes = 7;
    for (var i = 0; i < dashes; i += 2) {
      canvas.drawLine(
        a + (b - a) * (i / dashes),
        a + (b - a) * ((i + 1) / dashes),
        dash,
      );
    }
  }

  void _paintPreview(Canvas canvas, Edge e) {
    final a = _edgeA(e);
    final b = _edgeB(e);
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = previewColor.withValues(alpha: 0.45)
        ..strokeWidth = geo.spacing * 0.20
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A little wooden crayon tip gliding at the head of a bot's draw — makes
  /// bot turns unmistakably visible.
  void _paintPencilTip(Canvas canvas) {
    final pending = controller.pendingDraw;
    if (pending == null) return;
    if (!controller.seats[pending.player].isBot) return;
    final a = _edgeA(pending.edge);
    final b = _edgeB(pending.edge);
    final head = a + (b - a) * pending.progress.clamp(0.0, 1.0);
    final r = geo.spacing * 0.16;
    // shadow
    canvas.drawCircle(
        head + Offset(0, r * 0.5), r, Paint()..color = const Color(0x403D2614));
    // wooden crayon stub in the drawing player's color
    canvas.drawCircle(
      head,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.4),
            theme.playerColor(pending.player),
            theme.playerDeep(pending.player),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: head, radius: r)),
    );
  }

  // ---------- pegs ----------

  void _paintPegs(Canvas canvas) {
    final r = geo.pegRadius;
    for (var row = 0; row < engine.dots; row++) {
      for (var c = 0; c < engine.dots; c++) {
        final p = geo.dot(row, c);
        canvas.drawOval(
          Rect.fromCenter(
              center: p + Offset(0, r * 0.42),
              width: r * 2.1,
              height: r * 1.1),
          Paint()..color = const Color(0x473D2614),
        );
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 1.15,
              colors: [
                theme.pegLight,
                theme.pegMid,
                theme.pegDark,
                theme.pegDeep,
              ],
              stops: const [0.0, 0.45, 0.8, 1.0],
            ).createShader(Rect.fromCircle(center: p, radius: r)),
        );
        canvas.drawCircle(
          p,
          r * 0.68,
          Paint()
            ..color = theme.pegDeep.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: p + Offset(-r * 0.32, -r * 0.38),
            width: r * 0.62,
            height: r * 0.42,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
