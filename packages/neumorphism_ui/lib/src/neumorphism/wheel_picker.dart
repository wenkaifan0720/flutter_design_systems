// A wheel of choices turned in a well: the chosen one stands on a raised lens across the middle.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'frames.dart';
import 'layout.dart';
import 'shapes.dart';
import 'theme.dart';
import 'internal/out_of_use.dart';

/// One value from a short ordered list, turned on a wheel in a well: the chosen row stands on a raised lens across
/// the middle, in the ink and bold; the rest curve away in the quiet ink. On ui_core's [DesignWheelPicker]: drag or
/// flick it, tap a row, or focus it and use Up and Down, Page Up and Page Down, Home and End, or type a row's first
/// letters; a screen reader adjusts it up and down. For a date or a time, use the date and time pickers.
///
/// ```dart
/// NeumorphicWheelPicker<int>(label: 'Guests', items: const [1, 2, 3, 4, 5, 6], value: guests, onChanged: setGuests)
/// ```
class NeumorphicWheelPicker<T> extends StatelessWidget {
  /// A wheel of [items] at [value].
  const NeumorphicWheelPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.label,
    this.itemLabel,
    this.rows = 5,
    this.looping = false,
    this.width,
    this.style,
  }) : assert((width ?? 1) > 0),
       assert(rows >= 3 && rows % 2 == 1);

  /// The choices, in order.
  final List<T> items;

  /// The chosen one.
  final T value;

  /// Called with the value the wheel comes to rest on; null: out of use (quiet, still).
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls it.
  final String label;

  /// A value's words; null: its `toString()`.
  final String Function(T value)? itemLabel;

  /// How many rows show: odd, so one stands in the middle.
  final int rows;

  /// Whether the last row leads round to the first.
  final bool looping;

  /// Its width; null fills the width it is given.
  final double? width;

  /// The well's own style, before the text-field theme.
  final NeumorphicStyle? style;

  String _words(T value) => itemLabel?.call(value) ?? '$value';

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final n = items.length;
    final enabled = onChanged != null && n > 0;
    final scaler = MediaQuery.textScalerOf(context);
    final extent = scaler.scale(t.textTheme.body.fontSize ?? 16) * 1.25 + 20;
    final well = t.shapes.corner(NeumorphicRadii.well);
    const inset = 6.0;
    final lens = NeumorphicShapes.inset(
      well,
      inset + well.dimensions.resolve(Directionality.of(context)).left,
    );
    // With focus the well deepens round its lens; the lens says which row the keys move.
    Widget frame(Set<WidgetState> states, Widget wheel) => NeumorphicSurface(
      cast: NeumorphicSurfaceLevel.well,
      style: style,
      shape: well,
      states: {if (states.contains(WidgetState.focused)) WidgetState.focused},
      padding: const EdgeInsets.all(inset),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The lens: one row's height, raised, concentric with the well.
          SizedBox(
            height: extent,
            width: double.infinity,
            child: NeumorphicSurface(
              cast: NeumorphicSurfaceLevel.part,
              shape: lens,
              outlined: true,
            ),
          ),
          Positioned.fill(child: wheel),
        ],
      ),
    );
    // Its own height, and its width when given: a stretching column can't balloon the well, a narrow one scales it down.
    Widget sized(Widget child) => neumorphicOwnSize(
      width: width,
      height: extent * rows + inset * 2,
      child: child,
    );
    if (n == 0) {
      // Nothing to choose: the empty well, out of use.
      return Semantics(
        label: label,
        enabled: false,
        child: NeumorphicOutOfUse(
          off: true,
          child: sized(frame(const {}, const SizedBox.shrink())),
        ),
      );
    }
    final index = items.indexOf(value).clamp(0, n - 1);
    return NeumorphicOutOfUse(
      off: !enabled,
      child: sized(
        DesignWheelPicker(
          columns: (_) => [
            DesignWheelColumn(
              itemCount: n,
              itemLabel: (i) => _words(items[i]),
              semanticLabel: label,
              looping: looping,
            ),
          ],
          selection: [index],
          onChanged: enabled
              ? (selection) {
                  final chosen = items[selection.first];
                  if (chosen != value) onChanged!(chosen);
                }
              : null,
          itemExtent: extent,
          visibleItemCount: rows,
          // The look's wheel: flatter than iOS's, its rows at their own pitch, the far ones faded.
          diameterRatio: 1.6,
          squeeze: 1,
          overAndUnderCenterOpacity: .45,
          itemBuilder: (context, row) => Center(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.body.tabular.copyWith(
                color: c.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // The well takes the picker's whole height: ui_core's row would size it to its lens.
          layoutBuilder: (context, columns) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final c in columns) Expanded(child: c)],
          ),
          columnBuilder: (context, column, wheel) => frame(
            column.states,
            // A finger or a click on the wheel gives it the keys, without joining the gesture arena its drag is in:
            // ui_core's column takes focus from the keyboard only.
            Builder(
              builder: (context) => Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: enabled
                    ? (_) => Focus.of(context).requestFocus()
                    : null,
                child: wheel,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('items', items))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(StringProperty('label', label))
      ..add(
        ObjectFlagProperty<String Function(T value)>.has(
          'itemLabel',
          itemLabel,
        ),
      )
      ..add(IntProperty('rows', rows, defaultValue: 5))
      ..add(DiagnosticsProperty<bool>('looping', looping, defaultValue: false))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}
