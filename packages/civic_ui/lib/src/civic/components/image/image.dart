import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../theme.dart';

/// A picture that tells the reader something (a permit zone's map, a
/// sign): [image] cropped to [aspectRatio] in a card's corners, its
/// [caption] under it. A screen reader hears [description], which says
/// what the picture shows; one that only decorates is
/// [CivicImage.decorative] and says nothing.
///
/// While it loads the page's pale ground stands in its place; when there
/// is none or it fails, the ground says so in words ("Picture not
/// available") under a glyph, so a reader knows something is missing.
///
/// Reads [CivicStyle]'s fill (the ground) and foreground (the
/// caption and the missing words): its `style:`, then
/// [CivicThemeData.imageStyle].
///
/// ```dart
/// CivicImage(
///   image: AssetImage('assets/zone-b.png'),
///   description: 'Map of Zone B: from the river to Mill Lane',
///   caption: 'Zone B runs from the river to Mill Lane.',
/// )
/// ```
class CivicImage extends StatelessWidget {
  /// A picture described by [description].
  const CivicImage({
    super.key,
    required this.image,
    required String this.description,
    this.caption,
    this.aspectRatio = 3 / 2,
    this.alignment = Alignment.center,
    this.missingLabel = 'Picture not available',
    this.style,
  }) : assert(aspectRatio > 0);

  /// A picture that only decorates: a screen reader passes over it.
  const CivicImage.decorative({
    super.key,
    required this.image,
    this.caption,
    this.aspectRatio = 3 / 2,
    this.alignment = Alignment.center,
    this.missingLabel = 'Picture not available',
    this.style,
  }) : description = null,
       assert(aspectRatio > 0);

  /// The picture; null: the missing picture's ground.
  final ImageProvider? image;

  /// What the picture shows, for a screen reader; null for a decorative
  /// one.
  final String? description;

  /// The words under it.
  final String? caption;

  /// Its width over its height.
  final double aspectRatio;

  /// Which part of the picture stays in view when it is cropped.
  final Alignment alignment;

  /// The words on the ground when there is no picture.
  final String missingLabel;

  /// Overrides for this picture's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([style, t.imageStyle], const {});
    final ground = so.fill ?? t.surface;
    final quiet = so.foreground ?? t.textSecondary;
    final missing = ColoredBox(
      color: ground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(CivicSpacing.s16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: CivicSpacing.s8,
              children: [
                Icon(LucideIcons.imageOff, size: 32, color: quiet),
                Text(
                  missingLabel,
                  style: text.bodySmall.copyWith(color: quiet),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final loading = ColoredBox(color: ground);
    final picture = image;
    final framed = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
        child: picture == null
            ? missing
            : Image(
                image: picture,
                fit: BoxFit.cover,
                alignment: alignment,
                excludeFromSemantics: true,
                frameBuilder: (context, child, frame, loaded) =>
                    loaded || frame != null ? child : loading,
                errorBuilder: (context, error, stack) => missing,
              ),
      ),
    );
    final said = description;
    final body = Semantics(
      image: said != null,
      label: said,
      excludeSemantics: true,
      child: framed,
    );
    final words = caption;
    if (words == null) {
      return said == null ? ExcludeSemantics(child: body) : body;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: CivicSpacing.s8,
      children: [
        if (said == null) ExcludeSemantics(child: body) else body,
        Text(words, style: text.bodySmall.copyWith(color: quiet)),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ImageProvider>('image', image, defaultValue: null),
      )
      ..add(StringProperty('description', description, defaultValue: null))
      ..add(StringProperty('caption', caption, defaultValue: null))
      ..add(DoubleProperty('aspectRatio', aspectRatio, defaultValue: 3 / 2))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
