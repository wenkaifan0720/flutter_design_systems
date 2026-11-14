// A wheel of choices turned in a well: the chosen one stands on a raised lens across the middle.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'component_themes.dart';
import 'frames.dart';
import 'layout.dart';
import 'shapes.dart';
import 'theme.dart';
import 'internal/out_of_use.dart';

/// One value from a short ordered list, turned on a wheel in a well: the chosen row stands on a raised lens across
/// the middle, in the ink and bold; the rest curve away in the quiet ink. Drag or flick it, or focus it and use the
/// arrow keys; a screen reader adjusts it up and down. For a date or a time, use the date and time pickers.
///
/// ```dart
/// NeumorphicWheelPicker<int>(label: 'Guests', items: const [1, 2, 3, 4, 5, 6], value: guests, onChanged: setGuests)
/// ```
class NeumorphicWheelPicker<T> extends StatefulWidget {
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
  }) : assert(rows >= 3 && rows % 2 == 1);

  /// The choices, in order.
  final List<T> items;

  /// The chosen one.
  final T value;

  /// Called with the value the wheel comes to rest on; null: out of use (flat, still).
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

  @override
  State<NeumorphicWheelPicker<T>> createState() =>
      _NeumorphicWheelPickerState<T>();
}

class _NeumorphicWheelPickerState<T> extends State<NeumorphicWheelPicker<T>> {
  late final FixedExtentScrollController _scroll = FixedExtentScrollController(
    initialItem: _index,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'NeumorphicWheelPicker');
  bool _focused = false;

  int get _index =>
      widget.items.indexOf(widget.value).clamp(0, widget.items.length - 1);

  String _words(T value) => widget.itemLabel?.call(value) ?? '$value';

  @override
  void didUpdateWidget(NeumorphicWheelPicker<T> old) {
    super.didUpdateWidget(old);
    if (!_scroll.hasClients) return;
    final n = widget.items.length;
    final at = _scroll.selectedItem;
    if (n > 0 && ((at % n) + n) % n != _index) {
      // Turn the shortest way to the value the caller now holds.
      _scroll.jumpToItem(at - (((at % n) + n) % n) + _index);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _step(int by) {
    final n = widget.items.length;
    if (widget.onChanged == null || n == 0) return;
    final next = _scroll.selectedItem + by;
    if (!widget.looping && (next < 0 || next >= n)) return;
    _scroll.animateToItem(
      next,
      duration: NeumorphicTheme.of(context).motion.move,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final n = widget.items.length;
    final enabled = widget.onChanged != null && n > 0;
    final scaler = MediaQuery.textScalerOf(context);
    final extent = scaler.scale(t.textTheme.body.fontSize ?? 16) * 1.25 + 20;
    final well = t.shapes.corner(NeumorphicRadii.well);
    const inset = 6.0;
    final lens = NeumorphicShapes.inset(
      well,
      inset + well.dimensions.resolve(Directionality.of(context)).left,
    );
    final index = _index;
    String? near(int by) {
      final i = index + by;
      if (n == 0) return null;
      if (widget.looping) return _words(widget.items[((i % n) + n) % n]);
      return i < 0 || i >= n ? null : _words(widget.items[i]);
    }

    Widget row(int i) {
      final item = widget.items[((i % n) + n) % n];
      return Center(
        child: Text(
          _words(item),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.textTheme.body.tabular.copyWith(
            color: c.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final wheel = ListWheelScrollView.useDelegate(
      controller: _scroll,
      itemExtent: extent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.6,
      perspective: .003,
      overAndUnderCenterOpacity: .45,
      onSelectedItemChanged: (i) {
        if (n == 0) return;
        final value = widget.items[((i % n) + n) % n];
        if (value != widget.value) widget.onChanged?.call(value);
      },
      childDelegate: widget.looping
          ? ListWheelChildLoopingListDelegate(
              children: [for (var i = 0; i < n; i++) row(i)],
            )
          : ListWheelChildBuilderDelegate(
              childCount: n,
              builder: (context, i) => row(i),
            ),
    );
    // Its own height, and its width when given: a stretching column can't balloon the well, a narrow one scales it down.
    final body = neumorphicOwnSize(
      width: widget.width,
      height: extent * widget.rows + inset * 2,
      // With focus the well deepens round its lens; the lens says which row the keys move.
      child: NeumorphicSurface(
        cast: NeumorphicSurfaceLevel.well,
        style: widget.style,
        shape: well,
        states: {if (_focused) WidgetState.focused},
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
      ),
    );
    return Semantics(
      container: true,
      label: widget.label,
      value: n == 0 ? null : _words(widget.items[index]),
      increasedValue: enabled ? near(1) : null,
      decreasedValue: enabled ? near(-1) : null,
      onIncrease: enabled && near(1) != null ? () => _step(1) : null,
      onDecrease: enabled && near(-1) != null ? () => _step(-1) : null,
      enabled: enabled,
      child: ExcludeSemantics(
        child: Focus(
          focusNode: _focus,
          canRequestFocus: enabled,
          skipTraversal: !enabled,
          onFocusChange: (on) => setState(() => _focused = on),
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
              return KeyEventResult.ignored;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _step(1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _step(-1);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          // A finger on the wheel gives it the keys, without joining the gesture arena its drag is in.
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: enabled ? (_) => _focus.requestFocus() : null,
            child: IgnorePointer(
              ignoring: !enabled,
              child: NeumorphicOutOfUse(off: !enabled, child: body),
            ),
          ),
        ),
      ),
    );
  }
}
