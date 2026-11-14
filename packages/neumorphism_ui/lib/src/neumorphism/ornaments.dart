// The small marks: the LED, the pigment's words, shape marks, monograms, icon wells, the engraved rule, the look's mark.
// Objects keep their round shape here: nothing in this file holds a sentence.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'frames.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'shapes.dart';
import 'internal/geometry.dart';
import 'layout.dart';
import 'theme.dart';

class _Paint extends CustomPainter {
  _Paint(this.fn, this.key);
  final void Function(Canvas, Size) fn;
  final Object key;
  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size);
  @override
  bool shouldRepaint(_Paint o) => o.key != key;
}

/// A paint of a size of its own, keyed by what it draws. Internal to the look's parts.
Widget neumorphicPaint(
  double? w,
  double? h,
  Object key,
  void Function(Canvas, Size) fn,
) {
  final paint = CustomPaint(painter: _Paint(fn, key));
  return w != null && h != null
      ? neumorphicOwnSize(width: w, height: h, child: paint)
      : SizedBox(width: w, height: h, child: paint);
}

/// The LED: a small dome of the pigment. It means this thing is live, and nothing else. Off has no LED at all.
///
/// ```dart
/// NeumorphicLed()
/// ```
class NeumorphicLed extends StatelessWidget {
  /// Creates a [NeumorphicLed].
  const NeumorphicLed({super.key, this.size = 8});

  /// The indicator diameter in logical pixels.
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    final flat = NeumorphicFlatScope.of(context);
    return neumorphicPaint(size, size, (c, size, flat), (canvas, s) {
      neumorphicPaintLed(
        canvas,
        s.center(Offset.zero),
        s.width / 2,
        c,
        flat: flat,
      );
    });
  }
}

/// An LED at [at], for a part that paints its own.
void neumorphicPaintLed(
  Canvas canvas,
  Offset at,
  double r,
  NeumorphicColors c, {
  bool flat = false,
}) {
  if (!flat) canvas.drawCircle(at, r + 3, neumorphicFillPaint(c.ledGlow));
  final box = Rect.fromCircle(center: at, radius: r);
  canvas.drawCircle(
    at,
    r,
    Paint()
      ..isAntiAlias = true
      ..shader = cssRadial(
        box,
        .35,
        .35,
        [c.pigmentHi, c.pigment],
        const [0, .7],
      ),
  );
}

/// Words in the pigment: this is on, now, running. The one way a page writes in it. Say what's live in the words themselves
/// ('On, 30%', 'Since 19:45'), and only for what's live.
///
/// ```dart
/// NeumorphicLiveText('On, 30%', icon: NeumorphicGlyphs.flame)
/// ```
class NeumorphicLiveText extends StatelessWidget {
  /// Creates a [NeumorphicLiveText].
  const NeumorphicLiveText(
    this.words, {
    super.key,
    this.icon,
    this.large = false,
    this.led = false,
    this.lit = false,
  });

  /// The text displayed by this indicator.
  final String words;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// A caption's size, not a micro's.
  final bool large;

  /// An LED before the words.
  final bool led;

  /// Standing on a wash of the pigment: a deeper ink.
  final bool lit;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final ink = lit ? c.pigmentInkLit : c.pigmentInk;
    final style = (large ? t.textTheme.caption : t.textTheme.micro).copyWith(
      color: ink,
      fontWeight: large ? FontWeight.w600 : FontWeight.w700,
    );
    final parts = [
      if (led) const NeumorphicLed(),
      if (icon != null) Icon(icon, size: large ? 16 : 14, color: ink),
      Text(words, style: style.tabular),
    ];
    return NeumorphicFitRow(
      fill: parts.length - 1,
      shrink: true,
      gap: led ? 8 : 4,
      children: parts,
    );
  }
}

/// Three shapes that tell things apart without a hue, so the pigment stays free for live: a solid dot, a ring, a half.
/// Geometric category marks, distinguishable without colour.
enum NeumorphicMarkShape {
  /// A filled circular mark.
  solid,

  /// An outlined circular mark.
  ring,

  /// A half-filled circular mark.
  half,
}

/// A kind told apart by shape: a calendar, a category, a source. Never by colour.
///
/// ```dart
/// NeumorphicShapeMark(NeumorphicMarkShape.ring)
/// ```
class NeumorphicShapeMark extends StatelessWidget {
  /// Creates a [NeumorphicShapeMark].
  const NeumorphicShapeMark(this.shape, {super.key, this.size = 10});

  /// The geometric mark used to distinguish this category.
  final NeumorphicMarkShape shape;

  /// The square mark size in logical pixels.
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    return neumorphicPaint(size, size, (c, shape, size), (canvas, s) {
      final mid = s.center(Offset.zero);
      final r = s.width / 2;
      switch (shape) {
        case NeumorphicMarkShape.solid:
          canvas.drawCircle(mid, r, neumorphicFillPaint(c.inkSecondary));
        case NeumorphicMarkShape.ring:
          canvas.drawCircle(
            mid,
            r - 1,
            neumorphicStrokePaint(c.inkSecondary, 2),
          );
        case NeumorphicMarkShape.half:
          canvas.drawCircle(
            mid,
            r - 1,
            neumorphicStrokePaint(c.inkSecondary, 2),
          );
          canvas.drawPath(
            Path()
              ..addArc(Rect.fromCircle(center: mid, radius: r), 1.5708, 3.14159)
              ..close(),
            neumorphicFillPaint(c.inkSecondary),
          );
      }
    });
  }
}

/// Initials on a raised round cap: a person. [led]: they're here, or it's live.
///
/// ```dart
/// NeumorphicMonogram('MA', led: true)
/// ```
class NeumorphicMonogram extends StatelessWidget {
  /// Creates a [NeumorphicMonogram].
  const NeumorphicMonogram(
    this.initials, {
    super.key,
    this.size = 36,
    this.led = false,
    this.style,
  });

  /// Cap and initials before the avatar component theme.
  final NeumorphicStyle? style;

  /// The initials shown when no usable image is available.
  final String initials;

  /// The face diameter in logical pixels.
  final double size;

  /// Whether to show the live indicator.
  final bool led;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final look = NeumorphicStyleOf([style, t.avatarTheme], const {});
    final words = t.textTheme.micro
        .copyWith(fontWeight: FontWeight.w700, color: t.colors.inkSecondary)
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    final measure = TextPainter(
      text: TextSpan(text: initials, style: words),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    var diameter = size.clamp(
      math.max(measure.width, measure.height) + 8,
      double.infinity,
    );
    var shape = look.shape;
    final pad =
        look.padding(Directionality.of(context)) ??
        const EdgeInsets.symmetric(horizontal: 4);
    diameter = math.max(
      diameter,
      math.max(look.minimumSize?.width ?? 0, look.minimumSize?.height ?? 0),
    );
    if (shape is NeumorphicCircleBorder) {
      diameter = math.max(
        diameter,
        math.max(
              measure.width + pad.horizontal,
              measure.height + pad.vertical,
            ) *
            math.sqrt2,
      );
    } else if (shape != null) {
      final inset = shape.dimensions.resolve(Directionality.of(context));
      diameter = math.max(
        diameter,
        math.max(
          measure.width + pad.horizontal + inset.horizontal,
          measure.height + pad.vertical + inset.vertical,
        ),
      );
    }
    if (shape is NeumorphicBorder) shape = shape.fit(Size.square(diameter));
    measure.dispose();
    return neumorphicOwnSize(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          NeumorphicSurface(
            style: style,
            themeStyle: t.avatarTheme,
            shape: shape,
            cast: NeumorphicSurfaceLevel.part,
            round: true,
            child: Center(
              child: Padding(
                padding: pad,
                child: Text(initials, maxLines: 1, style: words),
              ),
            ),
          ),
          if (led)
            const PositionedDirectional(
              end: -1,
              bottom: 0,
              child: NeumorphicLed(),
            ),
        ],
      ),
    );
  }
}

/// A glyph in a small pressed round well. [live] sets the pigment in it: this thing is on. Off, it's an ink glyph.
///
/// ```dart
/// NeumorphicIconWell(NeumorphicGlyphs.lock, live: true)
/// ```
class NeumorphicIconWell extends StatelessWidget {
  /// Creates a [NeumorphicIconWell].
  const NeumorphicIconWell(
    this.icon, {
    super.key,
    this.live = false,
    this.size = 44,
    this.square = false,
    this.style,
  });

  /// Mark face before the icon-button component theme.
  final NeumorphicStyle? style;

  /// The glyph displayed with the content.
  final IconData icon;

  /// Whether to emphasize the active state with the pigment colour.
  final bool live;

  /// The square face size in logical pixels.
  final double size;

  /// A square well on the control radius, for something like art: what's playing, a kind of file.
  final bool square;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context), c = t.colors;
    final look = NeumorphicStyleOf(
      [style, t.iconButtonTheme],
      {if (live) WidgetState.selected},
    );
    final diameter = math.max(
      size,
      math.max(look.minimumSize?.width ?? 0, look.minimumSize?.height ?? 0),
    );
    var shape = look.shape ?? (square ? null : t.shapes.circle());
    if (shape is NeumorphicBorder) shape = shape.fit(Size.square(diameter));
    return neumorphicOwnSize(
      width: diameter,
      height: diameter,
      child: NeumorphicSurface(
        style: style,
        themeStyle: t.iconButtonTheme,
        shape: shape,
        states: {if (live) WidgetState.selected},
        cast: NeumorphicSurfaceLevel.groove,
        round: !square,
        radius: square ? NeumorphicRadii.control : null,
        live: live,
        child: Center(
          child: Icon(
            icon,
            size: look.iconSize ?? size * .46,
            color: look.foreground ?? (live ? c.pigment : c.inkSecondary),
          ),
        ),
      ),
    );
  }
}

/// The brand's mark: a raised round cap with a pressed material dimple.
/// Accent colour is reserved for actions and explicit live state.
///
/// ```dart
/// NeumorphicBrandMark(size: 36)
/// ```
class NeumorphicBrandMark extends StatelessWidget {
  /// Creates a [NeumorphicBrandMark].
  const NeumorphicBrandMark({super.key, this.size = 36});

  /// The square dimple motif size in logical pixels.
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    final flat = NeumorphicFlatScope.of(context);
    return neumorphicPaint(size, size, (c, size, flat), (canvas, s) {
      final mid = s.center(Offset.zero);
      final k = s.width / 36;
      neumorphicPaintCast(
        canvas,
        Path()..addOval(Offset.zero & s),
        NeumorphicDraw.part,
        c,
        flat: flat,
      );
      neumorphicPaintPressed(
        canvas,
        Path()..addOval(Rect.fromCircle(center: mid, radius: 8 * k)),
        c,
        light: (const Offset(-2, -2), 4),
        dark: (const Offset(2, 2), 4),
        flat: flat,
      );
    });
  }
}

/// The look's mark with no pigment: a small moat and dome in the plaster. It stands in for a picture and waits with a page.
///
/// ```dart
/// NeumorphicMark(size: 44)
/// ```
class NeumorphicMark extends StatelessWidget {
  /// Creates a [NeumorphicMark].
  const NeumorphicMark({super.key, this.size = 44});

  /// The square inset mark size in logical pixels.
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    final flat = NeumorphicFlatScope.of(context);
    return neumorphicPaint(size, size, (c, size, flat), (canvas, s) {
      neumorphicPaintDimple(
        canvas,
        s.center(Offset.zero),
        s.width / 2,
        c,
        flat: flat,
      );
    });
  }
}

/// A moat and a dome at [at], in the plaster alone.
void neumorphicPaintDimple(
  Canvas canvas,
  Offset at,
  double r,
  NeumorphicColors c, {
  bool flat = false,
}) {
  final outer = Rect.fromCircle(center: at, radius: r);
  neumorphicPaintPressed(
    canvas,
    Path()..addOval(outer),
    c,
    light: (const Offset(-2, -2), 5),
    dark: (const Offset(2, 2), 5),
    flat: flat,
  );
  if (flat) canvas.drawCircle(at, r - .5, neumorphicStrokePaint(c.quiet, 1));
  final dome = Rect.fromCircle(center: at, radius: r * .58);
  neumorphicPaintDome(canvas, dome, c, flat: flat, light: 3, dark: 4);
}

/// A glossy dome in [box]: a knob's cap, a gauge's centre. Its shadow is small and soft, and doesn't need the wall's.
void neumorphicPaintDome(
  Canvas canvas,
  Rect box,
  NeumorphicColors c, {
  bool flat = false,
  double light = 3,
  double dark = 4,
}) {
  neumorphicPaintRaised(
    canvas,
    Path()..addOval(box),
    c,
    light: (Offset(-light, -light), light * 2.3),
    dark: (Offset(dark, dark), dark * 2.5),
    lightColor: c.highlightSoft,
    face: cssRadial(
      box,
      .34,
      .28,
      [c.domeLight, c.domeMid, c.domeDark],
      const [0, .5, 1],
    ),
    flat: flat,
  );
  if (flat) canvas.drawOval(box.deflate(.5), neumorphicStrokePaint(c.quiet, 1));
}

/// The only line in the look: a 1 px crease over a 1 px catch-light, cut into the plaster. Rows draw it themselves.
///
/// ```dart
/// NeumorphicEngraved()
/// ```
class NeumorphicEngraved extends StatelessWidget {
  /// Creates a [NeumorphicEngraved].
  const NeumorphicEngraved({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = NeumorphicTheme.of(context);
    final c = theme.colors;
    const width = neumorphicRuleWidth;
    final flat = NeumorphicFlatScope.of(context);
    return neumorphicPaint(null, 2 * width, (c, flat, width), (canvas, s) {
      neumorphicPaintEngraved(
        canvas,
        Offset.zero,
        s.width,
        c,
        flat: flat,
        thickness: width,
      );
    });
  }
}

/// An engraved line from [at], [width] long.
void neumorphicPaintEngraved(
  Canvas canvas,
  Offset at,
  double width,
  NeumorphicColors c, {
  bool flat = false,
  double thickness = 1,
}) {
  canvas.drawRect(
    at & Size(width, thickness),
    neumorphicFillPaint(flat ? c.quiet : c.crease),
  );
  if (!flat) {
    canvas.drawRect(
      (at + Offset(0, thickness)) & Size(width, thickness),
      neumorphicFillPaint(c.rim),
    );
  }
}
