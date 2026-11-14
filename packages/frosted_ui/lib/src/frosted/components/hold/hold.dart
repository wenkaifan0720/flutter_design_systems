import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/corner.dart';
import '../../internal/cut.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../../internal/cap.dart';
import '../../internal/ink_on.dart';

/// A hairline across the width (or, [FrostedDivider.vertical], down the
/// height) in the theme's hairline ink, standing in [height] of room with
/// [indent] off its start and [endIndent] off its end. Decoration: it says
/// nothing.
///
/// ```dart
/// FrostedDivider()
/// ```
///
/// ```dart
/// FrostedDivider(height: 24, indent: 16)
/// ```
///
/// ```dart
/// FrostedDivider.vertical(width: 16)
/// ```
class FrostedDivider extends StatelessWidget {
  /// A rule across.
  const FrostedDivider({
    this.height = 1,
    this.thickness,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
    super.key,
  }) : axis = Axis.horizontal;

  /// A rule down, standing in [width] of room.
  const FrostedDivider.vertical({
    double width = 1,
    this.thickness,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
    super.key,
  }) : axis = Axis.vertical,
       height = width;

  /// Which way it runs.
  final Axis axis;

  /// The room it stands in, across its run; the line sits in its middle.
  final double height;

  /// The line's width; null is the theme's hairline stroke.
  final double? thickness;

  /// The gap before the line starts and after it ends.
  final double indent;

  /// The room left at the line's end.
  final double endIndent;

  /// The line's colour; null is the theme's hairline ink.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final line = thickness ?? FrostedStrokes.hairline;
    final rule = ColoredBox(color: color ?? t.colorScheme.border);
    return ExcludeSemantics(
      child: axis == Axis.horizontal
          ? SizedBox(
              height: height,
              child: Center(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: indent,
                    end: endIndent,
                  ),
                  child: SizedBox(
                    height: line,
                    width: double.infinity,
                    child: rule,
                  ),
                ),
              ),
            )
          : SizedBox(
              width: height,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: indent, bottom: endIndent),
                  child: SizedBox(
                    width: line,
                    height: double.infinity,
                    child: rule,
                  ),
                ),
              ),
            ),
    );
  }
}

/// A count, or a dot, on the top end corner of [child] (a glyph, an
/// avatar, a tab): a capsule of the unread coral, the [count] in white (past
/// [max], `99+`), the child cut clear of it by a 2 px gap so what the child
/// stands on shows between them (a gap is cut, never painted);
/// [FrostedBadge.dot] the dot alone. Without a child it stands on its own
/// in a line. A count of 0 hides it. Read aloud with the child as [label]
/// (the count by default).
///
/// ```dart
/// FrostedBadge(3, child: Icon(FrostedGlyphs.notifications))
/// ```
///
/// ```dart
/// FrostedBadge.dot(label: 'New', child: FrostedAvatar('IP', name: 'Ines Park'))
/// ```
///
/// ```dart
/// FrostedBadge(12)
/// ```
class FrostedBadge extends StatelessWidget {
  /// [count] on [child].
  const FrostedBadge(
    int this.count, {
    this.child,
    this.label,
    this.max = 99,
    this.isLabelVisible = true,
    this.style,
    super.key,
  });

  /// The dot alone on [child]: something new, uncounted.
  const FrostedBadge.dot({
    this.child,
    this.label,
    this.isLabelVisible = true,
    this.style,
    super.key,
  }) : count = null,
       max = 99;

  /// How many; null for the dot.
  final int? count;

  /// What it stands on; null stands it alone.
  final Widget? child;

  /// The largest count it prints; past it, `max+`.
  final int max;

  /// Whether it shows at all.
  final bool isLabelVisible;

  /// What a screen reader adds to the child; null says the count.
  final String? label;

  /// This badge's own style, over `FrostedThemeData.components.badge`: its
  /// fill, the count's colour and style, its shape (a count's capsule; the
  /// dot stays round) and padding.
  ///
  /// ```dart
  /// FrostedBadge(
  ///   3,
  ///   style: const FrostedStyle(
  ///     fill: WidgetStatePropertyAll(Color(0xFF5B5BD6)),
  ///   ),
  ///   child: inboxIcon,
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final count = this.count;
    final shown = isLabelVisible && (count == null || count > 0);
    const gap = FrostedChromeMetrics.unreadDotRing;
    final s = FrostedStyleLayers(style, t.components.badge);
    final fill = s.fill ?? t.colorScheme.unreadDot;
    final direction = Directionality.of(context);
    final Widget mark;
    // The mark's own size and outline, for the gap cut round it.
    final Size size;
    final ShapeBorder outline;
    if (count == null) {
      const d = FrostedChromeMetrics.unreadDot + gap * 2;
      size = const Size.square(d);
      outline = const CircleBorder();
      mark = SizedBox.square(
        dimension: d,
        child: DecoratedBox(
          decoration: ShapeDecoration(shape: outline, color: fill),
        ),
      );
    } else {
      final words = count > max ? '$max+' : '$count';
      final padding = (s.padding ?? const EdgeInsets.symmetric(horizontal: 5))
          .resolve(direction);
      // Words that read 4.5:1 on the fill the badge wears (the danger's own
      // words were chosen for the danger fill; white on the unread dot's
      // salmon read 3.1:1).
      final wordsStyle = s.words(
        t.textTheme.labelSmall.tabular.c(
          frostedInkOn(t, fill, preferred: t.colorScheme.onDanger),
        ),
      );
      final painter = TextPainter(
        text: TextSpan(text: words, style: wordsStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      size = Size(
        (painter.width + padding.horizontal).clamp(18, double.infinity),
        (painter.height + padding.vertical).clamp(18, double.infinity),
      );
      painter.dispose();
      outline = s.shape ?? FrostedCorners.full;
      mark = Container(
        width: size.width,
        height: size.height,
        padding: padding,
        decoration: ShapeDecoration(shape: outline, color: fill),
        // As wide as its words: a lone badge in a wrap or a column is
        // offered the whole width, and an aligned box would take it.
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: frostedCapCentred(
            Text(
              words,
              maxLines: 1,
              // "99+" in any language, never "+99".
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.noScaling,
              style: wordsStyle,
            ),
          ),
        ),
      );
    }
    final spoken = label ?? (count == null ? null : '$count');
    final child = this.child;
    if (child == null) {
      return shown
          ? Semantics(
              label: spoken,
              child: ExcludeSemantics(child: mark),
            )
          : const SizedBox.shrink();
    }
    return Semantics(
      label: shown ? spoken : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (shown)
            ClipPath(
              clipper: FrostedCutClipper((box) {
                final at = Offset(
                  direction == TextDirection.rtl
                      ? -6
                      : box.width + 6 - size.width,
                  -6,
                );
                return outline.getOuterPath(
                  (at & size).inflate(gap),
                  textDirection: direction,
                );
              }, (size, outline, direction)),
              child: child,
            )
          else
            child,
          if (shown)
            PositionedDirectional(
              top: -6,
              end: -6,
              child: ExcludeSemantics(child: mark),
            ),
        ],
      ),
    );
  }
}

/// A heading that opens to show what it holds: the [title] (and a quiet
/// [meta] under it) beside a chevron that turns as it opens, over [child]
/// once open, its height easing open and shut (a cut under Reduce Motion).
/// One target: a press, Enter or Space opens and shuts it; a screen reader
/// hears a button that is expanded or collapsed. Open by itself from
/// [initiallyExpanded]; with [expanded] the page holds it, told by
/// [onExpansionChanged].
///
/// ```dart
/// FrostedDisclosure(title: 'What does the plan include?', child: Text(answer))
/// ```
///
/// ```dart
/// FrostedDisclosure(title: 'Advanced', meta: '3 settings', expanded: open, onExpansionChanged: (v) => setState(() => open = v), child: settings)
/// ```
class FrostedDisclosure extends StatefulWidget {
  /// A heading over [child], shut until opened.
  const FrostedDisclosure({
    required this.title,
    required this.child,
    this.meta,
    this.leading,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The heading's words.
  final String title;

  /// A quiet line under the title.
  final String? meta;

  /// What stands before the title (a glyph).
  final Widget? leading;

  /// What it holds.
  final Widget child;

  /// Whether it starts open, when the page does not hold it.
  final bool initiallyExpanded;

  /// Whether it is open, when the page holds it.
  final bool? expanded;

  /// Told the new state on each press.
  final ValueChanged<bool>? onExpansionChanged;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  State<FrostedDisclosure> createState() => _FrostedDisclosureState();
}

class _FrostedDisclosureState extends State<FrostedDisclosure> {
  late bool _open = widget.initiallyExpanded;

  bool get _isOpen => widget.expanded ?? _open;

  void _toggle() {
    final next = !_isOpen;
    if (widget.expanded == null) setState(() => _open = next);
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final open = _isOpen;
    final head = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: FrostedBreakpoints.hitTargetOf(context),
      ),
      child: Row(
        spacing: FrostedSpacing.s12,
        children: [
          ?widget.leading,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, style: t.textTheme.titleMedium.semibold),
                  if (widget.meta case final meta?)
                    Text(meta, style: t.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          AnimatedRotation(
            turns: open ? .5 : 0,
            duration: motion.base,
            curve: motion.curve,
            child: Icon(
              FrostedGlyphs.chevronDown,
              size: 18,
              color: t.colorScheme.textTertiary,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FrostedPressable(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onPressed: _toggle,
          label: widget.title,
          value: widget.meta,
          expanded: open,
          radius: FrostedCorners.r12,
          child: head,
        ),
        ClipRect(
          child: AnimatedSize(
            duration: motion.base,
            curve: motion.curve,
            alignment: AlignmentDirectional.topStart,
            child: open
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: FrostedSpacing.s4,
                      bottom: FrostedSpacing.s12,
                    ),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

/// One moment of a [FrostedTimeline]: its [title], a quiet [meta] under it,
/// the [time] at its end, and the dot it stands on, in [hue] (the accent
/// by default); [current] rings the dot, the moment the record stands at.
class FrostedTimelineEntry {
  /// A moment.
  const FrostedTimelineEntry({
    required this.title,
    this.meta,
    this.time,
    this.hue,
    this.current = false,
  });

  /// What happened.
  final String title;

  /// A line under it.
  final String? meta;

  /// When, at the row's end.
  final String? time;

  /// The dot's hue.
  final FrostedHue? hue;

  /// Whether the record stands here now.
  final bool current;
}

/// Moments in order down a rail: a hairline joining a dot for each, the
/// entry's words beside it and its time at the row's end. Read aloud entry
/// by entry, the current one said to be current.
///
/// ```dart
/// FrostedTimeline(entries: const [FrostedTimelineEntry(title: 'Order placed', time: '9:02'), FrostedTimelineEntry(title: 'Packed', time: '11:40', current: true), FrostedTimelineEntry(title: 'Out for delivery')])
/// ```
class FrostedTimeline extends StatelessWidget {
  /// The [entries], first at the top.
  const FrostedTimeline({required this.entries, super.key});

  /// The moments, in order.
  final List<FrostedTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const dot = 10.0;
    const rail = 24.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, e) in entries.indexed)
          Semantics(
            container: true,
            label: [e.title, ?e.meta, ?e.time].join(', '),
            selected: e.current,
            excludeSemantics: true,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: rail,
                    child: CustomPaint(
                      painter: _RailPainter(
                        line: t.colorScheme.border,
                        width: FrostedStrokes.hairline,
                        above: i > 0,
                        below: i < entries.length - 1,
                        dotTop: 7 + dot / 2,
                        // The rail stops 2 short of the dot (and of the
                        // current one's ring): a gap, not a painted ring.
                        clear: dot / 2 + (e.current ? 3 : 0) + 2,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: SizedBox.square(
                            dimension: dot,
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                shape: const CircleBorder(),
                                gradient: (e.hue ?? t.hues.iris).band,
                                shadows: [
                                  if (e.current)
                                    BoxShadow(
                                      color: t.colorScheme.accent,
                                      spreadRadius: 3,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: FrostedSpacing.s8),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < entries.length - 1 ? FrostedSpacing.s16 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: e.current
                                ? t.textTheme.titleMedium.semibold
                                : t.textTheme.titleMedium,
                          ),
                          if (e.meta case final meta?)
                            Text(meta, style: t.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  if (e.time case final time?) ...[
                    const SizedBox(width: FrostedSpacing.s12),
                    Text(time, style: t.textTheme.bodySmall.tabular),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.line,
    required this.width,
    required this.above,
    required this.below,
    required this.dotTop,
    required this.clear,
  });

  final Color line;
  final double width;
  final bool above;
  final bool below;
  final double dotTop;
  final double clear;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..color = line
      ..strokeWidth = width;
    if (above) {
      canvas.drawLine(Offset(x, 0), Offset(x, dotTop - clear), paint);
    }
    if (below) {
      canvas.drawLine(Offset(x, dotTop + clear), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.line != line ||
      old.width != width ||
      old.above != above ||
      old.below != below ||
      old.dotTop != dotTop ||
      old.clear != clear;
}

/// A column of a [FrostedTable]: its [label], whether its cells are
/// [numeric] (set to the end in figures of one width), and its share of the
/// width ([flex]).
class FrostedTableColumn {
  /// A column headed [label].
  const FrostedTableColumn(this.label, {this.numeric = false, this.flex = 1});

  /// The column's head.
  final String label;

  /// Whether its cells are figures, set to the end.
  final bool numeric;

  /// Its share of the width.
  final double flex;
}

/// Rows of cells under column heads, on a glass tile: the heads in the
/// quiet caption, each row ruled from the next by a hairline, numeric
/// columns set to the end in figures of one width. Where the columns do not
/// fit their [minColumnWidth] (a phone), each row stands as its own block
/// of label and value lines, so nothing is cut or scrolled sideways. A cell
/// is any widget; a [String] cell is set in the body type.
///
/// ```dart
/// FrostedTable(columns: const [FrostedTableColumn('Item'), FrostedTableColumn('Qty', numeric: true), FrostedTableColumn('Price', numeric: true)], rows: const [['Notebook', '2', '\$12.00'], ['Pens', '10', '\$8.50']])
/// ```
class FrostedTable extends StatelessWidget {
  /// A table of [rows] under [columns].
  const FrostedTable({
    required this.columns,
    required this.rows,
    this.minColumnWidth = 96,
    this.semanticsLabel,
    super.key,
  });

  /// The columns, start to end.
  final List<FrostedTableColumn> columns;

  /// The rows, each a cell per column: a [String] or a [Widget].
  final List<List<Object>> rows;

  /// The narrowest a column may be before the rows stand as blocks.
  final double minColumnWidth;

  /// What a screen reader calls the table.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final radius = frostedRadiusOf(FrostedCorners.medium);
    Widget cell(Object value, FrostedTableColumn column, {bool head = false}) {
      final style = head
          ? t.textTheme.labelMedium.c(t.colorScheme.textSecondary)
          : column.numeric
          ? t.textTheme.titleMedium.tabular
          : t.textTheme.titleMedium;
      final align = column.numeric ? TextAlign.end : TextAlign.start;
      return switch (value) {
        final String s => Text(s, style: style, textAlign: align),
        final Widget w => DefaultTextStyle.merge(
          style: style,
          textAlign: align,
          child: Align(
            alignment: column.numeric
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: w,
          ),
        ),
        _ => Text('$value', style: style, textAlign: align),
      };
    }

    const pad = EdgeInsets.symmetric(
      horizontal: FrostedSpacing.s16,
      vertical: FrostedSpacing.s12,
    );
    final rule = BorderSide(
      color: t.colorScheme.border,
      width: FrostedStrokes.hairline,
    );
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: radius,
        color: t.glass.fill,
        edge: t.glass.edge,
        sheen: t.glass.rim,
        clipChild: true,
        child: LayoutBuilder(
          builder: (context, box) {
            final fits = box.maxWidth >= columns.length * minColumnWidth;
            if (fits) {
              return Table(
                columnWidths: {
                  for (final (i, c) in columns.indexed)
                    i: FlexColumnWidth(c.flex),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(horizontalInside: rule),
                children: [
                  TableRow(
                    decoration: BoxDecoration(border: Border(bottom: rule)),
                    children: [
                      for (final c in columns)
                        Padding(
                          padding: pad,
                          child: Semantics(
                            header: true,
                            child: cell(c.label, c, head: true),
                          ),
                        ),
                    ],
                  ),
                  for (final row in rows)
                    TableRow(
                      children: [
                        for (final (i, c) in columns.indexed)
                          Padding(
                            padding: pad,
                            child: cell(i < row.length ? row[i] : '', c),
                          ),
                      ],
                    ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (r, row) in rows.indexed)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: r == 0 ? null : Border(top: rule),
                    ),
                    child: Padding(
                      padding: pad,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: FrostedSpacing.s4,
                        children: [
                          for (final (i, c) in columns.indexed)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: FrostedSpacing.s12,
                              children: [
                                Expanded(
                                  child: Text(
                                    c.label,
                                    style: t.textTheme.labelMedium.c(
                                      t.colorScheme.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: cell(
                                    i < row.length ? row[i] : '',
                                    FrostedTableColumn(c.label, numeric: true),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
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
