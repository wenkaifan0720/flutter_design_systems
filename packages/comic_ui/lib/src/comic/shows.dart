/// People and quantities in the comic's inked frames.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'controls.dart';
import 'glyphs.dart';
import 'localizations.dart';
import 'moves.dart';
import 'press.dart';
import 'theme.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'layout.dart';
import 'tell.dart';
import 'internal/lettering.dart';

Size _avatarSize(double size, ComicStyleOf look) {
  return Size(
    look.minimumSize?.width ?? size,
    look.minimumSize?.height ?? size,
  );
}

/// The line box [initials] lay out in, unconstrained, and the reach of their
/// glyphs (which can pass the line) from its centre, as half extents.
(Size, Size) _measure(
  String initials,
  TextStyle style,
  TextScaler scaler,
  TextDirection direction,
) {
  final painter = TextPainter(
    text: TextSpan(text: initials, style: style),
    textDirection: direction,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final line = painter.size;
  var glyphs = Offset.zero & line;
  for (final box in painter.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: initials.length),
  )) {
    glyphs = glyphs.expandToInclude(box.toRect());
  }
  painter.dispose();
  final cx = line.width / 2, cy = line.height / 2;
  return (
    line,
    Size(
      math.max(cx - glyphs.left, glyphs.right - cx),
      math.max(cy - glyphs.top, glyphs.bottom - cy),
    ),
  );
}

/// The scale (at most 1) at which centred initials, measured by [_measure],
/// keep 4 px clear of [shape]'s inner contour, [rim] inside an outline drawn
/// round a [face]-sized box: with the line box at that scale and the height
/// their glyphs then paint. Null for an outline other than a circle, capsule
/// or rounded rectangle.
(double, Size, double)? _initialsScale(
  OutlinedBorder shape,
  Size face,
  (Size, Size) text,
  double rim,
  TextDirection direction,
) {
  // The glyph box grown by 4 px on every side must stay inside the contour.
  const gap = 4.25;
  final (line, reach) = text;
  final half = face.shortestSide / 2;
  final double outer;
  if (shape is CircleBorder || shape is StadiumBorder) {
    outer = half + rim;
  } else if (shape is RoundedRectangleBorder) {
    final r = shape.borderRadius.resolve(direction);
    outer = math.min(
      half + rim,
      [
        r.topLeft.x,
        r.topLeft.y,
        r.topRight.x,
        r.topRight.y,
        r.bottomLeft.x,
        r.bottomLeft.y,
        r.bottomRight.x,
        r.bottomRight.y,
      ].reduce(math.max),
    );
  } else {
    return null;
  }
  final width = face.width / 2, height = face.height / 2;
  final radius = math.max(0.0, outer - rim);
  if (width <= gap || height <= gap || reach.isEmpty) {
    return (0, Size.zero, 0);
  }
  bool fits(double s) {
    final a = reach.width * s + gap, b = reach.height * s + gap;
    if (a > width || b > height) return false;
    final cx = width - radius, cy = height - radius;
    if (a <= cx || b <= cy) return true;
    final dx = a - cx, dy = b - cy;
    return dx * dx + dy * dy <= radius * radius;
  }

  var scale = 1.0;
  if (!fits(1)) {
    var lo = 0.0, hi = 1.0;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) / 2;
      if (fits(mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    scale = lo;
  }
  return (scale, line * scale, reach.height * 2 * scale);
}

/// A framed photo with an initials fallback while loading or on failure.
///
/// ```dart
/// ComicAvatar('NW', name: 'Nia Walker', image: NetworkImage(url))
/// ```
class ComicAvatar extends StatelessWidget {
  /// Creates an avatar with caller-owned image data.
  const ComicAvatar(
    this.initials, {
    super.key,
    this.style,
    this.image,
    this.name,
    this.size = 40,
    this.selected = false,
  }) : assert(size > 0);

  /// Initials visible until a photo is available.
  /// Appearance above the avatar component theme.
  final ComicStyle? style;

  /// Letters shown when no portrait is supplied.
  final String initials;

  /// Optional photo provider.
  final ImageProvider? image;

  /// Accessible person name; defaults to initials.
  final String? name;

  /// Preferred frame size. Component styles can supply a larger minimum.
  final double size;

  /// Emphasizes the frame with the caption ink.
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = ComicTheme.of(context).colors;
    final look = ComicStyleOf([
          style,
          t.avatarTheme,
        ], comicStates(selected: selected)),
        rim = comicRim(
          t,
          ComicStyleOf([style, t.avatarTheme], comicStates(selected: selected)),
          c.nightLine,
        );
    final frame = _avatarSize(size, look);
    Widget fallback(OutlinedBorder? shape) {
      final direction = Directionality.of(context);
      final fill =
          look.fill ??
          (selected
              ? c.caption
              : c.dark
              ? c.card
              : c.control);
      // The face keeps its own fill inside a filled ground (a chosen row's caption), whose rescoped inks are
      // for that ground, not this face: the letters read on the face itself.
      final ink = t.type.title
          .merge(look.textStyle)
          .copyWith(
            color:
                look.foreground ??
                comicInkOn(
                  fill,
                  selected
                      ? c.onCaption
                      : c.dark
                      ? c.text
                      : c.onPaper,
                  [c.onPaper, c.paper, c.onCaption, c.caption],
                ),
          );
      // Initials take the largest size, up to the title's, at which their
      // glyphs keep 4 px clear of the face's own outline: measured against
      // the circle or rounded rectangle itself rather than a square inscribed
      // in it, which shrank a small avatar's letters to a speck. Where two
      // letters would stand under 10 px, the first stands alone, larger.
      final outline = shape ?? t.shapes.full;
      final face = Size(
        frame.width - rim.width * 2,
        frame.height - rim.width * 2,
      );
      final scaler = MediaQuery.textScalerOf(context);
      var shown = initials;
      var scale = _initialsScale(
        outline,
        face,
        _measure(shown, ink, scaler, direction),
        rim.width,
        direction,
      );
      if (scale != null && scale.$3 < 10 && shown.characters.length > 1) {
        shown = shown.characters.first;
        scale = _initialsScale(
          outline,
          face,
          _measure(shown, ink, scaler, direction),
          rim.width,
          direction,
        );
      }
      final text = Text(shown, maxLines: 1, softWrap: false, style: ink);
      final Widget letters;
      if (scale != null) {
        letters = Center(
          child: SizedBox.fromSize(
            size: scale.$2,
            child: FittedBox(child: text),
          ),
        );
      } else {
        // Another outline (a burst): fit to the square its corners leave.
        letters = Padding(
          padding: (shape?.dimensions ?? EdgeInsets.zero).add(
            EdgeInsets.all(
              4 +
                  comicCornerInset(
                    shape,
                    direction,
                    shortestSide: frame.shortestSide - rim.width * 2,
                  ),
            ),
          ),
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: text),
          ),
        );
      }
      return ColoredBox(color: fill, child: letters);
    }

    return Semantics(
      image: true,
      label: name ?? initials,
      child: ExcludeSemantics(
        child: comicOwnSize(
          width: frame.width,
          height: frame.height,
          child: AnimatedComicShape(
            shape: look.shape ?? t.shapes.full,
            builder: (context, shape) => DecoratedBox(
              decoration: ShapeDecoration(
                color:
                    look.fill ??
                    (selected
                        ? c.caption
                        : c.dark
                        ? c.card
                        : c.control),
                shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                  side: rim,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(rim.width),
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: comicInsetShape(shape ?? t.shapes.full, rim.width),
                  ),
                  child: image == null
                      ? fallback(shape)
                      : Image(
                          image: image!,
                          fit: BoxFit.cover,
                          frameBuilder:
                              (context, picture, frame, synchronous) =>
                                  frame == null && !synchronous
                                  ? fallback(shape)
                                  : picture,
                          errorBuilder: (_, _, _) => fallback(shape),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data for a face pile.
@immutable
class ComicFace {
  /// Creates a face with initials and an optional photo.
  const ComicFace(this.initials, {this.image, this.name});

  /// Fallback initials.
  final String initials;

  /// Optional image.
  final ImageProvider? image;

  /// Accessible name.
  final String? name;
  @override
  bool operator ==(Object other) =>
      other is ComicFace &&
      other.initials == initials &&
      other.image == image &&
      other.name == name;
  @override
  int get hashCode => Object.hash(initials, image, name);
}

/// Overlapping framed faces, followed by the number of remaining people.
///
/// ```dart
/// ComicAvatarGroup([ComicFace('NW'), ComicFace('AK')], label: 'Contributors')
/// ```
class ComicAvatarGroup extends StatelessWidget {
  /// Creates a face pile.
  const ComicAvatarGroup(
    this.faces, {
    super.key,
    this.max = 4,
    this.size = 36,
    this.label,
  }) : assert(max >= 0),
       assert(size > 0);

  /// People in reading order.
  final List<ComicFace> faces;

  /// Maximum visible faces before the remaining count.
  final int max;

  /// Preferred frame size. Custom marks and the avatar theme may enlarge it.
  final double size;

  /// Overrides the joined names or initials.
  final String? label;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final frame = _avatarSize(size, ComicStyleOf([t.avatarTheme], const {}));
    final shown = faces.take(max).toList(),
        rest = faces.length - faces.take(max).length;
    final n = shown.length + (rest > 0 ? 1 : 0), step = frame.width * .75;
    return Semantics(
      label:
          label ?? faces.map((face) => face.name ?? face.initials).join(', '),
      child: ExcludeSemantics(
        child: comicOwnSize(
          width: n == 0 ? 0 : frame.width + step * (n - 1),
          height: frame.height,
          child: Stack(
            children: [
              if (rest > 0)
                PositionedDirectional(
                  start: shown.length * step,
                  child: ComicAvatar('+$rest', size: size),
                ),
              for (var i = shown.length - 1; i >= 0; i--)
                PositionedDirectional(
                  start: i * step,
                  child: ComicAvatar(
                    shown[i].initials,
                    name: shown[i].name,
                    image: shown[i].image,
                    size: size,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A measured quantity with a value, unit and ruled bar.
///
/// ```dart
/// ComicMeter(label: 'Capacity', value: 35, max: 100, unit: 'pages')
/// ```
class ComicMeter extends StatelessWidget {
  /// Creates a meter.
  const ComicMeter({
    super.key,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.unit,
  }) : assert(max > min);

  /// Quantity name.
  final String label;

  /// Measured value.
  final double value;

  /// Scale start.
  final double min;

  /// Scale end.
  final double max;

  /// Optional unit suffix.
  final String? unit;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context),
        words =
            '${value == value.roundToDouble() ? value.toInt() : value}${unit == null ? '' : ' $unit'}';
    return Semantics(
      label: label,
      value: words,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(label, style: t.type.title),
                Text(words, style: t.type.body),
              ],
            ),
            const SizedBox(height: 8),
            ComicLinearProgressIndicator(
              value: ((value - min) / (max - min)).clamp(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row of panels that slides sideways one at a time: the next one peeks at the edge, page dots below say where you
/// are, and on a wide window a step back and a step on stand beside the dots. Each item is clipped to the medium
/// corner, so pictures follow the shape theme.
///
/// ```dart
/// ComicCarouselView(label: 'This week', children: [for (final p in picks) ComicPictureCard(slotId: p.slotId, title: p.title)])
/// ```
class ComicCarouselView extends StatefulWidget {
  /// Creates a carousel.
  const ComicCarouselView({
    super.key,
    required this.label,
    required this.children,
    this.height = 220,
    this.itemWidth,
    this.initialIndex = 0,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  /// The carousel's accessible name.
  final String label;

  /// The items, in order.
  final List<Widget> children;

  /// The items' height.
  final double height;

  /// An item's width; null takes 86% of a phone's width and 40% of a wide one.
  final double? itemWidth;

  /// The item shown first.
  final int initialIndex;

  /// Reports the item that settles in view.
  final ValueChanged<int>? onChanged;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  State<ComicCarouselView> createState() => _ComicCarouselState();
}

class _ComicCarouselState extends State<ComicCarouselView> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final words = ComicLocalizations.of(context);
    final motion = ComicMotion.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final count = widget.children.length;
    if (count == 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth.isFinite ? box.maxWidth : 390.0;
        final share = widget.itemWidth == null
            ? (t.desk ? .4 : .86)
            : (widget.itemWidth! / width).clamp(.2, 1.0);
        // The item in view starts on the column's edge and the next peeks at its end: the page view is
        // laid out wider than the column, by the room it keeps before a centred page, with that room standing
        // outward and cut at the column's edge.
        final item = share * width;
        final viewport = 2 * width - item;
        final fraction = item / viewport;
        return DesignCarousel(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          // The kit's page view keeps the fraction it was built with.
          key: ValueKey(fraction),
          itemCount: count,
          initialPage: _index,
          viewportFraction: fraction,
          semanticLabel: widget.label,
          slideLabel: (index, total) => words.page(index + 1, total),
          duration: motion.state == Duration.zero
              ? Duration.zero
              : motion.travel,
          onPageChanged: (i) {
            setState(() => _index = i);
            widget.onChanged?.call(i);
          },
          // A neighbour peeking at the edge is a glimpse, not a target: a sliver of it is too narrow to press, and a
          // screen reader reaches it through the dots and the steps. It takes presses once it settles in view.
          itemBuilder: (context, i) => IgnorePointer(
            ignoring: i != _index,
            child: ExcludeSemantics(
              excluding: i != _index,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: t.shapes.medium,
                    textDirection: Directionality.of(context),
                  ),
                  child: widget.children[i],
                ),
              ),
            ),
          ),
          layoutBuilder: (context, pages, controls) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: widget.height,
                child: ComicHighlight(
                  states: controls.focused
                      ? const <WidgetState>{WidgetState.focused}
                      : const <WidgetState>{},
                  shape: t.shapes.medium,
                  wash: false,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerEnd,
                      minWidth: viewport,
                      maxWidth: viewport,
                      child: pages,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // The steps and the dots start where the item in view does.
              Row(
                spacing: 16,
                children: [
                  if (t.desk)
                    ComicIconButton(
                      rtl ? ComicGlyphs.chevronRight : ComicGlyphs.chevronLeft,
                      label: words.previous,
                      onPressed: controls.previous,
                    ),
                  Flexible(
                    child: ComicPageDots(
                      count: controls.count,
                      selectedIndex: controls.page,
                      label: widget.label,
                      onChanged: controls.goToPage,
                    ),
                  ),
                  if (t.desk)
                    ComicIconButton(
                      rtl ? ComicGlyphs.chevronLeft : ComicGlyphs.chevronRight,
                      label: words.next,
                      onPressed: controls.next,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
