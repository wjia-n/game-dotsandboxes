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
    widget.store.lastThanks.addListener(_onThanks);
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
