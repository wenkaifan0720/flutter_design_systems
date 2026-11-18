/// A list and the detail of its chosen item, headless: side by side when
/// there is room, else the list alone and the detail pushed over it.
/// Crossing the width keeps the reader where they were. F6 moves focus
/// between the list and the detail.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'adaptive_shell.dart';
import 'internal/panes.dart';
import 'split_view.dart';

/// A list ([listBuilder]) and the detail of [selectedItem] ([detailBuilder]),
/// as Compose's ListDetailPaneScaffold.
///
/// Side by side ([sideBySide], or from [DesignWindowSizeClass.expanded]'s
/// 840 up in its own width), the list [listWidth] wide at the start, the
/// detail beside it (with nothing chosen, [emptyDetailBuilder]); given a
/// [dividerBuilder], a [DesignSplitView] the reader can resize. Narrow, the
/// list alone: choosing an item pushes [detailRouteBuilder]'s route (the
/// look's page route) with its detail, and that route's pop clears the
/// choice. Narrow to wide, the pushed detail leaves and shows beside the
/// list; wide to narrow with an item chosen, it is pushed.
///
/// ```dart
/// DesignListDetail<String>(selectedItem: null, onSelectedItemChanged: (item) {}, listBuilder: (context) => const Text('Inbox'), detailBuilder: (context, item) => Text(item), detailRouteBuilder: (builder) => PageRouteBuilder<void>(pageBuilder: (context, _, _) => builder(context)))
/// ```
class DesignListDetail<T extends Object> extends StatefulWidget {
  /// A list and its chosen item's detail.
  const DesignListDetail({
    super.key,
    required this.selectedItem,
    required this.onSelectedItemChanged,
    required this.listBuilder,
    required this.detailBuilder,
    required this.detailRouteBuilder,
    this.emptyDetailBuilder,
    this.sideBySide,
    this.dividerBuilder,
    this.listWidth = 360,
  }) : assert(listWidth > 0);

  /// The item whose detail shows; null: none.
  final T? selectedItem;

  /// Called with an item chosen (the list's rows call it), or with null as
  /// a pushed detail pops.
  final ValueChanged<T?> onSelectedItemChanged;

  /// The list pane.
  final WidgetBuilder listBuilder;

  /// An item's detail.
  final Widget Function(BuildContext context, T item) detailBuilder;

  /// The route a narrow list-detail pushes the detail in, around the builder
  /// it is given: the look's page route.
  final Route<void> Function(WidgetBuilder builder) detailRouteBuilder;

  /// Side by side with nothing chosen; null: empty.
  final WidgetBuilder? emptyDetailBuilder;

  /// Whether list and detail show side by side; null: from 840 wide up.
  final bool? sideBySide;

  /// Side by side, the divider of a [DesignSplitView] the reader resizes;
  /// null: the list fixed at [listWidth].
  final DesignDividerBuilder? dividerBuilder;

  /// The list pane's width side by side (its first width, resizable).
  final double listWidth;

  @override
  State<DesignListDetail<T>> createState() => _DesignListDetailState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('selectedItem', selectedItem))
      ..add(
        ObjectFlagProperty<ValueChanged<T?>>.has(
          'onSelectedItemChanged',
          onSelectedItemChanged,
        ),
      )
      ..add(ObjectFlagProperty<WidgetBuilder>.has('listBuilder', listBuilder))
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext, T)>.has(
          'detailBuilder',
          detailBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<Route<void> Function(WidgetBuilder)>.has(
          'detailRouteBuilder',
          detailRouteBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<WidgetBuilder>.has(
          'emptyDetailBuilder',
          emptyDetailBuilder,
        ),
      )
      ..add(
        FlagProperty(
          'sideBySide',
          value: sideBySide,
          ifTrue: 'side by side',
          ifFalse: 'list alone',
        ),
      )
      ..add(
        ObjectFlagProperty<DesignDividerBuilder>.has(
          'dividerBuilder',
          dividerBuilder,
        ),
      )
      ..add(DoubleProperty('listWidth', listWidth, defaultValue: 360));
  }
}

class _DesignListDetailState<T extends Object>
    extends State<DesignListDetail<T>> {
  // The list keeps its state (its scroll) as the layout changes.
  final GlobalKey _list = GlobalKey(debugLabel: 'DesignListDetail list');
  Route<void>? _pushed;
  T? _pushedItem;
  bool _wide = false;
  bool _syncing = false;
  // Its width and the window's when it was last laid out.
  double? _laidOut;
  double? _windowThen;

  @override
  void dispose() {
    _drop();
    super.dispose();
  }

  // After the frame: a narrow list-detail pushes its chosen item's detail,
  // or drops a pushed detail no longer wanted.
  void _scheduleSync() {
    if (_syncing) return;
    _syncing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncing = false;
      if (mounted) _sync();
    });
  }

  void _sync() {
    final item = widget.selectedItem;
    if (_wide || item == null) {
      _drop();
      return;
    }
    if (_pushed != null && _pushedItem == item) return;
    _drop();
    final route = widget.detailRouteBuilder(
      (context) => widget.detailBuilder(context, item),
    );
    _pushed = route;
    _pushedItem = item;
    Navigator.of(context).push(route).whenComplete(() {
      if (!identical(_pushed, route)) return;
      _pushed = null;
      _pushedItem = null;
      if (mounted) widget.onSelectedItemChanged(null);
    });
  }

  // Takes a pushed detail away without clearing the choice.
  void _drop() {
    final route = _pushed;
    _pushed = null;
    _pushedItem = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  bool _wideAt(double width) =>
      widget.sideBySide ??
      DesignWindowSizeClass.fromWidth(width).index >=
          DesignWindowSizeClass.expanded.index;

  @override
  Widget build(BuildContext context) {
    final window = MediaQuery.sizeOf(context).width;
    final laidOut = _laidOut;
    final then = _windowThen;
    // Covered by its pushed detail, it is not laid out: its width follows
    // the window's change, and a window grown wide takes the detail back.
    if (_pushed != null && laidOut != null && then != null && window != then) {
      _wide = _wideAt(laidOut + window - then);
      _scheduleSync();
    }
    return LayoutBuilder(builder: _layout);
  }

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final window = MediaQuery.sizeOf(context).width;
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : window;
    // Covered, it builds on its last constraints: the window's guess holds.
    final stale = _pushed != null && width == _laidOut && window != _windowThen;
    if (!stale) {
      _laidOut = width;
      _windowThen = window;
      _wide = _wideAt(width);
    }
    _scheduleSync();
    final list = KeyedSubtree(
      key: _list,
      child: Pane(
        debugLabel: 'DesignListDetail list',
        child: Builder(builder: widget.listBuilder),
      ),
    );
    if (!_wide) return PaneCycle(child: list);
    final item = widget.selectedItem;
    final Widget detail = Pane(
      debugLabel: 'DesignListDetail detail',
      child: item == null
          ? (widget.emptyDetailBuilder?.call(context) ??
                const SizedBox.expand())
          : KeyedSubtree(
              key: ValueKey<T>(item),
              child: Builder(
                builder: (context) => widget.detailBuilder(context, item),
              ),
            ),
    );
    final divider = widget.dividerBuilder;
    final Widget panes = divider == null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: widget.listWidth.clamp(0, width).toDouble(),
                child: list,
              ),
              Expanded(child: detail),
            ],
          )
        : DesignSplitView(
            first: list,
            second: detail,
            dividerBuilder: divider,
            initialFraction: (widget.listWidth / width).clamp(0.0, 1.0),
          );
    return PaneCycle(child: panes);
  }
}
