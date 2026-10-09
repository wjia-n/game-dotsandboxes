import 'package:flutter/material.dart';

/// "Artisan Playboard" design tokens — children's wooden toy box.
/// Source of truth: stitch-batch4/dotsandboxes/DESIGN.md.
abstract final class ToyPalette {
  // ---- Surfaces ----
  static const paper = Color(0xFFFBF6ED); // craft paper / felt base
  static const maple = Color(0xFFF4ECE0); // birch plaque
  static const channel = Color(0xFFEADCC8); // routed (unclaimed) edge slot
  static const ink = Color(0xFF2F1502); // warm brown text

  // ---- Woods ----
  static const walnut = Color(0xFF5C3A21);
  static const walnutDeep = Color(0xFF3D2614);
  static const oak = Color(0xFF8B5A2B);

  // ---- Brand ----
  static const honey = Color(0xFFE5A93C); // primary amber
  static const honeyDeep = Color(0xFFB57A1F);
  static const leaf = Color(0xFF7CB342); // affirmative green
  static const leafDeep = Color(0xFF558B2F);
  static const gold = Color(0xFFE8B93C); // victory star

  // ---- Players ----
  static const red = Color(0xFFE24A4A); // P1 crayon
  static const redDeep = Color(0xFFB3272D);
  static const blue = Color(0xFF3B9FE2); // P2 crayon
  static const blueDeep = Color(0xFF006496);

  static const scrim = Color(0x663D2614); // felt scrim 40%

  // ---- Shadows (warm top-down nursery daylight) ----
  static List<BoxShadow> buttonShadow() => const [
        BoxShadow(
          color: Color(0x33853D14),
          offset: Offset(0, 8),
          blurRadius: 12,
        ),
      ];
  static List<BoxShadow> pressedShadow() => const [
        BoxShadow(
          color: Color(0x22853D14),
          offset: Offset(0, 2),
          blurRadius: 5,
        ),
      ];
  static List<BoxShadow> plaqueShadow() => const [
        BoxShadow(
          color: Color(0x2E3D2614),
          offset: Offset(0, 6),
          blurRadius: 10,
        ),
      ];
}

/// Typography: Comfortaa 700 headlines, Quicksand 500/600 body.
abstract final class ToyType {
  static const headline = TextStyle(
    fontFamily: 'Comfortaa',
    fontWeight: FontWeight.w700,
    color: ToyPalette.ink,
  );
  static const body = TextStyle(
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w500,
    color: ToyPalette.ink,
  );

  static TextStyle get h1 => headline.copyWith(fontSize: 32, height: 1.25);
  static TextStyle get h2 => headline.copyWith(fontSize: 26, height: 1.3);
  static TextStyle get h3 => headline.copyWith(fontSize: 20, height: 1.35);
  static TextStyle get bodyLg => body.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle get bodyMd => body.copyWith(fontSize: 16);
  static TextStyle get bodySm => body.copyWith(fontSize: 14);
  static TextStyle get label => body.copyWith(fontSize: 13, fontWeight: FontWeight.w600);
  static TextStyle get buttonLabel => headline.copyWith(fontSize: 18, color: Colors.white);
  static TextStyle get buttonLabelDark => headline.copyWith(fontSize: 18, color: ToyPalette.ink);
}
