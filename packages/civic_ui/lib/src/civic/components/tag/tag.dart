import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../theme.dart';

/// A status in words on its tone's tint: Not started, In progress,
/// Approved, Refused. Square, bold, its words in the tone's ink at better
/// than 7 to 1, so the words carry the status and the tint only sorts it.
///
/// Reads [CivicStyle]'s fill (the tint), foreground (the words), padding
/// and textStyle: its `style:`, then [CivicThemeData.tagStyle], over its
/// tone's. Keep the words at 7:1 on the tint: they carry the status.
///
/// ```dart
/// CivicTag(label: 'In progress', tone: CivicTone.info)
/// ```
class CivicTag extends StatelessWidget {
  /// A tag saying [label] in [tone].
  const CivicTag({
    super.key,
    required this.label,
    this.tone = CivicTone.neutral,
    this.style,
  });

  /// The words.
  final String label;

  /// The tone.
  final CivicTone tone;

  /// Overrides for this tag's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf([style, t.tagStyle], const {});
    final (fill, ink) = t.toneOf(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: so.fill ?? fill,
        borderRadius: BorderRadius.circular(CivicMetrics.corner),
      ),
      child: Padding(
        padding:
            so.padding(Directionality.of(context)) ??
            const EdgeInsets.symmetric(
              horizontal: CivicSpacing.s8,
              vertical: CivicSpacing.s4,
            ),
        child: Text(
          label,
          style: context.civicText.bodySmall
              .copyWith(fontWeight: FontWeight.w700, height: 1.25)
              .merge(so.textStyle)
              .copyWith(color: so.foreground ?? ink),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(
        EnumProperty<CivicTone>('tone', tone, defaultValue: CivicTone.neutral),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
