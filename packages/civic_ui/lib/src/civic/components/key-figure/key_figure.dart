import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

/// One figure a page leads with ("1,240 permits issued this year"): its
/// [label] over it, the [value] large in tabular figures, a line of
/// [detail] under it. A screen reader hears it as one line, the value as
/// [semanticValue] when the figures alone would be read wrong.
///
/// Put the figure's source and date in [detail]: a number with no date
/// is a number no one can check.
///
/// Reads [CivicStyle]'s foreground (the value) and textStyle (the value):
/// its `style:`, then [CivicThemeData.keyFigureStyle].
///
/// ```dart
/// CivicKeyFigure(
///   label: 'Permits issued this year',
///   value: '1,240',
///   detail: 'To 31 October 2026',
/// )
/// ```
class CivicKeyFigure extends StatelessWidget {
  /// [value] under [label].
  const CivicKeyFigure({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.semanticValue,
    this.style,
  });

  /// What it counts: "Permits issued this year".
  final String label;

  /// The figure: "1,240", "€62.50".
  final String value;

  /// A line under it: its date, its source, its change.
  final String? detail;

  /// How a screen reader should hear [value]; null: [value].
  final String? semanticValue;

  /// Overrides for this figure's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([style, t.keyFigureStyle], const {});
    final more = detail;
    return Semantics(
      container: true,
      label: [label, semanticValue ?? value, ?more].join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s4,
        children: [
          Text(label, style: text.body.copyWith(color: t.textSecondary)),
          Text(
            value,
            style: text.headingXL
                .copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: so.foreground ?? t.textPrimary,
                )
                .merge(so.textStyle),
          ),
          if (more != null)
            Text(more, style: text.bodySmall.copyWith(color: t.textSecondary)),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('value', value))
      ..add(StringProperty('detail', detail, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
