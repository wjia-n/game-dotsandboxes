import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/toybox_themes.dart';
import '../toybox/widgets.dart';
import '../transfer/transfer_ui.dart';

/// Settings: sound/music/volume, player names (4 renameable slots),
/// board size, vibration, stats reset.
class SettingsScreen extends StatelessWidget {
  final ToyboxAudio audio;
  final ToyboxSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  ToyThemeDef get _t => settings.theme;

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
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              TransferSaveTile(gameSlug: 'dotsandboxes'),
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
                      Text('Settings', style: toyHeadline(26, t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ToyCard(
                    theme: t,
                    child: Column(
                      children: [
                        _ToggleRow(
                          theme: t,
                          label: 'Music',
                          value: s.musicOn,
                          onChanged: (v) {
                            s.setMusic(v);
                            if (v) {
                              audio.startMenuMusic();
                            } else {
                              audio.stopMusic();
                            }
                          },
                        ),
                        _ToggleRow(
                          theme: t,
                          label: 'Sound effects',
                          value: s.sfxOn,
                          onChanged: (v) {
                            s.setSfx(v);
                            if (v) audio.click();
                          },
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.volume_up,
                                color: t.text.withValues(alpha: 0.7)),
                            Expanded(
                              child: Slider(
                                value: s.volume,
                                onChanged: (v) {
                                  s.setVolume(v);
                                  audio.configure(
                                    musicOn: s.musicOn,
                                    sfxOn: s.sfxOn,
                                    volume: v,
                                  );
                                },
                                onChangeEnd: (_) => audio.click(),
                              ),
                            ),
                          ],
                        ),
                        _ToggleRow(
                          theme: t,
                          label: 'Vibration',
                          value: s.vibrationOn,
                          onChanged: s.setVibration,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ToyCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child:
                                SectionLabel(theme: t, text: 'PLAYER NAMES')),
                        const SizedBox(height: 10),
                        for (var i = 0; i < 4; i++)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: t.playerColor(i),
                                    border: Border.all(
                                        color: t.pegDeep, width: 1.5),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _NameField(
                                    key: ValueKey('name_$i'),
                                    theme: t,
                                    index: i,
                                    initial: s.playerNames[i],
                                    onChanged: (v) => s.setPlayerName(i, v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Center(
                          child: Text(
                            'Names are used for every seat, in every mode.',
                            style: toyBody(12, t,
                                color:
                                    t.text.withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ToyCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                            child: SectionLabel(
                                theme: t, text: 'SCORES')),
                        const SizedBox(height: 10),
                        Text(
                            'Wins ${s.wins} · Losses ${s.losses} · Ties ${s.ties} · Games ${s.gamesPlayed}',
                            style: toyBody(15, t)),
                        const SizedBox(height: 12),
                        Center(
                          child: ToyButton(
                            label: 'Reset scores',
                            small: true,
                            onTap: () {
                              audio.click();
                              s.resetStats();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ToyButton(
                      label: 'Done',
                      color: const Color(0xFF3B9FE2),
                      onTap: () {
                        audio.click();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final ToyThemeDef theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label, style: toyBody(16, theme))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: theme.wood,
        ),
      ],
    );
  }
}

/// Player-name rename field: saves on every keystroke AND on focus loss
/// (tapping elsewhere) AND on keyboard-done, so a rename is never lost.
/// The controller lives in state so rebuilds from [onChanged] saves don't
/// jump the cursor.
class _NameField extends StatefulWidget {
  final ToyThemeDef theme;
  final int index;
  final String initial;
  final ValueChanged<String> onChanged;
  const _NameField({
    super.key,
    required this.theme,
    required this.index,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial)
      ..selection = TextSelection.collapsed(offset: widget.initial.length);
  }

  @override
  void didUpdateWidget(covariant _NameField old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _commit() => widget.onChanged(_c.text);

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _commit(); // tap elsewhere commits the rename
      },
      child: TextField(
        controller: _c,
        maxLength: 16,
        style: toyBody(15, t),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.woodDark),
          ),
        ),
        onChanged: (_) => _commit(), // save on every keystroke
        onSubmitted: (_) => _commit(), // keyboard-done commits too
      ),
    );
  }
}
