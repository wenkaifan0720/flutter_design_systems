/// A picture in Ledger's frame, with the engraver's hatching standing in
/// while it loads and when it fails.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/hatch.dart';
import '../../theme.dart';

/// A picture in Ledger's frame (a receipt's photo, a payee's storefront): the
/// [image] laid in the slip's small corners under a fine rule, cropped to
/// [aspectRatio]. While it loads, when there is none and when it fails, the
/// darker paper stands in its place, engraved with fine hatching, a glyph in
/// its middle. [caption] stands under it in the mono capitals. A screen
/// reader hears [semanticLabel] as an image; without one the picture says
/// nothing (the words round it say what it shows).
///
/// ```dart
/// LedgerMedia(image: const AssetImage('assets/photos/receipt.jpg'), caption: 'Corner Market, Oct 27', semanticLabel: 'The receipt from Corner Market')
/// ```
class LedgerMedia extends StatelessWidget {
  /// [image] in Ledger's frame.
  const LedgerMedia({
    this.image,
    this.aspectRatio = 4 / 3,
    this.alignment = Alignment.center,
    this.caption,
    this.semanticLabel,
    super.key,
  }) : assert(aspectRatio > 0);

  /// The picture; null stands the engraving.
  final ImageProvider? image;

  /// Its width over its height.
  final double aspectRatio;

  /// Which part of the picture stays in view when it is cropped.
  final Alignment alignment;

  /// The words under it.
  final String? caption;

  /// What a screen reader hears; null: nothing.
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ImageProvider>('image', image, defaultValue: null),
      )
      ..add(DoubleProperty('aspectRatio', aspectRatio))
      ..add(DiagnosticsProperty<Alignment>('alignment', alignment))
      ..add(StringProperty('caption', caption, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final corners = BorderRadius.circular(t.smallRadius);
    const stand = _Engraving();
    final picture = image;
    final framed = AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: corners,
          border: Border.all(color: t.border),
        ),
        child: ClipRRect(
          borderRadius: corners,
          child: picture == null
              ? stand
              : Image(
                  image: picture,
                  fit: BoxFit.cover,
                  alignment: alignment,
                  excludeFromSemantics: true,
                  frameBuilder: (context, child, frame, loaded) =>
                      loaded || frame != null ? child : stand,
                  errorBuilder: (context, error, stack) => stand,
                ),
        ),
      ),
    );
    final words = caption;
    final body = words == null
        ? framed
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: LedgerSpacing.s8,
            children: [
              framed,
              Text(words.toUpperCase(), style: t.meta.colored(t.textSecondary)),
            ],
          );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(excluding: words == null, child: body)
        : Semantics(image: true, label: label, child: body);
  }
}

/// The darker paper engraved with hatching, the image glyph in its middle.
class _Engraving extends StatelessWidget {
  const _Engraving();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return CustomPaint(
      painter: _Hatch(paper: t.surfaceAlt, line: t.hatchInk),
      child: Center(
        child: Icon(
          LucideIcons.image,
          size: LedgerIconSize.i20,
          color: t.textTertiary,
        ),
      ),
    );
  }
}

class _Hatch extends CustomPainter {
  const _Hatch({required this.paper, required this.line});

  final Color paper;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = paper)
      ..drawPath(
        ledgerHatch((x, y) => true, 0, 0, size.width, size.height, 6, step: 1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6
          ..color = line,
      );
  }

  @override
  bool shouldRepaint(_Hatch old) => old.paper != paper || old.line != line;
}
