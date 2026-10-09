import 'package:flutter/material.dart';

/// Theme, line-style and paper-accent catalog for Dots & Boxes.
///
/// Every theme stays inside the "children's wooden toy box" material world —
/// real wood, beeswax crayon, craft paper — the variety comes from different
/// woods, paper tints and crayon color families. No neon, no glow.
class ToyThemeDef {
  final String id;
  final String name;
  final bool pro;

  // Board surfaces
  final Color paper;
  final Color paperEdge;
  final Color channel; // routed (unclaimed) edge slot
  final Color speck; // paper fiber speck

  // Wooden pegs + buttons
  final Color pegLight;
  final Color pegMid;
  final Color pegDark;
  final Color pegDeep;
  final Color wood; // button base
  final Color woodDark; // bevel / border
  final Color woodLight; // top highlight

  // Text + scrims
  final Color text;
  final Color felt; // modal scrim

  // 4 player crayon colors + deep variants + names
  final List<Color> playerColors;
  final List<Color> playerDeeps;
  final List<String> playerColorNames;

  const ToyThemeDef({
    required this.id,
    required this.name,
    this.pro = false,
    required this.paper,
    required this.paperEdge,
    required this.channel,
    required this.speck,
    required this.pegLight,
    required this.pegMid,
    required this.pegDark,
    required this.pegDeep,
    required this.wood,
    required this.woodDark,
    required this.woodLight,
    required this.text,
    required this.felt,
    required this.playerColors,
    required this.playerDeeps,
    required this.playerColorNames,
  });

  Color playerColor(int i) => playerColors[i % playerColors.length];
  Color playerDeep(int i) => playerDeeps[i % playerDeeps.length];
  String playerColorName(int i) =>
      playerColorNames[i % playerColorNames.length];
}

class ToyThemes {
  /// First 4 are FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'maple',
    'cherrywood',
    'seaside',
  ];

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';

  static const List<ToyThemeDef> all = [
    ToyThemeDef(
      id: 'classic',
      name: 'Classic Toybox',
      paper: Color(0xFFFBF6ED),
      paperEdge: Color(0xFFE4D6BD),
      channel: Color(0xFFEADCC8),
      speck: Color(0x1A5C3A21),
      pegLight: Color(0xFFB07B45),
      pegMid: Color(0xFF8B5A2B),
      pegDark: Color(0xFF5C3A21),
      pegDeep: Color(0xFF3D2614),
      wood: Color(0xFFE5A93C),
      woodDark: Color(0xFF8B5A2B),
      woodLight: Color(0xFFF7DEA8),
      text: Color(0xFF2F1502),
      felt: Color(0x663D2614),
      playerColors: [
        Color(0xFFE24A4A),
        Color(0xFF3B9FE2),
        Color(0xFF7CB342),
        Color(0xFFE8A93C),
      ],
      playerDeeps: [
        Color(0xFFB3272D),
        Color(0xFF006496),
        Color(0xFF558B2F),
        Color(0xFFB57A1F),
      ],
      playerColorNames: ['Cherry', 'Sky', 'Leaf', 'Honey'],
    ),
    ToyThemeDef(
      id: 'maple',
      name: 'Maple Morning',
      paper: Color(0xFFFFFBF3),
      paperEdge: Color(0xFFEBDFC6),
      channel: Color(0xFFF0E4CE),
      speck: Color(0x1A8B5A2B),
      pegLight: Color(0xFFD9A862),
      pegMid: Color(0xFFB07B45),
      pegDark: Color(0xFF7A4E24),
      pegDeep: Color(0xFF4A2E14),
      wood: Color(0xFFF0BE55),
      woodDark: Color(0xFF9A6A2E),
      woodLight: Color(0xFFFFEBBE),
      text: Color(0xFF3A2208),
      felt: Color(0x664A2E14),
      playerColors: [
        Color(0xFFD94F4F),
        Color(0xFF4FA3DC),
        Color(0xFF8FC25A),
        Color(0xFFD98A2B),
      ],
      playerDeeps: [
        Color(0xFFA83232),
        Color(0xFF2B6E9E),
        Color(0xFF5E8A35),
        Color(0xFF9E5F1A),
      ],
      playerColorNames: ['Apple', 'Rain', 'Sprout', 'Amber'],
    ),
    ToyThemeDef(
      id: 'cherrywood',
      name: 'Cherry Orchard',
      paper: Color(0xFFF9EFE4),
      paperEdge: Color(0xFFE6CDB4),
      channel: Color(0xFFEAD2B8),
      speck: Color(0x1A6E2F1C),
      pegLight: Color(0xFF9C5A3A),
      pegMid: Color(0xFF7A3F24),
      pegDark: Color(0xFF552712),
      pegDeep: Color(0xFF381808),
      wood: Color(0xFFD98A5A),
      woodDark: Color(0xFF6E2F1C),
      woodLight: Color(0xFFF3C49A),
      text: Color(0xFF331507),
      felt: Color(0x66552112),
      playerColors: [
        Color(0xFFC94F5E),
        Color(0xFF5AA3C9),
        Color(0xFF86A94B),
        Color(0xFFD9A03C),
      ],
      playerDeeps: [
        Color(0xFF96323E),
        Color(0xFF386E8A),
        Color(0xFF5C7430),
        Color(0xFF9C6E22),
      ],
      playerColorNames: ['Berry', 'Brook', 'Moss', 'Wheat'],
    ),
    ToyThemeDef(
      id: 'seaside',
      name: 'Seaside Cottage',
      paper: Color(0xFFF4F1E6),
      paperEdge: Color(0xFFD9D2B8),
      channel: Color(0xFFE3DCC4),
      speck: Color(0x1A3E5A66),
      pegLight: Color(0xFFB98A5E),
      pegMid: Color(0xFF8A5F3A),
      pegDark: Color(0xFF5E3F22),
      pegDeep: Color(0xFF3A2512),
      wood: Color(0xFF6FB3C9),
      woodDark: Color(0xFF3E6E80),
      woodLight: Color(0xFFBCE0EA),
      text: Color(0xFF1E2E35),
      felt: Color(0x663A4A52),
      playerColors: [
        Color(0xFFE2604F),
        Color(0xFF2E8FB8),
        Color(0xFF7FB069),
        Color(0xFFE8B93C),
      ],
      playerDeeps: [
        Color(0xFFA83E30),
        Color(0xFF1C5F7A),
        Color(0xFF557A44),
        Color(0xFFA8821F),
      ],
      playerColorNames: ['Coral', 'Harbor', 'Kelp', 'Sand'],
    ),
    ToyThemeDef(
      id: 'forest',
      name: 'Forest Cabin',
      pro: true,
      paper: Color(0xFFF3EEDF),
      paperEdge: Color(0xFFD5C9A6),
      channel: Color(0xFFE2D7B8),
      speck: Color(0x1A2E3B22),
      pegLight: Color(0xFF8A6A42),
      pegMid: Color(0xFF5E482A),
      pegDark: Color(0xFF3E2F18),
      pegDeep: Color(0xFF241B0C),
      wood: Color(0xFF7A9A55),
      woodDark: Color(0xFF4A5A34),
      woodLight: Color(0xFFBFD49A),
      text: Color(0xFF1F2A12),
      felt: Color(0x662E3B22),
      playerColors: [
        Color(0xFFC9574F),
        Color(0xFF5A93C9),
        Color(0xFFE0A83C),
        Color(0xFF8E6BB8),
      ],
      playerDeeps: [
        Color(0xFF8F3833),
        Color(0xFF38638A),
        Color(0xFF9E7522),
        Color(0xFF624781),
      ],
      playerColorNames: ['Fox', 'Jay', 'Acorn', 'Violet'],
    ),
    ToyThemeDef(
      id: 'desert',
      name: 'Desert Market',
      pro: true,
      paper: Color(0xFFFBEEDC),
      paperEdge: Color(0xFFE8CFA8),
      channel: Color(0xFFF0DCBC),
      speck: Color(0x1A8A5A2E),
      pegLight: Color(0xFFC08A4E),
      pegMid: Color(0xFF96622E),
      pegDark: Color(0xFF6B431C),
      pegDeep: Color(0xFF452A10),
      wood: Color(0xFFD98A3C),
      woodDark: Color(0xFF8A4E1C),
      woodLight: Color(0xFFF5C489),
      text: Color(0xFF3A2208),
      felt: Color(0x66523118),
      playerColors: [
        Color(0xFFC94F4F),
        Color(0xFF3E9AB8),
        Color(0xFF8FB04B),
        Color(0xFF7A5FC9),
      ],
      playerDeeps: [
        Color(0xFF8F3232),
        Color(0xFF27677D),
        Color(0xFF5F7530),
        Color(0xFF524088),
      ],
      playerColorNames: ['Chili', 'Oasis', 'Cactus', 'Dusk'],
    ),
    ToyThemeDef(
      id: 'midnight',
      name: 'Midnight Nursery',
      pro: true,
      paper: Color(0xFF2E2A38),
      paperEdge: Color(0xFF1C1A26),
      channel: Color(0xFF45405A),
      speck: Color(0x22C0C6D4),
      pegLight: Color(0xFF9A8FB8),
      pegMid: Color(0xFF6E6390),
      pegDark: Color(0xFF4A4270),
      pegDeep: Color(0xFF2E2948),
      wood: Color(0xFFE0A83C),
      woodDark: Color(0xFF8A6420),
      woodLight: Color(0xFFF5D98A),
      text: Color(0xFFF2EEE4),
      felt: Color(0xAA141220),
      playerColors: [
        Color(0xFFE2605A),
        Color(0xFF5AB0E0),
        Color(0xFF9ACD6A),
        Color(0xFFF0C84F),
      ],
      playerDeeps: [
        Color(0xFFA83E38),
        Color(0xFF36799E),
        Color(0xFF678F44),
        Color(0xFFA8872A),
      ],
      playerColorNames: ['Ember', 'Moon', 'Firefly', 'Star'],
    ),
    ToyThemeDef(
      id: 'berry',
      name: 'Berry Jam',
      pro: true,
      paper: Color(0xFFF9EDF0),
      paperEdge: Color(0xFFE5C6D2),
      channel: Color(0xFFEED8E2),
      speck: Color(0x1A7A2E4A),
      pegLight: Color(0xFFA86A72),
      pegMid: Color(0xFF7E4852),
      pegDark: Color(0xFF552E36),
      pegDeep: Color(0xFF371B22),
      wood: Color(0xFFC9577A),
      woodDark: Color(0xFF7A2E4A),
      woodLight: Color(0xFFEDA9BE),
      text: Color(0xFF3A1420),
      felt: Color(0x66552E36),
      playerColors: [
        Color(0xFFB83E5A),
        Color(0xFF4FA3DC),
        Color(0xFF7CB342),
        Color(0xFFE8A93C),
      ],
      playerDeeps: [
        Color(0xFF82263C),
        Color(0xFF2B6E9E),
        Color(0xFF558B2F),
        Color(0xFFB57A1F),
      ],
      playerColorNames: ['Jam', 'Frost', 'Pip', 'Custard'],
    ),
    ToyThemeDef(
      id: 'mint',
      name: 'Mint Parlor',
      pro: true,
      paper: Color(0xFFEFF6F0),
      paperEdge: Color(0xFFC6DCC8),
      channel: Color(0xFFD8E8DA),
      speck: Color(0x1A2E5A44),
      pegLight: Color(0xFF9AB892),
      pegMid: Color(0xFF6E8F66),
      pegDark: Color(0xFF4A6644),
      pegDeep: Color(0xFF2E442A),
      wood: Color(0xFF7FB069),
      woodDark: Color(0xFF4A6644),
      woodLight: Color(0xFFC2DDAE),
      text: Color(0xFF1A2E1A),
      felt: Color(0x664A6644),
      playerColors: [
        Color(0xFFE2604F),
        Color(0xFF3E9AB8),
        Color(0xFFD9A03C),
        Color(0xFF9A6BC9),
      ],
      playerDeeps: [
        Color(0xFFA83E30),
        Color(0xFF27677D),
        Color(0xFF9C6E22),
        Color(0xFF68468F),
      ],
      playerColorNames: ['Punch', 'Glacier', 'Butter', 'Lilac'],
    ),
    ToyThemeDef(
      id: 'autumn',
      name: 'Autumn Fair',
      pro: true,
      paper: Color(0xFFFAF0E2),
      paperEdge: Color(0xFFE4CDA4),
      channel: Color(0xFFEEDCBE),
      speck: Color(0x1A7A4A1E),
      pegLight: Color(0xFFB87A3E),
      pegMid: Color(0xFF8E5524),
      pegDark: Color(0xFF623812),
      pegDeep: Color(0xFF3E220A),
      wood: Color(0xFFC97B2E),
      woodDark: Color(0xFF7A4514),
      woodLight: Color(0xFFEFB878),
      text: Color(0xFF33200A),
      felt: Color(0x66623812),
      playerColors: [
        Color(0xFFB8452E),
        Color(0xFF4F8FC9),
        Color(0xFF7CA845),
        Color(0xFF8E6BB8),
      ],
      playerDeeps: [
        Color(0xFF7E2C1C),
        Color(0xFF33638F),
        Color(0xFF54732E),
        Color(0xFF624781),
      ],
      playerColorNames: ['Rust', 'Denim', 'Hay', 'Plum'],
    ),
    ToyThemeDef(
      id: 'cocoa',
      name: 'Cocoa House',
      pro: true,
      paper: Color(0xFFF4EADC),
      paperEdge: Color(0xFFDBC6A8),
      channel: Color(0xFFE6D4B8),
      speck: Color(0x1A4A2E14),
      pegLight: Color(0xFF7A5232),
      pegMid: Color(0xFF5A3A22),
      pegDark: Color(0xFF3C2514),
      pegDeep: Color(0xFF241408),
      wood: Color(0xFF9A6A3E),
      woodDark: Color(0xFF5A3A22),
      woodLight: Color(0xFFD9A878),
      text: Color(0xFF2A180A),
      felt: Color(0x663C2514),
      playerColors: [
        Color(0xFFD96A5A),
        Color(0xFF6AB0D9),
        Color(0xFF9ACD6A),
        Color(0xFFF0C84F),
      ],
      playerDeeps: [
        Color(0xFF9E4438),
        Color(0xFF437A9E),
        Color(0xFF678F44),
        Color(0xFFA8872A),
      ],
      playerColorNames: ['Caramel', 'Milk', 'Pistachio', 'Toffee'],
    ),
    ToyThemeDef(
      id: 'snowday',
      name: 'Snow Day',
      pro: true,
      paper: Color(0xFFF2F4F6),
      paperEdge: Color(0xFFD2D9E0),
      channel: Color(0xFFE0E6EC),
      speck: Color(0x1A3E5A7A),
      pegLight: Color(0xFFB89A6A),
      pegMid: Color(0xFF8E7048),
      pegDark: Color(0xFF624A2E),
      pegDeep: Color(0xFF3E2E1A),
      wood: Color(0xFF5A8FB8),
      woodDark: Color(0xFF34586E),
      woodLight: Color(0xFFA9CDE8),
      text: Color(0xFF1E2E3A),
      felt: Color(0x66344858),
      playerColors: [
        Color(0xFFD94F4F),
        Color(0xFF2E7FB8),
        Color(0xFF6AA84F),
        Color(0xFFE8A93C),
      ],
      playerDeeps: [
        Color(0xFF9E3232),
        Color(0xFF1C557A),
        Color(0xFF467433),
        Color(0xFFB57A1F),
      ],
      playerColorNames: ['Sled', 'Glacier', 'Pine', 'Lantern'],
    ),
  ];

  static ToyThemeDef byId(String id, {ToyThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

// ---------------------------------------------------------------------------
// Line (pencil) styles — how claimed edges are drawn.
// First 4 FREE, rest PRO.
// ---------------------------------------------------------------------------

class LineStyleDef {
  final int id;
  final String name;
  final bool pro;
  final double widthFactor; // relative to spacing
  final double wobble; // hand-wobble amplitude in px
  final int passes; // texture passes
  final double sheen; // white sheen alpha
  final double speckles; // texture speckle count
  final bool soft; // chalk-like soft edges

  const LineStyleDef({
    required this.id,
    required this.name,
    this.pro = false,
    required this.widthFactor,
    required this.wobble,
    required this.passes,
    required this.sheen,
    required this.speckles,
    this.soft = false,
  });
}

class LineStyles {
  static const List<LineStyleDef> all = [
    LineStyleDef(
      id: 0,
      name: 'Beeswax Crayon',
      widthFactor: 0.20,
      wobble: 2.6,
      passes: 1,
      sheen: 0.16,
      speckles: 10,
    ),
    LineStyleDef(
      id: 1,
      name: 'Colored Pencil',
      widthFactor: 0.11,
      wobble: 1.2,
      passes: 2,
      sheen: 0.05,
      speckles: 4,
    ),
    LineStyleDef(
      id: 2,
      name: 'Wax Marker',
      widthFactor: 0.26,
      wobble: 0.8,
      passes: 1,
      sheen: 0.08,
      speckles: 2,
    ),
    LineStyleDef(
      id: 3,
      name: 'Sidewalk Chalk',
      widthFactor: 0.24,
      wobble: 3.4,
      passes: 2,
      sheen: 0.22,
      speckles: 22,
      soft: true,
    ),
    LineStyleDef(
      id: 4,
      name: 'Gel Pen',
      pro: true,
      widthFactor: 0.10,
      wobble: 0.5,
      passes: 1,
      sheen: 0.35,
      speckles: 0,
    ),
    LineStyleDef(
      id: 5,
      name: 'Paint Brush',
      pro: true,
      widthFactor: 0.30,
      wobble: 2.0,
      passes: 2,
      sheen: 0.10,
      speckles: 14,
    ),
    LineStyleDef(
      id: 6,
      name: 'Felt Tip',
      pro: true,
      widthFactor: 0.22,
      wobble: 0.6,
      passes: 1,
      sheen: 0.0,
      speckles: 6,
    ),
    LineStyleDef(
      id: 7,
      name: 'Charcoal',
      pro: true,
      widthFactor: 0.18,
      wobble: 4.5,
      passes: 3,
      sheen: 0.05,
      speckles: 26,
      soft: true,
    ),
  ];

  static bool isPro(int id) =>
      id >= 0 && id < all.length && all[id].pro;

  static LineStyleDef byId(int id) {
    if (id < 0 || id >= all.length) return all.first;
    return all[id];
  }

  static List<String> get names => [for (final s in all) s.name];
}

// ---------------------------------------------------------------------------
// Paper accents — board background treatments. First 3 FREE, rest PRO.
// ---------------------------------------------------------------------------

class PaperAccentDef {
  final int id;
  final String name;
  final bool pro;
  const PaperAccentDef({required this.id, required this.name, this.pro = false});
}

class PaperAccents {
  static const List<PaperAccentDef> all = [
    PaperAccentDef(id: 0, name: 'Craft Paper'),
    PaperAccentDef(id: 1, name: 'Linen Cloth'),
    PaperAccentDef(id: 2, name: 'Recycled Kraft'),
    PaperAccentDef(id: 3, name: 'Felt Mat', pro: true),
    PaperAccentDef(id: 4, name: 'Denim', pro: true),
    PaperAccentDef(id: 5, name: 'Cork Board', pro: true),
  ];

  static bool isPro(int id) => id >= 0 && id < all.length && all[id].pro;

  static PaperAccentDef byId(int id) {
    if (id < 0 || id >= all.length) return all.first;
    return all[id];
  }

  static List<String> get names => [for (final a in all) a.name];
}
