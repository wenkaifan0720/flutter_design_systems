import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../internal/styled.dart';
import '../theme.dart';
import 'media_slots.dart';

/// What a [MinimalPlaceholderImage] stands for: it picks the placeholder's glyph and
/// seeds its tint.
enum MinimalMediaKind {
  /// A dish, a drink, a table.
  food,

  /// A place, a stay, a trip.
  travel,

  /// A thing for sale.
  product,

  /// A room, a space.
  interior,

  /// A pattern, a texture: nothing in particular.
  abstract,

  /// A face.
  avatar,

  /// A sport, a workout.
  athletic,

  /// A gathering, a stage, a ticket.
  event,

  /// A landscape, a plant, an animal.
  nature,
}

/// Reference to a placeholder image — never a URL, because network images
/// are banned so every render is deterministic and offline-safe.
///
/// The kind and the index seed the painter, so the same reference always
/// draws the same placeholder.
///
/// ```dart
/// MinimalPlaceholderImage(MinimalMediaKind.product, 3)
/// ```
@immutable
class MinimalPlaceholderImage {
  /// The [index]th placeholder of [kind].
  const MinimalPlaceholderImage(this.kind, this.index);

  /// What it stands for.
  final MinimalMediaKind kind;

  /// Which one: the same index draws the same placeholder.
  final int index;
}

/// An image in the theme's `shapes.small` inside a hairline — real corpus imagery
/// for a declared media slot, or Minimal's placeholder while it is
/// pending: a muted, deterministic gradient under a faint diagonal hatch,
/// the drafting-table sign for "an image goes here".
///
/// [MinimalMedia.media] renders the photograph resolved for one of the plan's
/// declared media slots (`assets/media/<slot>.jpg`, or the durable
/// reference `assets/media/remote.json` maps it to). While a linked photo
/// is still being made the placeholder carries a slow sheen, and the photo
/// replaces it when it lands. An unresolved or failed slot paints the
/// placeholder seeded from the slot id — a page is never wrong to
/// reference a declared slot. For an API that takes an [ImageProvider],
/// [MinimalMediaSource.image] is the same slot. The positional form keeps the
/// pure
/// placeholder for imagery no slot covers. Decorative unless given a
/// [semanticLabel].
///
/// ```dart
/// MinimalMedia.media('hero-bakery', height: 180)
/// ```
class MinimalMedia extends StatelessWidget {
  /// The placeholder [src] in a frame.
  const MinimalMedia(
    MinimalPlaceholderImage this.src, {
    super.key,
    this.width,
    this.height,
    this.radius,
    this.shape,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  }) : media = null;

  /// The photograph resolved for the declared plan media slot [media].
  const MinimalMedia.media(
    String this.media, {
    super.key,
    this.width,
    this.height,
    this.radius,
    this.shape,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  }) : src = null;

  /// The placeholder it draws; null for a slot's photograph.
  final MinimalPlaceholderImage? src;

  /// The declared media slot id, in the media form.
  final String? media;

  /// Unstated, the image FILLS THE CROSS AXIS — see the note in [build].
  final double? width;

  /// Its height; null leaves it to the parent.
  final double? height;

  /// One corner radius for this image; null takes [shape].
  final double? radius;

  /// The frame's outline; null (with no [radius]) takes the theme's
  /// `shapes.small`, so the image follows the corner setting.
  final OutlinedBorder? shape;

  /// How a photograph sits in its frame. The placeholder always covers its
  /// box.
  final BoxFit fit;

  /// What the image shows, for a screen reader. Null leaves the image
  /// decorative (silent).
  final String? semanticLabel;

  /// The deterministic seed a slot id paints with when its slot resolved to
  /// nothing. String.hashCode is not stable across runs, so the seed is its
  /// own arithmetic.
  static MinimalPlaceholderImage _slotFallback(String slotId) {
    var hash = 0;
    for (final unit in slotId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    const kinds = MinimalMediaKind.values;
    return MinimalPlaceholderImage(
      kinds[hash % kinds.length],
      (hash ~/ 7) % 97,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final slotId = media;
    final Widget content;
    if (slotId != null) {
      content = MinimalMediaImage(
        slotId: slotId,
        fit: fit,
        // The graceful miss: an unresolved slot paints the placeholder
        // instead of the framework's missing-asset error box.
        fallback: _Placeholder(src: _slotFallback(slotId), tokens: t),
      );
    } else {
      content = _Placeholder(src: src!, tokens: t);
    }
    final r = radius;
    final frame =
        shape ??
        (r == null
            ? t.shapes.small
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)));
    final image = Container(
      // Under LOOSE horizontal constraints — what a Stack hands its
      // non-positioned children, and what a CrossAxisAlignment.start column
      // hands its own — an unstated width means the width the caller has,
      // which is what every full-bleed register asks for.
      width: width ?? double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: minimalFrame(frame.copyWith(side: BorderSide.none)),
      // The hairline sits over the picture, so a photograph and a
      // placeholder share one edge with the page's other objects.
      foregroundDecoration: minimalFrame(
        frame,
        side: BorderSide(color: t.border, width: t.hairline),
      ),
      child: content,
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: image);
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(child: image),
    );
  }
}

/// The placeholder: a flat quiet fill (no light falls on Minimal, so no
/// gradient; nothing on the page is coloured, so no hue), a step lighter or
/// darker by index so a grid of them still reads as several pictures, a
/// faint 45° hatch, and on a small tile the kind's glyph.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.src, required this.tokens});

  final MinimalPlaceholderImage src;
  final MinimalThemeData tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final dark = !t.isLightAppearance;
    final seed = (src.kind.index * 53 + src.index * 29) % 3;
    // The quiet fill, or one or two steps on toward the well: close to the
    // ground in both appearances, so a placeholder never shouts over the
    // content beside it.
    final fill = Color.lerp(t.muted, t.sunken, seed / 2)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The glyph helps a small tile read as imagery; on a hero-sized
        // fill it reads as a broken image, so large fills stay bare.
        final large =
            constraints.maxWidth >= 110 || constraints.maxHeight >= 110;
        return DecoratedBox(
          decoration: BoxDecoration(color: fill),
          child: CustomPaint(
            painter: _Hatch(t.foreground.withValues(alpha: dark ? 0.06 : 0.05)),
            // Bare, the hatch takes the box it is given (nothing along an
            // unbounded axis, as a childless Container would).
            size: Size(
              constraints.hasBoundedWidth ? constraints.maxWidth : 0,
              constraints.hasBoundedHeight ? constraints.maxHeight : 0,
            ),
            child: large
                ? null
                : Center(
                    child: MinimalIcon(
                      switch (src.kind) {
                        MinimalMediaKind.food => LucideIcons.utensils,
                        MinimalMediaKind.travel => LucideIcons.plane,
                        MinimalMediaKind.product => LucideIcons.package,
                        MinimalMediaKind.interior => LucideIcons.house,
                        MinimalMediaKind.abstract => LucideIcons.shapes,
                        MinimalMediaKind.avatar => LucideIcons.user,
                        MinimalMediaKind.athletic => LucideIcons.dumbbell,
                        MinimalMediaKind.event => LucideIcons.calendar,
                        MinimalMediaKind.nature => LucideIcons.leaf,
                      },
                      size: MinimalIconSize.i18,
                      color: t.textTertiary,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// A faint 45° hatch, one hairline every [_pitch] px.
class _Hatch extends CustomPainter {
  const _Hatch(this.color);

  final Color color;

  static const double _pitch = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += _pitch) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Hatch oldDelegate) => color != oldDelegate.color;
}
