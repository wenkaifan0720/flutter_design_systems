/// Clay's foundations: the palette by day and by night, the type scale, the
/// clay itself at each depth, and its motion.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';

import '../kit.dart';

/// The foundations page.
Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  sections: const [
    KitSection(
      title: 'The clay',
      note:
          'One material at four depths: a well pressed in, clay resting flat, '
          'a raised volume, and one floating over the page.',
      children: [_Depths()],
    ),
    KitSection(
      title: 'Palette',
      note:
          'A pale lilac ground, white clay, one coral accent with dark words, '
          'and six pastels for habits (deep and saturated by night).',
      children: [_Palette()],
    ),
    KitSection(title: 'Type', children: [_Type()]),
    KitSection(
      title: 'Motion',
      note:
          'Critically damped springs: a press squashes in 1.5 px in about '
          '150 ms; a page inflates into place; nothing bounces.',
      children: [_Motion()],
    ),
  ],
);

class _Depths extends StatelessWidget {
  const _Depths();

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    final t = ClayTheme.of(context).textTheme;
    Widget swatch(String name, ClayFace face) => Column(
      children: [
        SizedBox(width: 120, height: 88, child: ClaySurface(face: face)),
        const SizedBox(height: ClaySpacing.small),
        Text(name, style: t.secondary),
      ],
    );
    return KitRow(
      children: [
        swatch('Well', ClayFace.well(c, radius: ClayRadius.large)),
        swatch('Flat', ClayFace.flat(c, radius: ClayRadius.large)),
        swatch('Raised', ClayFace.raised(c, radius: ClayRadius.large)),
        swatch('Floating', ClayFace.floating(c, radius: ClayRadius.large)),
        swatch(
          'Accent',
          ClayFace.raised(c, color: c.accent, radius: ClayRadius.large),
        ),
      ],
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette();

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    final t = ClayTheme.of(context).textTheme;
    Widget chip(String name, Color fill) => SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            child: ClaySurface(
              face: ClayFace.raised(c, color: fill, radius: ClayRadius.control),
              child: Center(
                child: Text(
                  'Aa',
                  style: t.label.copyWith(color: c.onColor(fill)),
                ),
              ),
            ),
          ),
          const SizedBox(height: ClaySpacing.small),
          Text(name, style: t.caption.copyWith(color: c.inkSecondary)),
        ],
      ),
    );
    return KitRow(
      children: [
        chip('Clay', c.clay),
        chip('Accent', c.accent),
        chip('Danger', c.danger),
        for (final tint in ClayTint.values) chip(tint.name, c.tint(tint)),
      ],
    );
  }
}

class _Type extends StatelessWidget {
  const _Type();

  @override
  Widget build(BuildContext context) {
    final t = ClayTheme.of(context).textTheme;
    final c = ClayTheme.of(context).colors;
    final styles = <(String, TextStyle)>[
      ('Display 32', t.display),
      ('Headline 24', t.headline),
      ('Title 18', t.title),
      ('Body 16', t.body),
      ('Label 16', t.label),
      ('Secondary 14', t.secondary),
      ('Caption 12', t.caption),
    ];
    // At a large text size the sample stands under its name: beside it, a
    // display line has no room for its words.
    final stacked = MediaQuery.textScalerOf(context).scale(16) > 24;
    return ClayGroup(
      children: [
        for (final (name, style) in styles)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClaySpacing.roomy,
              vertical: ClaySpacing.medium,
            ),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: t.caption.copyWith(color: c.inkSecondary),
                      ),
                      const SizedBox(height: ClaySpacing.tight),
                      Text('Steady days', style: style.copyWith(color: c.ink)),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          name,
                          style: t.caption.copyWith(color: c.inkSecondary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Steady days',
                          style: style.copyWith(color: c.ink),
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _Motion extends StatefulWidget {
  const _Motion();

  @override
  State<_Motion> createState() => _MotionState();
}

class _MotionState extends State<_Motion> {
  int _place = 0;
  int _count = 1;

  @override
  Widget build(BuildContext context) {
    final t = ClayTheme.of(context).textTheme;
    final words = clayPlural(
      context,
      _count,
      one: '1 day in a row',
      other: '$_count days in a row',
    );
    final category = clayPluralCategory(
      Localizations.maybeLocaleOf(context) ?? const Locale('en'),
      _count,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KitRow(
          children: [
            ClayButton(
              'Switch place',
              onPressed: () => setState(() => _place = 1 - _place),
            ),
            ClayButton('Add a day', onPressed: () => setState(() => _count++)),
          ],
        ),
        const SizedBox(height: ClaySpacing.regular),
        SizedBox(
          // The card's padding and a title line, at the reader's text size.
          height: 32 + MediaQuery.textScalerOf(context).scale(40),
          child: ClayPlaceSwitch(
            place: _place,
            child: ClayCard(
              color: ClayTheme.of(context).colors
                  .tint(_place == 0 ? ClayTint.mint : ClayTint.sky),
              child: Text(_place == 0 ? 'Today' : 'Habits', style: t.title),
            ),
          ),
        ),
        const SizedBox(height: ClaySpacing.regular),
        Text(
          '$words (${category == ClayPluralCategory.one ? 'one' : 'other'})',
          style: t.secondary,
        ),
        const SizedBox(height: ClaySpacing.small),
        Text(
          'Pages push with ${const ClayPageTransitionsBuilder().transitionDuration.inMilliseconds} ms of inflation.',
          style: t.secondary,
        ),
      ],
    );
  }
}
