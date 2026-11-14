// The relief: a set of grouped things as one casting from the wall, no cards and no tiles. A pediment with a pressed tympanum, a moon, a
// cornice, a wall with a course of bays per group, string courses between them, a plinth, the ground. An arched window is a drawing with
// nothing written in it: a bay's words stand on the wall's raised face, under its window, since a giant radius holding words is
// exactly what this look must not do.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../controls.dart';
import '../frames.dart';
import '../internal/geometry.dart';
import '../heads.dart';
import '../layout.dart';
import '../ornaments.dart';
import '../theme.dart';
import 'dial.dart';

/// One bay of a course: a figure, a name, a state, and a window that shows how lit it is.
class NeumorphicBay {
  /// Creates a [NeumorphicBay].
  const NeumorphicBay({
    required this.name,
    this.figure,
    this.note,
    this.noteIcon,
    this.lit = 0,
    this.flag,
    this.onPressed,
  });

  /// The name displayed for this item.
  final String name;

  /// The formatted value to display.
  final String? figure;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// The glyph displayed beside the supporting note.
  final IconData? noteIcon;

  /// 0 to 1: how much light is in its window. Over 0 it's live: an LED at the crown, its note in the pigment.
  final double lit;

  /// A glyph on the pigment at the window's crown: this one wants you. Use it for one bay.
  final IconData? flag;

  /// Called when the item is activated.
  final VoidCallback? onPressed;
}

/// One group of bays, and its name on the course under them.
class NeumorphicCourse {
  /// Creates a [NeumorphicCourse].
  const NeumorphicCourse(this.name, this.bays);

  /// The name displayed for this item.
  final String name;

  /// The data bays displayed in this architectural course.
  final List<NeumorphicBay> bays;
}

void _paintBand(
  Canvas canvas,
  Rect box,
  double r,
  NeumorphicColors c,
  bool flat, {
  double r2 = -1,
  NeumorphicThrow light = (const Offset(-3, -2), 6),
  NeumorphicThrow dark = (const Offset(4, 5), 10),
  Color? darkColor,
}) {
  final shape = Path()
    ..addRRect(
      RRect.fromRectAndCorners(
        box,
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
        bottomLeft: Radius.circular(r2 < 0 ? r : r2),
        bottomRight: Radius.circular(r2 < 0 ? r : r2),
      ),
    );
  neumorphicPaintRaised(
    canvas,
    shape,
    c,
    light: light,
    dark: dark,
    darkColor: darkColor,
    face: cssLinear(box, 180, [c.faceStart, c.faceEnd]),
    flat: flat,
    rim: false,
  );
  if (flat) {
    canvas.drawPath(shape, neumorphicStrokePaint(c.quiet, 1));
    return;
  }
  canvas.save();
  canvas.clipPath(shape);
  canvas.drawRect(
    Rect.fromLTWH(box.left, box.top, box.width, 1),
    neumorphicFillPaint(c.rim),
  );
  canvas.drawRect(
    Rect.fromLTWH(box.left, box.bottom - 1, box.width, 1),
    neumorphicFillPaint(c.crease),
  );
  canvas.restore();
}

class _BandPainter extends CustomPainter {
  _BandPainter(
    this.c,
    this.flat,
    this.r, {
    this.r2 = -1,
    this.light = (const Offset(-3, -2), 6),
    this.dark = (const Offset(4, 5), 10),
    this.deep = false,
  });
  final NeumorphicColors c;
  final bool flat, deep;
  final double r, r2;
  final NeumorphicThrow light, dark;
  @override
  void paint(Canvas canvas, Size s) => _paintBand(
    canvas,
    Offset.zero & s,
    r,
    c,
    flat,
    r2: r2,
    light: light,
    dark: dark,
    darkColor: deep ? c.shadowDeep : null,
  );
  @override
  bool shouldRepaint(_BandPainter o) =>
      o.c != c ||
      o.flat != flat ||
      o.r != r ||
      o.r2 != r2 ||
      o.light != light ||
      o.dark != dark ||
      o.deep != deep;
}

class _WallPainter extends CustomPainter {
  _WallPainter(this.c, this.flat, this.side, this.top, this.bottom);
  final NeumorphicColors c;
  final bool flat;
  final double side, top, bottom;
  @override
  void paint(Canvas canvas, Size s) {
    final box = Rect.fromLTRB(side, top, s.width - side, s.height - bottom);
    if (!flat) {
      canvas.drawRect(
        box.shift(const Offset(18, 16)),
        Paint()
          ..color = c.shadowDeep
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      canvas.drawRect(
        box.shift(const Offset(-12, -4)),
        Paint()
          ..color = c.highlight
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
      );
    }
    canvas.drawRect(
      box,
      Paint()..shader = cssLinear(box, 145, [c.faceStart, c.faceEnd]),
    );
    if (flat) {
      canvas.drawRect(box.deflate(.5), neumorphicStrokePaint(c.quiet, 1));
    } else {
      canvas.drawRect(
        Rect.fromLTWH(box.left, box.top, 1, box.height),
        neumorphicFillPaint(c.rim),
      );
      canvas.drawRect(
        Rect.fromLTWH(box.right - 1, box.top, 1, box.height),
        neumorphicFillPaint(c.crease),
      );
    }
  }

  @override
  bool shouldRepaint(_WallPainter o) =>
      o.c != c ||
      o.flat != flat ||
      o.side != side ||
      o.top != top ||
      o.bottom != bottom;
}

/// The pressed window: a full round head on a small foot, lamplight in it by how lit it is, and nothing written in it.
class _WindowPainter extends CustomPainter {
  _WindowPainter(this.c, this.flat, this.lit, this.foot);
  final NeumorphicColors c;
  final bool flat;
  final double lit, foot;
  @override
  void paint(Canvas canvas, Size s) {
    if (s.height <= foot || s.width <= 0) return;
    // As wide as it stands tall allows: a full round head while it can be, a flatter elliptical one when the bay is wide and low.
    final rise = s.height - foot;
    final w = math.min(s.width, rise * 2.9).toDouble();
    final left = (s.width - w) / 2;
    final box = Rect.fromLTWH(left, 0, w, s.height);
    final h = s.height;
    // The head leaves the foot room for a whole least corner: with a short foot the sill's corners came to 3 or 4.
    final head = Radius.elliptical(
      w / 2,
      math.min(
        math.min(rise, w / 2),
        math.max(0.0, h - 2 * NeumorphicRadii.least),
      ),
    );
    // Its foot is rounded too: a square-cornered sill is a sharp corner in the plaster.
    final sill = Radius.circular(
      math.min(NeumorphicRadii.least, math.max(0, h - head.y) / 2),
    );
    final shape = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          box,
          topLeft: head,
          topRight: head,
          bottomLeft: sill,
          bottomRight: sill,
        ),
      );
    neumorphicPaintPressed(
      canvas,
      shape,
      c,
      light: (const Offset(-5, -5), 11),
      dark: (const Offset(5, 5), 12),
      flat: flat,
    );
    if (lit > 0) {
      final alpha = (.16 + lit * .46).clamp(0.0, .62);
      canvas.drawPath(
        shape,
        Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.radial(
            box.topCenter + Offset(0, h * .1),
            math.max(w, h) * (.7 + lit * .4),
            [
              c.art.lamp.withValues(alpha: alpha),
              c.art.lamp.withValues(alpha: 0),
            ],
          ),
      );
    }
    if (flat) canvas.drawPath(shape, neumorphicStrokePaint(c.quiet, 1));
  }

  @override
  bool shouldRepaint(_WindowPainter o) =>
      o.c != c || o.flat != flat || o.lit != lit || o.foot != foot;
}

class _BayCell extends StatelessWidget {
  const _BayCell(this.bay);
  final NeumorphicBay bay;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final figure = desk
        ? t.textTheme.text(30, 36, weight: FontWeight.w300, tracking: -.02)
        : t.textTheme.text(20, 24, weight: FontWeight.w500, tracking: -.01);
    final name = t.textTheme.text(
      14,
      18,
      weight: FontWeight.w700,
      tracking: -.01,
    );
    final live = bay.lit > 0 || bay.flag != null;
    final noteStyle = t.textTheme.micro.copyWith(
      color: live ? c.pigmentInk : c.inkTertiary,
    );
    final flat = NeumorphicFlatScope.of(context);
    final foot = desk ? 14.0 : 10.0;
    Widget window = Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _WindowPainter(c, flat, bay.lit, foot)),
        ),
        if (bay.flag != null)
          Align(
            alignment: Alignment.center,
            child: neumorphicOwnSize(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.pigment, c.pigmentDk],
                  ),
                ),
                child: Center(
                  child: Icon(bay.flag, size: 14, color: c.onPigment),
                ),
              ),
            ),
          )
        else if (bay.lit > 0)
          const Align(alignment: Alignment(0, -.1), child: NeumorphicLed()),
      ],
    );
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bay.figure != null)
          Text(bay.figure!, textAlign: TextAlign.center, style: figure),
        const SizedBox(height: 2),
        Text(bay.name, textAlign: TextAlign.center, style: name),
        // A bay without a note keeps the note's line empty: the figures of a course stand on one line whichever room
        // has a note.
        if (bay.note == null)
          ExcludeSemantics(child: Text('', style: noteStyle))
        else
          Text.rich(
            TextSpan(
              children: [
                if (bay.noteIcon != null)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Icon(
                        bay.noteIcon,
                        size: 14,
                        color: noteStyle.color,
                      ),
                    ),
                  ),
                TextSpan(text: bay.note),
              ],
            ),
            textAlign: TextAlign.center,
            style: noteStyle,
          ),
      ],
    );
    final cell = ConstrainedBox(
      constraints: BoxConstraints(minHeight: desk ? 146 : 112),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          desk ? 8 : 2,
          2,
          desk ? 8 : 2,
          desk ? 12 : 8,
        ),
        child: _WindowAbove(
          minWindow: desk ? 40 : 30,
          gap: desk ? 6 : 4,
          window: Padding(
            padding: EdgeInsets.symmetric(horizontal: desk ? 8 : 6),
            child: window,
          ),
          words: words,
        ),
      ),
    );
    // A bay's face is its whole wall, window and words: ui_core's row and keyline checks read it by its box.
    return bay.onPressed == null
        ? cell
        : NeumorphicTap(
            onPressed: bay.onPressed,
            label: bay.name,
            child: DesignKeylineFace(child: cell),
          );
  }
}

/// Words at the foot, the window taking every pixel above them, however tall the bay is stretched.
class _WindowAbove extends MultiChildRenderObjectWidget {
  _WindowAbove({
    required Widget window,
    required Widget words,
    required this.minWindow,
    required this.gap,
  }) : super(children: [window, words]);
  final double minWindow, gap;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWindowAbove(minWindow, gap);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWindowAbove renderObject,
  ) {
    renderObject
      ..minWindow = minWindow
      ..gap = gap
      ..markNeedsLayout();
  }
}

class _BayData extends ContainerBoxParentData<RenderBox> {}

class _RenderWindowAbove extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BayData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BayData> {
  _RenderWindowAbove(this.minWindow, this.gap);
  double minWindow, gap;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BayData) child.parentData = _BayData();
  }

  @override
  void performLayout() {
    final window = firstChild!, words = lastChild!;
    final w = constraints.maxWidth;
    words.layout(
      BoxConstraints(minWidth: w, maxWidth: w),
      parentUsesSize: true,
    );
    final min = words.size.height + gap + minWindow;
    final height = constraints.hasBoundedHeight
        ? math.max(constraints.maxHeight, min)
        : math.max(constraints.minHeight, min);
    final wh = height - words.size.height - gap;
    window.layout(BoxConstraints.tightFor(width: w, height: wh));
    (words.parentData as _BayData).offset = Offset(
      0,
      height - words.size.height,
    );
    size = constraints.constrain(Size(w, height));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      lastChild!.getMinIntrinsicHeight(width) + gap + minWindow;
  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);
  @override
  double computeMinIntrinsicWidth(double height) =>
      lastChild!.getMinIntrinsicWidth(double.infinity);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      lastChild!.getMaxIntrinsicWidth(double.infinity);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

class _Floor extends StatelessWidget {
  const _Floor(this.bays);
  final List<NeumorphicBay> bays;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final gap = t.desk ? 14.0 : 8.0;
    final columns = bays.length <= 3 ? 3 : (t.desk ? 4 : 3);
    final rows = <Widget>[];
    for (var i = 0; i < bays.length; i += columns) {
      final line = bays.sublist(i, math.min(i + columns, bays.length));
      rows.add(
        NeumorphicGrow(
          child: NeumorphicEqualRow(
            flex: List.filled(columns, 1),
            gap: gap,
            children: [
              for (var j = 0; j < columns; j++)
                j < line.length ? _BayCell(line[j]) : const SizedBox.shrink(),
            ],
          ),
        ),
      );
    }
    return NeumorphicColumn(gap: gap, children: rows);
  }
}

class _Sill extends StatelessWidget {
  const _Sill(this.name);
  final String name;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final desk = t.desk;
    return CustomPaint(
      painter: _BandPainter(
        t.colors,
        NeumorphicFlatScope.of(context),
        desk ? NeumorphicRadii.cap : 6,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: desk ? 26 : 20),
        child: Center(child: Text(name, style: t.textTheme.micro)),
      ),
    );
  }
}

/// The small elevation for a phone's compact band: a gable, a wall, a window per bay, lit by how lit it is.
class _MiniElevation extends CustomPainter {
  _MiniElevation(this.c, this.flat, this.courses);
  final NeumorphicColors c;
  final bool flat;
  final List<NeumorphicCourse> courses;
  @override
  void paint(Canvas canvas, Size s) {
    final gableH = s.height * .3;
    // Its apex and eaves round by the least corner, as the wall's corners do (law 8): a small house is no sharper.
    final sil = neumorphicRoundedPath([
      Offset(0, gableH),
      Offset(s.width / 2, 0),
      Offset(s.width, gableH),
    ]);
    neumorphicPaintRaised(
      canvas,
      sil,
      c,
      light: (const Offset(-3, -3), 6),
      dark: (const Offset(4, 4), 9),
      darkColor: c.shadowDeep,
      flat: flat,
    );
    if (flat) canvas.drawPath(sil, neumorphicStrokePaint(c.quiet, 1));
    final wall = Rect.fromLTRB(5, gableH, s.width - 5, s.height);
    final walled = RRect.fromRectAndRadius(
      wall,
      const Radius.circular(NeumorphicRadii.least),
    );
    neumorphicPaintRaised(
      canvas,
      Path()..addRRect(walled),
      c,
      light: (const Offset(-3, -2), 6),
      dark: (const Offset(5, 5), 11),
      darkColor: c.shadowDeep,
      flat: flat,
    );
    if (flat) canvas.drawRRect(walled, neumorphicStrokePaint(c.quiet, 1));
    final floors = courses.where((e) => e.bays.isNotEmpty).toList();
    if (floors.isEmpty) return;
    final rowH = (wall.height - 8) / floors.length;
    for (var f = 0; f < floors.length; f++) {
      final bays = floors[f].bays.take(4).toList();
      final colW = (wall.width - 8) / bays.length;
      for (var b = 0; b < bays.length; b++) {
        final cell = Rect.fromLTWH(
          wall.left + 4 + b * colW,
          wall.top + 4 + f * rowH,
          colW,
          rowH,
        ).deflate(3);
        final w = math.min(cell.width, (cell.height - 2) * 2).toDouble();
        final box = Rect.fromCenter(
          center: cell.center,
          width: w,
          height: w / 2 + 2,
        );
        // A small window's sill rounds as far as its foot allows: no square corner even at this size.
        final sill = Radius.circular(math.min(NeumorphicRadii.least, w / 8));
        final shape = Path()
          ..addRRect(
            RRect.fromRectAndCorners(
              box,
              topLeft: Radius.circular(w / 2),
              topRight: Radius.circular(w / 2),
              bottomLeft: sill,
              bottomRight: sill,
            ),
          );
        neumorphicPaintPressed(
          canvas,
          shape,
          c,
          light: (const Offset(-1, -1), 2),
          dark: (const Offset(1, 1), 3),
          flat: flat,
        );
        if (bays[b].lit > 0 || bays[b].flag != null) {
          canvas.drawPath(
            shape,
            neumorphicFillPaint(
              c.art.lamp.withValues(alpha: .32 + bays[b].lit * .4),
            ),
          );
        }
        if (flat) canvas.drawPath(shape, neumorphicStrokePaint(c.quiet, 1));
      }
    }
  }

  @override
  bool shouldRepaint(_MiniElevation o) =>
      o.c != c || o.flat != flat || o.courses != courses;
}

/// The hero of a home page: a set of grouped things as one plaster casting, on the wall and not in a card. Each [courses] entry is a floor
/// of bays with its name on a string course; [title] and [subtitle] are cast in the pediment. Use one on an app, on its home. [compact]: on
/// a phone a small elevation beside the words, about 130 tall.
///
/// ```dart
/// NeumorphicRelief(title: '14', subtitle: 'A place', count: '*5 of 9* on', courses: const [NeumorphicCourse('Upper', [NeumorphicBay(name: 'A room', figure: '18.2', note: 'Off')])])
/// ```
class NeumorphicRelief extends StatelessWidget {
  /// Creates a [NeumorphicRelief].
  const NeumorphicRelief({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.title,
    this.subtitle,
    this.count,
    this.courses = const [],
    this.ground = const [],
    this.compact = false,
    this.onPressed,
    this.headerArt,
  });

  /// Optional decorative header. The app owns this art; the package supplies
  /// no static illustration. Words remain separate and grow with text scale.
  final Widget? headerArt;

  /// A big figure or a word, cast in the pediment.
  final String title;

  /// Supporting text beneath the relief heading.
  final String? subtitle;

  /// Over the pediment's right slope, with an LED: how many are live. `*bold*` the count.
  final String? count;

  /// Top floor first. The last one's name goes on the plinth.
  final List<NeumorphicCourse> courses;

  /// The ground band's words. On a phone the middle of three goes.
  final List<NeumorphicGroundNote> ground;

  /// Whether to use the compact arrangement.
  final bool compact;

  /// The whole relief opens something, in its compact form.
  final VoidCallback? onPressed;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final flat = NeumorphicFlatScope.of(context);
    final desk = t.desk;
    final last = courses.isEmpty ? null : courses.last;

    if (compact && !desk) {
      final under = [?subtitle, ?count?.replaceAll('*', '')].join(' · ');
      final band = NeumorphicHeroBand(
        object: neumorphicPaint(112, 120, (
          c,
          flat,
          courses,
        ), (canvas, s) => _MiniElevation(c, flat, courses).paint(canvas, s)),
        // The title is the band's heading and the subtitle stays a line under it, as in the pediment; the live count
        // follows the subtitle.
        title: title,
        body: under.isEmpty ? null : under,
      );
      return onPressed == null
          ? band
          : NeumorphicTap(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: onPressed,
              label: title,
              child: band,
            );
    }

    final head = t.textTheme.text(
      desk ? 48 : 30,
      desk ? 50 : 32,
      weight: FontWeight.w300,
      tracking: -.02,
    );
    final sub = (desk ? t.textTheme.caption : t.textTheme.micro).copyWith(
      fontWeight: FontWeight.w700,
      color: c.inkSecondary,
    );
    final heading = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, textAlign: TextAlign.center, style: head),
        if (subtitle != null)
          Text(subtitle!, textAlign: TextAlign.center, style: sub),
      ],
    );
    final countLine = count == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NeumorphicLed(),
              const SizedBox(width: 8),
              Flexible(
                child: NeumorphicText(
                  count!,
                  style: (desk ? t.textTheme.caption : t.textTheme.micro)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.inkSecondary,
                      ),
                ),
              ),
            ],
          );
    final gable = headerArt == null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [heading, ?countLine],
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(1200.0, constraints.maxWidth);
              final painter = TextPainter(
                text: TextSpan(
                  children: [
                    TextSpan(text: title, style: head),
                    if (subtitle != null)
                      TextSpan(text: '\n$subtitle', style: sub),
                  ],
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: width);
              final inline = painter.height < width * 176 / 620 * .65;
              painter.dispose();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!inline && countLine != null) countLine,
                  NeumorphicFill(
                    maxWidth: 1200,
                    aspect: 620 / 176,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: headerArt!),
                        if (inline)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: desk ? 12 : 6,
                            child: heading,
                          ),
                        if (inline && countLine != null)
                          PositionedDirectional(
                            start: 0,
                            end: 0,
                            top: desk ? 0 : -6,
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: countLine,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!inline)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: heading,
                    ),
                ],
              );
            },
          );
    final side = desk ? 16.0 : 8.0;
    final inner = side + (desk ? 16.0 : 8.0);
    final sillInset = inner - (desk ? 22.0 : 12.0);
    final corniceH = desk ? 20.0 : 14.0;
    final plinthH = desk ? 34.0 : 26.0;
    final floors = <Widget>[];
    for (var i = 0; i < courses.length; i++) {
      floors.add(
        NeumorphicGrow(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: inner),
            child: _Floor(courses[i].bays),
          ),
        ),
      );
      if (i < courses.length - 1) {
        floors.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
              sillInset,
              desk ? 10 : 6,
              sillInset,
              desk ? 14 : 8,
            ),
            child: _Sill(courses[i].name),
          ),
        );
      }
    }
    final block = CustomPaint(
      painter: _WallPainter(c, flat, side, corniceH, plinthH),
      child: NeumorphicColumn(
        children: [
          CustomPaint(
            painter: _BandPainter(
              c,
              flat,
              corniceH / 2,
              light: (const Offset(-5, -3), 10),
              dark: (const Offset(7, 8), 16),
              deep: true,
            ),
            child: SizedBox(height: corniceH),
          ),
          NeumorphicGrow(
            child: Padding(
              padding: EdgeInsets.only(
                top: desk ? 18 : 10,
                bottom: desk ? 14 : 8,
              ),
              child: NeumorphicColumn(children: floors),
            ),
          ),
          CustomPaint(
            painter: _BandPainter(
              c,
              flat,
              desk ? NeumorphicRadii.chip : NeumorphicRadii.cap,
              r2: desk ? NeumorphicRadii.well : NeumorphicRadii.control,
              light: (const Offset(-5, -3), 10),
              dark: (const Offset(8, 10), 20),
              deep: true,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: plinthH),
              child: Center(
                child: Text(last?.name ?? '', style: t.textTheme.micro),
              ),
            ),
          ),
        ],
      ),
    );
    final shown = [
      for (var i = 0; i < ground.length; i++)
        if (desk || ground.length < 3 || i != 1) ground[i],
    ];
    return NeumorphicColumn(
      children: [
        gable,
        NeumorphicGrow(child: block),
        if (shown.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: desk ? 18 : 12),
            child: NeumorphicSurface(
              cast: NeumorphicSurfaceLevel.groove,
              radius: NeumorphicRadii.control,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < shown.length; i++)
                    i == shown.length - 1 && shown.length > 1
                        ? Flexible(child: _GroundText(shown[i], end: true))
                        : Flexible(child: _GroundText(shown[i])),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A short fact on the ground band under a relief.
class NeumorphicGroundNote {
  /// Creates a [NeumorphicGroundNote].
  const NeumorphicGroundNote(this.words, {this.icon});

  /// The text displayed by this indicator.
  final String words;

  /// The glyph displayed with the content.
  final IconData? icon;
}

class _GroundText extends StatelessWidget {
  const _GroundText(this.note, {this.end = false});
  final NeumorphicGroundNote note;
  final bool end;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final style = t.textTheme.micro
        .copyWith(color: t.colors.inkSecondary)
        .tabular;
    return Text.rich(
      TextSpan(
        children: [
          if (note.icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: Icon(note.icon, size: 16, color: t.colors.inkSecondary),
              ),
            ),
          TextSpan(text: note.words),
        ],
      ),
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: style,
    );
  }
}
