/// Appliance's containers: [ApplianceDisclosure] (a hinged lid over more),
/// [ApplianceTable] and [ApplianceDataTable] (rows ruled on the panel, a
/// data table's sorting keys and its lit rows), [ApplianceScrollArea] (a
/// slot and its slider), [ApplianceSplitView] (two panes and the grip
/// between), [ApplianceCarousel] (slides in a window, their lamps under
/// it), [ApplianceReorderableList], [ApplianceSwipeActions],
/// [ApplianceRefresh], [ApplianceTree] and [ApplianceTimeline].
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'actions.dart';
import 'button.dart';
import 'choices.dart';
import 'feedback.dart';
import 'internal/spring_value.dart';
import 'lists.dart';
import 'material.dart';
import 'theme.dart';
import 'wayfinding.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart'
    show
        RawDataTableSelection,
        RawSortDirection,
        RawDataColumn,
        RawDataTableController;
export 'package:ui_core/ui_core.dart' show RawSwipeAction;
export 'package:ui_core/ui_core.dart' show RawTreeController;

/// A chevron that turns from pointing to the end ([turn] 0) to pointing
/// down ([turn] 1), mirrored for right-to-left text.
class _Hinge extends StatelessWidget {
  const _Hinge({required this.turn, required this.color});

  final double turn;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.rotate(
      angle: (rtl ? -1 : 1) * turn * math.pi / 2,
      child: Transform.flip(
        flipX: rtl,
        child: CustomPaint(
          size: const Size.square(16),
          painter: ApplianceChevronPainter(color),
        ),
      ),
    );
  }
}

/// A disclosure: a row with a chevron that lifts a hinged lid on more. The
/// lid opens and shuts on the lid's spring; the chevron turns with it.
///
/// Give [open] and [onChanged] to hold it yourself; otherwise it holds its
/// own, starting at [initiallyOpen].
///
/// ```dart
/// ApplianceDisclosure(title: 'Care and cleaning', child: const Text('Descale monthly.'))
/// ```
class ApplianceDisclosure extends StatefulWidget {
  /// A disclosure headed [title] over [child].
  const ApplianceDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.open,
    this.onChanged,
    this.initiallyOpen = false,
    this.style,
  });

  /// The row's words.
  final String title;

  /// A second line under them.
  final String? subtitle;

  /// What the lid covers.
  final Widget child;

  /// Whether it is open, when you hold it.
  final bool? open;

  /// Called with its new state.
  final ValueChanged<bool>? onChanged;

  /// Whether it starts open, when it holds its own.
  final bool initiallyOpen;

  /// The row's style, over [ApplianceThemeData.listTileStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceDisclosure> createState() => _ApplianceDisclosureState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(DiagnosticsProperty<bool>('open', open, defaultValue: null));
  }
}

class _ApplianceDisclosureState extends State<ApplianceDisclosure> {
  late bool _open = widget.initiallyOpen;

  bool get _isOpen => widget.open ?? _open;

  void _toggle() {
    final next = !_isOpen;
    if (widget.open == null) setState(() => _open = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final open = _isOpen;
    return ApplianceSpringValue(
      value: open ? 1 : 0,
      spring: ApplianceMotion.lid,
      builder: (context, v, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RawButton(
            onPressed: _toggle,
            expanded: open,
            semanticLabel: widget.title,
            excludeSemantics: true,
            builder: (context, states, _) {
              final layered = RawStyleOf([
                widget.style,
                theme.listTileStyle,
              ], states);
              final pressed = states.contains(WidgetState.pressed);
              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: theme.controlHeight + 8),
                child: AnimatedApplianceSurface(
                  control: false,
                  face: layered.on(
                    ApplianceFace(
                      top: pressed
                          ? c.keyDownTop
                          : c.keyDownTop.withValues(alpha: 0),
                      bottom: pressed
                          ? c.keyDownBottom
                          : c.keyDownBottom.withValues(alpha: 0),
                      lift: pressed ? -0.5 : 0,
                      radius: BorderRadius.circular(
                        ApplianceMetrics.smallKeyRadius,
                      ),
                      foreground: c.print,
                      focus: states.contains(WidgetState.focused)
                          ? c.focus
                          : c.focus.withValues(alpha: 0),
                    ),
                  ),
                  child: Padding(
                    padding:
                        layered.padding(Directionality.of(context)) ??
                        const EdgeInsets.symmetric(
                          horizontal: ApplianceSpacing.regular,
                          vertical: ApplianceSpacing.small,
                        ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: layered.text(
                                  t.body.copyWith(
                                    color: c.print,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  style: t.secondary.copyWith(
                                    color: c.printMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: ApplianceSpacing.medium),
                        _Hinge(turn: v, color: c.printMuted),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          ClipRect(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: v.clamp(0.0, 1.0),
              child: Visibility(
                visible: v > 0.01,
                maintainState: true,
                child: Opacity(
                  opacity: v.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ApplianceSpacing.regular,
                      ApplianceSpacing.tight,
                      ApplianceSpacing.regular,
                      ApplianceSpacing.regular,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A column of an [ApplianceTable].
@immutable
class ApplianceTableColumn {
  /// A column headed [label].
  const ApplianceTableColumn(this.label, {this.numeric = false, this.flex = 1});

  /// Its heading.
  final String label;

  /// Whether it holds figures: set to the end, in even widths.
  final bool numeric;

  /// Its share of the width.
  final int flex;
}

/// The header row's legend.
Widget _heading(BuildContext context, String label, {bool numeric = false}) {
  final theme = ApplianceTheme.of(context);
  return Text(
    label.toUpperCase(),
    textAlign: numeric ? TextAlign.end : TextAlign.start,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: theme.textTheme.legend.copyWith(color: theme.colors.printMuted),
  );
}

/// A cell's words.
Widget _cell(BuildContext context, String text, {bool numeric = false}) {
  final theme = ApplianceTheme.of(context);
  return Text(
    text,
    textAlign: numeric ? TextAlign.end : TextAlign.start,
    style: theme.textTheme.body.copyWith(
      color: theme.colors.print,
      fontFeatures: numeric ? const [FontFeature.tabularFigures()] : null,
    ),
  );
}

/// A table: rows ruled on the panel, the columns' legends printed in small
/// capitals over a seam, figures set to the end in even widths.
///
/// ```dart
/// ApplianceTable(columns: const [ApplianceTableColumn('Item'), ApplianceTableColumn('Price', numeric: true)], rows: const [['Kettle', '£48.00'], ['Toaster', '£36.00']])
/// ```
class ApplianceTable extends StatelessWidget {
  /// A table of [rows] in [columns].
  const ApplianceTable({
    super.key,
    required this.columns,
    required this.rows,
    this.style,
  });

  /// The columns.
  final List<ApplianceTableColumn> columns;

  /// The rows, a text for each column.
  final List<List<String>> rows;

  /// Its style, over [ApplianceThemeData.tableStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.tableStyle], const {});
    final pad =
        layered.padding(Directionality.of(context)) ??
        const EdgeInsets.symmetric(
          horizontal: ApplianceSpacing.small,
          vertical: ApplianceSpacing.medium,
        );
    return Table(
      columnWidths: {
        for (final (i, col) in columns.indexed)
          i: FlexColumnWidth(col.flex.toDouble()),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.seamShade, width: 2)),
          ),
          children: [
            for (final col in columns)
              Padding(
                padding: pad.copyWith(top: 0, bottom: ApplianceSpacing.small),
                child: Semantics(
                  header: true,
                  child: _heading(context, col.label, numeric: col.numeric),
                ),
              ),
          ],
        ),
        for (final (r, row) in rows.indexed)
          TableRow(
            decoration: BoxDecoration(
              border: r == rows.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: c.hairline)),
            ),
            children: [
              for (final (i, col) in columns.indexed)
                Padding(
                  padding: pad,
                  child: _cell(
                    context,
                    i < row.length ? row[i] : '',
                    numeric: col.numeric,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('columns', columns.length))
      ..add(IntProperty('rows', rows.length));
  }
}

/// A sort's arrows: up lit when ascending, down when descending, both
/// faint when unsorted.
class _SortPainter extends CustomPainter {
  _SortPainter({required this.up, required this.down});

  final Color up;
  final Color down;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas
      ..drawPath(
        Path()
          ..moveTo(w * 0.2, h * 0.42)
          ..lineTo(w * 0.5, h * 0.12)
          ..lineTo(w * 0.8, h * 0.42)
          ..close(),
        Paint()..color = up,
      )
      ..drawPath(
        Path()
          ..moveTo(w * 0.2, h * 0.58)
          ..lineTo(w * 0.5, h * 0.88)
          ..lineTo(w * 0.8, h * 0.58)
          ..close(),
        Paint()..color = down,
      );
  }

  @override
  bool shouldRepaint(_SortPainter old) => old.up != up || old.down != down;
}

/// A data table: [ApplianceTable]'s ruled rows over a
/// [RawDataTableController]. A sortable column's legend is a key that
/// sorts it, its arrow lit; a selected row is lit as a key pressed into
/// the panel, its box checked. One tab stop for the rows: the arrows walk
/// them, Space selects, Enter opens.
///
/// ```dart
/// ApplianceDataTable<String>(controller: RawDataTableController<String>(rows: const ['Kettle'], columns: [RawDataColumn<String>(id: 'name', label: 'Name', sortKey: (row) => row)]), cellText: (row, column) => row)
/// ```
class ApplianceDataTable<R> extends StatelessWidget {
  /// The table of [controller], each cell's words from [cellText].
  const ApplianceDataTable({
    super.key,
    required this.controller,
    required this.cellText,
    this.selectable = true,
    this.onActivate,
    this.rowLabel,
    this.style,
  });

  /// The rows, columns, sort, selection and page; yours to dispose.
  final RawDataTableController<R> controller;

  /// A cell's words.
  final String Function(R row, RawDataColumn<R> column) cellText;

  /// Whether rows are selected (a box at each row's start).
  final bool selectable;

  /// Opens a row (Enter, or a press when it does not select).
  final ValueChanged<R>? onActivate;

  /// A row's name for its box, for a screen reader.
  final String Function(R row)? rowLabel;

  /// Its style, over [ApplianceThemeData.tableStyle].
  final ApplianceStyle? style;

  static const double _box = 48;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    Widget cells(List<Widget> cells, {Widget? lead}) => Row(
      children: [
        if (selectable) SizedBox(width: _box, child: lead),
        for (final cell in cells) Expanded(child: cell),
      ],
    );
    return RawDataTable<R>(
      controller: controller,
      selectable: selectable,
      onActivate: onActivate,
      headerRowBuilder: (context, header) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final page = controller.pageSelection;
          return Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.seamShade, width: 2)),
            ),
            padding: const EdgeInsets.only(bottom: ApplianceSpacing.tight),
            child: cells(
              header,
              lead: Center(
                child: ApplianceCheckbox(
                  value: switch (page) {
                    RawDataTableSelection.none => false,
                    RawDataTableSelection.some => null,
                    RawDataTableSelection.all => true,
                  },
                  tristate: true,
                  semanticLabel: 'Select every row on the page',
                  onChanged: (_) => controller.togglePage(),
                ),
              ),
            ),
          );
        },
      ),
      headerBuilder: (context, column, sort, states) {
        final legend = Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ApplianceSpacing.small,
          ),
          child: _heading(context, column.label, numeric: column.numeric),
        );
        if (!column.sortable) return legend;
        final pressed = states.contains(WidgetState.pressed);
        return SizedBox(
          height: theme.controlHeight - ApplianceSpacing.tight,
          child: AnimatedApplianceSurface(
            face: ApplianceFace(
              top: pressed ? c.keyDownTop : c.keyDownTop.withValues(alpha: 0),
              bottom: pressed
                  ? c.keyDownBottom
                  : c.keyDownBottom.withValues(alpha: 0),
              lift: pressed ? -0.5 : 0,
              radius: BorderRadius.circular(ApplianceSpacing.tight),
              foreground: c.printMuted,
              focus: states.contains(WidgetState.focused)
                  ? c.focus
                  : c.focus.withValues(alpha: 0),
            ),
            child: Row(
              mainAxisAlignment: column.numeric
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Flexible(child: legend),
                CustomPaint(
                  size: const Size(10, 14),
                  painter: _SortPainter(
                    up: sort == RawSortDirection.ascending
                        ? c.signal
                        : c.printDisabled.withValues(alpha: 0.5),
                    down: sort == RawSortDirection.descending
                        ? c.signal
                        : c.printDisabled.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: ApplianceSpacing.tight),
              ],
            ),
          ),
        );
      },
      cellBuilder: (context, row, column) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ApplianceSpacing.small,
          vertical: ApplianceSpacing.medium,
        ),
        child: _cell(context, cellText(row, column), numeric: column.numeric),
      ),
      rowBuilder: (context, row, rowCells) {
        final layered = RawStyleOf([style, theme.tableStyle], row.states);
        final lit = row.selected || row.states.contains(WidgetState.pressed);
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: AnimatedApplianceSurface(
            control: false,
            face: layered.on(
              ApplianceFace(
                top: lit ? c.keyDownTop : c.keyDownTop.withValues(alpha: 0),
                bottom: lit
                    ? c.keyDownBottom
                    : c.keyDownBottom.withValues(alpha: 0),
                lift: lit ? -0.4 : 0,
                radius: BorderRadius.circular(ApplianceSpacing.tight),
                foreground: c.print,
                focus: row.states.contains(WidgetState.focused)
                    ? c.focus
                    : c.focus.withValues(alpha: 0),
              ),
            ),
            child: cells(
              rowCells,
              lead: Center(
                child: ApplianceCheckbox(
                  value: row.selected,
                  semanticLabel: rowLabel == null
                      ? 'Select row'
                      : 'Select ${rowLabel!(row.row)}',
                  onChanged: (_) => row.toggle(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A scroll area: its contents with a slot at the side and a small slider
/// in it showing where you are; drag the slider, or press the slot to jump.
/// It focuses, and the arrows and Page keys scroll it.
///
/// With no [controller] it makes its own and hands it to [child] as its
/// [PrimaryScrollController]: a scroll view along [axis] with no controller
/// of its own (and `primary` left null) takes it.
///
/// ```dart
/// ApplianceScrollArea(child: ListView(children: const [Text('Flour')]))
/// ```
class ApplianceScrollArea extends StatefulWidget {
  /// A scroll area round [child], scrolled by [controller].
  const ApplianceScrollArea({
    super.key,
    this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.semanticLabel,
  });

  /// [child]'s scroll controller, which [child] must scroll on too; yours
  /// to dispose. Null: the area makes one, gives it to [child] as its
  /// [PrimaryScrollController], and disposes it.
  final ScrollController? controller;

  /// The scroll view.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// Its name for a screen reader.
  final String? semanticLabel;

  @override
  State<ApplianceScrollArea> createState() => _ApplianceScrollAreaState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ScrollController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(EnumProperty<Axis>('axis', axis, defaultValue: Axis.vertical));
  }
}

class _ApplianceScrollAreaState extends State<ApplianceScrollArea> {
  // The area's own controller, while none is handed in.
  ScrollController? _own;

  ScrollController get _controller => widget.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _own = ScrollController();
  }

  @override
  void didUpdateWidget(ApplianceScrollArea old) {
    super.didUpdateWidget(old);
    if (widget.controller == null && _own == null) {
      _own = ScrollController();
    } else if (widget.controller != null && _own != null) {
      _own!.dispose();
      _own = null;
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    final controller = _controller;
    final axis = widget.axis;
    return RawScrollArea(
      controller: controller,
      axis: axis,
      thickness: 10,
      semanticLabel: widget.semanticLabel,
      trackBuilder: (context, thumb) => AnimatedOpacity(
        opacity: thumb.visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Padding(
          padding: const EdgeInsets.all(ApplianceMetrics.capInset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.trough,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
      thumbBuilder: (context, thumb) {
        final down = thumb.states.contains(WidgetState.pressed);
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.all(ApplianceSpacing.hair),
            child: ApplianceSurface(
              face: applianceKeyFace(c, down: down, radius: 4),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
      frameBuilder: (context, focused, area) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ApplianceMetrics.smallKeyRadius),
          border: Border.all(
            color: focused ? c.focus : c.focus.withValues(alpha: 0),
            width: ApplianceMetrics.focusWidth,
          ),
        ),
        child: area,
      ),
      child: _own == null
          ? widget.child
          : PrimaryScrollController(
              controller: controller,
              automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
              scrollDirection: axis,
              child: widget.child,
            ),
    );
  }
}

/// A split view: two panes and, on the seam between them, a moulded grip
/// that drags to share the room. It focuses; the arrows move the seam.
///
/// ```dart
/// ApplianceSplitView(first: const Text('Orders'), second: const Text('Order 1042'))
/// ```
class ApplianceSplitView extends StatelessWidget {
  /// [first] and [second], side by side (or stacked along [axis]).
  const ApplianceSplitView({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = 0.4,
    this.onChanged,
    this.minFirst = 160,
    this.minSecond = 160,
    this.semanticLabel = 'Resize panes',
  });

  /// The first pane.
  final Widget first;

  /// The second pane.
  final Widget second;

  /// Side by side ([Axis.horizontal]) or stacked.
  final Axis axis;

  /// The first pane's share, when you hold it.
  final double? fraction;

  /// The first pane's share to start with.
  final double initialFraction;

  /// Called with the first pane's new share.
  final ValueChanged<double>? onChanged;

  /// The first pane's least extent.
  final double minFirst;

  /// The second pane's least extent.
  final double minSecond;

  /// The grip's name for a screen reader.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    return RawSplitView(
      first: first,
      second: second,
      axis: axis,
      fraction: fraction,
      initialFraction: initialFraction,
      onChanged: onChanged,
      minFirst: minFirst,
      minSecond: minSecond,
      dividerThickness: 12,
      hitExtent: 16,
      semanticLabel: semanticLabel,
      dividerBuilder: (context, states, axis) {
        final across = axis == Axis.horizontal;
        final down =
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.dragged);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: across ? 2 : double.infinity,
              height: across ? double.infinity : 2,
              color: c.seamShade,
            ),
            SizedBox(
              width: across ? 10 : 36,
              height: across ? 36 : 10,
              child: AnimatedApplianceSurface(
                face: applianceKeyFace(
                  c,
                  down: down,
                  focused: states.contains(WidgetState.focused),
                  radius: 4,
                ),
                child: Center(
                  child: Flex(
                    direction: across ? Axis.vertical : Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox.square(dimension: 3),
                        Container(
                          width: across ? 4 : 1.5,
                          height: across ? 1.5 : 4,
                          color: c.seamShade,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('axis', axis))
      ..add(DoubleProperty('fraction', fraction, defaultValue: null));
  }
}

/// A carousel: slides in a window sunk in the panel, under it a key back,
/// a lamp for each slide (the one shown lit) and a key on. A swipe, the
/// keys and the arrows turn it.
///
/// ```dart
/// ApplianceCarousel(itemCount: 3, height: 180, itemBuilder: (context, i) => Text('Slide $i'))
/// ```
class ApplianceCarousel extends StatelessWidget {
  /// A carousel of [itemCount] slides.
  const ApplianceCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 200,
    this.loop = false,
    this.onPageChanged,
    this.semanticLabel,
    this.style,
  });

  /// How many slides.
  final int itemCount;

  /// Builds a slide.
  final IndexedWidgetBuilder itemBuilder;

  /// The window's height.
  final double height;

  /// Whether the last slide turns to the first.
  final bool loop;

  /// Called with the slide turned to.
  final ValueChanged<int>? onPageChanged;

  /// Its name for a screen reader.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.displayStyle]: fill (the window).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      style,
      ApplianceTheme.of(context).displayStyle,
    ], const {});
    final c = ApplianceTheme.of(context).colors;
    return RawCarousel(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      loop: loop,
      onPageChanged: onPageChanged,
      semanticLabel: semanticLabel,
      layoutBuilder: (context, viewport, controls) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: ApplianceSurface(
              face: ApplianceFace.well(c, fill: look.fill ?? c.trough).copyWith(
                focus: controls.focused
                    ? c.focus
                    : c.focus.withValues(alpha: 0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(ApplianceMetrics.windowInset),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ApplianceMetrics.wellRadius - ApplianceMetrics.windowInset,
                  ),
                  child: viewport,
                ),
              ),
            ),
          ),
          const SizedBox(height: ApplianceSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ApplianceIconButton(
                icon: const _Arrow(back: true),
                semanticLabel: 'Previous slide',
                onPressed: controls.previous,
              ),
              const SizedBox(width: ApplianceSpacing.small),
              AppliancePageDots(
                count: math.max(controls.count, 1),
                index: controls.page.clamp(0, math.max(controls.count - 1, 0)),
                onChanged: controls.goToPage,
              ),
              const SizedBox(width: ApplianceSpacing.small),
              ApplianceIconButton(
                icon: const _Arrow(),
                semanticLabel: 'Next slide',
                onPressed: controls.next,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('itemCount', itemCount));
  }
}

/// A chevron in the ambient icon colour, pointing back or on.
class _Arrow extends StatelessWidget {
  const _Arrow({this.back = false});

  final bool back;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: back != rtl,
      child: CustomPaint(
        size: Size.square(icon.size ?? 20),
        painter: ApplianceChevronPainter(icon.color ?? const Color(0xFF000000)),
      ),
    );
  }
}

/// A grip: three ridges moulded in, where a row is held to move it, a
/// finger's floor square on every input.
class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox.fromSize(
        size: RawTapTargets.of(context).touch,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: ApplianceSpacing.nudge),
                Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: c.seamShade,
                    border: Border(bottom: BorderSide(color: c.seamLight)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A reorderable list: rows with a grip at their end; drag a row by its
/// grip (or, on a phone, by a long press) and it lifts off the panel as a
/// key would. A screen reader's actions move a row up and down.
///
/// ```dart
/// ApplianceReorderableList<String>(items: const ['Milk', 'Eggs'], labelOf: (item) => item, onReorder: (from, to) {}, title: (item) => item)
/// ```
class ApplianceReorderableList<T extends Object> extends StatelessWidget {
  /// A list of [items], each row reading [title].
  const ApplianceReorderableList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.labelOf,
    required this.title,
    this.subtitle,
    this.shrinkWrap = true,
  });

  /// The items, in order.
  final List<T> items;

  /// Moves the item at the first index to the second.
  final void Function(int from, int to) onReorder;

  /// An item's name for a screen reader.
  final String Function(T item) labelOf;

  /// A row's words.
  final String Function(T item) title;

  /// A row's second line.
  final String? Function(T item)? subtitle;

  /// Whether it is as tall as its rows (inside another scroll view).
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return RawReorderableList<T>(
      items: items,
      onReorder: onReorder,
      labelOf: labelOf,
      shrinkWrap: shrinkWrap,
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) => ApplianceSurface(
          face: ApplianceFace.key(
            c,
            radius: ApplianceMetrics.smallKeyRadius,
          ).copyWith(lift: 1 + animation.value * 1.5),
          child: child,
        ),
      ),
      itemBuilder: (context, item, reorder) {
        final sub = subtitle?.call(item);
        return Container(
          decoration: BoxDecoration(
            border: reorder.index == reorder.count - 1
                ? null
                : Border(bottom: BorderSide(color: c.hairline)),
          ),
          constraints: BoxConstraints(minHeight: theme.controlHeight + 8),
          padding: const EdgeInsetsDirectional.only(
            start: ApplianceSpacing.regular,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title(item),
                      style: theme.textTheme.body.copyWith(color: c.print),
                    ),
                    if (sub != null)
                      Text(
                        sub,
                        style: theme.textTheme.secondary.copyWith(
                          color: c.printMuted,
                        ),
                      ),
                  ],
                ),
              ),
              reorder.handle(const _Grip()),
            ],
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}

/// Swipe actions: a row slid aside to show the keys behind it, a
/// destructive one red. Slid far enough, the nearest one runs. A screen
/// reader finds them among the row's actions.
///
/// ```dart
/// ApplianceSwipeActions(endActions: [RawSwipeAction(label: 'Remove', destructive: true, onPressed: () {})], child: const ApplianceListTile(title: 'Kettle'))
/// ```
class ApplianceSwipeActions extends StatelessWidget {
  /// [child], with [startActions] and [endActions] behind it.
  const ApplianceSwipeActions({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
  });

  /// The row.
  final Widget child;

  /// The keys a swipe toward the end shows.
  final List<RawSwipeAction> startActions;

  /// The keys a swipe toward the start shows.
  final List<RawSwipeAction> endActions;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return RawSwipeActions(
      startActions: startActions,
      endActions: endActions,
      actionExtent: 88,
      actionBuilder: (context, action, details) {
        final pressed = details.states.contains(WidgetState.pressed);
        final destructive = action.destructive;
        final top = destructive ? c.danger : c.keyDownTop;
        final bottom = destructive
            ? Color.lerp(c.danger, c.shade, 0.12)!
            : c.keyDownBottom;
        final ink = destructive ? c.onDanger : c.print;
        return AnimatedApplianceSurface(
          face: ApplianceFace(
            top: pressed ? bottom : top,
            bottom: bottom,
            lift: pressed ? -0.5 : 0,
            radius: BorderRadius.zero,
            foreground: ink,
            focus: details.states.contains(WidgetState.focused)
                ? c.focus
                : c.focus.withValues(alpha: 0),
          ),
          child: Center(
            child: Text(
              action.label,
              style: theme.textTheme.label.copyWith(
                color: ink,
                fontWeight: details.armed ? FontWeight.w700 : null,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Pull to refresh: pull the list down and a dial's ring fills as you
/// pull; far enough, its lamp lights, and letting go turns it while the
/// list refreshes.
///
/// ```dart
/// ApplianceRefresh(onRefresh: () async {}, child: ListView(children: const [Text('Orders')]))
/// ```
class ApplianceRefresh extends StatelessWidget {
  /// [child], refreshed by [onRefresh].
  const ApplianceRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// Refreshes; the ring turns until it completes.
  final Future<void> Function() onRefresh;

  /// The scroll view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    return RawRefreshIndicator(
      onRefresh: onRefresh,
      indicatorBuilder: (context, details) {
        final mode = details.mode;
        if (mode == RawRefreshIndicatorMode.inactive) {
          return const SizedBox.shrink();
        }
        final turning =
            mode == RawRefreshIndicatorMode.refresh ||
            mode == RawRefreshIndicatorMode.done;
        return Center(
          child: SizedBox.square(
            dimension: 40,
            child: ApplianceSurface(
              face: ApplianceFace.key(c, circle: true),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ApplianceProgressRing(
                      value: turning ? null : details.progress.clamp(0.0, 1.0),
                      size: 26,
                      stroke: 3,
                    ),
                    ApplianceLamp(
                      lit: mode == RawRefreshIndicatorMode.armed || turning,
                      size: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// A tree: rows indented by their depth, a chevron turning on those that
/// open, the one chosen lit as a key pressed into the panel. One tab stop:
/// the arrows walk and open it.
///
/// ```dart
/// ApplianceTree<String>(controller: RawTreeController<String>(roots: const ['Kitchen'], childrenOf: (node) => const []), labelOf: (node) => node)
/// ```
class ApplianceTree<T extends Object> extends StatelessWidget {
  /// A tree view of [controller].
  const ApplianceTree({
    super.key,
    required this.controller,
    required this.labelOf,
    this.onActivate,
    this.semanticLabel,
    this.style,
  });

  /// The nodes, and which are open and chosen; yours to dispose.
  final RawTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// Opens a node (Enter, a press).
  final ValueChanged<T>? onActivate;

  /// Its name for a screen reader.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.tableStyle]: foreground.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      style,
      ApplianceTheme.of(context).tableStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return RawTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: semanticLabel,
      rowBuilder: (context, item) {
        final lit = item.selected || item.states.contains(WidgetState.pressed);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: ApplianceSpacing.hair),
          child: AnimatedApplianceSurface(
            control: false,
            face: ApplianceFace(
              top: lit ? c.keyDownTop : c.keyDownTop.withValues(alpha: 0),
              bottom: lit
                  ? c.keyDownBottom
                  : c.keyDownBottom.withValues(alpha: 0),
              lift: lit ? -0.5 : 0,
              radius: BorderRadius.circular(ApplianceMetrics.smallKeyRadius),
              foreground: look.foreground ?? c.print,
              focus: item.states.contains(WidgetState.focused)
                  ? c.focus
                  : c.focus.withValues(alpha: 0),
            ),
            child: SizedBox(
              height: theme.controlHeight - 4,
              child: Row(
                children: [
                  SizedBox(width: item.row.depth * 20.0),
                  SizedBox(
                    width: 36,
                    child: item.hasChildren
                        ? GestureDetector(
                            onTap: item.toggle,
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: ApplianceSpringValue(
                                value: item.expanded ? 1 : 0,
                                spring: ApplianceMotion.lid,
                                builder: (context, v, _) =>
                                    _Hinge(turn: v, color: c.printMuted),
                              ),
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: RawCapCenter(
                      capHeightFactor: theme.capHeightFactor,
                      child: Text(
                        labelOf(item.row.node),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.body.copyWith(
                          color: c.print,
                          fontWeight: item.selected ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ),
                  if (item.selected) ...[
                    const ApplianceLamp(lit: true),
                    const SizedBox(width: ApplianceSpacing.medium),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Where an [ApplianceTimelineEntry] stands.
enum ApplianceTimelineState {
  /// Done: its lamp lit.
  done,

  /// Under way: its lamp lit in a ring, its words in the print.
  current,

  /// To come: its lamp out.
  upcoming,
}

/// One entry of an [ApplianceTimeline].
@immutable
class ApplianceTimelineEntry {
  /// An entry headed [title].
  const ApplianceTimelineEntry({
    required this.title,
    this.detail,
    this.time,
    this.state = ApplianceTimelineState.done,
  });

  /// Its heading.
  final String title;

  /// A line under it.
  final String? detail;

  /// When, in words ("Mon 16 Nov, 09:40").
  final String? time;

  /// Where it stands.
  final ApplianceTimelineState state;
}

/// A timeline: lamps down one seam, an entry beside each: the entries done
/// lit, the one under way lit in a ring, those to come out. An order's
/// tracking reads as one.
///
/// ```dart
/// ApplianceTimeline(entries: const [ApplianceTimelineEntry(title: 'Ordered', time: 'Mon 09:40'), ApplianceTimelineEntry(title: 'Out for delivery', state: ApplianceTimelineState.current)])
/// ```
class ApplianceTimeline extends StatelessWidget {
  /// A timeline of [entries], the first at the top.
  const ApplianceTimeline({super.key, required this.entries, this.style});

  /// The entries.
  final List<ApplianceTimelineEntry> entries;

  static const double _rail = 28;

  /// Its style, over [ApplianceThemeData.listTileStyle]: textStyle (titles).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      style,
      ApplianceTheme.of(context).listTileStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final headingStrut = StrutStyle.fromTextStyle(look.text(t.body));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in entries.indexed)
          Semantics(
            container: true,
            label: [
              e.title,
              ?e.detail,
              ?e.time,
              switch (e.state) {
                ApplianceTimelineState.done => 'done',
                ApplianceTimelineState.current => 'under way',
                ApplianceTimelineState.upcoming => 'to come',
              },
            ].join(', '),
            child: ExcludeSemantics(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: _rail,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          if (i < entries.length - 1)
                            Positioned(
                              top: 11,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color:
                                    entries[i + 1].state ==
                                        ApplianceTimelineState.upcoming
                                    ? c.seamShade
                                    : c.signal,
                              ),
                            ),
                          if (i > 0)
                            Positioned(
                              top: 0,
                              height: 11,
                              child: Container(
                                width: 2,
                                color:
                                    e.state == ApplianceTimelineState.upcoming
                                    ? c.seamShade
                                    : c.signal,
                              ),
                            ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.face,
                              border: Border.all(
                                color: e.state == ApplianceTimelineState.current
                                    ? c.signal
                                    : c.seamShade,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: ApplianceLamp(
                              lit: e.state != ApplianceTimelineState.upcoming,
                              size: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ApplianceSpacing.medium),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: i == entries.length - 1
                              ? 0
                              : ApplianceSpacing.large,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: ApplianceSpacing.small,
                                children: [
                                  Text(
                                    e.title,
                                    strutStyle: headingStrut,
                                    style: look
                                        .text(t.body)
                                        .copyWith(
                                          color:
                                              e.state ==
                                                  ApplianceTimelineState
                                                      .upcoming
                                              ? c.printMuted
                                              : c.print,
                                          fontWeight:
                                              e.state ==
                                                  ApplianceTimelineState.current
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                  ),
                                  if (e.time != null)
                                    Text(
                                      e.time!,
                                      strutStyle: headingStrut,
                                      style: t.secondary.copyWith(
                                        color: c.printMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (e.detail != null)
                              Text(
                                e.detail!,
                                style: t.secondary.copyWith(
                                  color: c.printMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('entries', entries.length));
  }
}
