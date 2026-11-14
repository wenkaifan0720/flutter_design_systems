// Groups and records on softly raised slabs, with engraved separators.
import 'dart:math' as math;

import 'component_themes.dart';

import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'heads.dart';
import 'internal/group_rows.dart';
import 'layout.dart';
import 'ornaments.dart';
import 'rows.dart';
import 'theme.dart';
import 'internal/out_of_use.dart';

/// The engraved separator used by lists, with optional space on either side.
///
/// ```dart
/// NeumorphicDivider(space: 24)
/// ```
class NeumorphicDivider extends StatelessWidget {
  /// Creates a [NeumorphicDivider].
  const NeumorphicDivider({
    super.key,
    this.space = 16,
    this.indent = 0,
    this.endIndent = 0,
  }) : assert(space >= 2),
       assert(indent >= 0),
       assert(endIndent >= 0);

  /// The total vertical space occupied by the divider.
  final double space;

  /// The logical start inset of the line.
  final double indent;

  /// The logical end inset of the line.
  final double endIndent;
  @override
  Widget build(BuildContext context) {
    final height = 2 * neumorphicRuleWidth;
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          indent,
          math.max(0.0, (space - height) / 2),
          endIndent,
          math.max(0.0, (space - height) / 2),
        ),
        child: const NeumorphicEngraved(),
      ),
    );
  }
}

/// Related rows on one slab, with a heading and an optional explanation below.
///
/// ```dart
/// NeumorphicListSection(label: 'Account', children: [NeumorphicListTile(title: 'Profile', onPressed: open)])
/// ```
class NeumorphicListSection extends StatelessWidget {
  /// Creates a [NeumorphicListSection].
  const NeumorphicListSection({
    super.key,
    this.style,
    this.label,
    this.footer,
    required this.children,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The text identifying this item or control.
  final String? label;

  /// Optional text beneath the grouped rows.
  final String? footer;

  /// The content widgets, in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: NeumorphicColumn(
      gap: 8,
      children: [
        NeumorphicSlab(
          style: style,
          child: NeumorphicColumn(
            gap: 12,
            children: [
              if (label != null)
                Semantics(
                  header: true,
                  child: NeumorphicSectionHeader(title: label!),
                ),
              // Each row is a band of the card, from its rule down to the next: its lift and its press go round the
              // whole band and follow the card's corners where it meets them.
              for (final (i, child) in children.indexed)
                NeumorphicGroupRowScope(
                  top: i == 0 && label == null,
                  bottom: i == children.length - 1,
                  gap: 12,
                  child: child,
                ),
            ],
          ),
        ),
        if (footer != null)
          Text(footer!, style: NeumorphicTheme.of(context).textTheme.caption),
      ],
    ),
  );
}

/// A heading that opens in place. The child keeps its state while it is hidden.
///
/// ```dart
/// NeumorphicDisclosure(title: 'What is included?', child: Text(details))
/// ```
class NeumorphicDisclosure extends StatefulWidget {
  /// Creates a [NeumorphicDisclosure].
  const NeumorphicDisclosure({
    super.key,
    this.autofocus = false,
    required this.title,
    this.note,
    required this.child,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    this.enabled = true,
    this.isFirst = false,
    this.focusNode,
  });

  /// The primary heading.
  final String title;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// The content placed inside this component.
  final Widget child;

  /// The initial open state when expanded is not controlled.
  final bool initiallyExpanded;

  /// The controlled open state, or null to keep local state.
  final bool? expanded;

  /// Reports when the user requests a different open state.
  final ValueChanged<bool>? onExpansionChanged;

  /// Whether the control accepts user interaction.
  final bool enabled;

  /// Whether this is the first row, without a preceding separator.
  final bool isFirst;

  /// An optional externally owned focus node.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  State<NeumorphicDisclosure> createState() => _NeumorphicDisclosureState();
}

class _NeumorphicDisclosureState extends State<NeumorphicDisclosure> {
  late bool _inner = widget.initiallyExpanded;
  final _ownFocus = FocusNode();
  final _bodyFocus = FocusScopeNode();
  bool get _open => widget.expanded ?? _inner;
  FocusNode get _headFocus => widget.focusNode ?? _ownFocus;
  @override
  void didUpdateWidget(NeumorphicDisclosure old) {
    super.didUpdateWidget(old);
    if (!_open && _bodyFocus.hasFocus) _headFocus.requestFocus();
  }

  @override
  void dispose() {
    _ownFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_open;
    if (!next && _bodyFocus.hasFocus) _headFocus.requestFocus();
    if (widget.expanded == null) setState(() => _inner = next);
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final motion = NeumorphicMotion.of(context);
    final enabled =
        widget.enabled &&
        (widget.expanded == null || widget.onExpansionChanged != null);
    return NeumorphicRuled(
      rule: !widget.isFirst,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NeumorphicTap(
            autofocus: widget.autofocus,
            label: [
              widget.title,
              if (widget.note != null) widget.note!,
            ].join(', '),
            expanded: _open,
            focusNode: _headFocus,
            onPressed: enabled ? _toggle : null,
            child: NeumorphicOutOfUse(
              off: !enabled,
              // On the column's keyline, as every ruled row's words are: 6 in, its title stood off the rows beside it.
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: t.textTheme.title),
                          if (widget.note != null)
                            Text(widget.note!, style: t.textTheme.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: _open ? .5 : 0,
                      duration: motion.move,
                      child: Icon(
                        NeumorphicGlyphs.chevronDown,
                        color: t.colors.ink,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !_open,
            child: ExcludeSemantics(
              excluding: !_open,
              child: ExcludeFocus(
                excluding: !_open,
                child: TweenAnimationBuilder<double>(
                  duration: motion.move,
                  curve: motion.enter,
                  tween: Tween(end: _open ? 1 : 0),
                  // The body comes down from under the head: cut along its foot while it moves, never at its sides
                  // or once open, where a raised part inside casts past the body's box.
                  // One clip throughout, off once open: a tree that changed shape would drop the body's state (what
                  // was typed in it).
                  builder: (context, value, child) => ClipRect(
                    clipper: const _FootCut(),
                    clipBehavior: value >= 1 ? Clip.none : Clip.hardEdge,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      heightFactor: value,
                      child: child,
                    ),
                  ),
                  child: FocusScope(
                    node: _bodyFocus,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DefaultTextStyle.merge(
                        style: t.textTheme.body,
                        child: widget.child,
                      ),
                    ),
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

/// A cut along a box's foot alone: above it and to its sides, what is painted shows.
class _FootCut extends CustomClipper<Rect> {
  const _FootCut();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.width, -size.width, size.width * 2, size.height);

  @override
  bool shouldReclip(_FootCut oldClipper) => false;
}

/// One column, whose flex controls its share of the table's width.
@immutable
class NeumorphicTableColumn {
  /// Creates a [NeumorphicTableColumn].
  const NeumorphicTableColumn(this.label, {this.numeric = false, this.flex = 1})
    : assert(flex > 0);

  /// The text identifying this item or control.
  final String label;

  /// Whether to align the column as numeric data.
  final bool numeric;

  /// The relative width of the column in the wide layout.
  final int flex;
}

/// Cells in column order. Short rows leave empty cells; a row can open a record.
@immutable
class NeumorphicTableRow {
  /// Creates a [NeumorphicTableRow].
  const NeumorphicTableRow(
    this.cells, {
    this.onPressed,
    this.selected = false,
    this.key,
    this.label,
  });

  /// Cell content in column order; each entry is text or a widget.
  final List<Object> cells;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// Whether this item is selected.
  final bool selected;

  /// The identity of this item when building its widget.
  final Key? key;

  /// An optional accessible name for the whole row.
  final String? label;
}

/// Records in columns, becoming labelled cards when width or text size needs it.
///
/// ```dart
/// NeumorphicTable(columns: const [NeumorphicTableColumn('Item'), NeumorphicTableColumn('Paid', numeric: true)], rows: const [NeumorphicTableRow(['Dinner', '84.00'])])
/// ```
class NeumorphicTable extends StatelessWidget {
  /// Creates a [NeumorphicTable].
  const NeumorphicTable({
    super.key,
    this.style,
    required this.columns,
    required this.rows,
    this.label,
    this.stackBelow = 520,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The column descriptions, in display order.
  final List<NeumorphicTableColumn> columns;

  /// The table records, in display order.
  final List<NeumorphicTableRow> rows;

  /// The text identifying this item or control.
  final String? label;

  /// The width below which rows become labelled vertical records.
  final double stackBelow;

  Widget _cell(BuildContext context, Object? cell, int index) {
    final column = columns[index];
    final t = NeumorphicTheme.of(context);
    final style = column.numeric ? t.textTheme.body.tabular : t.textTheme.body;
    return Align(
      alignment: column.numeric
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: DefaultTextStyle.merge(
        style: style,
        child: cell is Widget
            ? cell
            : Text(
                cell?.toString() ?? '',
                textAlign: column.numeric ? TextAlign.end : TextAlign.start,
              ),
      ),
    );
  }

  /// A value in a labelled card: its own width, at the end of its line.
  Widget _stackedValue(BuildContext context, Object? cell, int index) {
    final t = NeumorphicTheme.of(context);
    return DefaultTextStyle.merge(
      style: columns[index].numeric
          ? t.textTheme.body.tabular
          : t.textTheme.body,
      child: cell is Widget
          ? cell
          : Text(cell?.toString() ?? '', textAlign: TextAlign.end),
    );
  }

  String _spoken(NeumorphicTableRow row) =>
      row.label ??
      [
        for (var i = 0; i < row.cells.length && i < columns.length; i++)
          if (row.cells[i] is! Widget) '${columns[i].label}: ${row.cells[i]}',
      ].join(', ');
  Widget _row(
    BuildContext context,
    NeumorphicTableRow row,
    Widget content, {
    required bool first,
  }) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: content,
    );
    final face = row.selected
        ? NeumorphicSurface(
            style: style,
            themeStyle: NeumorphicTheme.of(context).cardTheme,
            cast: NeumorphicSurfaceLevel.groove,
            outlined: true,
            child: body,
          )
        : body;
    return NeumorphicRuled(
      key: row.key,
      rule: !first,
      child: row.onPressed == null
          ? Semantics(selected: row.selected, child: face)
          : NeumorphicTap(
              onPressed: row.onPressed,
              label: _spoken(row),
              selected: row.selected,
              child: face,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      columns.isNotEmpty || rows.isEmpty,
      'Rows need at least one column.',
    );
    assert(
      rows.every((row) => row.cells.length <= columns.length),
      'A row has more cells than columns.',
    );
    final t = NeumorphicTheme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, box) {
          if (columns.isEmpty) return const SizedBox.shrink();
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final threshold =
              (columns.length * 140.0).clamp(stackBelow, double.infinity) *
              scale;
          final stacked = !box.hasBoundedWidth || box.maxWidth < threshold;
          Widget line(List<Widget> cells) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(flex: columns[i].flex, child: cells[i]),
              ],
            ],
          );
          return NeumorphicColumn(
            gap: 0,
            children: [
              if (!stacked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: line([
                    for (final column in columns)
                      Semantics(
                        header: true,
                        child: Text(
                          column.label,
                          style: t.textTheme.caption,
                          textAlign: column.numeric
                              ? TextAlign.end
                              : TextAlign.start,
                        ),
                      ),
                  ]),
                ),
              for (var r = 0; r < rows.length; r++)
                _row(
                  context,
                  rows[r],
                  // A labelled card: each column's name and its value share a line, the value at the end, and
                  // the value drops under its name only when the two can't fit.
                  stacked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < columns.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              NeumorphicSplit(
                                start: Text(
                                  columns[i].label,
                                  style: t.textTheme.caption,
                                ),
                                end: _stackedValue(
                                  context,
                                  i < rows[r].cells.length
                                      ? rows[r].cells[i]
                                      : null,
                                  i,
                                ),
                              ),
                            ],
                          ],
                        )
                      : line([
                          for (var i = 0; i < columns.length; i++)
                            _cell(
                              context,
                              i < rows[r].cells.length
                                  ? rows[r].cells[i]
                                  : null,
                              i,
                            ),
                        ]),
                  // Stacked records are ruled apart as rows are: unruled, every record after a chosen one
                  // floated loose on the wall.
                  first: r == 0,
                ),
            ],
          );
        },
      ),
    );
  }
}
