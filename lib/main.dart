import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const DotsAndBoxesApp());

class DotsAndBoxesApp extends StatelessWidget {
  const DotsAndBoxesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Dots and Boxes',
      tagline: 'Claim boxes and outsmart your opponent, 2-4 players',
      emoji: '📦',
      slug: 'dotsandboxes',
      howToPlay:
          '• Tap any line between two dots to draw your edge. ✏️\n• Close a box and it\'s YOURS — plus you steal another turn!\n• Boxes fill with your color and your emoji. So satisfying. 📦\n• Most boxes when the grid is full wins the crown. 👑\n• Careful: the third wall of a box is basically a gift to your rival… 🎁',
      playerOptions: const [1, 2, 3, 4],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => DotsAndBoxesScreen(players: players, callbacks: cb),
    );
  }
}
