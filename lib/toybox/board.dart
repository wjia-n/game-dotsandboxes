import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../engine/dots_boxes_engine.dart';
import '../toybox/palette.dart';

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

/// Interactive toy board: craft-paper card, wooden pegs, crayon edges.
class BoardView extends StatefulWidget {
  final DotsBoxesEngine engine;
  final int activePlayer; // 0/1 — crayon color for preview + hints
  final Color playerColor0;
  final Color playerColor1;
  final void Function(Edge) onEdgeTap;
  final void Function()? onInvalidTap;

  const BoardView({
    super.key,
    required this.engine,
    required this.activePlayer,
    required this.playerColor0,
    required this.playerColor1,
    required this.onEdgeTap,
    this.onInvalidTap,
  });

  @override
  State<BoardView> createState() => BoardViewState();
}

class BoardViewState extends State<BoardView> with SingleTickerProviderStateMixin {
  final Map<Edge, _Anim> _drawn = {};
  final Map<Point<int>, _Anim> _claimed = {};
  Edge? _preview;
  Edge? _hintEdge;
  DateTime? _hintUntil;
  double _shakeT = -1; // animation start (seconds), -1 = idle
  late Ticker _ticker;
  double _now = 0;
  DateTime _lastAnimAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _now = elapsed.inMilliseconds / 1000.0;
      if (mounted) setState(() {});
      if (!_animsActive()) _ticker.stop();
    });
  }

  bool _animsActive() {
    if (_hintEdge != null && DateTime.now().isBefore(_hintUntil!)) return true;
    if (_preview != null) return true;
    if (_shakeT >= 0 && _now - _shakeT < 0.45) return true;
    // draw-in (150ms) and claim-pop (420ms) animations
    if (DateTime.now().difference(_lastAnimAt).inMilliseconds < 600) return true;
    return false;
  }

  void _kick() {
    if (!_ticker.isActive) _ticker.start();
  }

  /// Call when an edge was just drawn: plays the crayon draw-in animation.
  void notifyDrawn(Edge e) {
    _drawn[e] = _Anim(DateTime.now());
    _lastAnimAt = DateTime.now();
    _preview = null;
    _kick();
  }

  /// Call with boxes just claimed: plays the snug pop-in.
  void notifyClaimed(Iterable<Point<int>> boxes) {
    final now = DateTime.now();
    for (final b in boxes) {
      _claimed[b] = _Anim(now);
    }
    _lastAnimAt = now;
    _kick();
  }

  /// Gentle shake + hint for an illegal tap.
  void notifyInvalid() {
    _shakeT = _now;
    _lastAnimAt = DateTime.now();
    _kick();
  }

  /// Dashed crayon hint line for ~2.2s.
  void showHint(Edge e) {
    _lastAnimAt = DateTime.now();
    _hintEdge = e;
    _hintUntil = DateTime.now().add(const Duration(milliseconds: 2200));
    _kick();
  }

  /// Clear transient animation state (e.g. on new game).
  void resetAnims() {
    _drawn.clear();
    _claimed.clear();
    _preview = null;
    _hintEdge = null;
    _hintUntil = null;
    _shakeT = -1;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Color _crayon(int player) => player == 0 ? ToyPalette.red : ToyPalette.blue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final geo = BoardGeometry(dots: widget.engine.dots, size: size);
        double dx = 0;
        if (_shakeT >= 0) {
          final t = _now - _shakeT;
          if (t < 0.45) dx = sin(t * 40) * 7 * (1 - t / 0.45);
        }
        return Transform.translate(
          offset: Offset(dx, 0),
          child: GestureDetector(
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox;
              final p = box.globalToLocal(d.globalPosition);
              final e = geo.edgeAt(p);
              if (e != null && widget.engine.isLegal(e)) {
                setState(() => _preview = e);
                _kick();
              }
            },
            onTapUp: (_) {
              final e = _preview;
              setState(() => _preview = null);
              if (e != null && widget.engine.isLegal(e)) {
                widget.onEdgeTap(e);
              }
            },
            onTapCancel: () => setState(() => _preview = null),
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _BoardPainter(
                  engine: widget.engine,
                  geo: geo,
                  drawn: _drawn,
                  claimed: _claimed,
                  preview: _preview,
                  previewColor: _crayon(widget.activePlayer),
                  hintEdge: _hintEdge,
                  hintVisible: _hintEdge != null &&
                      _hintUntil != null &&
                      DateTime.now().isBefore(_hintUntil!),
                  hintColor: _crayon(widget.activePlayer),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final DotsBoxesEngine engine;
  final BoardGeometry geo;
  final Map<Edge, _Anim> drawn;
  final Map<Point<int>, _Anim> claimed;
  final Edge? preview;
  final Color previewColor;
  final Edge? hintEdge;
  final bool hintVisible;
  final Color hintColor;

  _BoardPainter({
    required this.engine,
    required this.geo,
    required this.drawn,
    required this.claimed,
    required this.preview,
    required this.previewColor,
    required this.hintEdge,
    required this.hintVisible,
    required this.hintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintPaper(canvas, size);
    _paintBoxes(canvas);
    _paintEdges(canvas);
    if (hintVisible && hintEdge != null) _paintHint(canvas, hintEdge!);
    if (preview != null) _paintPreview(canvas, preview!);
    _paintPegs(canvas);
  }

  void _paintPaper(Canvas canvas, Size size) {
    final bg = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22));
    // soft drop shadow under the paper card
    canvas.drawRRect(
      bg.shift(const Offset(0, 8)),
      Paint()..color = const Color(0x2E3D2614),
    );
    canvas.drawRRect(bg, Paint()..color = ToyPalette.paper);
    // inset edge light
    canvas.drawRRect(
      bg,
      Paint()
        ..color = ToyPalette.walnut.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // paper fiber specks (deterministic)
    final rng = Random(77);
    final speck = Paint()..color = ToyPalette.walnut.withValues(alpha: 0.05);
    for (var i = 0; i < 130; i++) {
      final p = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      canvas.drawCircle(p, 0.8 + rng.nextDouble() * 1.2, speck);
    }
    // warm ambient occlusion in corners
    final ao = Paint()
      ..color = ToyPalette.walnut.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (final c in [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      canvas.drawCircle(c, 34, ao);
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
          if (t < 1) {
            scale = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
          } else {
            claimed.remove(Point(r, c));
          }
        }
        final color = owner == 0 ? ToyPalette.red : ToyPalette.blue;
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.scale(scale, scale);
        canvas.translate(-rect.center.dx, -rect.center.dy);
        // crayon wash fill
        final wash = RRect.fromRectAndRadius(rect, Radius.circular(geo.spacing * 0.12));
        canvas.drawRRect(wash, Paint()..color = color.withValues(alpha: 0.22));
        // inner scribble texture
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
        // contact shadow under the star token
        final sc = rect.center;
        final sr = geo.spacing * 0.20;
        canvas.drawCircle(
          sc + const Offset(0, 3),
          sr,
          Paint()..color = const Color(0x403D2614),
        );
        // painted wooden star token
        _paintStar(canvas, sc, sr, owner == 0 ? ToyPalette.redDeep : ToyPalette.blueDeep);
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
          colors: [Colors.white.withValues(alpha: 0.35), color, ToyPalette.walnutDeep.withValues(alpha: 0.4)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = ToyPalette.walnutDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ---------- edges ----------

  Offset _edgeA(Edge e) => e.horizontal ? geo.dot(e.r, e.c) : geo.dot(e.r, e.c);
  Offset _edgeB(Edge e) =>
      e.horizontal ? geo.dot(e.r, e.c + 1) : geo.dot(e.r + 1, e.c);

  /// Deterministic hand-wobble offsets for an edge's crayon stroke.
  List<double> _wobble(Edge e) {
    final seed = (e.horizontal ? 100003 : 200011) + e.r * 911 + e.c * 37;
    final rng = Random(seed);
    return List.generate(9, (_) => (rng.nextDouble() - 0.5) * 2.6);
  }

  void _paintEdges(Canvas canvas) {
    final dots = engine.dots;
    for (var r = 0; r < dots; r++) {
      for (var c = 0; c < dots - 1; c++) {
        _paintEdgeSlot(canvas, Edge(true, r, c), engine.h[r][c]);
      }
    }
    for (var r = 0; r < dots - 1; r++) {
      for (var c = 0; c < dots; c++) {
        _paintEdgeSlot(canvas, Edge(false, r, c), engine.v[r][c]);
      }
    }
  }

  void _paintEdgeSlot(Canvas canvas, Edge e, int owner) {
    final a = _edgeA(e);
    final b = _edgeB(e);
    final w = geo.spacing * 0.30;
    if (owner == -1) {
      // routed channel: inset slot
      final rect = _slotRect(a, b, w);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w / 2)),
        Paint()..color = ToyPalette.channel,
      );
      // inset shadow on the top edge of the channel
      canvas.drawLine(
        Offset(rect.left + 3, rect.top + 1.5),
        Offset(rect.right - 3, rect.top + 1.5),
        Paint()
          ..color = ToyPalette.walnut.withValues(alpha: 0.16)
          ..strokeWidth = 1.5,
      );
      return;
    }
    // crayon stroke with draw-in animation
    final now = DateTime.now();
    double frac = 1.0;
    final anim = drawn[e];
    if (anim != null) {
      final t = now.difference(anim.at).inMilliseconds / 150.0;
      if (t < 1) {
        frac = t.clamp(0.0, 1.0);
      } else {
        drawn.remove(e);
      }
    }
    final color = owner == 0 ? ToyPalette.red : ToyPalette.blue;
    final wob = _wobble(e);
    final ab = b - a;
    final len = ab.distance;
    final dir = len > 0 ? ab / len : const Offset(1, 0);
    final nrm = Offset(-dir.dy, dir.dx);
    final segs = 8;
    final paint = Paint()
      ..color = color
      ..strokeWidth = geo.spacing * 0.20
      ..strokeCap = StrokeCap.round;
    final upto = (segs * frac).ceil().clamp(1, segs);
    for (var i = 0; i < upto; i++) {
      final t0 = i / segs;
      final t1 = min((i + 1) / segs, frac);
      if (t1 <= t0) break;
      final p0 = a + (b - a) * t0 + nrm * wob[i];
      final p1 = a + (b - a) * t1 + nrm * wob[i + 1];
      canvas.drawLine(p0, p1, paint);
    }
    // wax sheen core + texture speckles
    final sheen = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = geo.spacing * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a + nrm * -1.5 + dir * 3, b + nrm * -1.5 - dir * 3, sheen);
    final rng = Random((e.horizontal ? 7 : 13) + e.r * 101 + e.c * 31);
    final speck = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i < 10; i++) {
      final t = rng.nextDouble() * frac;
      final p = a + (b - a) * t + nrm * (rng.nextDouble() - 0.5) * 5;
      canvas.drawCircle(p, 1.1, speck);
    }
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

  void _paintHint(Canvas canvas, Edge e) {
    final a = _edgeA(e);
    final b = _edgeB(e);
    final dash = Paint()
      ..color = hintColor.withValues(alpha: 0.75)
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

  // ---------- pegs ----------

  void _paintPegs(Canvas canvas) {
    final r = geo.pegRadius;
    for (var row = 0; row < engine.dots; row++) {
      for (var c = 0; c < engine.dots; c++) {
        final p = geo.dot(row, c);
        // contact shadow
        canvas.drawOval(
          Rect.fromCenter(center: p + Offset(0, r * 0.42), width: r * 2.1, height: r * 1.1),
          Paint()..color = const Color(0x473D2614),
        );
        // lathe-turned bead
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 1.15,
              colors: const [
                Color(0xFFB07B45),
                ToyPalette.oak,
                ToyPalette.walnut,
                ToyPalette.walnutDeep,
              ],
              stops: const [0.0, 0.45, 0.8, 1.0],
            ).createShader(Rect.fromCircle(center: p, radius: r)),
        );
        // turned groove ring
        canvas.drawCircle(
          p,
          r * 0.68,
          Paint()
            ..color = ToyPalette.walnutDeep.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        // off-center warm specular highlight
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
