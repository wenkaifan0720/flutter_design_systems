/// Clay's foundations: the palette by day and by night, the type scale, the
/// clay itself at each depth, and its motion.
library;

import 'dart:math' as math;

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
    KitSection(
      title: 'Palettes',
      note:
          'Six palettes, each a clay and a key of its own at the same tones: '
          'clay, mint, sky, butter, peach and lavender (ClayThemeData.preset).',
      children: [_Palettes()],
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
        swatch(
          'Well',
          ClayFace.well(
            c,
            radius: ClayTheme.of(context).shapeScheme.corners.large,
          ),
        ),
        swatch(
          'Flat',
          ClayFace.flat(
            c,
            radius: ClayTheme.of(context).shapeScheme.corners.large,
          ),
        ),
        swatch(
          'Raised',
          ClayFace.raised(
            c,
            radius: ClayTheme.of(context).shapeScheme.corners.large,
          ),
        ),
        swatch(
          'Floating',
          ClayFace.floating(
            c,
            radius: ClayTheme.of(context).shapeScheme.corners.large,
          ),
        ),
        swatch(
          'Accent',
          ClayFace.raised(
            c,
            color: c.accent,
            radius: ClayTheme.of(context).shapeScheme.corners.large,
          ),
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
    Widget chip(String name, Color fill) {
      final rim = paletteRim(c, fill);
      final words = Center(
        child: Text('Aa', style: t.label.copyWith(color: c.onColor(fill))),
      );
      return SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 56,
              child: ClaySurface(
                face: ClayFace.raised(
                  c,
                  color: fill,
                  radius: ClayTheme.of(context).shapeScheme.corners.medium,
                ),
                child: rim == null
                    ? words
                    : CustomPaint(
                        foregroundPainter: _LitRim(
                          rim,
                          Directionality.of(context),
                          ClayTheme.of(context).shapeScheme.corners.medium,
                        ),
                        child: words,
                      ),
              ),
            ),
            const SizedBox(height: ClaySpacing.small),
            Text(name, style: t.caption.copyWith(color: c.inkSecondary)),
          ],
        ),
      );
    }

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

// Each of Clay's palettes at the page's brightness: its ground, a puck of
// its clay and its key with the key's words, named under it.
class _Palettes extends StatelessWidget {
  const _Palettes();

  @override
  Widget build(BuildContext context) {
    final page = ClayTheme.of(context);
    final brightness = page.colors.brightness;
    Widget puck(
      ClayColors c,
      TextStyle style, {
      Color? fill,
      required Color ink,
    }) => ClaySurface(
      face: ClayFace.raised(
        c,
        color: fill,
        radius: ClayTheme.of(context).shapeScheme.corners.medium,
      ),
      child: Center(
        child: Text('Aa', style: style.copyWith(color: ink)),
      ),
    );
    return KitRow(
      children: [
        for (final name in ClayThemeData.presets)
          SizedBox(
            width: 104,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClayTheme(
                  data: ClayThemeData.preset(name, brightness),
                  child: Builder(
                    builder: (context) {
                      final theme = ClayTheme.of(context);
                      final c = theme.colors;
                      final style = theme.textTheme.caption;
                      return SizedBox(
                        height: 64,
                        child: ClaySurface(
                          face: ClayFace.flat(
                            c,
                            color: c.ground,
                            radius: ClayTheme.of(context)
                                .shapeScheme
                                .corners
                                .large,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(ClaySpacing.small),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: puck(c, style, ink: c.ink)),
                                const SizedBox(width: ClaySpacing.small),
                                Expanded(
                                  child: puck(
                                    c,
                                    style,
                                    fill: c.accent,
                                    ink: c.onAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: ClaySpacing.small),
                Text(
                  name,
                  style: page.textTheme.caption.copyWith(
                    color: page.colors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The light a palette swatch of [fill] catches by night, or null when it
/// needs none. A deep night pastel, or the night clay, sinks into the dark
/// ground; the light inside its top-leading edge (Clay's first law) is
/// brought up until that edge stands 3:1 from the ground, so it reads as
/// its colour and apart. A pastel's light is its own hue, lifted; the
/// clay's, the clay lifted toward the ink, without a hue of its own. The
/// accent and the danger colour stand apart on their own. By day each
/// swatch's float, in its own hue, sets it apart.
Color? paletteRim(ClayColors colors, Color fill) {
  // The raised face's shade darkens its lower trailing edge: a margin.
  if (colors.brightness != Brightness.dark ||
      clayContrast(fill, colors.ground) >= 3.5) {
    return null;
  }
  final hsl = HSLColor.fromColor(fill);
  final hued = hsl.saturation >= 0.3;
  var step = 0.0;
  var rim = fill;
  // The light is soft: a margin over 3:1 for its blur.
  while (clayContrast(rim, colors.ground) < 3.8 && step < 1) {
    step = math.min(1.0, step + 0.02);
    rim = hued
        ? hsl.withLightness(math.min(1.0, hsl.lightness + step)).toColor()
        : Color.lerp(fill, colors.ink, step)!;
  }
  return rim;
}

/// A swatch's light: a soft band of [rim] inside its top and leading edges,
/// where the light falls (mirrored right to left), fading down the leading
/// side; its bottom and its trailing side stay in shade.
class _LitRim extends CustomPainter {
  const _LitRim(this.rim, this.direction, this.radius);

  final Color rim;
  final TextDirection direction;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = Path()
      ..addRSuperellipse(
        RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius)),
      );
    // Where the light falls, as on every raised part: inside the shape and
    // outside itself moved toward the lower trailing corner, so the top and
    // the leading side, and neither the bottom nor the trailing side. (A
    // frame round the moved shape, filled even-odd: a browser draws it as
    // the tests do, where a combined path's hole would fill.)
    const reach = 5.0;
    final lit = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(4 * reach))
      ..addRSuperellipse(
        RSuperellipse.fromRectAndRadius(
          rect.shift(
            Offset(direction == TextDirection.rtl ? -reach : reach, reach),
          ),
          Radius.circular(radius),
        ),
      );
    canvas
      ..save()
      ..clipPath(shape)
      ..drawPath(
        lit,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
          // Whole along the top, fading down the leading side, gone before
          // the lower leading corner.
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rim, rim, rim.withValues(alpha: 0)],
            stops: const [0, 0.4, 0.75],
          ).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_LitRim old) =>
      old.rim != rim || old.direction != direction || old.radius != radius;
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
