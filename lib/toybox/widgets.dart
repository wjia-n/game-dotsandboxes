import 'package:flutter/material.dart';

import '../theme/toybox_themes.dart';

/// Chunky wooden toy-box widgets, driven by the active [ToyThemeDef].
/// Physical recipe: lacquered slab, oak border, top highlight, solid bottom
/// bevel, warm cast shadow; pressed state translates down and the bevel
/// collapses.

TextStyle toyHeadline(double size, ToyThemeDef t) => TextStyle(
      fontFamily: 'Comfortaa',
      fontWeight: FontWeight.w700,
      fontSize: size,
      color: t.text,
      shadows: const [
        Shadow(
            color: Color(0x33FFFFFF),
            offset: Offset(0, 1),
            blurRadius: 0), // debossed carve
      ],
    );

TextStyle toyBody(double size, ToyThemeDef t, {Color? color}) => TextStyle(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
      fontSize: size,
      color: color ?? t.text,
    );

/// Warm nursery backdrop with soft vignette.
class ToyBackdrop extends StatelessWidget {
  final ToyThemeDef theme;
  final Widget child;
  const ToyBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.paper,
        gradient: RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.4,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            theme.paper,
            theme.paperEdge.withValues(alpha: 0.55),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Chunky wooden button with a physical press.
class ToyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color; // button face; defaults to theme wood
  final Color? textColor;
  final double fontSize;
  final IconData? icon;
  final bool small;

  const ToyButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.textColor,
    this.fontSize = 18,
    this.icon,
    this.small = false,
  });

  @override
  State<ToyButton> createState() => _ToyButtonState();
}

class _ToyButtonState extends State<ToyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    // theme comes from an inherited lookup via ToyThemeScope below; fall back
    // to a neutral warm palette when absent (e.g. tests).
    final t = ToyThemeScope.of(context);
    final face = widget.color ?? t.wood;
    final bevel = t.woodDark;
    final h = widget.small ? 46.0 : 58.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: h,
        padding: EdgeInsets.symmetric(horizontal: widget.small ? 16 : 26),
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: bevel, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.45),
              offset: const Offset(0, 2),
              blurRadius: 0,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: bevel,
              offset: Offset(0, _down ? 1 : 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0x33853D14),
              offset: Offset(0, _down ? 3 : 8),
              blurRadius: _down ? 5 : 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon,
                  color: widget.textColor ?? Colors.white, size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                style: toyHeadline(widget.fontSize, t).copyWith(
                  color: widget.textColor ?? Colors.white,
                  shadows: const [
                    Shadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 1),
                        blurRadius: 0),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round wooden icon button (undo / hint / pause / settings …).
class ToyIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final Color? color;

  const ToyIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 56,
    this.color,
  });

  @override
  State<ToyIconButton> createState() => _ToyIconButtonState();
}

class _ToyIconButtonState extends State<ToyIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = ToyThemeScope.of(context);
    final face = widget.color ?? t.woodLight;
    return Tooltip(
      message: widget.tooltip ?? '',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: widget.size,
          height: widget.size,
          transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: face,
            border: Border.all(color: t.woodDark, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                offset: const Offset(0, 2),
                blurRadius: 0,
              ),
              BoxShadow(
                color: t.woodDark,
                offset: Offset(0, _down ? 1 : 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0x2E3D2614),
                offset: Offset(0, _down ? 2 : 6),
                blurRadius: _down ? 4 : 10,
              ),
            ],
          ),
          child: Icon(widget.icon, color: t.text, size: widget.size * 0.44),
        ),
      ),
    );
  }
}

/// Wooden plaque card.
class ToyCard extends StatelessWidget {
  final ToyThemeDef theme;
  final Widget child;
  final EdgeInsets padding;
  const ToyCard({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.woodDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
          const BoxShadow(
            color: Color(0x2E3D2614),
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Per-side player tray: color disc + name + claimed-box count.
/// The active tray raises and shows a wooden tag; a bot that is thinking or
/// drawing shows an animated crayon nib. Never silently auto-plays: every
/// seat's activity is visible right here.
class TrayStrip extends StatelessWidget {
  final ToyThemeDef theme;
  final List<String> names;
  final List<bool> isBot;
  final List<int> scores;
  final int activeSeat;
  final List<bool> seatBusy; // thinking/drawing animation per seat
  final void Function(int seat)? onEditName;

  const TrayStrip({
    super.key,
    required this.theme,
    required this.names,
    required this.isBot,
    required this.scores,
    required this.activeSeat,
    required this.seatBusy,
    this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < names.length; i++)
          _Tray(
            theme: theme,
            name: names[i],
            isBot: isBot[i],
            score: scores[i],
            color: theme.playerColor(i),
            deep: theme.playerDeep(i),
            active: i == activeSeat,
            busy: seatBusy[i],
            onEdit: onEditName == null ? null : () => onEditName!(i),
          ),
      ],
    );
  }
}

class _Tray extends StatelessWidget {
  final ToyThemeDef theme;
  final String name;
  final bool isBot;
  final int score;
  final Color color;
  final Color deep;
  final bool active;
  final bool busy;
  final VoidCallback? onEdit;

  const _Tray({
    required this.theme,
    required this.name,
    required this.isBot,
    required this.score,
    required this.color,
    required this.deep,
    required this.active,
    required this.busy,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? Colors.white.withValues(alpha: 0.5) : theme.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? color : theme.woodDark.withValues(alpha: 0.5),
          width: active ? 3 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    offset: const Offset(0, 4),
                    blurRadius: 8),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // crayon color disc
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.35),
                colors: [
                  Colors.white.withValues(alpha: 0.4),
                  color,
                  deep
                ],
              ),
              border: Border.all(color: theme.pegDeep, width: 1.5),
            ),
            child: busy
                ? const _ThinkingDots()
                : Center(
                    child: Text(
                      '$score',
                      style: toyBody(12, theme, color: Colors.white),
                    ),
                  ),
          ),
          const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: toyBody(13, theme),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isBot)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.smart_toy,
                          size: 13,
                          color: theme.text.withValues(alpha: 0.55)),
                    ),
                ],
              ),
              Text(
                '$score box${score == 1 ? '' : 'es'}',
                style: toyBody(11, theme,
                    color: theme.text.withValues(alpha: 0.6)),
              ),
            ],
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.edit,
                    size: 14, color: theme.text.withValues(alpha: 0.45)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Three bouncing dots for a busy (thinking/drawing) bot tray.
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 4,
              height: 4 + 4 * (0.5 + 0.5 * (i / 2 - _c.value).abs() * -1 + 1),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated wooden loading line (splash / progress).
class LoadingLine extends StatelessWidget {
  final ToyThemeDef theme;
  final Animation<double> progress;
  final double width;
  const LoadingLine({
    super.key,
    required this.theme,
    required this.progress,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, _) => Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: theme.pegDeep.withValues(alpha: 0.35),
            border: Border.all(color: theme.woodDark.withValues(alpha: 0.6)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.value.clamp(0.03, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: theme.wood,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section label carved into a small wooden tag.
class SectionLabel extends StatelessWidget {
  final ToyThemeDef theme;
  final String text;
  const SectionLabel({super.key, required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: theme.wood,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.woodDark, width: 1.5),
      ),
      child: Text(
        text,
        style: toyBody(12, theme, color: Colors.white),
      ),
    );
  }
}

/// Inherited theme scope so buttons deep in the tree can read the theme.
class ToyThemeScope extends InheritedWidget {
  final ToyThemeDef theme;
  const ToyThemeScope({super.key, required this.theme, required super.child});

  static ToyThemeDef of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ToyThemeScope>();
    return scope?.theme ?? ToyThemes.all.first;
  }

  @override
  bool updateShouldNotify(ToyThemeScope old) => old.theme != theme;
}
