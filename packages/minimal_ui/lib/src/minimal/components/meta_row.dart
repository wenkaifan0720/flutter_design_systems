import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../theme.dart';

/// A dense single-line metadata row: small fixed [leading] and [trailing]
/// adornments around a flexible [middle] that ellipsizes. Only [middle]
/// absorbs width; keep the fixed slots to a glyph, a tag, an id or a time
/// so the row always fits its line. At large text (from
/// [MinimalChromeMetrics.rowStackScale]) the slots flow onto lines of their
/// own.
///
/// Minimal sets the line's registers: the middle prints in
/// [MinimalThemeData.bodySmall], the adornments in [MinimalThemeData.mono] in
/// the quiet
/// ink (ids and times are figures) — a Text with its own style keeps it.
/// Each slot's words carry their capitals on the row's middle, so a mono id
/// and a sans name of different sizes read as one line, level with a face
/// beside the row. Lines whose [leading] adornments differ (an id, a tag, a
/// glyph, a face) give each the same [leadingWidth], so their middles start
/// on one keyline.
///
/// ```dart
/// MinimalMetaRow(leading: Text('1047'), middle: Text('Hanna Berg · 3 loaves'), trailing: Text('09:30'))
/// ```
class MinimalMetaRow extends StatelessWidget {
  /// A line of metadata around [middle].
  const MinimalMetaRow({
    required this.middle,
    this.leading,
    this.leadingWidth,
    this.trailing,
    this.spacing = MinimalSpacing.s8,
    super.key,
  });

  /// The line's flexible part; it ellipsizes.
  final Widget middle;

  /// What stands before it.
  final Widget? leading;

  /// The width of [leading]'s slot, grown with the text scale as the words
  /// in it grow: the adornment stands at its start, and a wider one keeps
  /// its own width. Null gives the adornment its own width.
  final double? leadingWidth;

  /// What stands after it.
  final Widget? trailing;

  /// Air between the slots.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final figure = t.mono.c(t.mutedForeground);
    final slot = leadingWidth;
    Widget? lead = leading == null
        ? null
        : DefaultTextStyle.merge(
            style: figure,
            child: minimalCapLabel(leading!),
          );
    if (lead != null && slot != null) {
      lead = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.textScalerOf(context).scale(slot),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: lead,
        ),
      );
    }
    // At large text the slots flow onto lines of their own (the middle
    // still ellipsizes at the row's width) rather than run off the line.
    if (MediaQuery.textScalerOf(context).scale(10) / 10 >=
        MinimalChromeMetrics.rowStackScale) {
      return DefaultTextStyle.merge(
        style: t.bodySmall,
        child: Wrap(
          spacing: spacing,
          runSpacing: MinimalSpacing.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ?lead,
            DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              child: minimalCapLabel(middle),
            ),
            if (trailing != null)
              DefaultTextStyle.merge(
                style: figure,
                child: minimalCapLabel(trailing!),
              ),
          ],
        ),
      );
    }
    return DefaultTextStyle.merge(
      style: t.bodySmall,
      child: Row(
        children: <Widget>[
          if (lead != null) ...<Widget>[lead, SizedBox(width: spacing)],
          Expanded(
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              child: minimalCapLabel(middle),
            ),
          ),
          if (trailing != null) ...<Widget>[
            SizedBox(width: spacing),
            DefaultTextStyle.merge(
              style: figure,
              child: minimalCapLabel(trailing!),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('leadingWidth', leadingWidth, defaultValue: null))
      ..add(
        DoubleProperty('spacing', spacing, defaultValue: MinimalSpacing.s8),
      );
  }
}
