/// A dashboard's figures: [MinimalStat] and the row that holds them, as
/// separate tiles or one joined strip.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../internal/styled.dart';
import '../shapes.dart';
import '../theme.dart';
import 'charts.dart';
import 'pressable.dart';
import 'tag.dart';

/// A dashboard figure: the uppercase label, the value in mono with tabular
/// figures, an optional delta and a line of detail, and an optional
/// sparkline.
///
/// On its own, or in a [MinimalStatRow], it is a hairline tile on the card
/// colour, its delta after an arrow that points along time: up or down
/// toward the end edge, so right to left it leans left, as the sparkline
/// runs. In a [MinimalStatRow.joined] it is one cell of a single hairline
/// strip on the ground, divided from its neighbours by hairlines, its value
/// a step smaller and its delta signed (`+12%`) so three or four fit. The
/// value always prints whole at its size, never scaled down: a row too
/// narrow for its figures stacks them.
///
/// [delta] is the change's magnitude and [deltaUp] its direction; a sign
/// already on [delta] is dropped. [deltaGood] owns the colour and defaults
/// to [deltaUp] (higher is better): set it when the two part ways, as for
/// latency or an error rate. [tone] inks the value itself for a figure that
/// is the alarm (`Late 4` in [MinimalTone.warning]).
///
/// ```dart
/// MinimalStat(label: 'Kept', value: '23/28', delta: '4', deltaUp: true)
/// ```
class MinimalStat extends StatelessWidget {
  /// A figure and what it counts.
  const MinimalStat({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaUp = true,
    this.deltaGood,
    this.detail,
    this.icon,
    this.tone,
    this.spark,
    this.large = false,
    this.weight = 1,
    this.selected = false,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// What the figure counts; printed upper-cased in the label style.
  final String label;

  /// The figure, already formatted (`€1,284`, `12d`, `23/28`).
  final String value;

  /// The change's magnitude, already formatted (`12%`, `3`). A leading sign
  /// (`+12%`, `−3`) is dropped: [deltaUp] says which way.
  final String? delta;

  /// Which way the number moved: the tile's arrow, the joined cell's sign.
  final bool deltaUp;

  /// Whether that move is good news (the success colour, else the
  /// destructive one); null takes [deltaUp].
  final bool? deltaGood;

  /// The quiet rest of the line: the delta's baseline (`vs last week`) or,
  /// with no delta, a fact about the figure (`best 21d`).
  final String? detail;

  /// A glyph at the label's end, on a tile.
  final IconData? icon;

  /// Inks the value in a tone; null keeps the foreground.
  final MinimalTone? tone;

  /// A series drawn as a sparkline under the figure, in the delta's colour.
  final List<double>? spark;

  /// Prints a tile's value at the giant step, for the one figure a screen
  /// leads with.
  final bool large;

  /// The cell's share of a [MinimalStatRow.joined] row's width (the cell
  /// with a sparkline usually takes 1.3).
  final double weight;

  /// Whether this cell is a joined row's current filter: a 2 px foot in
  /// ink under a label in ink, announced as selected.
  final bool selected;

  /// Makes the figure a control (opens its breakdown, filters a list to
  /// it); null leaves it a figure.
  final VoidCallback? onPressed;

  /// The width of a selected cell's foot.
  static const double footWidth = 2;

  /// The value's style: a tile's (mono 600 at 22/28, a step under giant so
  /// two tiles share a row), or with [joined] a joined cell's (20/26, so
  /// three or four fit a strip).
  static TextStyle valueStyleOf(MinimalThemeData t, {bool joined = false}) =>
      joined
      ? t.giant.copyWith(fontSize: 20, height: 26 / 20, letterSpacing: -0.5)
      : t.giant.copyWith(fontSize: 22, height: 28 / 22, letterSpacing: -0.4);

  /// [delta] with any leading sign (`+`, `-`, `−`, `±`) and the space after
  /// it dropped: the magnitude a stat prints.
  static String magnitude(String delta) =>
      delta.replaceFirst(RegExp(r'^[+\-−±]\s*'), '');

  static const EdgeInsets _tilePadding = EdgeInsets.fromLTRB(14, 12, 14, 14);
  static const EdgeInsets _cellPadding = EdgeInsets.fromLTRB(12, 10, 12, 12);

  /// The width this figure needs to print its value whole on one line: the
  /// value at its style and the text scale, and the padding (and a tile's
  /// rim) on either side.
  double _need(BuildContext context, {required bool joined}) {
    final t = context.minimalTheme;
    final style = joined
        ? valueStyleOf(t, joined: true)
        : large
        ? t.giant
        : valueStyleOf(t);
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width +
        (joined
            ? _cellPadding.horizontal
            : _tilePadding.horizontal + 2 * t.hairline);
  }

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final place = _JoinedScope.of(context);
    return place != null ? _cell(context, place) : _tile(context);
  }

  Widget _tile(BuildContext context) {
    final t = context.minimalTheme;
    final signed = delta;
    final change = signed == null ? null : magnitude(signed);
    final good = deltaGood ?? deltaUp;
    // Words and the arrow glyph take the tone's ink; the sparkline's line
    // is a mark, so it keeps the fill.
    final deltaColor = good ? t.successInk : t.destructiveInk;
    final deltaMark = good ? t.success : t.destructive;
    final valueStyle = large ? t.giant : valueStyleOf(t);
    final note = detail;
    final series = spark;
    final glyph = icon;

    final tile = Container(
      padding: _tilePadding,
      decoration: minimalFrame(
        t.shapes.medium,
        fill: t.card,
        side: BorderSide(color: t.border, width: t.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: t.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (glyph != null) ...[
                const MinimalGap(MinimalSpacing.s4),
                MinimalIcon(
                  glyph,
                  size: MinimalIconSize.i14,
                  color: t.textTertiary,
                ),
              ],
            ],
          ),
          const MinimalGap(MinimalSpacing.s4),
          // Whole, at its size: a row too narrow for it stacks its figures
          // rather than shrink one.
          Text(value, style: _inked(t, valueStyle)),
          if (change != null || note != null) ...[
            const MinimalGap(MinimalSpacing.s4),
            Wrap(
              spacing: MinimalSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (change != null)
                  Semantics(
                    label: '${deltaUp ? 'up' : 'down'} $change',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mirrored right to left, where time (a
                        // sparkline's too) runs from the right.
                        MinimalIcon(
                          deltaUp
                              ? LucideIcons.arrowUpRightDir
                              : LucideIcons.arrowDownRightDir,
                          size: MinimalIconSize.i14,
                          color: deltaColor,
                        ),
                        const MinimalGap(MinimalSpacing.s2),
                        Text(change, style: t.mono.medium.c(deltaColor)),
                      ],
                    ),
                  ),
                if (note != null) Text(note, style: t.caption),
              ],
            ),
          ],
          if (series != null) ...[
            const MinimalGap(MinimalSpacing.s8),
            MinimalSparkline(
              series,
              height: 28,
              color: change != null ? deltaMark : t.primary,
            ),
          ],
        ],
      ),
    );

    final tap = onPressed;
    if (tap == null) {
      return MergeSemantics(
        child: Semantics(selected: selected ? true : null, child: tile),
      );
    }
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: tap,
      shape: t.shapes.medium,
      selected: selected,
      child: tile,
    );
  }

  Widget _cell(BuildContext context, _JoinedScope place) {
    final t = context.minimalTheme;
    final signed = delta;
    final change = signed == null
        ? null
        : '${deltaUp ? '+' : '−'}${magnitude(signed)}';
    final note = detail;
    final series = spark;
    final good = deltaGood ?? deltaUp;
    // The signed figure is words: the tone's ink. The sparkline is a mark
    // and keeps the fill.
    final deltaColor = good ? t.successInk : t.destructiveInk;
    final deltaMark = good ? t.success : t.destructive;
    final cell = Padding(
      padding: _cellPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: selected ? t.label.medium.c(t.foreground) : t.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const MinimalGap(MinimalSpacing.s2),
          Text(
            value,
            style: _inked(t, valueStyleOf(t, joined: true).c(t.foreground)),
          ),
          if (change != null || note != null)
            Text.rich(
              TextSpan(
                children: [
                  if (change != null)
                    TextSpan(
                      text: change,
                      style: t.mono
                          .copyWith(fontSize: 11.5)
                          .medium
                          .c(deltaColor),
                    ),
                  if (change != null && note != null) const TextSpan(text: ' '),
                  if (note != null) TextSpan(text: note, style: t.caption),
                ],
              ),
              style: t.caption,
              // One line, however large the text: a cell of a strip keeps
              // the strip's height.
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (series != null) ...[
            const MinimalGap(MinimalSpacing.s4),
            MinimalSparkline(
              series,
              height: 26,
              color: change != null ? deltaMark : t.primary,
            ),
          ],
        ],
      ),
    );
    final body = !selected
        ? cell
        : CustomPaint(
            painter: _FootPainter(
              color: t.foreground,
              width: footWidth,
              // The strip's corner inside its rim, where the cell meets it.
              corner: MinimalShapes.radiusOf(
                MinimalShapes.inset(t.shapes.medium, t.hairline),
              ),
              bottomStart: place.bottomStart,
              bottomEnd: place.bottomEnd,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
            child: cell,
          );
    final tap = onPressed;
    if (tap == null) {
      return MergeSemantics(
        child: Semantics(selected: selected ? true : null, child: body),
      );
    }
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: tap,
      radius: 0,
      selected: selected,
      child: body,
    );
  }

  /// [style] in [tone]'s foreground, or as it is with no tone.
  TextStyle _inked(MinimalThemeData t, TextStyle style) => switch (tone) {
    null => style,
    MinimalTone.neutral => style.c(t.foreground),
    final named => style.c(t.tone(named).foreground),
  };
}

/// Figures side by side, matched in height even when their contents differ
/// (one carries a delta or a sparkline, its neighbour does not): separate
/// tiles 8 px apart, or with [MinimalStatRow.joined] one bordered strip.
///
/// A figure is never scaled down to fit. When one would not print whole in
/// its share (a phone, large text), the row breaks: four figures go two to
/// a row, any other count one under another, tiles 8 px apart and a strip's
/// cells divided by hairlines.
///
/// ```dart
/// MinimalStatRow(children: [streak, kept])
/// ```
class MinimalStatRow extends StatelessWidget {
  /// A row of separate tiles.
  const MinimalStatRow({super.key, required this.children}) : joined = false;

  /// A back office's headline numbers as ONE instrument: two to four
  /// [MinimalStat] cells in a single hairline strip on the ground,
  /// divided by hairlines. Each cell's [MinimalStat.weight] sets its share of
  /// the width.
  ///
  /// ```dart
  /// MinimalStatRow.joined(children: [revenue, orders, late])
  /// ```
  const MinimalStatRow.joined({super.key, required this.children})
    : joined = true;

  /// The figures, start to end.
  final List<Widget> children;

  /// Whether the figures are cells of one strip rather than separate tiles.
  final bool joined;

  /// The space between tiles, across a row and down a stack.
  static const double _tileGap = MinimalSpacing.s8;

  @override
  Widget build(BuildContext context) {
    // A const list's length is not a constant, so the count is checked
    // here rather than in the constructor.
    assert(
      !joined || (children.length >= 2 && children.length <= 4),
      'a joined row holds two to four figures',
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = _rows(context, constraints.maxWidth);
        return joined ? _strip(context, rows) : _tiles(rows);
      },
    );
  }

  static double _weightOf(Widget child) =>
      child is MinimalStat ? child.weight : 1;

  /// [children] in rows: all in one when each figure prints whole in its
  /// share of [width], else two to a row for four, else one to a row.
  List<List<Widget>> _rows(BuildContext context, double width) {
    final n = children.length;
    List<List<Widget>> split(int across) => [
      for (var i = 0; i < n; i += across)
        children.sublist(i, math.min(i + across, n)),
    ];
    if (n < 2 || !width.isFinite) return split(math.max(n, 1));
    final hairline = context.minimalTheme.hairline;
    final need = <Widget, double>{
      for (final child in children)
        if (child is MinimalStat) child: child._need(context, joined: joined),
    };
    bool fits(List<Widget> row) {
      // A strip's cells share what its rim and their rules leave, by
      // weight; tiles share what their gaps leave, evenly.
      final room = joined
          ? width - (row.length + 1) * hairline
          : width - (row.length - 1) * _tileGap;
      final weights = row.fold(0.0, (sum, c) => sum + _weightOf(c));
      return row.every((c) {
        final share = room * (joined ? _weightOf(c) / weights : 1 / row.length);
        return (need[c] ?? 0) <= share;
      });
    }

    for (final across in [n, if (n == 4) 2]) {
      final rows = split(across);
      if (rows.every(fits)) return rows;
    }
    return split(1);
  }

  /// One row of figures, matched in height, [gap] between them. A strip's
  /// cells ([strip]) share it by weight and learn which of its bottom
  /// corners they stand in ([last]: the strip's last row).
  Widget _row(
    List<Widget> row,
    Widget gap, {
    bool strip = false,
    bool last = false,
  }) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < row.length; i++) ...[
          if (i > 0) gap,
          Expanded(
            flex: strip ? (_weightOf(row[i]) * 100).round() : 1,
            child: strip
                ? _JoinedScope(
                    bottomStart: last && i == 0,
                    bottomEnd: last && i == row.length - 1,
                    child: row[i],
                  )
                : row[i],
          ),
        ],
      ],
    ),
  );

  Widget _tiles(List<List<Widget>> rows) {
    const gap = MinimalGap(_tileGap);
    if (rows.length == 1) return _row(rows.single, gap);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) gap,
          _row(rows[i], gap),
        ],
      ],
    );
  }

  Widget _strip(BuildContext context, List<List<Widget>> rows) {
    final t = context.minimalTheme;
    final rule = ColoredBox(color: t.border);
    final across = SizedBox(width: t.hairline, child: rule);
    final down = SizedBox(height: t.hairline, child: rule);
    return Container(
      decoration: minimalFrame(
        t.shapes.medium,
        side: BorderSide(color: t.border, width: t.hairline),
      ),
      child: ClipPath(
        // Inside the border, so a pressed corner cell's wash keeps the
        // strip's corners.
        clipper: ShapeBorderClipper(
          shape: MinimalShapes.inset(t.shapes.medium, t.hairline),
          textDirection: Directionality.of(context),
        ),
        child: rows.length == 1
            ? _row(rows.single, across, strip: true, last: true)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) down,
                    _row(
                      rows[i],
                      across,
                      strip: true,
                      last: i == rows.length - 1,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Marks a figure under a [MinimalStatRow.joined] as one of its cells, and
/// says which of the strip's round bottom corners the cell stands in.
class _JoinedScope extends InheritedWidget {
  const _JoinedScope({
    required this.bottomStart,
    required this.bottomEnd,
    required super.child,
  });

  /// Whether the cell stands in the strip's bottom corner at the start.
  final bool bottomStart;

  /// Whether the cell stands in the strip's bottom corner at the end.
  final bool bottomEnd;

  static _JoinedScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_JoinedScope>();

  @override
  bool updateShouldNotify(_JoinedScope oldWidget) =>
      oldWidget.bottomStart != bottomStart || oldWidget.bottomEnd != bottomEnd;
}

/// A selected cell's foot: one straight bar, [width] of ink along its
/// bottom edge. In a corner of the strip it stops the corner's radius short
/// of that side, where the corner starts to round, so it neither bends up
/// the curve nor runs flat across it; right to left as left to right.
class _FootPainter extends CustomPainter {
  const _FootPainter({
    required this.color,
    required this.width,
    required this.corner,
    required this.bottomStart,
    required this.bottomEnd,
    required this.rtl,
  });

  final Color color;
  final double width;

  /// The strip's corner radius inside its rim.
  final double corner;
  final bool bottomStart;
  final bool bottomEnd;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= width) return;
    final reach = math.min(corner, math.min(w, h) / 2);
    // Each side stands in from a strip's round bottom corner by its radius,
    // where the bottom edge runs straight again.
    final left = (rtl ? bottomEnd : bottomStart) ? reach : 0.0;
    final right = (rtl ? bottomStart : bottomEnd) ? reach : 0.0;
    if (w - right <= left) return;
    canvas.drawRect(
      Rect.fromLTRB(left, h - width, w - right, h),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_FootPainter old) =>
      old.color != color ||
      old.width != width ||
      old.corner != corner ||
      old.bottomStart != bottomStart ||
      old.bottomEnd != bottomEnd ||
      old.rtl != rtl;
}
