/// Containers and disclosure in the vocabulary of inked panels and ruled rows.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'glyphs.dart';

import 'frames.dart';
import 'internal/row_frame.dart';
import 'layout.dart';
import 'styled.dart';
import 'component_themes.dart';
import 'press.dart';
import 'rows.dart';
import 'theme.dart';

/// An inked card with a title and a stack of content. Given a height (cards sharing a row), a child wrapped in
/// [ComicGrow] takes the slack, so what follows it (an action) stands on the card's foot, on one line across the row.
///
/// ```dart
/// ComicCard(title: 'This issue', children: [ComicGrow(child: Text('Twelve pages')), ComicButton.text('Read')])
/// ```
class ComicCard extends StatelessWidget {
  /// Creates a titled card.
  const ComicCard({
    super.key,
    required this.title,
    required this.children,
    this.style,
  });

  /// Frame style above the card component theme.
  final ComicStyle? style;

  /// The card's heading.
  final String title;

  /// Content in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ComicPanel(
    style: style,
    child: ComicColumn(
      gap: 12,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: ComicTheme.of(context).type.panel),
        ),
        ...children,
      ],
    ),
  );
}

/// A ruled group whose rows retain their own semantics and controls.
///
/// ```dart
/// ComicListSection(children: [ComicListTile(title: 'First'), ComicListTile(title: 'Second')])
/// ```
class ComicListSection extends StatelessWidget {
  /// Creates a group of rows.
  const ComicListSection({super.key, required this.children, this.label});

  /// Rows in reading order.
  final List<Widget> children;

  /// Optional accessible group name.
  final String? label;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final look = ComicStyleOf([t.cardTheme], const {});
    final inset =
        (look.padding(Directionality.of(context)) ?? comicPanelInset(t))
            .resolve(Directionality.of(context));
    // The rows stand [_rowGap] inside the rim, as an open menu's do, and their fill takes the group's corner less
    // that inset: concentric, the first and last rows with the group's own corners. Each row reaches past the
    // group's padding to there while its words keep the padding; anything else in the group keeps the padding.
    final gap = math.min(_rowGap, math.min(inset.left, inset.right));
    // The first row's words stand as far below the rim as the last row's stand above it: a panel's own inset is
    // 2 px deeper at the foot on a desktop (20 over 22), which a group of rows would show as uneven ends.
    final end = math.max(0.0, math.max(inset.top, inset.bottom) - gap);
    final rows = comicInsetShape(
      look.shape ?? t.shapes.medium,
      comicRim(t, look, t.colors.nightLine, 3).width + gap,
    );
    return Semantics(
      label: label,
      child: ComicPanel(
        bleed: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(inset.left, gap, inset.right, gap),
          child: RowGroup(
            shape: rows,
            reach: EdgeInsets.only(
              left: inset.left - gap,
              right: inset.right - gap,
            ),
            ends: EdgeInsets.only(top: end, bottom: end),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// How far a group's rows stand inside its rim, as an open menu's rows do.
const double _rowGap = 4;

/// A section that opens in place. Use [expanded] for external control.
///
/// ```dart
/// ComicDisclosure(title: 'More about this issue', child: Text('The full story'))
/// ```
class ComicDisclosure extends StatefulWidget {
  /// Creates a disclosure, initially closed unless requested otherwise.
  const ComicDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    this.focusNode,
    this.autofocus = false,
  });

  /// The header and accessible name.
  final String title;

  /// Content shown while expanded.
  final Widget child;

  /// Initial state when uncontrolled.
  final bool initiallyExpanded;

  /// A controlled state, or null to maintain state internally.
  final bool? expanded;

  /// Reports a requested state change once.
  final ValueChanged<bool>? onExpansionChanged;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  State<ComicDisclosure> createState() => _ComicDisclosureState();
}

class _ComicDisclosureState extends State<ComicDisclosure> {
  late bool _expanded = widget.initiallyExpanded;
  bool get _open => widget.expanded ?? _expanded;
  @override
  Widget build(BuildContext context) {
    final duration = ComicMotion.of(context).state;
    final content = _open
        ? Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: widget.child,
          )
        : const SizedBox.shrink();
    return ComicRuled(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ComicPressable(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            label: widget.title,
            expanded: _open,
            onPressed: () {
              final next = !_open;
              if (widget.expanded == null) setState(() => _expanded = next);
              widget.onExpansionChanged?.call(next);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: ComicTheme.of(context).type.title,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_open ? ComicGlyphs.chevronUp : ComicGlyphs.chevronDown),
                ],
              ),
            ),
          ),
          if (duration == Duration.zero)
            content
          else
            AnimatedSize(
              duration: duration,
              alignment: AlignmentDirectional.topStart,
              child: content,
            ),
        ],
      ),
    );
  }
}

/// A table that becomes labelled ledger rows below 600 logical pixels.
///
/// ```dart
/// ComicTable(columns: ['Issue', 'Pages'], rows: [['Twelve', '24'], ['Thirteen', '32']])
/// ```
class ComicTable extends StatelessWidget {
  /// Creates a table; each row must have one value per column.
  const ComicTable({super.key, required this.columns, required this.rows});

  /// Column labels in reading order.
  final List<String> columns;

  /// Cell values in row order.
  final List<List<String>> rows;
  @override
  Widget build(BuildContext context) {
    assert(columns.isNotEmpty);
    assert(rows.every((row) => row.length == columns.length));
    final t = ComicTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                  child: ComicPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var j = 0; j < columns.length; j++)
                          ComicKvRow(columns[j], rows[i][j], isFirst: j == 0),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
            horizontalInside: BorderSide(
              color: t.colors.divider,
              width: t.rule(2),
            ),
          ),
          children: [
            TableRow(
              children: [
                for (final column in columns)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Semantics(
                      header: true,
                      child: Text(column, style: t.type.title),
                    ),
                  ),
              ],
            ),
            for (final row in rows)
              TableRow(
                children: [
                  for (final cell in row)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(cell, style: t.type.body),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
