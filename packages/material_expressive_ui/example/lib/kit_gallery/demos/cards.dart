/// The cards group's demo: the elevated, filled and outlined card with
/// media and text, clickable (state layers, the ripple, elevation by
/// interaction), and a card holding cards — the deepest
/// containment CONTRACT §3 allows. Pictures resolve from media slots; the
/// gallery bundles none, so each shows the placeholder a pending picture
/// paints.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The cards group's demo, in [brightness].
Widget kitCardsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Cards',
  sections: const <Widget>[_Variants(), _Clickable(), _Nested()],
);

/// A card's text block: a title and a line of supporting text, inset by
/// the spacing scale's 16dp.
class _Copy extends StatelessWidget {
  const _Copy(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Padding(
      padding: const EdgeInsets.all(ExpressiveSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ExpressiveSpacing.s4,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.type.titleMedium,
          ),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A media card: a 16:9 picture edge to edge, then its copy.
class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.variant,
    required this.slot,
    required this.title,
    required this.body,
  });

  final ExpressiveCardVariant variant;
  final String slot;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => ExpressiveCard(
    variant: variant,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExpressiveMedia(slotId: slot, aspectRatio: 16 / 9),
        _Copy(title, body),
      ],
    ),
  );
}

class _Variants extends StatelessWidget {
  const _Variants();

  @override
  Widget build(BuildContext context) => kitSection(
    'Elevated · filled · outlined',
    children: const <Widget>[
      _MediaCard(
        variant: ExpressiveCardVariant.elevated,
        slot: 'ridge-trail',
        title: 'Ridge trail at first light',
        body: 'Eleven kilometres, one steep hour, a long view over the bay.',
      ),
      Row(
        spacing: ExpressiveSpacing.s12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ExpressiveCard.filled(
              child: _Copy('Filled', 'The default card: flat, on the tone.'),
            ),
          ),
          Expanded(
            child: ExpressiveCard.outlined(
              child: _Copy('Outlined', 'The quietest: a hairline stroke.'),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Clickable extends StatefulWidget {
  const _Clickable();

  @override
  State<_Clickable> createState() => _ClickableState();
}

class _ClickableState extends State<_Clickable> {
  String _opened = 'Tap a card';

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Clickable · press, hover, focus',
      children: <Widget>[
        for (final (variant, slot, title, body)
            in const <(ExpressiveCardVariant, String, String, String)>[
              (
                ExpressiveCardVariant.elevated,
                'bakery-window',
                'Rye & Salt bakery',
                'Open until two · 400 m',
              ),
              (
                ExpressiveCardVariant.filled,
                'evening-sail',
                'Evening sail',
                'Two hours at sunset · pier 3',
              ),
              (
                ExpressiveCardVariant.outlined,
                'reading-room',
                'Reading room',
                'Quiet floor · 12 seats free',
              ),
            ])
          ExpressiveCard(
            variant: variant,
            onPressed: () => setState(() => _opened = title),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 96,
                  height: 96,
                  child: ExpressiveMedia(slotId: slot),
                ),
                Expanded(child: _Copy(title, body)),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: ExpressiveSpacing.s16,
                  ),
                  child: Icon(
                    ExpressiveSymbols.chevronRight,
                    color: t.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        Text(
          _opened,
          style: t.type.labelLarge.copyWith(color: t.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Nested extends StatelessWidget {
  const _Nested();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'A card of cards · two deep, no deeper',
      children: <Widget>[
        // The outer card on the page's tone, outlined; the days on the
        // filled tone above it, so each inner card reads as standing on
        // the outer one rather than cut through it.
        ExpressiveCard.outlined(
          padding: const EdgeInsets.all(ExpressiveSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ExpressiveSpacing.s12,
            children: <Widget>[
              Text('Coast weekend', style: t.type.titleLarge),
              Text(
                'Two days, two towns, one ferry.',
                style: t.type.bodyMedium.copyWith(
                  color: t.colors.onSurfaceVariant,
                ),
              ),
              Row(
                spacing: ExpressiveSpacing.s12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final (day, plan) in const <(String, String)>[
                    ('Saturday', 'Harbour walk, oysters, the late ferry'),
                    ('Sunday', 'Lighthouse, dunes, back by six'),
                  ])
                    Expanded(
                      child: ExpressiveCard.filled(
                        onPressed: () {},
                        child: _Copy(day, plan),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A filled card about one booking, tappable.
Widget kitSpecimenCardFilled() => Builder(
  builder: (context) {
    final t = context.expressiveTheme;
    return ExpressiveCard.filled(
      onPressed: () {},
      semanticLabel: 'Lisbon, three nights',
      padding: const EdgeInsets.all(ExpressiveSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Lisbon, three nights',
            style: t.type.titleMedium.copyWith(color: t.colors.onSurface),
          ),
          const SizedBox(height: ExpressiveSpacing.s4),
          Text(
            'Fri 18 Sep to Mon 21 Sep · Casa do Rio',
            style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  },
);
