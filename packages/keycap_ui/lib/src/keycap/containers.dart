/// Keycap's containers: what holds and arranges content, each a well cut
/// into the case (read it) with keys where something is pressed.
/// [KeycapDisclosure], [KeycapTable], [KeycapDataTable],
/// [KeycapScrollArea], [KeycapSplitView], [KeycapCarousel],
/// [KeycapReorderableList], [KeycapSwipeActions], [KeycapRefresh],
/// [KeycapTree] and [KeycapTimeline].
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'choices.dart';
import 'feedback.dart';
import 'internal/small_key.dart';
import 'internal/spring_value.dart';
import 'theme.dart';
import 'wayfinding.dart';

// The ui_core types these parts' APIs take, through the look's barrel.
export 'package:ui_core/ui_core.dart'
    show
        RawDataTableSelection,
        RawSortDirection,
        RawDataColumn,
        RawDataTableController;
export 'package:ui_core/ui_core.dart' show RawSwipeAction;
export 'package:ui_core/ui_core.dart' show DesignTreeController;

/// A row's floor in a well (or a page, [KeycapWell.isPage]) for [states]:
/// darker while pressed, a plate of modifier plastic while [selected].
Color _rowFloor(
  BuildContext context,
  KeycapColors c,
  Set<WidgetState> states, {
  bool selected = false,
}) {
  final page = KeycapWell.isPage(context);
  if (states.contains(WidgetState.pressed)) {
    return page ? c.pagePressed : c.wellPressed;
  }
  if (selected) {
    if (page) return c.pageSelected;
    return Color.lerp(
      c.well,
      c.modifier.top,
      c.brightness == Brightness.light ? 0.45 : 0.9,
    )!;
  }
  return (page ? c.page : c.well).withValues(alpha: 0);
}

/// A row's focus band, inside its edge.
BoxDecoration _rowBand(KeycapColors c, Set<WidgetState> states, Color floor) =>
    BoxDecoration(
      color: floor,
      borderRadius: BorderRadius.circular(KeycapMetrics.smallKeyRadius),
      border: Border.all(
        color: states.contains(WidgetState.focused)
            ? c.focus
            : c.focus.withValues(alpha: 0),
        width: KeycapMetrics.focusWidth,
      ),
    );

/// A chevron that turns a quarter as [turn] goes from 0 to 1.
class _Hinge extends StatelessWidget {
  const _Hinge({required this.turn, required this.color});

  final double turn;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.rotate(
      angle: (rtl ? -1 : 1) * turn * math.pi / 2,
      child: Icon(
        rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
        size: 18,
        color: color,
      ),
    );
  }
}

/// A section that opens and closes: its title on a row in a well, a
/// chevron turning as its content slides out under it, calmly. Built on
/// the kit's press; the state is its own unless [open] is given.
///
/// ```dart
/// KeycapDisclosure(title: 'Advanced export', child: options)
/// ```
class KeycapDisclosure extends StatefulWidget {
  /// A disclosure.
  const KeycapDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.open,
    this.onChanged,
    this.initiallyOpen = false,
  });

  /// Its title.
  final String title;

  /// Words under the title.
  final String? subtitle;

  /// What opens.
  final Widget child;

  /// Whether it is open; its own state when null.
  final bool? open;

  /// Called with its new state.
  final ValueChanged<bool>? onChanged;

  /// Whether it starts open (when [open] is null).
  final bool initiallyOpen;

  @override
  State<KeycapDisclosure> createState() => _KeycapDisclosureState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

class _KeycapDisclosureState extends State<KeycapDisclosure> {
  late bool _open = widget.initiallyOpen;

  bool get _isOpen => widget.open ?? _open;

  void _toggle() {
    final next = !_isOpen;
    if (widget.open == null) setState(() => _open = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final open = _isOpen;
    return KeycapWell(
      page: true,
      child: KeycapSpringValue(
        value: open ? 1 : 0,
        spring: KeycapMotion.panel,
        builder: (context, v, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RawButton(
              onPressed: _toggle,
              expanded: open,
              semanticLabel: widget.title,
              excludeSemantics: true,
              builder: (context, states, _) => KeycapSpringColor(
                color: _rowFloor(context, c, states),
                darken: KeycapMotion.press,
                lighten: KeycapMotion.colour,
                builder: (context, floor, child) => Container(
                  margin: const EdgeInsets.all(KeycapSpacing.hairline),
                  decoration: _rowBand(c, states, floor),
                  child: child,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: theme.controlHeight + 4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeycapSpacing.regular - 2,
                      vertical: KeycapSpacing.small,
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
                                style: theme.textTheme.body.copyWith(
                                  color: c.ink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  style: theme.textTheme.secondary,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: KeycapSpacing.medium),
                        _Hinge(turn: v, color: c.inkMuted),
                      ],
                    ),
                  ),
                ),
              ),
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
                        KeycapSpacing.regular,
                        KeycapSpacing.tight,
                        KeycapSpacing.regular,
                        KeycapSpacing.regular,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A column of a [KeycapTable]: its heading, whether it holds figures
/// (set to the end, in tabular figures), its share of the width.
@immutable
class KeycapTableColumn {
  /// A column headed [label].
  const KeycapTableColumn(this.label, {this.numeric = false, this.flex = 1});

  /// Its heading.
  final String label;

  /// Whether it holds figures.
  final bool numeric;

  /// Its share of the width.
  final int flex;
}

Widget _heading(BuildContext context, String label, {bool numeric = false}) {
  final theme = KeycapTheme.of(context);
  return Text(
    label.toUpperCase(),
    textAlign: numeric ? TextAlign.end : TextAlign.start,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: theme.textTheme.legend.copyWith(color: theme.colors.inkMuted),
  );
}

Widget _cell(BuildContext context, String text, {bool numeric = false}) {
  final theme = KeycapTheme.of(context);
  return Text(
    text,
    textAlign: numeric ? TextAlign.end : TextAlign.start,
    style: theme.textTheme.body.copyWith(
      color: theme.colors.ink,
      fontFeatures: numeric ? const [FontFeature.tabularFigures()] : null,
    ),
  );
}

/// Rows of words under headings, in a well: the headings in the legend's
/// small capitals, the rows divided by hairlines, figures set to the end.
/// Read, never pressed.
///
/// ```dart
/// KeycapTable(columns: const [KeycapTableColumn('Folder'), KeycapTableColumn('Notes', numeric: true)], rows: const [['Garden', '12'], ['Work', '40']])
/// ```
class KeycapTable extends StatelessWidget {
  /// A table.
  const KeycapTable({
    super.key,
    required this.columns,
    required this.rows,
    this.style,
  });

  /// The columns.
  final List<KeycapTableColumn> columns;

  /// The rows, a string per column.
  final List<List<String>> rows;

  /// Overrides, over [KeycapThemeData.tableStyle]: [DesignStyle.fill] the
  /// well's floor.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tableStyle], const {});
    const pad = EdgeInsets.symmetric(
      horizontal: KeycapSpacing.small,
      vertical: KeycapSpacing.medium,
    );
    return KeycapWell(
      page: true,
      floor: layered.fill,
      padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.small),
      child: Table(
        columnWidths: {
          for (final (i, col) in columns.indexed)
            i: FlexColumnWidth(col.flex.toDouble()),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.edge)),
            ),
            children: [
              for (final col in columns)
                Padding(
                  padding: pad,
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
      ),
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

/// A table that sorts, selects and opens: a sortable heading is pressed
/// to sort by it (its arrow in the accent's ink), each row has a checkbox
/// key when [selectable], a pressed row's floor darkens, a chosen row
/// stands on a plate of modifier plastic. The arrows move between rows;
/// Space chooses, Enter opens ([onActivate]). Built on ui_core's
/// `RawDataTable`.
///
/// ```dart
/// KeycapDataTable<String>(controller: table, cellText: (title, column) => column.id == 'title' ? title : '${title.length}')
/// ```
class KeycapDataTable<R> extends StatelessWidget {
  /// A data table over [controller].
  const KeycapDataTable({
    super.key,
    required this.controller,
    required this.cellText,
    this.selectable = true,
    this.onActivate,
    this.rowLabel,
    this.style,
  });

  /// The columns, rows, sort and selection.
  final RawDataTableController<R> controller;

  /// A cell's words.
  final String Function(R row, RawDataColumn<R> column) cellText;

  /// Whether rows can be chosen.
  final bool selectable;

  /// Opens a row.
  final ValueChanged<R>? onActivate;

  /// A row's name, for its checkbox's label.
  final String Function(R row)? rowLabel;

  /// Overrides, over [KeycapThemeData.tableStyle].
  final KeycapStyle? style;

  static const double _box = 48;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tableStyle], const {});
    Widget cells(List<Widget> cells, {Widget? lead}) => Row(
      children: [
        if (selectable) SizedBox(width: _box, child: lead),
        for (final cell in cells) Expanded(child: cell),
      ],
    );
    return KeycapWell(
      page: true,
      floor: layered.fill,
      padding: const EdgeInsets.all(KeycapSpacing.tight),
      child: RawDataTable<R>(
        controller: controller,
        selectable: selectable,
        onActivate: onActivate,
        headerRowBuilder: (context, header) => ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final page = controller.pageSelection;
            return Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.edge)),
              ),
              padding: const EdgeInsets.only(bottom: KeycapSpacing.tight),
              child: cells(
                header,
                lead: Center(
                  child: KeycapCheckbox(
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
              horizontal: KeycapSpacing.small,
            ),
            child: _heading(context, column.label, numeric: column.numeric),
          );
          if (!column.sortable) return legend;
          return SizedBox(
            height: theme.controlHeight - KeycapSpacing.tight,
            child: DecoratedBox(
              decoration: _rowBand(c, states, _rowFloor(context, c, states)),
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
                          ? c.accentInk
                          : c.inkDisabled.withValues(alpha: 0.5),
                      down: sort == RawSortDirection.descending
                          ? c.accentInk
                          : c.inkDisabled.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: KeycapSpacing.tight),
                ],
              ),
            ),
          );
        },
        cellBuilder: (context, row, column) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KeycapSpacing.small,
            vertical: KeycapSpacing.medium,
          ),
          child: _cell(context, cellText(row, column), numeric: column.numeric),
        ),
        rowBuilder: (context, row, rowCells) => Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: KeycapSpringColor(
            color: _rowFloor(context, c, row.states, selected: row.selected),
            darken: KeycapMotion.press,
            lighten: KeycapMotion.colour,
            builder: (context, floor, child) => DecoratedBox(
              decoration: _rowBand(c, row.states, floor),
              child: child,
            ),
            child: cells(
              rowCells,
              lead: Center(
                child: KeycapCheckbox(
                  value: row.selected,
                  semanticLabel: rowLabel == null
                      ? 'Select row'
                      : 'Select ${rowLabel!(row.row)}',
                  onChanged: (_) => row.toggle(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A scrolling region with a scrollbar of its own: a small cap riding in a
/// slot cut along its end edge, shown while it scrolls or a pointer is
/// near; the region takes focus and scrolls by the arrows. Built on
/// ui_core's `RawScrollArea`.
///
/// ```dart
/// KeycapScrollArea(controller: scroll, child: SingleChildScrollView(controller: scroll, child: body))
/// ```
class KeycapScrollArea extends StatelessWidget {
  /// A scroll area over [child], a scroll view on [controller].
  const KeycapScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.semanticLabel,
  });

  /// The scroll view's controller.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    return RawScrollArea(
      controller: controller,
      axis: axis,
      thickness: 10,
      semanticLabel: semanticLabel,
      trackBuilder: (context, thumb) => AnimatedOpacity(
        opacity: thumb.visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Padding(
          padding: const EdgeInsets.all(KeycapSpacing.hairline),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.well,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
      thumbBuilder: (context, thumb) {
        final face = keycapKeyFace(
          theme,
          KeycapKind.alpha,
          thumb.states,
          radius: 3,
        );
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.all(KeycapSpacing.hairline),
            child: KeycapCap(face: face, walls: (side: 1, back: 0.5, front: 2)),
          ),
        );
      },
      frameBuilder: (context, focused, area) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KeycapMetrics.smallKeyRadius),
          border: Border.all(
            color: focused ? c.focus : c.focus.withValues(alpha: 0),
            width: KeycapMetrics.focusWidth,
          ),
        ),
        child: area,
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('axis', axis));
  }
}

/// Two panes side by side (or stacked) with a seam between them that
/// moves: a hairline with a small cap on it to drag, or to step with the
/// arrows once focused. Built on ui_core's `RawSplitView`.
///
/// ```dart
/// KeycapSplitView(first: notesList, second: editor, initialFraction: 0.36)
/// ```
class KeycapSplitView extends StatelessWidget {
  /// A split view.
  const KeycapSplitView({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = 0.4,
    this.onChanged,
    this.minFirst = 200,
    this.minSecond = 280,
    this.semanticLabel,
  });

  /// The first pane.
  final Widget first;

  /// The second.
  final Widget second;

  /// Side by side (horizontal) or stacked.
  final Axis axis;

  /// The first pane's share; its own when null.
  final double? fraction;

  /// Its share to start.
  final double initialFraction;

  /// Called with the new share.
  final ValueChanged<double>? onChanged;

  /// The first pane's least extent.
  final double minFirst;

  /// The second's.
  final double minSecond;

  /// The seam's name, for a screen reader.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
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
      semanticLabel:
          semanticLabel ??
          RawWidgetsLocalizations.of(context).splitViewHandleLabel,
      dividerBuilder: (context, states, axis) {
        final across = axis == Axis.horizontal;
        final held =
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.dragged);
        final face = keycapKeyFace(theme, KeycapKind.alpha, {
          ...states,
          if (held) WidgetState.pressed,
        }, radius: 4);
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: across ? 1 : double.infinity,
              height: across ? double.infinity : 1,
              child: ColoredBox(color: c.edge),
            ),
            SizedBox(
              width: across ? 10 : 36,
              height: across ? 36 : 10,
              child: AnimatedKeycapCap(
                face: face,
                walls: (side: 1.5, back: 1, front: 2.5),
                child: const SizedBox.expand(),
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

/// Slides one at a time in a well, with keys to the slide before and after
/// and dots for where it is. A swipe, the keys and a screen reader turn
/// them. Built on ui_core's `RawCarousel`.
///
/// ```dart
/// KeycapCarousel(itemCount: 3, itemBuilder: (context, i) => KeycapMedia(slotId: 'tip.$i', semanticLabel: tips[i]))
/// ```
class KeycapCarousel extends StatelessWidget {
  /// A carousel of [itemCount] slides.
  const KeycapCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 200,
    this.loop = false,
    this.onPageChanged,
    this.semanticLabel,
  });

  /// How many slides.
  final int itemCount;

  /// Builds a slide.
  final IndexedWidgetBuilder itemBuilder;

  /// The well's height.
  final double height;

  /// Whether it wraps round.
  final bool loop;

  /// Called with each new slide.
  final ValueChanged<int>? onPageChanged;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const inset = KeycapSpacing.tight;
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
            child: KeycapWell(
              rim: controls.focused ? c.focus : null,
              padding: const EdgeInsets.all(inset),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  KeycapMetrics.wellRadius - inset,
                ),
                child: viewport,
              ),
            ),
          ),
          const SizedBox(height: KeycapSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KeycapSmallKey(
                icon: rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                semanticLabel: 'Previous slide',
                onPressed: controls.previous,
                side: 40,
              ),
              const SizedBox(width: KeycapSpacing.small),
              KeycapPageDots(
                count: math.max(controls.count, 1),
                index: controls.page.clamp(0, math.max(controls.count - 1, 0)),
                onChanged: controls.goToPage,
              ),
              const SizedBox(width: KeycapSpacing.small),
              KeycapSmallKey(
                icon: rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                semanticLabel: 'Next slide',
                onPressed: controls.next,
                side: 40,
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

class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(LucideIcons.gripVertical, size: 18, color: c.inkMuted),
        ),
      ),
    );
  }
}

/// Rows in a well that can be put in order: drag a row by its grip (or
/// long-press it); while carried it lifts out as a panel of keycap
/// plastic. A screen reader's actions and the keys move a row up or down
/// one. Built on ui_core's `RawReorderableList`.
///
/// ```dart
/// KeycapReorderableList<String>(items: folders, title: (f) => f, onReorder: (from, to) => setState(() => move(from, to)))
/// ```
class KeycapReorderableList<T extends Object> extends StatelessWidget {
  /// A reorderable list of [items].
  const KeycapReorderableList({
    super.key,
    required this.items,
    required this.title,
    required this.onReorder,
    this.subtitle,
  });

  /// The rows.
  final List<T> items;

  /// A row's words.
  final String Function(T item) title;

  /// Words under a row's.
  final String? Function(T item)? subtitle;

  /// Called to move a row from one place to another.
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    return KeycapWell(
      page: true,
      child: RawReorderableList<T>(
        items: items,
        onReorder: onReorder,
        labelOf: title,
        shrinkWrap: true,
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (context, child) => KeycapPanel(
            radius: BorderRadius.circular(KeycapMetrics.smallKeyRadius),
            elevated: animation.value > 0.05,
            child: child!,
          ),
          child: child,
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
              start: KeycapSpacing.regular,
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
                        style: theme.textTheme.body.copyWith(color: c.ink),
                      ),
                      if (sub != null)
                        Text(sub, style: theme.textTheme.secondary),
                    ],
                  ),
                ),
                reorder.handle(const _Grip()),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}

/// A row with actions under it, uncovered by a swipe: each action a slab
/// of key plastic as tall as the row (the danger plastic for one that
/// destroys), its words printed on it; a full swipe runs the first. Built
/// on ui_core's `RawSwipeActions`.
///
/// ```dart
/// KeycapSwipeActions(endActions: [RawSwipeAction(label: 'Delete', destructive: true, onPressed: delete)], child: row)
/// ```
class KeycapSwipeActions extends StatelessWidget {
  /// [child] with actions under it.
  const KeycapSwipeActions({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
  });

  /// The row.
  final Widget child;

  /// The actions under its start edge.
  final List<RawSwipeAction> startActions;

  /// The actions under its end edge.
  final List<RawSwipeAction> endActions;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    return RawSwipeActions(
      startActions: startActions,
      endActions: endActions,
      actionExtent: 88,
      actionBuilder: (context, action, details) {
        final cap = action.destructive ? c.danger : c.modifier;
        final pressed = details.states.contains(WidgetState.pressed);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: pressed ? cap.wall : cap.top,
            border: Border.all(
              color: details.states.contains(WidgetState.focused)
                  ? c.focus
                  : c.focus.withValues(alpha: 0),
              width: KeycapMetrics.focusWidth,
            ),
          ),
          child: Center(
            child: Text(
              action.label,
              style: theme.textTheme.label.copyWith(
                color: cap.legend,
                fontWeight: details.armed ? FontWeight.w700 : null,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('startActions', startActions.length))
      ..add(IntProperty('endActions', endActions.length));
  }
}

/// A list refreshed by a pull: a small key comes down with the pull, its
/// arc filling, and turns while the refresh runs. Built on ui_core's
/// `RawRefreshIndicator`.
///
/// ```dart
/// KeycapRefresh(onRefresh: sync, child: ListView(children: rows))
/// ```
class KeycapRefresh extends StatelessWidget {
  /// [child], a scroll view, refreshed by [onRefresh].
  const KeycapRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// Refreshes; the key turns until it completes.
  final Future<void> Function() onRefresh;

  /// The scroll view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
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
        final face = keycapKeyFace(theme, KeycapKind.alpha, const {});
        return Center(
          child: SizedBox.square(
            dimension: 40,
            child: KeycapCap(
              face: face,
              walls: KeycapMetrics.walls(40),
              child: Center(
                child: KeycapSpinner(
                  size: 22,
                  value: turning ? null : details.progress.clamp(0.0, 1.0),
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

/// Nested rows in a well that open and close (folders in folders): a
/// chevron turning beside each row with rows under it, a pressed row's
/// floor darkening, the chosen row on a plate of modifier plastic. The
/// arrows move, open and close. Built on ui_core's `DesignTree`.
///
/// ```dart
/// KeycapTree<String>(controller: tree, labelOf: (folder) => folder, onActivate: open)
/// ```
class KeycapTree<T extends Object> extends StatelessWidget {
  /// A tree over [controller].
  const KeycapTree({
    super.key,
    required this.controller,
    required this.labelOf,
    this.onActivate,
    this.semanticLabel,
    this.iconOf,
  });

  /// The rows and which are open and chosen.
  final DesignTreeController<T> controller;

  /// A row's words.
  final String Function(T node) labelOf;

  /// Opens a row.
  final ValueChanged<T>? onActivate;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  /// A row's glyph.
  final IconData Function(T node, bool expanded)? iconOf;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    return KeycapWell(
      page: true,
      padding: const EdgeInsets.all(KeycapSpacing.tight),
      child: DesignTree<T>(
        controller: controller,
        labelOf: labelOf,
        onActivate: onActivate,
        semanticLabel: semanticLabel,
        rowBuilder: (context, item) => KeycapSpringColor(
          color: _rowFloor(context, c, item.states, selected: item.selected),
          darken: KeycapMotion.press,
          lighten: KeycapMotion.colour,
          builder: (context, floor, child) => DecoratedBox(
            decoration: _rowBand(c, item.states, floor),
            child: child,
          ),
          child: SizedBox(
            height: KeycapMetrics.grown(
              context,
              theme.controlHeight - KeycapSpacing.tight,
              theme.textTheme.body,
            ),
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
                            child: KeycapSpringValue(
                              value: item.expanded ? 1 : 0,
                              spring: KeycapMotion.panel,
                              builder: (context, v, _) =>
                                  _Hinge(turn: v, color: c.inkMuted),
                            ),
                          ),
                        )
                      : null,
                ),
                if (iconOf != null) ...[
                  Icon(
                    iconOf!(item.row.node, item.expanded),
                    size: 18,
                    color: c.inkMuted,
                  ),
                  const SizedBox(width: KeycapSpacing.small),
                ],
                Expanded(
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Text(
                      labelOf(item.row.node),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.body.copyWith(
                        color: item.selected ? c.latchedLegend : c.ink,
                        fontWeight: item.selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KeycapSpacing.medium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where an entry of a [KeycapTimeline] stands.
enum KeycapTimelineState {
  /// It happened.
  done,

  /// It is under way.
  current,

  /// It is to come.
  upcoming,
}

/// One entry of a [KeycapTimeline].
@immutable
class KeycapTimelineEntry {
  /// An entry titled [title].
  const KeycapTimelineEntry({
    required this.title,
    this.detail,
    this.time,
    this.state = KeycapTimelineState.done,
  });

  /// What happened.
  final String title;

  /// More about it.
  final String? detail;

  /// When.
  final String? time;

  /// Where it stands.
  final KeycapTimelineState state;
}

/// What happened, in order (a note's history, a sync's steps): each entry
/// a small mark on a slot cut down the start edge, done marks a tab of
/// accent plastic, the current one ringed in the accent, the slot lit as
/// far as it has gone. Each entry is one node to a screen reader.
///
/// ```dart
/// KeycapTimeline(entries: const [KeycapTimelineEntry(title: 'Created', time: '9:02'), KeycapTimelineEntry(title: 'Synced', state: KeycapTimelineState.current)])
/// ```
class KeycapTimeline extends StatelessWidget {
  /// A timeline of [entries].
  const KeycapTimeline({super.key, required this.entries});

  /// The entries, first to last.
  final List<KeycapTimelineEntry> entries;

  static const double _rail = 28;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    Color lane(KeycapTimelineState s) =>
        s == KeycapTimelineState.upcoming ? c.well : c.accent.top;
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
                KeycapTimelineState.done => 'done',
                KeycapTimelineState.current => 'under way',
                KeycapTimelineState.upcoming => 'to come',
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
                              top: 12,
                              bottom: 0,
                              child: SizedBox(
                                width: 4,
                                child: ColoredBox(
                                  color: lane(entries[i + 1].state),
                                ),
                              ),
                            ),
                          if (i > 0)
                            Positioned(
                              top: 0,
                              height: 12,
                              child: SizedBox(
                                width: 4,
                                child: ColoredBox(color: lane(e.state)),
                              ),
                            ),
                          SizedBox.square(
                            dimension: 22,
                            child: switch (e.state) {
                              KeycapTimelineState.done => DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.accent.top,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: c.accent.legend,
                                ),
                              ),
                              KeycapTimelineState.current => KeycapWell(
                                radius: BorderRadius.circular(6),
                                rim: c.accentInk,
                              ),
                              KeycapTimelineState.upcoming => KeycapWell(
                                radius: BorderRadius.circular(6),
                              ),
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: KeycapSpacing.medium),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: i == entries.length - 1
                              ? 0
                              : KeycapSpacing.large,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: Text(
                                    e.title,
                                    style: theme.textTheme.body.copyWith(
                                      color:
                                          e.state ==
                                              KeycapTimelineState.upcoming
                                          ? c.inkMuted
                                          : c.ink,
                                      fontWeight:
                                          e.state == KeycapTimelineState.current
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (e.time != null)
                                  Text(e.time!, style: theme.textTheme.figure),
                              ],
                            ),
                            if (e.detail != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: KeycapSpacing.hairline,
                                ),
                                child: Text(
                                  e.detail!,
                                  style: theme.textTheme.secondary,
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
