import 'package:dotsandboxes/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the player-name persistence bug (2026-10-09):
///
/// Player names were stored with SharedPreferences.setStringList, which on
/// Android is backed by an UNORDERED StringSet — so after an app restart the
/// four names came back in arbitrary order and renames appeared "not saved".
/// Names are now stored as one order-preserving JSON string under
/// 'dotsandboxes_player_names_json', with a one-time migration from the
/// legacy key. These tests cover the encode/decode round-trip plus the
/// "restart" reload path, without needing platform channels.
void main() {
  test('names survive an encode/decode round-trip in exact slot order', () {
    const names = ['Wajiha', 'Zara', 'Ali', 'Bot Bob'];
    final decoded = ToyboxSettings.decodePlayerNames(
      ToyboxSettings.encodePlayerNames(names),
    );
    expect(decoded, names);
    // Slot order is what matters: each index must map to the same player.
    for (int i = 0; i < 4; i++) {
      expect(decoded[i], names[i]);
    }
  });

  test('encoded payload is a single JSON string, not a StringList', () {
    const names = ['You', 'Robot', 'Player 3', 'Player 4'];
    final raw = ToyboxSettings.encodePlayerNames(names);
    expect(raw, isA<String>());
    // A StringList-backed unordered store could never produce this; the
    // JSON array preserves slot order exactly.
    expect(raw, '["You","Robot","Player 3","Player 4"]');
  });

  test('decode falls back to defaults on missing or corrupt data', () {
    expect(
      ToyboxSettings.decodePlayerNames(null),
      ToyboxSettings.defaultNames,
    );
    expect(
      ToyboxSettings.decodePlayerNames('definitely not json'),
      ToyboxSettings.defaultNames,
    );
    expect(
      ToyboxSettings.decodePlayerNames('["only","two"]'),
      ToyboxSettings.defaultNames,
    );
    expect(
      ToyboxSettings.decodePlayerNames('{"a":1}'),
      ToyboxSettings.defaultNames,
    );
  });

  test('blank entries fall back to that slot\'s default name', () {
    final decoded =
        ToyboxSettings.decodePlayerNames('["Wajiha","","  ","Amber"]');
    expect(decoded, ['Wajiha', 'Robot', 'Player 3', 'Amber']);
  });

  test('engine rebuilt after "restart" shows the persisted names', () {
    // Simulate: user renamed slot 0, app restarted, the settings + seats are
    // rebuilt from the persisted value.
    const renamed = ['Wajiha', 'Robot', 'Player 3', 'Player 4'];
    final persisted = ToyboxSettings.decodePlayerNames(
      ToyboxSettings.encodePlayerNames(renamed),
    );
    final seatNames = [
      for (int i = 0; i < 4; i++) persisted[i],
    ];
    expect(seatNames[0], 'Wajiha');
    expect(seatNames[1], 'Robot');
    expect(seatNames[2], 'Player 3');
    expect(seatNames[3], 'Player 4');
    // A second "restart" round-trip keeps the same order.
    final again = ToyboxSettings.decodePlayerNames(
      ToyboxSettings.encodePlayerNames(persisted),
    );
    expect(again, renamed);
  });
}
