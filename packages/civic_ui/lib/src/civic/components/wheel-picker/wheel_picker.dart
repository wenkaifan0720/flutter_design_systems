import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/field_frame.dart';
import '../../material.dart';
import '../../theme.dart';

// A wheel's caller gives its columns.
export 'package:ui_core/ui_core.dart' show RawPickerColumn;

/// Linked lists turned to a choice, a column each (hours and minutes, a
/// month and its days): every column a flat well, the row chosen across its
/// middle on the action's tint with the chosen rule down its start and its
/// words in bold, so the choice reads as an open list's does. Flat, not a
/// drum: the rows stand straight and whole, at every text size.
///
/// A drag or a flick turns a column; a press on a row turns to it. Tab
/// reaches each column; Up and Down turn it a row, Page Up and Page Down
/// five, Home and End to its ends; the keyboard's column doubles its edge
/// in the yellow ring. Use it where a phone's spinning list is expected;
/// on a form a select or typed boxes are quicker.
///
/// Reads [CivicStyle]'s fill (the chosen band) and foreground (its words)
/// by state: its `style:`, then [CivicThemeData.wheelPickerStyle].
///
/// ```dart
/// CivicWheelPicker(
///   labelText: 'Arrival time',
///   columns: (_) => [
///     RawPickerColumn(itemCount: 24, itemLabel: (i) => '$i', looping: true),
///     RawPickerColumn(itemCount: 4, itemLabel: (i) => '${i * 15}'.padLeft(2, '0')),
///   ],
///   selection: slot,
///   onChanged: (next) => setState(() => slot = next),
/// )
/// ```
class CivicWheelPicker extends StatelessWidget {
  /// A wheel picker.
  const CivicWheelPicker({
    super.key,
    required this.columns,
    required this.selection,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.errorText,
    this.visibleItemCount = 5,
    this.autofocus = false,
    this.style,
  }) : assert(visibleItemCount > 0 && visibleItemCount % 2 == 1);

  /// The columns for a selection (a month's days follow its month).
  final List<RawPickerColumn> Function(List<int> selection) columns;

  /// The row chosen in each column.
  final List<int> selection;

  /// Called with the whole selection once the columns come to rest; null
  /// disables the picker.
  final ValueChanged<List<int>>? onChanged;

  /// What it sets.
  final String? labelText;

  /// How to use it.
  final String? helperText;

  /// What to fix; null while the choice is fine.
  final String? errorText;

  /// How many rows each column shows: an odd number, the chosen one in the
  /// middle.
  final int visibleItemCount;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for the chosen band's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final scale = MediaQuery.textScalerOf(context);
    final extent = scale
        .scale((text.body.fontSize ?? 19) * 1.45 + CivicSpacing.s16)
        .clamp(CivicMetrics.controlHeight, 120.0);
    final hasError = errorText != null;
    // Each column as wide as its longest row in bold: a wheel's list has no
    // width of its own to give.
    final chosen = text.label.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final widths = [
      for (final column in columns(selection))
        _widest(column, chosen, scale) +
            2 * (CivicSpacing.s16 + CivicMetrics.edge * 2) +
            CivicMetrics.insetRule,
    ];
    final picker = RawPicker(
      columns: columns,
      selection: selection,
      onChanged: onChanged,
      itemExtent: extent,
      visibleItemCount: visibleItemCount,
      // Flat: a straight list behind the band, every row upright and whole.
      diameterRatio: 1000,
      perspective: 0.000001,
      squeeze: 1,
      semanticLabel: labelText,
      autofocus: autofocus,
      layoutBuilder: (context, list) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s8,
        children: list,
      ),
      columnBuilder: (context, column, wheel) {
        final so = RawStyleOf([style, t.wheelPickerStyle], column.states);
        final disabled = column.states.contains(WidgetState.disabled);
        return SizedBox(
          width: column.column < widths.length
              ? widths[column.column].clamp(72.0, double.infinity)
              : 88,
          child: CivicWell(
            fill: disabled ? t.disabledFill : t.background,
            edgeColor: hasError
                ? t.danger
                : disabled
                ? t.textDisabled
                : t.border,
            focused: column.states.contains(WidgetState.focused),
            child: Padding(
              padding: const EdgeInsets.all(CivicMetrics.edge),
              child: CustomPaint(
                painter: _Band(
                  extent: column.itemExtent,
                  fill: so.fill ?? (disabled ? t.surface : t.secondaryFill),
                  rule: disabled ? t.textDisabled : t.action,
                  direction: Directionality.of(context),
                ),
                child: wheel,
              ),
            ),
          ),
        );
      },
      itemBuilder: (context, item) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CivicSpacing.s16),
          child: Text(
            item.label,
            maxLines: 1,
            style: (item.selected ? text.label : text.body).copyWith(
              color: !item.enabled
                  ? t.textDisabled
                  : item.selected
                  ? (RawStyleOf(
                          [style, t.wheelPickerStyle],
                          const {WidgetState.selected},
                        ).foreground ??
                        t.textPrimary)
                  : t.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
    if (labelText == null && helperText == null && errorText == null) {
      return picker;
    }
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      enabled: onChanged != null,
      builder: (context, parts) => CivicFieldFrame(parts: parts),
      child: Align(alignment: AlignmentDirectional.centerStart, child: picker),
    );
  }

  static double _widest(
    RawPickerColumn column,
    TextStyle style,
    TextScaler scale,
  ) {
    var most = 0.0;
    final n = column.itemCount < 400 ? column.itemCount : 400;
    for (var i = 0; i < n; i++) {
      final painter = TextPainter(
        text: TextSpan(text: column.itemLabel(i), style: style),
        textScaler: scale,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width > most) most = painter.width;
      painter.dispose();
    }
    return most.ceilToDouble();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<int>('selection', selection))
      ..add(
        ObjectFlagProperty<ValueChanged<List<int>>>.has('onChanged', onChanged),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(IntProperty('visibleItemCount', visibleItemCount, defaultValue: 5))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The chosen row's band across a column's middle, with the chosen rule
/// down its start.
class _Band extends CustomPainter {
  _Band({
    required this.extent,
    required this.fill,
    required this.rule,
    required this.direction,
  });

  final double extent;
  final Color fill;
  final Color rule;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - extent) / 2;
    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width, extent),
      Paint()..color = fill,
    );
    const w = CivicMetrics.insetRule;
    final x = direction == TextDirection.rtl ? size.width - w : 0.0;
    canvas.drawRect(Rect.fromLTWH(x, top, w, extent), Paint()..color = rule);
  }

  @override
  bool shouldRepaint(_Band old) =>
      old.extent != extent ||
      old.fill != fill ||
      old.rule != rule ||
      old.direction != direction;
}
