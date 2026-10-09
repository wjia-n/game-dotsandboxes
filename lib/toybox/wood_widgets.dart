import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';

/// Lacquered wooden slab button — bevel collapses when pressed, like pushing
/// a real chunky toy button.
class WoodButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color bevel;
  final Color edgeColor;
  final double width;
  final double height;
  final TextStyle? textStyle;
  final IconData? icon;

  const WoodButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = ToyPalette.honey,
    this.bevel = ToyPalette.honeyDeep,
    this.edgeColor = ToyPalette.oak,
    this.width = 240,
    this.height = 60,
    this.textStyle,
    this.icon,
  });

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dy = _pressed ? 3.5 : 0.0;
    final bevelH = _pressed ? 1.5 : 5.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, dy, 0),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.edgeColor, width: 2),
          boxShadow: _pressed ? ToyPalette.pressedShadow() : ToyPalette.buttonShadow(),
        ),
        child: Stack(
          children: [
            // solid bottom bevel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: bevelH,
                decoration: BoxDecoration(
                  color: widget.bevel,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
              ),
            ),
            // top lacquer highlight
            Positioned(
              left: 4,
              right: 4,
              top: 3,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: bevelH),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: (widget.textStyle ?? ToyType.buttonLabel).copyWith(
                        shadows: const [
                          Shadow(
                            color: Color(0x55000000),
                            offset: Offset(0, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round wooden icon button (settings, help, undo, hint, pause...).
class WoodIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? tooltip;

  const WoodIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 52,
    this.color = ToyPalette.maple,
    this.tooltip,
  });

  @override
  State<WoodIconButton> createState() => _WoodIconButtonState();
}

class _WoodIconButtonState extends State<WoodIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _pressed ? 3.0 : 0.0, 0),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          border: Border.all(color: ToyPalette.oak, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0x33853D14),
              offset: Offset(0, _pressed ? 2 : 5),
              blurRadius: _pressed ? 4 : 8,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: widget.size * 0.08,
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.size * 0.11),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Icon(widget.icon, color: ToyPalette.walnut, size: widget.size * 0.44),
          ],
        ),
      ),
    );
  }
}

/// Hanging maple score plaque in a walnut frame.
class ScorePlaque extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final bool active;

  const ScorePlaque({
    super.key,
    required this.name,
    required this.score,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ToyPalette.maple,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? color : ToyPalette.oak,
          width: active ? 3 : 2,
        ),
        boxShadow: [
          if (active)
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              offset: const Offset(0, 4),
              blurRadius: 8,
            )
          else
            ...ToyPalette.plaqueShadow(),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScoreDisc(color: color, value: score, size: 34),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: ToyType.label.copyWith(fontSize: 12)),
              Text('$score', style: ToyType.h3.copyWith(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Painted wooden score disc (red/blue tally bead).
class _ScoreDisc extends StatelessWidget {
  final Color color;
  final int value;
  final double size;

  const _ScoreDisc({required this.color, required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [color.withValues(alpha: 0.75), color, ToyPalette.walnutDeep.withValues(alpha: 0.55)],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: ToyPalette.walnutDeep, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x443D2614),
            offset: Offset(0, 3),
            blurRadius: 5,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: ToyType.headline.copyWith(
          color: Colors.white,
          fontSize: size * 0.42,
          shadows: const [Shadow(color: Color(0x88000000), offset: Offset(0, 1))],
        ),
      ),
    );
  }
}

/// Round wooden thumbtack pinning a modal corner.
class Thumbtack extends StatelessWidget {
  final double size;
  const Thumbtack({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 1.15,
          colors: [Color(0xFFA06A35), ToyPalette.walnut, ToyPalette.walnutDeep],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.all(color: ToyPalette.walnutDeep, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x553D2614), offset: Offset(0, 3), blurRadius: 4),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.28,
          height: size * 0.28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

/// Little wooden tag ("Your turn").
class WoodenTag extends StatelessWidget {
  final String text;
  final Color color;
  const WoodenTag({super.key, required this.text, this.color = ToyPalette.honey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ToyPalette.oak, width: 2),
        boxShadow: ToyPalette.plaqueShadow(),
      ),
      child: Text(text, style: ToyType.label.copyWith(color: Colors.white)),
    );
  }
}
