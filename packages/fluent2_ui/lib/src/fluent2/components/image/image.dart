import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../theme.dart';

/// How a [Fluent2Image]'s picture fills its box, Fluent's `fit`: [fill]
/// (Fluent's `default`) stretched to the box, [none] at its own size from
/// the top start, [center] at its own size centred, [contain] whole inside
/// the box, [cover] filling the box and cropped.
enum Fluent2ImageFit {
  /// Stretched to fill the box.
  fill,

  /// At its own size, centred, clipped.
  none,

  /// At its own size, centred; scaled down when larger than the box.
  center,

  /// Scaled to fit inside the box whole.
  contain,

  /// Scaled to cover the box, clipped.
  cover,
}

/// An image's outline, Fluent's `shape`: [square] corners, [rounded] at
/// the medium corner (4), [circular].
enum Fluent2ImageShape {
  /// Square corners.
  square,

  /// Rounded corners.
  rounded,

  /// A circle.
  circular,
}

/// Fluent 2's Image: a picture ([image]) at [width] by [height] (or at
/// [aspectRatio], or the width of its parent with [block]), laid by [fit]
/// in its [shape], with a `neutralStroke1` hairline when [bordered] and
/// `shadow4` under it with [shadow]. While the picture loads, and when it
/// fails or there is none, it stands as a quiet placeholder: the inset
/// ground with the image glyph in the fourth ink. Read as an image named
/// [semanticLabel]; without one it is decoration and says nothing.
///
/// ```dart
/// Fluent2Image(image: photo, width: 160, aspectRatio: 4 / 3, shape: Fluent2ImageShape.rounded, fit: Fluent2ImageFit.cover, semanticLabel: 'The team at the offsite')
/// ```
class Fluent2Image extends StatelessWidget {
  /// An image of [image], Fluent's Image.
  const Fluent2Image({
    this.image,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = Fluent2ImageFit.cover,
    this.shape = Fluent2ImageShape.square,
    this.bordered = false,
    this.shadow = false,
    this.block = false,
    this.semanticLabel,
    super.key,
  });

  /// The picture; null stands as the placeholder.
  final ImageProvider? image;

  /// A fixed width; null takes the image's own or the room's.
  final double? width;

  /// A fixed height; null takes the image's own or the room's.
  final double? height;

  /// The box's width over its height, where one side is not given.
  final double? aspectRatio;

  /// Fluent's `fit`: how the picture fills the box.
  final Fluent2ImageFit fit;

  /// Fluent's `shape`: square, rounded or circular.
  final Fluent2ImageShape shape;

  /// Whether a hairline frames it.
  final bool bordered;

  /// Whether it stands raised in a shadow.
  final bool shadow;

  /// Takes its parent's whole width.
  final bool block;

  /// What the picture shows, for a screen reader; null is decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final image = this.image;
    final ratio = aspectRatio;
    const placeholder = _Placeholder();
    Widget picture = image == null
        ? placeholder
        : Image(
            image: image,
            fit: switch (fit) {
              Fluent2ImageFit.fill => BoxFit.fill,
              Fluent2ImageFit.none => BoxFit.none,
              Fluent2ImageFit.center => BoxFit.none,
              Fluent2ImageFit.contain => BoxFit.contain,
              Fluent2ImageFit.cover => BoxFit.cover,
            },
            alignment: fit == Fluent2ImageFit.none
                ? AlignmentDirectional.topStart
                : Alignment.center,
            width: double.infinity,
            height: double.infinity,
            excludeFromSemantics: true,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, sync) =>
                sync || frame != null ? child : placeholder,
            errorBuilder: (context, error, stack) => placeholder,
          );
    final BorderRadius? radius = switch (shape) {
      Fluent2ImageShape.square => null,
      Fluent2ImageShape.rounded => BorderRadius.circular(Fluent2Radius.medium),
      Fluent2ImageShape.circular => null,
    };
    final circle = shape == Fluent2ImageShape.circular;
    picture = circle
        ? ClipOval(child: picture)
        : radius != null
        ? ClipRRect(borderRadius: radius, child: picture)
        : ClipRect(child: picture);
    picture = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: shadow ? t.shadows.shadow4 : null,
      ),
      position: DecorationPosition.background,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          border: bordered ? Border.all(color: t.colors.neutralStroke1) : null,
        ),
        child: picture,
      ),
    );
    Widget sized = SizedBox(
      width: block ? double.infinity : width,
      height: height,
      child: picture,
    );
    if (ratio != null && (height == null || (width == null && !block))) {
      sized = SizedBox(
        width: block ? double.infinity : width,
        child: AspectRatio(aspectRatio: ratio, child: picture),
      );
    }
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: sized)
        : Semantics(image: true, label: label, child: sized);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return ColoredBox(
      color: t.surfaceAlt,
      child: LayoutBuilder(
        builder: (context, box) {
          if (!box.hasBoundedWidth || !box.hasBoundedHeight) {
            return const SizedBox.shrink();
          }
          final side = box.biggest.shortestSide;
          if (side < 28) return const SizedBox.expand();
          final glyph = side >= 96 ? Fluent2IconSize.i32 : Fluent2IconSize.i20;
          return Center(
            child: Icon(Fluent2Icons.image, size: glyph, color: t.textQuiet),
          );
        },
      ),
    );
  }
}
