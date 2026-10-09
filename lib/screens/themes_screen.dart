import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/toybox_themes.dart';
import '../toybox/widgets.dart';
import 'custom_theme_screen.dart';
import 'pro_screen.dart';

/// Theme picker: 12+ wooden-toy themes, 8+ line styles, 6 paper accents,
/// plus the custom theme creator. Pro items show a lock and open Pro.
class ThemesScreen extends StatelessWidget {
  final ToyboxAudio audio;
  final ToyboxSettings settings;
  final StoreService store;
  const ThemesScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  ToyThemeDef get _t => settings.theme;

  void _goPro(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
            audio: audio, settings: settings, store: store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = settings;
    return Scaffold(
      body: ToyBackdrop(
        theme: t,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ToyIconButton(
                        icon: Icons.arrow_back,
                        size: 44,
                        onTap: () {
                          audio.click();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 12),
                      Text('Toybox Themes', style: toyHeadline(24, t)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                      child: SectionLabel(
                          theme: t, text: 'BOARD THEMES')),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: ToyThemes.all.length + 1, // + custom
                    itemBuilder: (_, i) {
                      if (i == ToyThemes.all.length) {
                        return _ThemeTile(
                          theme: t,
                          name: 'My Creation',
                          swatch: s.customTheme.playerColors,
                          paper: s.customTheme.paper,
                          locked: false,
                          selected: s.themeId == 'custom',
                          onTap: () {
                            audio.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomThemeScreen(
                                    audio: audio, settings: s),
                              ),
                            );
                          },
                        );
                      }
                      final th = ToyThemes.all[i];
                      final locked =
                          !s.isPro && ToyThemes.isProTheme(th.id);
                      return _ThemeTile(
                        theme: t,
                        name: th.name,
                        swatch: th.playerColors,
                        paper: th.paper,
                        locked: locked,
                        selected: s.themeId == th.id,
                        onTap: () {
                          audio.click();
                          if (locked) {
                            _goPro(context);
                          } else {
                            s.setTheme(th.id);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Center(
                      child:
                          SectionLabel(theme: t, text: 'LINE STYLES')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final ls in LineStyles.all)
                        _Chip(
                          theme: t,
                          label:
                              '${ls.name}${!s.isPro && ls.pro ? ' 🔒' : ''}',
                          selected: s.lineStyle == ls.id,
                          onTap: () {
                            audio.click();
                            if (!s.isPro && ls.pro) {
                              _goPro(context);
                            } else {
                              s.setLineStyle(ls.id);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                      child: SectionLabel(
                          theme: t, text: 'PAPER ACCENTS')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final pa in PaperAccents.all)
                        _Chip(
                          theme: t,
                          label:
                              '${pa.name}${!s.isPro && pa.pro ? ' 🔒' : ''}',
                          selected: s.paperAccent == pa.id,
                          onTap: () {
                            audio.click();
                            if (!s.isPro && pa.pro) {
                              _goPro(context);
                            } else {
                              s.setPaperAccent(pa.id);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ToyThemeDef theme;
  final String name;
  final List<Color> swatch;
  final Color paper;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.theme,
    required this.name,
    required this.swatch,
    required this.paper,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? theme.wood : theme.woodDark.withValues(alpha: 0.5),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: theme.woodDark.withValues(alpha: 0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 8)
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4 && i < swatch.length; i++)
                      Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: swatch[i],
                          border: Border.all(
                              color: theme.pegDeep, width: 1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    name,
                    style: toyBody(11, theme),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (locked)
              Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.lock,
                    size: 16,
                    color: theme.text.withValues(alpha: 0.55)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final ToyThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.wood : theme.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.woodDark, width: selected ? 2.5 : 1.5),
        ),
        child: Text(
          label,
          style: toyBody(13, theme,
              color: selected ? Colors.white : null),
        ),
      ),
    );
  }
}
