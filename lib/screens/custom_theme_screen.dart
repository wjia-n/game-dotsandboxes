import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/toybox_themes.dart';
import '../toybox/widgets.dart';

/// Custom theme creator: pick paper, wood, peg and crayon colors.
/// Saved persistently and usable as the 'custom' theme.
class CustomThemeScreen extends StatelessWidget {
  final ToyboxAudio audio;
  final ToyboxSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  ToyThemeDef get _t => settings.theme;

  static const _fields = [
    ('paper', 'Paper'),
    ('channel', 'Line slots'),
    ('wood', 'Buttons'),
    ('woodDark', 'Wood trim'),
    ('peg', 'Peg dots'),
    ('text', 'Text ink'),
    ('pc0', 'Crayon 1'),
    ('pc1', 'Crayon 2'),
    ('pc2', 'Crayon 3'),
    ('pc3', 'Crayon 4'),
  ];

  static const _palette = [
    0xFFE24A4A,
    0xFF3B9FE2,
    0xFF7CB342,
    0xFFE8A93C,
    0xFF9A6BC9,
    0xFF5C3A21,
    0xFF8B5A2B,
    0xFFFBF6ED,
    0xFFEADCC8,
    0xFF2F1502,
    0xFF6FB3C9,
    0xFFC9577A,
    0xFF1E2E35,
    0xFFF2F4F6,
    0xFFB8452E,
    0xFFD9A03C,
  ];

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
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      Text('My Creation', style: toyHeadline(24, t)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Design your own toybox — every color is yours.',
                      style: toyBody(13, t,
                          color: t.text.withValues(alpha: 0.65)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final (key, label) in _fields)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: toyBody(14, t)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final argb in _palette)
                                GestureDetector(
                                  onTap: () {
                                    audio.click();
                                    s.setCustomColor(key, argb);
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(argb),
                                      border: Border.all(
                                        color: s.customColors[key] ==
                                                argb
                                            ? t.woodDark
                                            : t.woodDark.withValues(
                                                alpha: 0.3),
                                        width: s.customColors[key] ==
                                                argb
                                            ? 3
                                            : 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ToyButton(
                        label: 'Reset',
                        small: true,
                        onTap: () {
                          audio.click();
                          s.resetCustomColors();
                        },
                      ),
                      const SizedBox(width: 12),
                      ToyButton(
                        label: 'Use this theme',
                        small: true,
                        color: const Color(0xFF7CB342),
                        onTap: () {
                          audio.click();
                          s.setTheme('custom');
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
