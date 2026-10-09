import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/toybox_themes.dart';
import '../toybox/widgets.dart';

/// Dots & Boxes PRO: Free-vs-Pro comparison, real purchase, restore,
/// and tip jar. All prices come from the store — never hardcoded.
/// Until Wajiha creates the products in Play Console, the screen says so
/// honestly instead of showing fake buy buttons.
class ProScreen extends StatefulWidget {
  final ToyboxAudio audio;
  final ToyboxSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  ToyThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: toyBody(15, _t)),
          backgroundColor: _t.woodDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: toyBody(15, _t)),
        backgroundColor: _t.woodDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
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
                children: [
                  Row(
                    children: [
                      ToyIconButton(
                        icon: Icons.arrow_back,
                        size: 44,
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 12),
                      Text('Dots & Boxes PRO',
                          style: toyHeadline(24, t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
                  _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
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

class _ComparisonCard extends StatelessWidget {
  final ToyThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Play vs robot & pass-and-play', true, true),
      ('3 board sizes (5×5, 6×6, 7×7)', true, true),
      ('4 wooden-toy themes', true, true),
      ('4 line styles', true, true),
      ('8 more themes (Midnight, Berry…)', false, true),
      ('4 more line styles (Gel, Brush…)', false, true),
      ('3 paper accents + felt, denim, cork', false, true),
      ('Hard robot difficulty', false, true),
      ('Custom theme creator', false, true),
    ];
    return ToyCard(
      theme: theme,
      child: Column(
        children: [
          Text(
            isPro ? 'You have PRO 🎉' : 'Free vs PRO',
            style: toyHeadline(20, theme),
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  const SizedBox(),
                  Center(
                      child: Text('Free',
                          style: toyBody(13, theme,
                              color: theme.text
                                  .withValues(alpha: 0.6)))),
                  Center(
                      child: Text('PRO',
                          style: toyBody(13, theme))),
                ],
              ),
              for (final (label, free, pro) in rows)
                TableRow(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 5),
                      child: Text(label,
                          style: toyBody(13, theme)),
                    ),
                    Center(
                        child: Icon(
                            free
                                ? Icons.check_circle
                                : Icons.remove_circle_outline,
                            size: 18,
                            color: free
                                ? const Color(0xFF7CB342)
                                : theme.text
                                    .withValues(alpha: 0.3))),
                    Center(
                        child: Icon(Icons.check_circle,
                            size: 18,
                            color: pro
                                ? const Color(0xFFE8B93C)
                                : theme.text
                                    .withValues(alpha: 0.3))),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuyCard extends StatelessWidget {
  final ToyThemeDef theme;
  final ToyboxSettings settings;
  final StoreService store;
  final ToyboxAudio audio;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    if (settings.isPro) {
      return ToyCard(
        theme: theme,
        child: Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: Color(0xFFE8B93C), size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'PRO is active on this device. All themes, styles and Hard mode are unlocked.',
                style: toyBody(14, theme),
              ),
            ),
          ],
        ),
      );
    }
    final product = store.proProduct;
    if (!store.storeReady || product == null) {
      return ToyCard(
        theme: theme,
        child: Column(
          children: [
            Text('PRO unlock', style: toyHeadline(18, theme)),
            const SizedBox(height: 8),
            Text(
              'PRO purchases will appear here once the store products are set up. The game is fully playable for free meanwhile!',
              style: toyBody(14, theme,
                  color: theme.text.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ToyButton(
              label: 'Restore purchase',
              small: true,
              onTap: () {
                audio.click();
                store.restore();
              },
            ),
          ],
        ),
      );
    }
    return ToyCard(
      theme: theme,
      child: Column(
        children: [
          Text('Unlock PRO forever', style: toyHeadline(18, theme)),
          const SizedBox(height: 6),
          Text(
            'One-time purchase. Every future toybox game keeps it simple: pay once, own it.',
            style: toyBody(13, theme,
                color: theme.text.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ToyButton(
            label: 'Get PRO — ${product.price}',
            icon: Icons.workspace_premium,
            color: const Color(0xFFE8B93C),
            onTap: () {
              audio.click();
              store.buyPro();
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              audio.click();
              store.restore();
            },
            child: Text('Restore purchase',
                style: toyBody(13, theme,
                    color: theme.text.withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final ToyThemeDef theme;
  final StoreService store;
  final ToyboxAudio audio;
  const _TipsCard({
    required this.theme,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final coffee = store.coffeeProduct;
    final choco = store.chocolateProduct;
    return ToyCard(
      theme: theme,
      child: Column(
        children: [
          Text('Tip jar ☕🍫', style: toyHeadline(18, theme)),
          const SizedBox(height: 6),
          Text(
            'Made by one indie maker. Tips keep the crayons sharp!',
            style: toyBody(13, theme,
                color: theme.text.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady) ...[
            Text(
              'Tips will appear here once the store products are set up.',
              style: toyBody(13, theme,
                  color: theme.text.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (coffee != null)
                  _TipButton(
                    theme: theme,
                    label: 'Coffee\n${coffee.price}',
                    icon: Icons.coffee,
                    onTap: () {
                      audio.click();
                      store.buyTip(coffee);
                    },
                  ),
                if (coffee != null && choco != null)
                  const SizedBox(width: 12),
                if (choco != null)
                  _TipButton(
                    theme: theme,
                    label: 'Chocolate\n${choco.price}',
                    icon: Icons.cookie,
                    onTap: () {
                      audio.click();
                      store.buyTip(choco);
                    },
                  ),
              ],
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err,
                        style: toyBody(13, theme,
                            color: const Color(0xFFB3272D))),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TipButton extends StatelessWidget {
  final ToyThemeDef theme;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _TipButton({
    required this.theme,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: theme.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.woodDark, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.text, size: 26),
            const SizedBox(height: 4),
            Text(label,
                style: toyBody(12, theme),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
