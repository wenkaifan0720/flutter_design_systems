/// A wheel picker, headless: one or more columns of rows that turn past a
/// centre line (iOS's picker), the rows and the lens the look's.
///
/// [RawPicker] keeps a selection, one row per column. Its columns
/// are a function of that selection, so a pick in one refills the others (a
/// month's day count, a minimum date's months): when a column comes to rest,
/// every other column moves to its nearest live row and [RawPicker.onChanged] gets the
/// whole, valid selection once. Disabled rows, and rows outside a column's
/// least and greatest, show disabled; a wheel that comes to rest on one turns
/// on to the nearest live row. Each column is one tab stop and one adjustable
/// node for a screen reader; the keys step it, and typing jumps to a row.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'internal/focus_visible.dart';
import 'motion.dart';

/// One column of a [RawPicker]: its rows, their names and which of
/// them can be chosen.
///
/// ```dart
/// RawPickerColumn(itemCount: 12, itemLabel: (index) => 'Month ${index + 1}', semanticLabel: 'Month')
/// ```
@immutable
class RawPickerColumn {
  /// A column of [itemCount] rows, each named by [itemLabel].
  const RawPickerColumn({
    required this.itemCount,
    required this.itemLabel,
    this.semanticLabel,
    this.minIndex = 0,
    this.maxIndex,
    this.isItemEnabled,
    this.looping = false,
  }) : assert(itemCount > 0, 'a column has at least one row'),
       assert(minIndex >= 0 && minIndex < itemCount),
       assert(
         maxIndex == null || (maxIndex >= minIndex && maxIndex < itemCount),
       );

  /// How many rows the column has.
  final int itemCount;

  /// A row's name: what a screen reader says for it and what typing
  /// matches.
  final String Function(int index) itemLabel;

  /// The column's name, said before its row ("Month"); null: none.
  final String? semanticLabel;

  /// The least row that can be chosen; the rows before it show disabled,
  /// as iOS's picker shows dates before its minimum. Defaults to the first.
  final int minIndex;

  /// The greatest row that can be chosen; null: the last.
  final int? maxIndex;

  /// Whether a row between [minIndex] and [maxIndex] can be chosen (a
  /// booked time); null: every one. The wheel turns past a row it refuses.
  final bool Function(int index)? isItemEnabled;

  /// Whether the rows repeat past the ends (minutes, hours). Defaults to
  /// false.
  final bool looping;

  /// Whether row [index] can be chosen: between [minIndex] and [maxIndex],
  /// and allowed by [isItemEnabled].
  bool isEnabled(int index) =>
      index >= minIndex &&
      index <= (maxIndex ?? itemCount - 1) &&
      (isItemEnabled?.call(index) ?? true);

  /// The live row nearest [index] (clamped to the column), [index] itself
  /// when it is live. [forward] picks which way to look first: true, the
  /// rows after; false, before; null, the nearer (before on a tie). A looping
  /// column counts its distances round the ends. Null when no row is live.
  int? nearestEnabled(int index, {bool? forward}) {
    final from = index.clamp(0, itemCount - 1);
    if (isEnabled(from)) return from;
    int? step(int sign) {
      for (var d = 1; d < itemCount; d++) {
        var i = from + sign * d;
        if (looping) {
          i %= itemCount;
        } else if (i < 0 || i >= itemCount) {
          return null;
        }
        if (isEnabled(i)) return i;
      }
      return null;
    }

    if (forward != null) {
      return step(forward ? 1 : -1) ?? step(forward ? -1 : 1);
    }
    final before = step(-1);
    final after = step(1);
    if (before == null || after == null) return before ?? after;
    int distance(int i) {
      final d = (i - from).abs();
      return looping ? (d < itemCount - d ? d : itemCount - d) : d;
    }

    return distance(after) < distance(before) ? after : before;
  }

  /// The next live row [count] rows on from [index] ([count] negative:
  /// back), wrapping when [looping], else stopping at the last live row
  /// that way; [index] when none is live that way.
  int stepFrom(int index, int count) {
    var at = index;
    final sign = count.sign;
    for (var n = 0; n < count.abs(); n++) {
      int? next;
      for (var d = 1; d < itemCount; d++) {
        var i = at + sign * d;
        if (looping) {
          i %= itemCount;
        } else if (i < 0 || i >= itemCount) {
          break;
        }
        if (isEnabled(i)) {
          next = i;
          break;
        }
      }
      if (next == null) break;
      at = next;
    }
    return at;
  }

  /// The first live row, or null when none is.
  int? get firstEnabled => nearestEnabled(0, forward: true);

  /// The last live row, or null when none is.
  int? get lastEnabled => nearestEnabled(itemCount - 1, forward: false);
}

/// One row of a [RawPicker], as the look paints it.
@immutable
class RawPickerItemDetails {
  /// A row's details.
  const RawPickerItemDetails({
    required this.column,
    required this.index,
    required this.label,
    required this.selected,
    required this.enabled,
  });

  /// The column it is in.
  final int column;

  /// Its index in the column.
  final int index;

  /// Its name ([RawPickerColumn.itemLabel]).
  final String label;

  /// Whether it is at the wheel's centre now, as the wheel turns.
  final bool selected;

  /// Whether it can be chosen ([RawPickerColumn.isEnabled]) in a picker
  /// that takes input.
  final bool enabled;
}

/// One column of a [RawPicker], as the look frames it: its lens, a
/// band behind the centre row, a focus ring.
@immutable
class RawPickerColumnDetails {
  /// A column's details.
  const RawPickerColumnDetails({
    required this.column,
    required this.states,
    required this.itemExtent,
  });

  /// The column's index.
  final int column;

  /// Its states: [WidgetState.focused] while the keyboard is on it,
  /// [WidgetState.hovered], [WidgetState.dragged] (and
  /// [WidgetState.pressed]) while a finger or a pointer turns it,
  /// [WidgetState.disabled] when the picker takes no input.
  final Set<WidgetState> states;

  /// The height of one row, for a band behind the centre row.
  final double itemExtent;
}

/// Builds one row of a [RawPicker].
typedef RawPickerItemBuilder = Widget Function(
  BuildContext context,
  RawPickerItemDetails details,
);

/// Frames one column of a [RawPicker] round its [wheel].
typedef RawPickerColumnBuilder = Widget Function(
  BuildContext context,
  RawPickerColumnDetails details,
  Widget wheel,
);

/// A wheel picker of linked columns: [selection] holds a row per column,
/// [columns] gives the columns for a selection, and [onChanged] gets every
/// pick as a whole, valid selection.
///
/// Each column turns on a `ListWheelScrollView` of the look's shape
/// ([diameterRatio], [perspective], [offAxisFraction], [squeeze],
/// [useMagnifier], [magnification], [overAndUnderCenterOpacity]: its names,
/// `CupertinoPicker`'s defaults). A fling settles on its rows; a key, a tap
/// on a row, a screen reader's step and a parent's new [selection] turn the
/// wheel on a spring ([dampingRatio], [stiffness]), critically damped under
/// Reduce Motion. A row crossing the centre plays
/// [RawHaptics.selectionChanged], at most once a frame (a fast turn's
/// rows would blur into one anyway).
///
/// Keys, each column one tab stop: Down and Up the next and previous live
/// row (wrapping when the column loops), Page Down and Page Up five rows,
/// Home and End the first and last live row, letters and digits the next
/// row whose name starts with what was typed in the last second, Left and
/// Right the column before and after as drawn (mirrored right to left).
///
/// ```dart
/// RawPicker(columns: (selection) => [RawPickerColumn(itemCount: 24, itemLabel: (index) => '$index', semanticLabel: 'Hour', looping: true)], selection: const [9], onChanged: (selection) {}, itemExtent: 40, itemBuilder: (context, details) => Center(child: Text(details.label)))
/// ```
class RawPicker extends StatefulWidget {
  /// A picker showing [selection] in the [columns] it gives.
  const RawPicker({
    super.key,
    required this.columns,
    required this.selection,
    required this.onChanged,
    required this.itemExtent,
    required this.itemBuilder,
    this.columnBuilder,
    this.layoutBuilder,
    this.visibleItemCount = 5,
    this.diameterRatio = 1.07,
    this.perspective = 0.003,
    this.offAxisFraction = 0,
    this.squeeze = 1.45,
    this.useMagnifier = false,
    this.magnification = 1,
    this.overAndUnderCenterOpacity = 1,
    this.semanticLabel,
    this.autofocus = false,
    this.dampingRatio = 1,
    this.stiffness = 700,
  }) : assert(itemExtent > 0),
       assert(visibleItemCount > 0),
       assert(dampingRatio > 0 && stiffness > 0);

  /// The columns for a selection: called with the selection a pick makes,
  /// so a column's rows can follow the others' (a month's days).
  final List<RawPickerColumn> Function(List<int> selection) columns;

  /// The row chosen in each column, one per column.
  final List<int> selection;

  /// Called with the whole selection when a column comes to rest on a new
  /// row, after every other column has moved to a live row.
  ///
  /// {@macro design.nullDisables}
  final ValueChanged<List<int>>? onChanged;

  /// The height of a row.
  final double itemExtent;

  /// Paints a row.
  final RawPickerItemBuilder itemBuilder;

  /// Frames a column round its wheel; null: the wheel alone.
  final RawPickerColumnBuilder? columnBuilder;

  /// Lays the framed columns out; null: a [Row] with each column
  /// [Expanded].
  final Widget Function(BuildContext context, List<Widget> columns)?
  layoutBuilder;

  /// How many rows tall a column is. Defaults to 5.
  final int visibleItemCount;

  /// `ListWheelScrollView.diameterRatio`: the wheel's diameter over its
  /// height. Defaults to `CupertinoPicker`'s, 1.07; a large ratio flattens
  /// it.
  final double diameterRatio;

  /// `ListWheelScrollView.perspective`. Defaults to 0.003.
  final double perspective;

  /// `ListWheelScrollView.offAxisFraction`: how far the wheel's axis leans
  /// off the centre. Defaults to 0.
  final double offAxisFraction;

  /// `ListWheelScrollView.squeeze`: how close the rows stand. Defaults to
  /// `CupertinoPicker`'s, 1.45.
  final double squeeze;

  /// `ListWheelScrollView.useMagnifier`. Defaults to false.
  final bool useMagnifier;

  /// `ListWheelScrollView.magnification`. Defaults to 1.
  final double magnification;

  /// `ListWheelScrollView.overAndUnderCenterOpacity`. Defaults to 1.
  final double overAndUnderCenterOpacity;

  /// What a screen reader calls the whole picker ("Date"); null: nothing.
  final String? semanticLabel;

  /// Whether the first column takes focus when it first shows.
  final bool autofocus;

  /// The turning spring's damping ratio (ζ). Defaults to 1.
  final double dampingRatio;

  /// The turning spring's stiffness (k). Defaults to 700.
  final double stiffness;

  @override
  State<RawPicker> createState() => _RawWheelPickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<List<RawPickerColumn> Function(List<int>)>.has(
          'columns',
          columns,
        ),
      )
      ..add(
        ObjectFlagProperty<RawPickerItemBuilder>.has(
          'itemBuilder',
          itemBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawPickerColumnBuilder>.has(
          'columnBuilder',
          columnBuilder,
        ),
      )
      ..add(IterableProperty<int>('selection', selection))
      ..add(
        ObjectFlagProperty<ValueChanged<List<int>>>.has('onChanged', onChanged),
      )
      ..add(DoubleProperty('itemExtent', itemExtent))
      ..add(IntProperty('visibleItemCount', visibleItemCount, defaultValue: 5))
      ..add(DoubleProperty('diameterRatio', diameterRatio, defaultValue: 1.07))
      ..add(DoubleProperty('perspective', perspective, defaultValue: 0.003))
      ..add(DoubleProperty('offAxisFraction', offAxisFraction, defaultValue: 0))
      ..add(DoubleProperty('squeeze', squeeze, defaultValue: 1.45))
      ..add(
        FlagProperty(
          'useMagnifier',
          value: useMagnifier,
          ifTrue: 'useMagnifier',
          defaultValue: false,
        ),
      )
      ..add(DoubleProperty('magnification', magnification, defaultValue: 1))
      ..add(
        DoubleProperty(
          'overAndUnderCenterOpacity',
          overAndUnderCenterOpacity,
          defaultValue: 1,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      )
      ..add(DoubleProperty('dampingRatio', dampingRatio, defaultValue: 1))
      ..add(DoubleProperty('stiffness', stiffness, defaultValue: 700));
  }
}

class _RawWheelPickerState extends State<RawPicker> {
  final List<FixedExtentScrollController> _controllers = [];
  final List<FocusNode> _nodes = [];
  // Per column: the row at the centre now, where a spring is heading, the
  // way it last turned, and its states.
  final List<int> _centre = [];
  final List<int?> _heading = [];
  final List<BallisticScrollActivity?> _springs = [];
  final List<bool> _forward = [];
  final List<bool> _focused = [];
  // Each column's focus, shown as a browser's :focus-visible shows it.
  final List<RawFocusShown> _focus = [];
  final List<bool> _hovered = [];
  final List<bool> _dragged = [];
  late List<RawPickerColumn> _columns;
  String _typed = '';
  Timer? _typedClear;

  bool get _enabled => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _columns = _columnsFor(widget.selection);
    _sizeTo(widget.selection);
  }

  List<RawPickerColumn> _columnsFor(List<int> selection) {
    final columns = widget.columns(selection);
    assert(
      columns.length == selection.length,
      'columns gives ${columns.length} columns for a selection of '
      '${selection.length}: one row per column',
    );
    return columns;
  }

  void _sizeTo(List<int> selection) {
    while (_controllers.length > selection.length) {
      _controllers.removeLast().dispose();
      _nodes.removeLast().dispose();
      _focus.removeLast().dispose();
      for (final list in <List<Object?>>[
        _centre,
        _heading,
        _springs,
        _forward,
        _focused,
        _hovered,
        _dragged,
      ]) {
        list.removeLast();
      }
    }
    for (var c = _controllers.length; c < selection.length; c++) {
      _controllers.add(FixedExtentScrollController(initialItem: selection[c]));
      _nodes.add(FocusNode(debugLabel: 'RawPicker column $c'));
      _centre.add(selection[c]);
      _heading.add(null);
      _springs.add(null);
      _forward.add(true);
      _focused.add(false);
      _focus.add(
        RawFocusShown((on) {
          if (mounted) setState(() => _focused[c] = on);
        }),
      );
      _hovered.add(false);
      _dragged.add(false);
    }
  }

  @override
  void didUpdateWidget(RawPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _columns = _columnsFor(widget.selection);
    _sizeTo(widget.selection);
    // After layout: a column whose row count changed applies it first, and
    // a spring started before that would give way to the physics. A column
    // a finger holds or a fling turns is left to come to rest.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var c = 0; c < widget.selection.length; c++) {
        final controller = _controllers[c];
        if (_dragged[c] || !controller.hasClients) continue;
        final flung =
            controller.position.isScrollingNotifier.value &&
            _heading[c] == null;
        if (!flung) _turnTo(c, widget.selection[c]);
      }
    });
  }

  @override
  void dispose() {
    _typedClear?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    for (final focus in _focus) {
      focus.dispose();
    }
    super.dispose();
  }

  // The row [c]'s wheel stands on, within its column.
  int _rowOf(int c) {
    final controller = _controllers[c];
    if (!controller.hasClients) return widget.selection[c];
    final count = _columns[c].itemCount;
    return controller.selectedItem % count;
  }

  // Turns [c]'s wheel to [row] on the spring.
  void _turnTo(int c, int row) {
    final controller = _controllers[c];
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position is! ScrollPositionWithSingleContext) return;
    final column = _columns[c];
    final count = column.itemCount;
    final extent = widget.itemExtent;
    // A looping wheel goes the short way round.
    var target = row;
    if (column.looping) {
      final at = (position.pixels / extent).round();
      final base = at - at % count;
      final candidates = [base + row - count, base + row, base + row + count];
      target = candidates.reduce(
        (a, b) => (a - at).abs() <= (b - at).abs() ? a : b,
      );
    }
    final pixels = target * extent;
    if ((position.pixels - pixels).abs() < precisionErrorTolerance) {
      _heading[c] = null;
      return;
    }
    if (_heading[c] == target && position.isScrollingNotifier.value) return;
    _heading[c] = target;
    final spring = RawMotionPolicy.of(
      context,
    ).spatial(dampingRatio: widget.dampingRatio, stiffness: widget.stiffness);
    // A spring retargeted mid-turn keeps its momentum.
    final running = _springs[c];
    final activity = BallisticScrollActivity(
      position,
      rawSpringSimulation(
        spring,
        from: position.pixels,
        to: pixels,
        velocity: running?.velocity ?? 0,
      ),
      position.context.vsync,
      false,
    );
    _springs[c] = activity;
    position.beginActivity(activity);
  }

  // [c] comes to rest on [row] (a fling, a drag, a key): a disabled row
  // turns on to the nearest live one; a live one is picked.
  void _settle(int c) {
    final row = _rowOf(c);
    final column = _columns[c];
    final live = column.nearestEnabled(row, forward: _forward[c]);
    if (live == null) return;
    if (live != row) {
      _turnTo(c, live);
      return;
    }
    _pick(c, live);
  }

  // Picks [row] in [c]: every other column moves to its nearest live row
  // in the columns that pick gives, and onChanged gets the whole selection.
  void _pick(int c, int row) {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    final next = [...widget.selection]..[c] = row;
    for (var pass = 0; pass <= next.length; pass++) {
      final columns = _columnsFor(next);
      var moved = false;
      for (var j = 0; j < columns.length; j++) {
        final live = columns[j].nearestEnabled(next[j]);
        if (live != null && live != next[j]) {
          next[j] = live;
          moved = true;
        }
      }
      if (!moved) break;
    }
    if (listEquals(next, widget.selection)) {
      // Nothing changed for the parent, but a wheel may stand elsewhere.
      for (var j = 0; j < next.length; j++) {
        if (j != c && _rowOf(j) != next[j]) _turnTo(j, next[j]);
      }
      return;
    }
    onChanged(next);
  }

  // A key's or a screen reader's move to [row] in [c]: picked at once, and
  // the wheel turns there.
  void _moveTo(int c, int row) {
    if (!_enabled) return;
    _forward[c] = row >= _centre[c];
    _turnTo(c, row);
    _pick(c, row);
  }

  void _onCentre(int c, int row) {
    if (_centre[c] == row) return;
    setState(() => _centre[c] = row);
    RawHaptics.of(context).selectionChanged?.call();
  }

  bool _onScroll(int c, ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _heading[c] = null;
      _springs[c] = null;
      setState(() => _dragged[c] = true);
    } else if (n is ScrollUpdateNotification) {
      final delta = n.scrollDelta ?? 0;
      if (delta != 0) _forward[c] = delta > 0;
    } else if (n is ScrollEndNotification) {
      if (_dragged[c]) setState(() => _dragged[c] = false);
      _heading[c] = null;
      _springs[c] = null;
      // The end is told inside the scroll's own frame work: settle after.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && c < _controllers.length) _settle(c);
      });
    }
    return false;
  }

  KeyEventResult _onKey(int c, FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_enabled) return KeyEventResult.ignored;
    final column = _columns[c];
    final row = widget.selection[c];
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    int? to;
    if (key == LogicalKeyboardKey.arrowDown) {
      to = column.stepFrom(row, 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      to = column.stepFrom(row, -1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      to = column.stepFrom(row, 5);
    } else if (key == LogicalKeyboardKey.pageUp) {
      to = column.stepFrom(row, -5);
    } else if (key == LogicalKeyboardKey.home) {
      to = column.firstEnabled;
    } else if (key == LogicalKeyboardKey.end) {
      to = column.lastEnabled;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      final after = (key == LogicalKeyboardKey.arrowRight) != rtl;
      final other = c + (after ? 1 : -1);
      if (other < 0 || other >= _nodes.length) return KeyEventResult.handled;
      _nodes[other].requestFocus();
      return KeyEventResult.handled;
    } else {
      final typed = event.character;
      if (typed == null || typed.trim().isEmpty || typed.runes.length != 1) {
        return KeyEventResult.ignored;
      }
      if (typed.codeUnitAt(0) < 0x20) return KeyEventResult.ignored;
      _typedClear?.cancel();
      _typedClear = Timer(const Duration(seconds: 1), () => _typed = '');
      _typed += typed.toLowerCase();
      to = _matching(column, row, _typed);
      if (to == null) return KeyEventResult.handled;
    }
    if (to != null && to != row) _moveTo(c, to);
    return KeyEventResult.handled;
  }

  // The next live row from [row] whose name starts with [typed]: after it
  // for one character (so a letter cycles), from it for more.
  int? _matching(RawPickerColumn column, int row, String typed) {
    final count = column.itemCount;
    final start = typed.length == 1 ? 1 : 0;
    for (var d = start; d < count + start; d++) {
      final i = (row + d) % count;
      if (!column.isEnabled(i)) continue;
      if (column.itemLabel(i).toLowerCase().startsWith(typed)) return i;
    }
    return null;
  }

  Widget _column(BuildContext context, int c) {
    final column = _columns[c];
    final enabled = _enabled;
    final row = widget.selection[c].clamp(0, column.itemCount - 1);
    final next = column.stepFrom(row, 1);
    final previous = column.stepFrom(row, -1);
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (enabled && _focused[c]) WidgetState.focused,
      if (enabled && _hovered[c]) WidgetState.hovered,
      if (enabled && _dragged[c]) ...{WidgetState.pressed, WidgetState.dragged},
    };
    Widget item(BuildContext context, int index) {
      final live = enabled && column.isEnabled(index);
      return GestureDetector(
        onTap: live ? () => _moveTo(c, index) : null,
        child: widget.itemBuilder(
          context,
          RawPickerItemDetails(
            column: c,
            index: index,
            label: column.itemLabel(index),
            selected: index == _centre[c],
            enabled: live,
          ),
        ),
      );
    }

    final behavior = ScrollConfiguration.of(context);
    final wheel = NotificationListener<ScrollNotification>(
      onNotification: (n) => _onScroll(c, n),
      child: SizedBox(
        height: widget.itemExtent * widget.visibleItemCount,
        child: ListWheelScrollView.useDelegate(
          scrollBehavior: behavior.copyWith(
            scrollbars: false,
            dragDevices: {...behavior.dragDevices, PointerDeviceKind.mouse},
          ),
          controller: _controllers[c],
          itemExtent: widget.itemExtent,
          physics: enabled
              ? const FixedExtentScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          diameterRatio: widget.diameterRatio,
          perspective: widget.perspective,
          offAxisFraction: widget.offAxisFraction,
          squeeze: widget.squeeze,
          useMagnifier: widget.useMagnifier,
          magnification: widget.magnification,
          overAndUnderCenterOpacity: widget.overAndUnderCenterOpacity,
          onSelectedItemChanged: (i) => _onCentre(c, i % column.itemCount),
          childDelegate: column.looping
              ? ListWheelChildLoopingListDelegate(
                  children: [
                    for (var i = 0; i < column.itemCount; i++)
                      Builder(builder: (context) => item(context, i)),
                  ],
                )
              : ListWheelChildBuilderDelegate(
                  childCount: column.itemCount,
                  builder: item,
                ),
        ),
      ),
    );
    final framed =
        widget.columnBuilder?.call(
          context,
          RawPickerColumnDetails(
            column: c,
            states: states,
            itemExtent: widget.itemExtent,
          ),
          wheel,
        ) ??
        wheel;
    String? say(int i) => column.itemLabel(i);
    return Semantics(
      container: true,
      label: column.semanticLabel,
      value: say(row),
      increasedValue: next != row ? say(next) : null,
      decreasedValue: previous != row ? say(previous) : null,
      onIncrease: enabled && next != row ? () => _moveTo(c, next) : null,
      onDecrease: enabled && previous != row
          ? () => _moveTo(c, previous)
          : null,
      enabled: enabled,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: (node, event) => _onKey(c, node, event),
        child: FocusableActionDetector(
          enabled: enabled,
          focusNode: _nodes[c],
          autofocus: widget.autofocus && c == 0,
          onFocusChange: _focus[c].focused,
          // A mouse turns a wheel by dragging it: it grabs, and grabbing
          // while it turns.
          mouseCursor: !enabled
              ? SystemMouseCursors.basic
              : _dragged[c]
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered[c] = true),
            onExit: (_) => setState(() => _hovered[c] = false),
            child: ExcludeSemantics(child: framed),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = [
      for (var c = 0; c < _columns.length; c++) _column(context, c),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child:
          widget.layoutBuilder?.call(context, columns) ??
          Row(children: [for (final c in columns) Expanded(child: c)]),
    );
  }
}
