/// slipway's other screens: a run's change as a diff, and the desk's
/// panes with their switcher.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'kit.dart';
import 'slipway_pages.dart';

// ---------------------------------------------------------------- diff

/// A side of a diff row: its line numbers in the file before and after
/// (a gone line has no after, a new one no before) and its words, or
/// nothing (the other side has a line here, this one has none).
typedef _Side = ({int? before, int? after, String op, String text})?;

/// The change's rows side by side: kept lines on both sides, a run of gone
/// lines beside the run of new lines that replaced it, a blank where one
/// side has more.
List<(_Side, _Side)> _paired(List<DiffLine> lines, int start) {
  final rows = <(_Side, _Side)>[];
  var before = start;
  var after = start;
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (line.op == ' ') {
      rows.add((
        (before: before++, after: null, op: ' ', text: line.text),
        (before: null, after: after++, op: ' ', text: line.text),
      ));
      i++;
      continue;
    }
    final gone = <DiffLine>[];
    final added = <DiffLine>[];
    while (i < lines.length && lines[i].op == '-') {
      gone.add(lines[i++]);
    }
    while (i < lines.length && lines[i].op == '+') {
      added.add(lines[i++]);
    }
    for (var k = 0; k < math.max(gone.length, added.length); k++) {
      rows.add((
        k < gone.length
            ? (before: before++, after: null, op: '-', text: gone[k].text)
            : null,
        k < added.length
            ? (before: null, after: after++, op: '+', text: added[k].text)
            : null,
      ));
    }
  }
  return rows;
}

/// The change in one column, numbered in two gutters as `diff -u` readers
/// number it: the line before, then after (a gone line has only the first,
/// a new line only the second).
List<_Side> _unified(List<DiffLine> lines, int start) {
  var before = start;
  var after = start;
  return [
    for (final line in lines)
      (
        before: line.op == '+' ? null : before++,
        after: line.op == '-' ? null : after++,
        op: line.op,
        text: line.text,
      ),
  ];
}

/// One side of one diff row: its line number (both, before and after, in
/// one column), `-` or `+` in the tone's ink over a tinted ground, and the
/// words wrapped on the grid with a hanging indent, as the log wraps.
class _DiffCell extends StatelessWidget {
  const _DiffCell({required this.side, required this.cols, this.both = false});

  final _Side side;
  final int cols;

  /// Whether it numbers the line before and after (one column).
  final bool both;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final lh = grid.lineHeight;
    const gutterCols = 4;
    final numberCols = both ? gutterCols * 2 : gutterCols;
    const opCols = 2;
    const hangCols = 2;
    final s = side;
    if (s == null) {
      // No line on this side: a shaded blank, as a diff tool leaves it,
      // fainter on paper than an added or removed line's tint, so the blank
      // never reads as one of them.
      return ColoredBox(
        color: theme.rule.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
        ),
        child: SizedBox(height: lh),
      );
    }
    final ink = switch (s.op) {
      '-' => theme.danger,
      '+' => theme.success,
      _ => null,
    };
    final textCols = math.max(cols - numberCols - opCols, hangCols + 8);
    final rows = logRows(grid, s.text, textCols, textCols - hangCols);
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, (start, end)) in rows.indexed)
          SizedBox(
            height: lh,
            child: Row(
              children: [
                for (final n in [
                  if (both || s.after == null) s.before,
                  if (both || s.before == null) s.after,
                ]) ...[
                  SizedBox(
                    width: grid.cols(gutterCols - 1),
                    child: i > 0 || n == null
                        ? null
                        : Text(
                            '$n',
                            textAlign: TextAlign.end,
                            style: theme.dimStyle,
                          ),
                  ),
                  SizedBox(width: grid.cellWidth),
                ],
                SizedBox(
                  width: grid.cols(opCols),
                  child: i > 0
                      ? null
                      : Text(s.op, style: theme.boldStyle.copyWith(color: ink)),
                ),
                if (i > 0) SizedBox(width: grid.cols(hangCols)),
                Flexible(
                  child: Text(
                    s.text.substring(start, end),
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textStyle.copyWith(
                      color: ink == null ? null : theme.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    final said = switch (s.op) {
      '-' => 'line ${s.before} removed: ${s.text}',
      '+' => 'line ${s.after} added: ${s.text}',
      _ => 'line ${s.after ?? s.before}: ${s.text}',
    };
    return Semantics(
      label: said,
      excludeSemantics: true,
      child: ColoredBox(
        color: ink == null
            ? const Color(0x00000000)
            : ink.withValues(
                // On paper the green is dark: at a tenth it reads as grey.
                alpha: theme.brightness == Brightness.dark ? 0.14 : 0.16,
              ),
        child: words,
      ),
    );
  }
}

/// One file's change in a pane: side by side ([split]) or one column.
class _DiffPane extends StatelessWidget {
  const _DiffPane({required this.split});

  final bool split;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final added = slipwayDiff.where((l) => l.op == '+').length;
    final gone = slipwayDiff.where((l) => l.op == '-').length;
    return TermPane(
      title: slipwayDiffFile,
      trailing: '+$added −$gone',
      footer: split ? 'before │ after' : null,
      // A change is code: it runs left to right in any app.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, c) {
            final cols = grid.colsIn(c.maxWidth);
            if (!split) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: grid.lineHeight),
                  for (final side in _unified(slipwayDiff, slipwayDiffStart))
                    _DiffCell(side: side, cols: cols, both: true),
                ],
              );
            }
            final half = (cols - 1) ~/ 2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: grid.lineHeight),
                for (final (gone, added) in _paired(
                  slipwayDiff,
                  slipwayDiffStart,
                ))
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: grid.cols(half),
                          child: _DiffCell(side: gone, cols: half),
                        ),
                        SizedBox(width: grid.cellWidth),
                        Expanded(
                          child: _DiffCell(side: added, cols: half),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A run's change: its commit, then the file before and after side by side
/// on a wide screen, as one column of `-` and `+` lines on a phone.
class DiffPage extends StatelessWidget {
  /// The change behind [run].
  const DiffPage({super.key, required this.run});

  /// The run whose commit it shows.
  final Run run;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return PageScroll(
      cols: 160,
      children: [
        TermPane(
          title: 'change',
          trailing: run.commit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A line of room under the title, as every pane leaves.
              SizedBox(height: context.termGrid.lineHeight),
              Text(run.message, style: theme.boldStyle),
              Text(
                '${run.author} · ${run.branch} · #${run.number}',
                style: theme.dimStyle,
              ),
            ],
          ),
        ),
        _DiffPane(split: wide),
      ],
    );
  }
}

// ---------------------------------------------------------------- desk

/// The desk's panes and the switcher between them: each pane numbered in
/// its title, `[` and `]` (or a click) moving the keyboard to the one
/// before or after, the pane that has it drawn in double lines.
class DeskPanes extends StatefulWidget {
  /// Switches between [panes], laid out by [builder].
  const DeskPanes({
    super.key,
    required this.panes,
    required this.builder,
    this.initial = 0,
    this.initialControl = false,
  });

  /// The panes' names, in order.
  final List<String> panes;

  /// Lays the panes out: [focusOf] is the focus to put round pane i.
  final Widget Function(
    BuildContext context,
    FocusNode Function(int i) focusOf,
    int current,
  )
  builder;

  /// The pane the keyboard starts in.
  final int initial;

  /// Whether the starting pane's first control takes the keyboard (a search
  /// typed into); else the pane itself has it, its frame doubled and no
  /// control marked until Tab moves into one.
  final bool initialControl;

  @override
  State<DeskPanes> createState() => _DeskPanesState();
}

class _DeskPanesState extends State<DeskPanes> {
  late final List<FocusNode> _nodes = [
    for (final name in widget.panes) FocusNode(debugLabel: 'pane $name'),
  ];
  late int _current = widget.initial;

  @override
  void initState() {
    super.initState();
    for (final (i, node) in _nodes.indexed) {
      node.addListener(() {
        if (node.hasFocus && _current != i) setState(() => _current = i);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enter(_current, control: widget.initialControl);
    });
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Into pane i: the pane itself takes the keyboard, so the screen shows one
  // mark (the pane's double frame) until Tab moves into a control; with
  // [control], its first control takes it.
  void _enter(int i, {bool control = false}) {
    final node = _nodes[i];
    final first = node.traversalDescendants.where((n) => n.canRequestFocus);
    (control && first.isNotEmpty ? first.first : node).requestFocus();
    setState(() => _current = i);
  }

  void _step(int by) => _enter((_current + by + _nodes.length) % _nodes.length);

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.bracketRight): () => _step(1),
      const SingleActivator(LogicalKeyboardKey.bracketLeft): () => _step(-1),
    },
    child: widget.builder(context, (i) => _nodes[i], _current),
  );
}

/// The switcher as the status line shows it: `[1:runs] 2:run 3:log`, the
/// pane with the keyboard in inverse video.
List<TermStatusSegment> deskSegments(
  TermThemeData theme,
  List<String> panes,
  int current,
) => [
  for (final (i, name) in panes.indexed)
    TermStatusSegment(
      '${i + 1}:$name${i == current ? '*' : ''}',
      color: i == current ? theme.accent : theme.dim,
      semanticLabel: 'pane ${i + 1}, $name${i == current ? ', current' : ''}',
    ),
];
