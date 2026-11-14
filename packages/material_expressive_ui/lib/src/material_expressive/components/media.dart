/// Media: the image in a declared media slot, masked by the corner scale or
/// a library shape, and the avatar — a photo, initials or a glyph in a small
/// fixed shape (CONTRACT §4.1 `image`, `avatar`). Owner: w3-media.
///
/// Compose has no image or avatar component of its own: Material's image is
/// `Image` clipped by a shape (`Modifier.clip(shape)`), and its avatar is the
/// list item's leading avatar (`ListTokens.ItemLeadingAvatar*`: a 40dp
/// `primaryContainer` circle with its initials in `titleMedium`
/// `onPrimaryContainer`). Both are ported from those tokens.
///
/// - Delivery is the design kit's [MediaSlotImage] (bundled asset or the
///   host's durable URL, retries while mounted); this file draws only the
///   placeholder it passes and the mask.
/// - A library-shape mask on an image or an avatar is a hero moment
///   (CONTRACT §3): it asserts an [ExpressiveHeroMoment] ancestor. Masks never go
///   on text; the corner scale is not a hero.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../color.dart';
import '../elevation.dart';
import '../component_themes.dart';
import '../icons.dart';
import '../internal/tokens/app_bar_tokens.g.dart';
import '../internal/tokens/chips_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/large_icon_button_tokens.g.dart';
import '../internal/tokens/list_tokens.g.dart';
import '../internal/tokens/medium_icon_button_tokens.g.dart';
import '../internal/tokens/x_small_icon_button_tokens.g.dart';
import '../shape.dart';
import '../spacing.dart';
import '../theme.dart';
import 'hero.dart';

/// The largest positive 31-bit integer: the hash's mask.
const int _mask31 = 2147483647;

/// The hash's stirring multiplier.
const int _stir = 23505;

/// A stable hash of [text]: `String.hashCode` differs between runs, and a
/// placeholder's or an avatar's tone must not. Every product stays under
/// 2^53, so the web computes the same value as the VM.
int _stableHash(String text) {
  var hash = 0;
  for (final code in text.codeUnits) {
    hash = (hash * 31 + code) & _mask31;
  }
  hash ^= hash >> 13;
  hash = (hash * _stir) & _mask31;
  return hash ^ (hash >> 15);
}

/// The container family a placeholder or an avatar wears: one of the
/// scheme's three accent containers, with its on-container ink.
enum ExpressiveMediaTone {
  /// `primaryContainer` / `onPrimaryContainer` (Material's list avatar).
  primary,

  /// `secondaryContainer` / `onSecondaryContainer`.
  secondary,

  /// `tertiaryContainer` / `onTertiaryContainer`.
  tertiary;

  /// The tone [seed] always gets: a name or a slot id picks one of the
  /// three, the same one every time.
  static ExpressiveMediaTone of(String seed) =>
      values[_stableHash(seed) % values.length];

  /// The container colour of this tone in [colors].
  Color containerIn(ExpressiveColorScheme colors) => switch (this) {
    primary => colors.role(ListTokens.itemLeadingAvatarColor),
    secondary => colors.secondaryContainer,
    tertiary => colors.tertiaryContainer,
  };

  /// The ink on [containerIn].
  Color contentIn(ExpressiveColorScheme colors) => switch (this) {
    primary => colors.role(ListTokens.itemLeadingAvatarLabelColor),
    secondary => colors.onSecondaryContainer,
    tertiary => colors.onTertiaryContainer,
  };
}

/// What stands in for a picture while it is pending or missing, in the
/// look's own material: one tone's container, and on it two of Material's
/// library shapes (a large one in the tone's ink, faint, running off an
/// edge, and a smaller one in another tone's container), as Material 3
/// Expressive's own illustrations compose them. A box too small for the
/// shapes to read (under 96dp on its short side) shows the `image` glyph
/// in the tone's ink instead. [seed] (the slot id) picks the tone, the
/// shapes and where they sit, so a grid of pending pictures is varied and
/// stable.
class ExpressiveImagePlaceholder extends StatelessWidget {
  /// A placeholder whose tone is picked by [seed].
  const ExpressiveImagePlaceholder({
    this.seed = '',
    this.glyph = true,
    this.style,
    super.key,
  }) : _framed = true;

  const ExpressiveImagePlaceholder._plain({required this.seed, this.style})
    : glyph = true,
      _framed = false;

  final bool _framed;

  /// Visual overrides for the fallback fill and image glyph.
  final ExpressiveComponentThemeData? style;

  /// What picks the tone: the slot id.
  final String seed;

  /// Whether the `image` glyph is drawn (off for a very small picture).
  final bool glyph;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    final visual = theme.imageTheme.merge(style);
    const states = <WidgetState>{};
    final fill = visual.backgroundColor?.resolve(states);
    final tone = ExpressiveMediaTone.of(seed);
    if (fill == null) {
      final art = CustomPaint(
        painter: _ShapeArtPainter(
          seed: seed,
          ground: tone.containerIn(colors),
          ink: tone.contentIn(colors),
          other: ExpressiveMediaTone
              .values[(tone.index + 1) % ExpressiveMediaTone.values.length]
              .containerIn(colors),
          glyph: glyph
              ? (
                  ExpressiveSymbols.image,
                  visual.iconSize?.resolve(states) ??
                      MediumIconButtonTokens.iconSize,
                  visual.foregroundColor?.resolve(states) ??
                      tone.contentIn(colors),
                )
              : null,
        ),
        child: const SizedBox.expand(),
      );
      return _framed
          ? ExpressiveSurface(
              componentStyle: visual,
              shape: theme.shapes.none,
              color: tone.containerIn(colors),
              child: art,
            )
          : art;
    }
    // A fill of the app's own: that colour, and the glyph on it.
    final wash = ColoredBox(
      color: fill,
      child: glyph
          ? Center(
              child: ExcludeSemantics(
                child: Icon(
                  ExpressiveSymbols.image,
                  size:
                      visual.iconSize?.resolve(states) ??
                      MediumIconButtonTokens.iconSize,
                  color:
                      visual.foregroundColor?.resolve(states) ??
                      tone.contentIn(colors),
                ),
              ),
            )
          : const SizedBox.expand(),
    );
    return _framed
        ? ExpressiveSurface(
            componentStyle: visual,
            shape: theme.shapes.none,
            color: colors.surfaceContainerHighest,
            child: wash,
          )
        : wash;
  }
}

/// The placeholder's art: the tone's container; on it a large library
/// shape in the tone's ink, faint, off a corner, and a smaller one in the
/// next tone's container across from it, each turned. [seed] picks both
/// shapes, the corner and the turns. Under [_artMinimum] on its short side
/// the shapes would not read, and [glyph] (the `image` symbol, its size and
/// colour) stands in their place.
class _ShapeArtPainter extends CustomPainter {
  _ShapeArtPainter({
    required this.seed,
    required this.ground,
    required this.ink,
    required this.other,
    required this.glyph,
  });

  final String seed;
  final Color ground;
  final Color ink;
  final Color other;
  final (IconData, double, Color)? glyph;

  /// The short side under which the shapes would not read.
  static const double _artMinimum = 96;

  /// The large shapes: the library's rounded, many-lobed ones.
  static const List<ExpressiveMaterialShape> _large = [
    ExpressiveMaterialShape.cookie9Sided,
    ExpressiveMaterialShape.sunny,
    ExpressiveMaterialShape.flower,
    ExpressiveMaterialShape.cookie12Sided,
    ExpressiveMaterialShape.softBurst,
    ExpressiveMaterialShape.clover8Leaf,
  ];

  /// The small shapes: plainer ones, to sit against the large.
  static const List<ExpressiveMaterialShape> _small = [
    ExpressiveMaterialShape.pill,
    ExpressiveMaterialShape.gem,
    ExpressiveMaterialShape.arch,
    ExpressiveMaterialShape.clover4Leaf,
    ExpressiveMaterialShape.cookie4Sided,
    ExpressiveMaterialShape.slanted,
  ];

  void _shape(
    Canvas canvas,
    ExpressiveMaterialShape shape,
    Offset center,
    double side,
    double turn,
    Color color,
  ) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(turn);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: side,
      height: side,
    );
    canvas
      ..drawPath(
        ExpressiveMaterialShapeBorder(shape).getOuterPath(rect),
        Paint()..color = color,
      )
      ..restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = ground);
    final short = size.shortestSide;
    if (!short.isFinite || short <= 0) return;
    if (short < _artMinimum) {
      final glyph = this.glyph;
      if (glyph == null) return;
      final (icon, iconSize, color) = glyph;
      final text = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: iconSize,
            height: 1,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, bounds.center - text.size.center(Offset.zero));
      text.dispose();
      return;
    }
    final hash = _stableHash(seed);
    final large = short * 1.1;
    final small = short * .42;
    // The large shape off one of the four corners, the small one across
    // from it, inside.
    final corner = hash % 4;
    final right = corner.isOdd;
    final down = corner >= 2;
    canvas
      ..save()
      ..clipRect(bounds);
    _shape(
      canvas,
      _large[(hash >> 2) % _large.length],
      Offset(
        right ? size.width - large * .12 : large * .12,
        down ? size.height - large * .12 : large * .12,
      ),
      large,
      (hash >> 5) % 360 * math.pi / 180,
      Color.lerp(ground, ink, .12)!,
    );
    _shape(
      canvas,
      _small[(hash >> 9) % _small.length],
      Offset(
        right ? size.width * .18 + small / 2 : size.width * .82 - small / 2,
        down ? size.height * .16 + small / 2 : size.height * .84 - small / 2,
      ),
      small,
      ((hash >> 12) % 8 - 4) * math.pi / 16,
      other,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShapeArtPainter old) =>
      old.seed != seed ||
      old.ground != ground ||
      old.ink != ink ||
      old.other != other ||
      old.glyph != glyph;
}

/// A picture in a declared media slot (the design kit's resolver), filling
/// its box by [fit], at [aspectRatio] when given, masked by [corner] on the
/// theme's corner scale — or, with [ExpressiveMedia.shaped], by a library
/// shape (a hero moment).
///
/// While the picture is pending, and when it misses, [placeholder] stands
/// in ([ExpressiveImagePlaceholder] when null): layout, first paint and
/// publication never wait for it. Announced as an image of [semanticLabel];
/// decorative (silent) when that is null.
///
/// ```dart
/// ExpressiveMedia(slotId: 'hero', aspectRatio: 16 / 9, corner: ExpressiveCorner.extraLarge)
/// ```
class ExpressiveMedia extends StatelessWidget {
  /// An image of the media slot [slotId].
  const ExpressiveMedia({
    required this.slotId,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.corner = ExpressiveCorner.none,
    this.placeholder,
    this.semanticLabel,
    this.style,
    super.key,
  }) : shape = null;

  /// A picture masked by the library [shape] (Compose's
  /// `Modifier.clip(MaterialShapes.X.toShape())`), square by default: a
  /// hero moment, which asserts an [ExpressiveHeroMoment] ancestor (CONTRACT §3).
  const ExpressiveMedia.shaped({
    required this.slotId,
    required ExpressiveMaterialShape this.shape,
    this.aspectRatio = 1,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.semanticLabel,
    this.style,
    super.key,
  }) : corner = ExpressiveCorner.none;

  /// Stateful visual overrides for the image frame and fallback glyph.
  final ExpressiveComponentThemeData? style;

  /// The declared media slot the picture resolves from.
  final String slotId;

  /// The width-to-height ratio of the box; when null the picture fills the
  /// incoming constraints (square where they are unbounded).
  final double? aspectRatio;

  /// How the picture fills its box.
  final BoxFit fit;

  /// Where the picture sits when [fit] crops it: a subject low in its
  /// frame (a plant on a table) pinned `bottomCenter` keeps the subject,
  /// not the wall above it.
  final AlignmentGeometry alignment;

  /// The corner the box is rounded by, on the theme's corner scale.
  final ExpressiveCorner corner;

  /// The library shape the picture is masked by ([ExpressiveMedia.shaped]).
  final ExpressiveMaterialShape? shape;

  /// What stands in while the picture is pending or missing.
  final Widget? placeholder;

  /// What a screen reader says; the picture is decorative when null.
  final String? semanticLabel;

  /// The mask this picture is clipped by in [theme].
  ShapeBorder maskIn(ExpressiveThemeData theme) {
    final library = shape;
    return theme.imageTheme
            .merge(style)
            .shape
            ?.resolve(const <WidgetState>{}) ??
        (library == null
            ? theme.shapes.corner(corner)
            : ExpressiveMaterialShapeBorder(library));
  }

  @override
  Widget build(BuildContext context) {
    if (shape != null) {
      assert(
        ExpressiveHeroMoment.debugCheck(context, 'ExpressiveMedia.shaped'),
      );
    }
    final theme = context.expressiveTheme;
    Widget picture = MediaSlotImage(
      slotId: slotId,
      fit: fit,
      alignment: alignment,
      fallback:
          placeholder ??
          ExpressiveImagePlaceholder._plain(seed: slotId, style: style),
    );
    picture = SizedBox.expand(child: picture);
    picture = ExpressiveSurface(
      componentStyle: theme.imageTheme,
      style: style,
      clipBehavior:
          corner == ExpressiveCorner.none &&
              shape == null &&
              theme.imageTheme.merge(style).shape?.resolve({}) == null
          ? Clip.none
          : Clip.antiAlias,
      shape: maskIn(theme),
      color: expressiveTransparent,
      child: picture,
    );
    final ratio = aspectRatio;
    if (ratio != null) {
      picture = AspectRatio(aspectRatio: ratio, child: picture);
    } else {
      // No ratio: the picture fills its box. A box unbounded on an axis (a
      // scrolling column) has none to fill, so it falls back to square.
      final bounded = picture;
      picture = LayoutBuilder(
        builder: (context, constraints) =>
            constraints.hasBoundedWidth && constraints.hasBoundedHeight
            ? bounded
            : AspectRatio(aspectRatio: 1, child: bounded),
      );
    }
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: picture)
        : Semantics(
            image: true,
            label: label,
            child: ExcludeSemantics(child: picture),
          );
  }
}

/// The avatar's sizes. `m` is Material's (`ListTokens.ItemLeadingAvatar*`:
/// 40dp, initials in `titleMedium`); the others take the sizes Material's
/// own avatars wear elsewhere — the chip's 24, the app bar's 32 — and the
/// icon button's containers (56, 96), each with that component's icon size.
enum ExpressiveAvatarSize {
  /// 24dp: a chip's avatar (`ChipsTokens.AvatarSize`), in a dense row or a
  /// stack.
  extraSmall(
    ChipsTokens.avatarSize,
    ChipsTokens.leadingIconSize,
    ExpressiveTypeKey.labelSmall,
  ),

  /// 32dp: an app bar's avatar (`AppBarTokens.AvatarSize`).
  small(
    AppBarTokens.avatarSize,
    XSmallIconButtonTokens.iconSize,
    ExpressiveTypeKey.labelLarge,
  ),

  /// 40dp: a list item's leading avatar, Material's avatar.
  medium(
    ListTokens.itemLeadingAvatarSize,
    ListTokens.itemLeadingIconSize,
    ListTokens.itemLeadingAvatarLabelFont,
  ),

  /// 56dp: a profile header's avatar (the medium icon button's container).
  large(
    MediumIconButtonTokens.containerHeight,
    MediumIconButtonTokens.iconSize,
    ExpressiveTypeKey.titleLarge,
  ),

  /// 96dp: a profile page's portrait (the large icon button's container).
  extraLarge(
    LargeIconButtonTokens.containerHeight,
    LargeIconButtonTokens.iconSize,
    ExpressiveTypeKey.headlineLarge,
  );

  const ExpressiveAvatarSize(this.dimension, this.iconSize, this.label);

  /// The avatar's side, in dp.
  final double dimension;

  /// The glyph's size in an icon avatar.
  final double iconSize;

  /// The initials' style.
  final ExpressiveTypeKey label;
}

/// A person's or an entity's face in a small fixed shape: the photo in
/// [slotId] when given (the initials standing in while it is pending or
/// missing), else [icon] when given, else the initials of [name] — on a
/// tone's container: [tone], or when that is null the tone [name] always
/// picks, so a list of people is varied and each person keeps a colour
/// (`ExpressiveMediaTone.primary` is Material's list avatar exactly).
///
/// The shape is a circle (`ListTokens.ItemLeadingAvatarShape`, corner
/// full); [shape] masks it with a library shape instead — a hero moment,
/// which asserts an [ExpressiveHeroMoment] ancestor. Announced as an image of
/// [name].
///
/// ```dart
/// ExpressiveAvatar(name: 'Mara Quist', slotId: 'face-mara', size: ExpressiveAvatarSize.large)
/// ```
class ExpressiveAvatar extends StatelessWidget {
  /// An avatar for [name], showing the photo in [slotId] or [icon] when given.
  const ExpressiveAvatar({
    required this.name,
    this.slotId,
    this.icon,
    this.size = ExpressiveAvatarSize.medium,
    this.tone,
    this.shape,
    this.style,
    super.key,
  });

  /// Stateful visual overrides before the avatar theme.
  final ExpressiveComponentThemeData? style;

  /// Whose face this is: its initials, and what a screen reader says.
  final String name;

  /// The declared media slot of the photo, if any.
  final String? slotId;

  /// A glyph in place of the initials (an entity, an unknown person).
  final IconData? icon;

  /// The avatar's size.
  final ExpressiveAvatarSize size;

  /// The container family; the one [name] picks when null.
  final ExpressiveMediaTone? tone;

  /// A library shape mask in place of the circle (a hero moment).
  final ExpressiveMaterialShape? shape;

  /// The initials [name] prints: the first letter of each of its first two
  /// words, upper-cased.
  static String initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first).toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final library = shape;
    if (library != null) {
      assert(
        ExpressiveHeroMoment.debugCheck(context, 'A shaped ExpressiveAvatar'),
      );
    }
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    final resolved = tone ?? ExpressiveMediaTone.of(name);
    final visual = theme.avatarTheme.merge(style);
    const states = <WidgetState>{};
    final ink =
        visual.foregroundColor?.resolve(states) ?? resolved.contentIn(colors);
    final customMask = visual.shape?.resolve(states);
    final OutlinedBorder mask =
        customMask ??
        (library == null
            ? const CircleBorder()
            : ExpressiveMaterialShapeBorder(library));
    final outline = visual.outline?.resolve(states);
    final side =
        visual.side?.resolve(states) ??
        (outline == null
            ? BorderSide.none
            : BorderSide(color: outline, width: 1));
    final minimum = visual.minimumSize?.resolve(states) ?? Size.zero;
    final baseDimension = math.max(
      math.max(minimum.width, minimum.height),
      theme.density.width(size.dimension),
    );
    final inset = mask
        .copyWith(side: side)
        .dimensions
        .resolve(Directionality.of(context));
    final padding =
        (visual.padding?.resolve(states) ?? EdgeInsets.zero).resolve(
          Directionality.of(context),
        ) +
        inset;
    final dimension = math.max(
      math.max(minimum.width, minimum.height),
      math.max(
        baseDimension,
        math.max(padding.horizontal, padding.vertical) + 12,
      ),
    );
    final fill = Color.alphaBlend(
      visual.overlayColor?.resolve(states) ?? expressiveTransparent,
      visual.backgroundColor?.resolve(states) ?? resolved.containerIn(colors),
    );
    final glyph = icon;
    final initials = initialsOf(name);
    final Widget face = ColoredBox(
      color: fill,
      child: Padding(
        padding: padding,
        child: Center(
          child: _fitAvatarContent(
            context,
            circle: customMask == null && library == null,
            diameter:
                dimension - math.max(padding.horizontal, padding.vertical),
            child: glyph != null || initials.isEmpty
                ? Icon(
                    glyph ?? ExpressiveSymbols.person,
                    size: visual.iconSize?.resolve(states) ?? size.iconSize,
                    color: ink,
                  )
                : Text(
                    initials,
                    maxLines: 1,
                    style: theme.type
                        .of(size.label)
                        .merge(visual.textStyle?.resolve(states))
                        .copyWith(color: ink),
                  ),
          ),
        ),
      ),
    );
    final slot = slotId;
    final Widget content = slot == null
        ? face
        : MediaSlotImage(slotId: slot, fallback: face);
    return Semantics(
      image: true,
      label: name,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: dimension,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: ShapeDecoration(shape: mask.copyWith(side: side)),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: mask,
                textDirection: Directionality.maybeOf(context),
              ),
              child: SizedBox.expand(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// One face of an [ExpressiveAvatarGroup]: whose, and their picture — an
/// [image], or the app's picture slot [slotId] — with their initials
/// standing in when there is none.
@immutable
class ExpressiveFace {
  /// [name]'s face.
  const ExpressiveFace(this.name, {this.slotId, this.image});

  /// Their name as the app shows it.
  final String name;

  /// Their picture slot.
  final String? slotId;

  /// Their picture; it wins over [slotId].
  final ImageProvider? image;
}

/// Who is in: the first [max] faces side by side from the start, 4dp
/// apart, then one `surfaceContainerHighest` disc counting the rest of
/// [total] (`+3`). The faces never overlap: in Material two surfaces of one
/// level stand beside each other, never one through the other. Each face is
/// an [ExpressiveAvatar] at [size] (a picture in the same circle); a screen
/// reader hears [semanticLabel], or the names shown and how many more.
///
/// ```dart
/// ExpressiveAvatarGroup(faces: const [ExpressiveFace('Noor Wahid'), ExpressiveFace('Ada Kim'), ExpressiveFace('Jon Ruiz')], total: 7)
/// ```
class ExpressiveAvatarGroup extends StatelessWidget {
  /// A row of [faces].
  const ExpressiveAvatarGroup({
    required this.faces,
    this.total,
    this.max = 4,
    this.size = ExpressiveAvatarSize.small,
    this.semanticLabel,
    this.style,
    super.key,
  }) : assert(max > 0, 'a pile shows at least one face');

  /// Stateful visual overrides for every face and the remaining count.
  final ExpressiveComponentThemeData? style;

  /// The faces, in order; the first stands at the start.
  final List<ExpressiveFace> faces;

  /// How many there are in all; the length of [faces] when null.
  final int? total;

  /// How many faces show before the count.
  final int max;

  /// The avatars' size.
  final ExpressiveAvatarSize size;

  /// What a screen reader says for the pile.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final visual = t.avatarTheme.merge(style);
    const states = <WidgetState>{};
    final customMask = visual.shape?.resolve(states);
    final mask = customMask ?? const CircleBorder();
    // No rim of its own: a face's edge is the style's side or outline.
    final outline = visual.outline?.resolve(states);
    final side =
        visual.side?.resolve(states) ??
        (outline == null
            ? BorderSide.none
            : BorderSide(color: outline, width: ExpressiveSpacing.s2));
    final minimum = visual.minimumSize?.resolve(states) ?? Size.zero;
    final baseDimension = math.max(
      math.max(minimum.width, minimum.height),
      t.density.width(size.dimension),
    );
    final inset = mask
        .copyWith(side: side)
        .dimensions
        .resolve(Directionality.of(context));
    final padding =
        (visual.padding?.resolve(states) ?? EdgeInsets.zero).resolve(
          Directionality.of(context),
        ) +
        inset;
    final dimension = math.max(
      math.max(minimum.width, minimum.height),
      math.max(
        baseDimension,
        math.max(padding.horizontal, padding.vertical) + 12,
      ),
    );
    // Each face stands the spacing scale's 4dp after the one before.
    final step = dimension + ExpressiveSpacing.s4;
    return LayoutBuilder(
      builder: (context, constraints) {
        final all = math.max(total ?? faces.length, faces.length);
        final capacity = constraints.maxWidth.isFinite
            ? math.max(
                1,
                1 + ((constraints.maxWidth - dimension) / step).floor(),
              )
            : max + 1;
        final desired = math.min(max, faces.length);
        final shown = math.min(
          desired,
          math.max(0, capacity - (all > desired || desired > capacity ? 1 : 0)),
        );
        final rest = all - shown;
        Widget face(ExpressiveFace value) => value.image == null
            ? ExpressiveAvatar(
                name: value.name,
                slotId: value.slotId,
                size: size,
                // A styled rim shares its safe area with the initials and
                // paints only once.
                style: visual.isEmpty && customMask == null
                    ? style
                    : visual.copyWith(
                        side: const WidgetStatePropertyAll(BorderSide.none),
                        padding: WidgetStatePropertyAll(
                          padding -
                              mask
                                  .copyWith(side: BorderSide.none)
                                  .dimensions
                                  .resolve(Directionality.of(context)),
                        ),
                      ),
              )
            : ClipPath(
                clipper: ShapeBorderClipper(shape: mask),
                child: Image(
                  image: value.image!,
                  width: dimension,
                  height: dimension,
                  fit: BoxFit.cover,
                ),
              );
        Widget ringed(Widget face) => DecoratedBox(
          decoration: ShapeDecoration(shape: mask.copyWith(side: side)),
          position: DecorationPosition.foreground,
          child: face,
        );
        final discs = <Widget>[
          for (var i = 0; i < shown; i++) ringed(face(faces[i])),
          if (rest > 0)
            ringed(
              SizedBox.square(
                dimension: dimension,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: Color.alphaBlend(
                      visual.overlayColor?.resolve(states) ??
                          expressiveTransparent,
                      visual.backgroundColor?.resolve(states) ??
                          t.colors.surfaceContainerHighest,
                    ),
                    shape: mask,
                  ),
                  child: Padding(
                    padding: padding,
                    child: Center(
                      child: _fitAvatarContent(
                        context,
                        circle: customMask == null,
                        diameter:
                            dimension -
                            math.max(padding.horizontal, padding.vertical),
                        child: Text(
                          '+$rest',
                          maxLines: 1,
                          style: t.type
                              .of(size.label)
                              .merge(visual.textStyle?.resolve(states))
                              .copyWith(
                                color:
                                    visual.foregroundColor?.resolve(states) ??
                                    t.colors.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ];
        final spoken =
            semanticLabel ??
            <String>[
              for (var i = 0; i < shown; i++) faces[i].name,
              if (rest > 0) '+$rest',
            ].join(', ');
        return Semantics(
          container: true,
          label: spoken,
          child: ExcludeSemantics(
            child: SizedBox(
              width: discs.isEmpty ? 0 : dimension + step * (discs.length - 1),
              height: dimension,
              child: Stack(
                children: <Widget>[
                  for (var i = 0; i < discs.length; i++)
                    PositionedDirectional(
                      start: step * i,
                      top: 0,
                      width: dimension,
                      height: dimension,
                      child: discs[i],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// A circle fits any centered rectangle whose diagonal fits its diameter.
// Using an inscribed square needlessly shrinks short initials and counts.
//
// Words are measured by their ink band (the line's ascent and descent, not
// the style's leading), and every avatar of one size and style prints its
// words at one scale: the one the widest pair of capitals ("MW") needs, so
// "MO" sits beside "SR" and "Y" at the same size. Words wider still (three
// letters, a long count) shrink further on their own.
Widget _fitAvatarContent(
  BuildContext context, {
  required Widget child,
  required bool circle,
  required double diameter,
}) {
  final fitted = FittedBox(fit: BoxFit.scaleDown, child: child);
  if (!circle) return fitted;
  final Size natural;
  final double scale;
  if (child is Text) {
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    (Size, double) measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: child.style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final size = painter.size;
      final lines = painter.computeLineMetrics();
      final ink = lines.isEmpty
          ? size.height
          : lines.first.ascent + lines.first.descent;
      painter.dispose();
      final diagonal = math.sqrt(size.width * size.width + ink * ink);
      return (
        size,
        diagonal <= diameter ? 1.0 : math.max(0, diameter) / diagonal,
      );
    }

    final (size, own) = measure(child.data ?? '');
    natural = size;
    scale = math.min(own, measure('MW').$2);
  } else if (child is Icon) {
    natural = Size.square(
      child.size ??
          IconTheme.of(context).size ??
          ListTokens.itemLeadingIconSize,
    );
    final diagonal = natural.width * math.sqrt2;
    scale = diagonal <= diameter ? 1.0 : math.max(0, diameter) / diagonal;
  } else {
    return fitted;
  }
  if (scale >= 1) return fitted;
  return SizedBox(
    width: natural.width * scale,
    height: natural.height * scale,
    child: fitted,
  );
}
