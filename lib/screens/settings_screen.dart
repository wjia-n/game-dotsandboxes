import 'package:flutter/material.dart';

import '../engine/audio.dart';
import '../engine/dots_boxes_engine.dart';
import '../state/settings_store.dart';
import '../toybox/palette.dart';
import '../toybox/wood_widgets.dart';

/// Settings: painted title, wooden cards for sound/music/board/robot/vibration,
/// volume sliders, reset-scores tag, Done button.
class SettingsScreen extends StatelessWidget {
  final SettingsStore settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ToyPalette.paper,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (_, _) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Text('Settings', style: ToyType.h1)),
                const SizedBox(height: 18),
                _Card(
                  title: 'Sound',
                  child: _ToggleRow(
                    value: settings.sfxOn,
                    onChanged: (v) {
                      settings.setSfx(v);
                      ToyAudio.instance.sfx('click.wav');
                    },
                  ),
                ),
                _Card(
                  title: 'Music',
                  child: Column(
                    children: [
                      _ToggleRow(
                        value: settings.musicOn,
                        onChanged: settings.setMusic,
                      ),
                      _VolumeRow(
                        icon: Icons.music_note,
                        value: settings.musicVolume,
                        onChanged: settings.setMusicVolume,
                      ),
                    ],
                  ),
                ),
                _Card(
                  title: 'Effects volume',
                  child: _VolumeRow(
                    icon: Icons.volume_up,
                    value: settings.sfxVolume,
                    onChanged: (v) {
                      settings.setSfxVolume(v);
                      ToyAudio.instance.sfx('click.wav');
                    },
                  ),
                ),
                _Card(
                  title: 'Board size',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [5, 6, 7].map((d) {
                      final selected = settings.boardDots == d;
                      return GestureDetector(
                        onTap: () {
                          ToyAudio.instance.sfx('click.wav');
                          settings.setBoardDots(d);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: Matrix4.translationValues(0, selected ? 3.0 : 0.0, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? ToyPalette.honey : ToyPalette.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ToyPalette.oak, width: 2),
                            boxShadow:
                                selected ? ToyPalette.pressedShadow() : ToyPalette.plaqueShadow(),
                          ),
                          child: Text(
                            '${d}x$d',
                            style: ToyType.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : ToyPalette.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                _Card(
                  title: 'Robot difficulty',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: Difficulty.values.map((d) {
                      final selected = settings.difficulty == d;
                      final label = switch (d) {
                        Difficulty.easy => 'Easy',
                        Difficulty.medium => 'Medium',
                        Difficulty.hard => 'Hard',
                      };
                      return GestureDetector(
                        onTap: () {
                          ToyAudio.instance.sfx('click.wav');
                          settings.setDifficulty(d);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: Matrix4.translationValues(0, selected ? 3.0 : 0.0, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? ToyPalette.blue : ToyPalette.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ToyPalette.oak, width: 2),
                            boxShadow:
                                selected ? ToyPalette.pressedShadow() : ToyPalette.plaqueShadow(),
                          ),
                          child: Text(
                            label,
                            style: ToyType.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : ToyPalette.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                _Card(
                  title: 'Vibration',
                  child: _ToggleRow(
                    value: settings.vibrationOn,
                    onChanged: settings.setVibration,
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      ToyAudio.instance.sfx('invalid.wav');
                      settings.resetScores();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Scores cleared', style: ToyType.bodyMd),
                          backgroundColor: ToyPalette.walnut,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: ToyPalette.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ToyPalette.walnut, width: 2),
                        boxShadow: ToyPalette.plaqueShadow(),
                      ),
                      child: Text('Reset scores', style: ToyType.label),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Played ${settings.gamesPlayed} · Won ${settings.wins} · '
                    'Lost ${settings.losses} · Tied ${settings.ties}',
                    style: ToyType.bodySm,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: WoodButton(
                    label: 'Done',
                    width: 220,
                    height: 56,
                    icon: Icons.check,
                    onTap: () => Navigator.of(context).pop(),
                    color: ToyPalette.blue,
                    bevel: ToyPalette.blueDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: ToyPalette.maple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ToyPalette.oak, width: 2),
        boxShadow: ToyPalette.plaqueShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ToyType.h3.copyWith(fontSize: 17)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Chunky wooden ON/OFF toggle.
class _ToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 64,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? ToyPalette.leaf : ToyPalette.channel,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: ToyPalette.walnut, width: 2),
              boxShadow: ToyPalette.pressedShadow(),
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.35, -0.4),
                  colors: [Color(0xFFB07B45), ToyPalette.walnut],
                ),
                border: Border.all(color: ToyPalette.walnutDeep, width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(value ? 'ON' : 'OFF', style: ToyType.bodyLg),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  const _VolumeRow({required this.icon, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: ToyPalette.walnut),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ToyPalette.honey,
              inactiveTrackColor: ToyPalette.channel,
              thumbColor: ToyPalette.walnut,
              overlayColor: ToyPalette.honey.withValues(alpha: 0.2),
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
