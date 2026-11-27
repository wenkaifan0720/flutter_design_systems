/// Brutal's display parts, each drawn whole in flat ruled shapes: a
/// disclosure and its group, a plain table, a description list, a
/// timeline, square avatars and their pile, a count badge, media with its
/// fallback, a skeleton and a meter.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'lists.dart';
import 'surface.dart';
import 'theme.dart';

bool _still(BuildContext context) => rawReduceMotionOf(context);

/// A heading that opens to show [child] under it: a row with a square
/// cell holding a plus (a minus while open). A press anywhere on the row,
/// Enter or Space toggles it.
///
/// Give [expanded] to hold it from outside; otherwise it keeps its own,
/// starting at [initiallyExpanded]. Stack several in a
/// [BrutalDisclosureGroup].
///
/// Reads [style]'s `fill` (the heading while pressed), `foreground`,
/// `padding`, `minimumSize` (the heading's least height) and `textStyle`
/// (the title) in its states, open counted as selected, then
/// [BrutalThemeData.disclosureStyle]'s.
///
/// ```dart
/// BrutalDisclosure(title: 'Refunds', child: Text('Up to a day before.'))
/// ```
class BrutalDisclosure extends StatefulWidget {
  /// A disclosure headed [title] over [child].
  const BrutalDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.style,
  });

  /// The heading.
  final String title;

  /// A line under the heading, in the muted ink.
  final String? subtitle;

  /// What it shows when open.
  final Widget child;

  /// Whether it is open, held from outside; null keeps its own.
  final bool? expanded;

  /// Where its own state starts.
  final bool initiallyExpanded;

  /// Called with the state a press asks for.
  final ValueChanged<bool>? onExpansionChanged;

  /// Its style, over [BrutalThemeData.disclosureStyle].
  final BrutalStyle? style;

  @override
  State<BrutalDisclosure> createState() => _BrutalDisclosureState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('expanded', value: expanded, ifTrue: 'expanded'));
  }
}

class _BrutalDisclosureState extends State<BrutalDisclosure> {
  late bool _own = widget.initiallyExpanded;

  bool get _open => widget.expanded ?? _own;

  void _toggle() {
    final next = !_open;
    if (widget.expanded == null) setState(() => _own = next);
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final open = _open;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: open,
          child: RawButton(
            onPressed: _toggle,
            builder: (context, states, _) {
              final lit = states.contains(WidgetState.pressed);
              final layered = RawStyleOf(
                [widget.style, theme.disclosureStyle],
                {...states, if (open) WidgetState.selected},
              );
              final ink =
                  layered.foreground ??
                  (lit ? c.onColor(layered.fill ?? c.ink) : c.ink);
              return AnimatedBrutalSurface(
                stiffness: BrutalMotion.colorStiffness,
                face: BrutalFace(
                  fill: lit
                      ? (layered.fill ?? c.ink)
                      : c.ink.withValues(alpha: 0),
                  border: c.ink.withValues(alpha: 0),
                  foreground: ink,
                  borderWidth: 0,
                ),
                child: CustomPaint(
                  foregroundPainter: states.contains(WidgetState.focused)
                      ? BrutalInsetFocusPainter(ink)
                      : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          layered.minimumSize?.height ??
                          theme.controlHeight + 8,
                    ),
                    child: Padding(
                      padding:
                          layered.padding(Directionality.of(context)) ??
                          const EdgeInsets.symmetric(
                            horizontal: BrutalSpacing.regular,
                            vertical: BrutalSpacing.medium,
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
                                  style: layered
                                      .text(t.label)
                                      .copyWith(color: ink),
                                ),
                                if (widget.subtitle != null)
                                  Text(
                                    widget.subtitle!,
                                    style: t.secondary.copyWith(
                                      color: lit ? c.paper : c.inkMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: BrutalSpacing.medium),
                          _PlusCell(
                            open: open,
                            ink: ink,
                            width: theme.borderWidth,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: _still(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.topStart,
            child: open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BrutalRule(color: c.ink),
                      Padding(
                        padding: const EdgeInsets.all(BrutalSpacing.regular),
                        child: DefaultTextStyle.merge(
                          style: t.body.copyWith(color: c.ink),
                          child: widget.child,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

/// A 28 px ruled square holding a plus, its upright gone while open.
class _PlusCell extends StatelessWidget {
  const _PlusCell({required this.open, required this.ink, required this.width});

  final bool open;
  final Color ink;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 28,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: ink, width: width),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(width: 12, height: 2, child: ColoredBox(color: ink)),
          if (!open)
            SizedBox(width: 2, height: 12, child: ColoredBox(color: ink)),
        ],
      ),
    ),
  );
}

/// Disclosures stacked in one ruled box, a rule between each.
///
/// Reads [style]'s `fill` and `edge` (the box and its rules), then
/// [BrutalThemeData.disclosureStyle]'s.
///
/// ```dart
/// BrutalDisclosureGroup(children: [BrutalDisclosure(title: 'A', child: a)])
/// ```
class BrutalDisclosureGroup extends StatelessWidget {
  /// A box of [children].
  const BrutalDisclosureGroup({super.key, required this.children, this.style});

  /// The disclosures, top to bottom.
  final List<BrutalDisclosure> children;

  /// Its style, over [BrutalThemeData.disclosureStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.disclosureStyle], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    return BrutalSurface(
      face: BrutalFace(
        fill: layered.fill ?? c.surface,
        border: rule,
        foreground: c.ink,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, d) in children.indexed) ...[
            if (i > 0) BrutalRule(color: rule),
            d,
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalDisclosure>('children', children))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// One column of a [BrutalTable].
@immutable
class BrutalTableColumn {
  /// A column headed [label]; [numeric] sets it to the end in even
  /// figures, [flex] is its share of the width.
  const BrutalTableColumn(this.label, {this.numeric = false, this.flex = 1});

  /// The heading.
  final String label;

  /// Whether its cells are numbers: set to the end, in tabular figures.
  final bool numeric;

  /// Its share of the table's width.
  final double flex;
}

/// A plain table on a full grid of 2 px rules, its header row in ink.
/// Narrower than [minColumnWidth] a column, it scrolls sideways. A column
/// is never narrower than its widest figure (a numeric cell, whole) or
/// word, at the reader's text size: a time or a price never breaks, and
/// where they don't fit the table scrolls sideways, as Material's data
/// table does.
///
/// For sorting, selecting and pages, use [BrutalDataTable].
///
/// Reads [style]'s `fill` (the body), `edge` (the grid), `foreground` (the
/// body's words), `padding` (each cell's) and `textStyle` (the body's
/// words), then [BrutalThemeData.dataTableStyle]'s. The header row stays
/// ink with paper words.
///
/// ```dart
/// BrutalTable(columns: [BrutalTableColumn('Night'), BrutalTableColumn('Sold', numeric: true)], rows: [['Friday', '212'], ['Saturday', '340']])
/// ```
class BrutalTable extends StatelessWidget {
  /// A table of [rows] under [columns].
  const BrutalTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minColumnWidth = 112,
    this.style,
  });

  /// The columns.
  final List<BrutalTableColumn> columns;

  /// The rows, a string per column.
  final List<List<String>> rows;

  /// The width under which a column stops shrinking and the table scrolls.
  final double minColumnWidth;

  /// Its style, over [BrutalThemeData.dataTableStyle].
  final BrutalStyle? style;

  // It measures its words as it builds: it builds again when the
  // platform's fonts change (a face or a script's fallback arriving on
  // the web), so its widths follow the words drawn.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PaintingBinding.instance.systemFonts,
    builder: (context, _) => _measured(context),
  );

  Widget _measured(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layered = RawStyleOf([style, theme.dataTableStyle], const {});
    final pad =
        layered.padding(Directionality.of(context)) ??
        const EdgeInsets.symmetric(
          horizontal: BrutalSpacing.medium,
          vertical: BrutalSpacing.medium,
        );
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    final words = layered.foreground ?? c.ink;
    // A numeric column's words are in even figures.
    TextStyle styled(BrutalTableColumn column, TextStyle style) =>
        column.numeric
        ? style.copyWith(fontFeatures: const [FontFeature.tabularFigures()])
        : style;
    Widget cell(String text, BrutalTableColumn column, TextStyle style) =>
        Padding(
          padding: pad,
          child: Text(
            text,
            textAlign: column.numeric ? TextAlign.end : TextAlign.start,
            style: styled(column, style),
          ),
        );
    final side = BorderSide(color: rule, width: theme.borderWidth);
    final header = t.caption.copyWith(color: c.paper);
    final body = layered.text(t.body).copyWith(color: words);
    // Each column's least width: its widest figure (a numeric cell, whole)
    // or word, as laid out, and the cell's padding.
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    double measure(String text, TextStyle style) {
      painter.text = TextSpan(text: text, style: style);
      painter.layout();
      return painter.width.ceilToDouble();
    }

    final breaks = RegExp(r'\s+');
    final least = [
      for (final (i, col) in columns.indexed)
        pad.horizontal +
            [
              for (final word in col.label.toUpperCase().split(breaks))
                measure(word, styled(col, header)),
              for (final row in rows)
                if (i < row.length)
                  for (final piece
                      in col.numeric ? [row[i]] : row[i].split(breaks))
                    measure(piece, styled(col, body)),
            ].fold(0.0, math.max),
    ];
    painter.dispose();
    final needed =
        least.fold(0.0, (a, b) => a + b) +
        (columns.length - 1) * theme.borderWidth;
    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.maxWidth - 2 * theme.borderWidth;
        final floor = math.max(columns.length * minColumnWidth, needed);
        final width = inner.isFinite
            ? floor.clamp(inner, double.infinity)
            : floor;
        final table = Table(
          columnWidths: {
            for (final (i, col) in columns.indexed)
              i: MaxColumnWidth(
                FixedColumnWidth(least[i]),
                FlexColumnWidth(col.flex),
              ),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(horizontalInside: side, verticalInside: side),
          children: [
            TableRow(
              decoration: BoxDecoration(color: c.ink),
              children: [
                for (final col in columns)
                  Semantics(
                    header: true,
                    child: cell(col.label.toUpperCase(), col, header),
                  ),
              ],
            ),
            for (final row in rows)
              TableRow(
                children: [
                  for (final (i, col) in columns.indexed)
                    cell(i < row.length ? row[i] : '', col, body),
                ],
              ),
          ],
        );
        return BrutalSurface(
          face: BrutalFace(
            fill: layered.fill ?? c.surface,
            border: rule,
            foreground: words,
          ),
          child: width > inner
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: width, child: table),
                )
              : table,
        );
      },
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

/// One term of a [BrutalDescriptionList] and what it says.
@immutable
class BrutalDescription {
  /// [term] described by [detail].
  const BrutalDescription(this.term, this.detail);

  /// The term, in the muted label.
  final String term;

  /// What it says.
  final String detail;
}

/// Terms and their details on rules: side by side from 400 wide, the term
/// over its detail below that.
///
/// Reads [style]'s `edge` (the rules), `foreground` (the details),
/// `padding` (each entry's) and `textStyle` (the details), then
/// [BrutalThemeData.descriptionListStyle]'s.
///
/// ```dart
/// BrutalDescriptionList(entries: [BrutalDescription('Doors', '19:30')])
/// ```
class BrutalDescriptionList extends StatelessWidget {
  /// A list of [entries].
  const BrutalDescriptionList({super.key, required this.entries, this.style});

  /// The terms, top to bottom.
  final List<BrutalDescription> entries;

  /// Its style, over [BrutalThemeData.descriptionListStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layered = RawStyleOf([style, theme.descriptionListStyle], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 400;
        Widget entry(BrutalDescription e) {
          final term = Text(
            e.term.toUpperCase(),
            style: t.caption.copyWith(color: c.inkMuted),
          );
          final detail = Text(
            e.detail,
            style: layered
                .text(t.body)
                .copyWith(color: layered.foreground ?? c.ink),
          );
          return MergeSemantics(
            child: Padding(
              padding:
                  layered.padding(Directionality.of(context)) ??
                  const EdgeInsets.symmetric(vertical: BrutalSpacing.medium),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(width: 160, child: term),
                        const SizedBox(width: BrutalSpacing.regular),
                        Expanded(child: detail),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        term,
                        const SizedBox(height: BrutalSpacing.tight),
                        detail,
                      ],
                    ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrutalRule(color: rule),
            for (final e in entries) ...[entry(e), BrutalRule(color: rule)],
          ],
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalDescription>('entries', entries))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// One stop on a [BrutalTimeline].
@immutable
class BrutalTimelineEntry {
  /// A stop called [title], at [time], with [body] under it.
  const BrutalTimelineEntry({
    required this.title,
    this.time,
    this.body,
    this.done = false,
  });

  /// What happened, or will.
  final String title;

  /// When, in the caption over the title.
  final String? time;

  /// More words under the title.
  final String? body;

  /// Whether it has happened: its square filled with ink.
  final bool done;
}

/// Stops down a 2 px rule, each on a square: ink once done, open while to
/// come, and the first one to come in the signal colour.
///
/// Reads [style]'s `edge` (the rule and the squares'), `fill` (a done
/// square), `foreground` (the titles) and `textStyle` (the titles), then
/// [BrutalThemeData.timelineStyle]'s.
///
/// ```dart
/// BrutalTimeline(entries: [BrutalTimelineEntry(title: 'Doors', time: '19:30', done: true)])
/// ```
class BrutalTimeline extends StatelessWidget {
  /// A timeline of [entries], first to last.
  const BrutalTimeline({super.key, required this.entries, this.style});

  /// The stops.
  final List<BrutalTimelineEntry> entries;

  /// Its style, over [BrutalThemeData.timelineStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layered = RawStyleOf([style, theme.timelineStyle], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    final next = entries.indexWhere((e) => !e.done);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in entries.indexed)
          MergeSemantics(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        const SizedBox(height: BrutalSpacing.tight),
                        SizedBox.square(
                          dimension: 16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: e.done
                                  ? (layered.fill ?? c.ink)
                                  : i == next
                                  ? c.signal
                                  : c.surface,
                              border: Border.all(
                                color: rule,
                                width: theme.borderWidth,
                              ),
                            ),
                          ),
                        ),
                        if (i < entries.length - 1)
                          Expanded(
                            child: SizedBox(
                              width: theme.borderWidth,
                              child: ColoredBox(color: rule),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BrutalSpacing.medium),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < entries.length - 1
                            ? BrutalSpacing.large
                            : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (e.time != null)
                            Text(
                              e.time!.toUpperCase(),
                              style: t.caption.copyWith(color: c.inkMuted),
                            ),
                          Text(
                            e.title,
                            style: layered
                                .text(t.label)
                                .copyWith(color: layered.foreground ?? c.ink),
                          ),
                          if (e.body != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: BrutalSpacing.tight,
                              ),
                              child: Text(
                                e.body!,
                                style: t.secondary.copyWith(color: c.inkMuted),
                              ),
                            ),
                          if (e.done)
                            Semantics(label: 'done', child: const SizedBox()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalTimelineEntry>('entries', entries))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A person as a square: their picture, or their initials on a block
/// colour picked from their name (the same name, the same colour), in a
/// 2 px rule.
///
/// Reads [style]'s `fill` (in place of the block picked from the name; the
/// initials then take black or white by contrast), `edge`, `foreground`
/// and `textStyle` (the initials), then [BrutalThemeData.avatarStyle]'s.
///
/// ```dart
/// BrutalAvatar(name: 'Ines Okafor')
/// ```
class BrutalAvatar extends StatelessWidget {
  /// [name]'s square, [size] on a side.
  const BrutalAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = 40,
    this.style,
  });

  /// Whose it is: read by a screen reader, and the initials.
  final String name;

  /// Their picture; null, or one that fails, shows the initials.
  final ImageProvider? image;

  /// The side at the reader's text size; larger text grows it, up to
  /// twice, its letters with it.
  final double size;

  /// Its style, over [BrutalThemeData.avatarStyle].
  final BrutalStyle? style;

  /// The initials of [name]: the first letters of its first and last words.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    if (words.length == 1) return first.toUpperCase();
    return (first + words.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.avatarStyle], const {});
    final blocks = [c.lime, c.blue, c.pink, c.violet];
    final fill =
        layered.fill ?? blocks[name.codeUnits.fold(0, (a, b) => a + b) % 4];
    final words = layered.foreground ?? c.onColor(fill);
    // It grows with text up to twice its side, its letters with it, so they
    // stay inside its square.
    final side = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 2)
        .scale(size);
    final initials = Center(
      child: RawCapCenter(
        capHeightFactor: BrutalTheme.of(context).capHeightFactor,
        child: Text(
          initialsOf(name),
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: layered
              .text(theme.textTheme.label)
              .copyWith(
                color: words,
                fontSize: (side * 0.38).clamp(10, 56),
                height: 1,
              ),
        ),
      ),
    );
    return Semantics(
      label: name,
      image: image != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: side,
        child: BrutalSurface(
          face: BrutalFace(
            fill: fill,
            border: layered.side?.color ?? layered.edge ?? c.ink,
            foreground: words,
          ),
          child: image == null
              ? initials
              : Image(
                  image: image!,
                  fit: BoxFit.cover,
                  width: side,
                  height: side,
                  errorBuilder: (_, _, _) => initials,
                ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(DoubleProperty('size', size));
  }
}

/// A pile of [avatars], each over the last by a quarter, past [max] the
/// rest counted on an ink square.
///
/// Its avatars read [BrutalThemeData.avatarStyle] as each does; the count
/// square reads [style]'s `fill`, `edge` and `foreground`, then
/// [BrutalThemeData.avatarStyle]'s, ink with paper words when neither
/// gives them.
///
/// ```dart
/// BrutalAvatarGroup(avatars: [for (final n in names) BrutalAvatar(name: n)])
/// ```
class BrutalAvatarGroup extends StatelessWidget {
  /// A pile of [avatars].
  const BrutalAvatarGroup({
    super.key,
    required this.avatars,
    this.max = 4,
    this.size = 40,
    this.style,
  }) : assert(max > 0);

  /// The people.
  final List<BrutalAvatar> avatars;

  /// How many show before the count.
  final int max;

  /// Each square's side.
  final double size;

  /// The count square's style, over [BrutalThemeData.avatarStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.avatarStyle], const {});
    final countFill = layered.fill ?? c.ink;
    final countWords = layered.foreground ?? c.onColor(countFill);
    final shown = avatars.take(max).toList();
    final more = avatars.length - shown.length;
    final step = size * 0.75;
    final count = shown.length + (more > 0 ? 1 : 0);
    final names = [for (final a in shown) a.name];
    final label = more > 0
        ? '${names.join(', ')} and $more more'
        : names.join(', ');
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: count == 0 ? 0 : size + step * (count - 1),
        height: size,
        child: Stack(
          children: [
            for (final (i, a) in shown.indexed)
              PositionedDirectional(
                start: step * i,
                top: 0,
                child: BrutalAvatar(
                  name: a.name,
                  image: a.image,
                  size: size,
                  style: a.style,
                ),
              ),
            if (more > 0)
              PositionedDirectional(
                start: step * shown.length,
                top: 0,
                child: SizedBox.square(
                  dimension: size,
                  child: BrutalSurface(
                    face: BrutalFace(
                      fill: countFill,
                      border: layered.side?.color ?? layered.edge ?? c.ink,
                      foreground: countWords,
                    ),
                    child: Center(
                      child: Text(
                        '+$more',
                        maxLines: 1,
                        style: theme.textTheme.caption.copyWith(
                          color: countWords,
                        ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalAvatar>('avatars', avatars))
      ..add(IntProperty('max', max))
      ..add(DoubleProperty('size', size))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A count on a ruled signal square: on its own, or pinned over the top
/// end corner of [child]. Zero shows no square; past [maxCount] it reads
/// `99+`.
///
/// Reads [style]'s `fill` (the count then takes black or white by
/// contrast), `edge`, `foreground`, `padding`, `minimumSize` and
/// `textStyle`, then [BrutalThemeData.badgeStyle]'s.
///
/// ```dart
/// BrutalBadge(count: 3, child: Icon(LucideIcons.bell))
/// ```
class BrutalBadge extends StatelessWidget {
  /// A badge counting [count].
  const BrutalBadge({
    super.key,
    required this.count,
    this.child,
    this.maxCount = 99,
    this.semanticLabel,
    this.style,
  });

  /// The count.
  final int count;

  /// What it sits on; null stands it alone.
  final Widget? child;

  /// The highest count it shows.
  final int maxCount;

  /// What a screen reader hears for it, `3 new`, say; null reads the
  /// count.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.badgeStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.badgeStyle], const {});
    final fill = layered.fill ?? c.signal;
    final words =
        layered.foreground ??
        (layered.fill == null ? c.onSignal : c.onColor(fill));
    final least = layered.minimumSize ?? const Size(22, 22);
    final text = count > maxCount ? '$maxCount+' : '$count';
    final badge = Semantics(
      label: semanticLabel ?? text,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: least.width,
          minHeight: least.height,
        ),
        child: BrutalSurface(
          face: BrutalFace(
            fill: fill,
            border: layered.side?.color ?? layered.edge ?? c.ink,
            foreground: words,
          ),
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.symmetric(horizontal: BrutalSpacing.tight),
            child: Center(
              widthFactor: 1,
              child: Text(
                text,
                maxLines: 1,
                style: layered
                    .text(theme.textTheme.caption)
                    .copyWith(
                      color: words,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    if (child == null) return count <= 0 ? const SizedBox.shrink() : badge;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        if (count > 0) PositionedDirectional(top: -10, end: -12, child: badge),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('maxCount', maxCount))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A picture in a 2 px rule at [aspectRatio]; while it loads, and if it
/// fails, a ruled cross with an icon stands in its place.
///
/// Reads [style]'s `fill` (the ground), `edge` (the frame), `foreground`
/// (the stand-in's cross and icon) and `iconSize`, then
/// [BrutalThemeData.mediaStyle]'s.
///
/// ```dart
/// BrutalMedia(image: NetworkImage(url), semanticLabel: 'The stage at night')
/// ```
class BrutalMedia extends StatelessWidget {
  /// A frame for [image].
  const BrutalMedia({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.style,
  });

  /// The picture; null shows the stand-in.
  final ImageProvider? image;

  /// What the picture shows, for a screen reader.
  final String semanticLabel;

  /// Width over height.
  final double aspectRatio;

  /// How the picture fills the frame.
  final BoxFit fit;

  /// Its style, over [BrutalThemeData.mediaStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.mediaStyle], const {});
    final ground = layered.fill ?? c.surface;
    final mark = layered.foreground ?? c.inkMuted;
    final standIn = CustomPaint(
      painter: _CrossPainter(mark, theme.borderWidth),
      child: Center(
        child: ColoredBox(
          color: ground,
          child: Padding(
            padding: const EdgeInsets.all(BrutalSpacing.small),
            child: Icon(
              LucideIcons.image,
              size: layered.iconSize ?? 24,
              color: mark,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: BrutalSurface(
          face: BrutalFace(
            fill: ground,
            border: layered.side?.color ?? layered.edge ?? c.ink,
            foreground: c.ink,
          ),
          child: image == null
              ? standIn
              : Image(
                  image: image!,
                  fit: fit,
                  width: double.infinity,
                  height: double.infinity,
                  frameBuilder: (context, child, frame, sync) =>
                      sync || frame != null ? child : standIn,
                  errorBuilder: (_, _, _) => standIn,
                ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ImageProvider>('image', image, defaultValue: null),
      )
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(DoubleProperty('aspectRatio', aspectRatio))
      ..add(DiagnosticsProperty<BoxFit>('fit', fit))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.color, this.width);

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) =>
      old.color != color || old.width != width;
}

/// A flat block in the disabled grey standing where content will come,
/// its tone breathing slowly (still when motion is reduced). Screen
/// readers skip it; label the region that holds it instead.
///
/// Reads [style]'s `fill`, then [BrutalThemeData.skeletonStyle]'s.
///
/// ```dart
/// BrutalSkeleton(height: 16, width: 180)
/// ```
class BrutalSkeleton extends StatefulWidget {
  /// A block [width] by [height]; a null width fills the row.
  const BrutalSkeleton({super.key, this.width, this.height = 16, this.style});

  /// Its width; null fills the row.
  final double? width;

  /// Its height.
  final double height;

  /// Its style, over [BrutalThemeData.skeletonStyle].
  final BrutalStyle? style;

  /// Lines of text yet to come: [lines] blocks, the last one shorter.
  static Widget lines(int lines, {double height = 14}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < lines; i++) ...[
        if (i > 0) const SizedBox(height: BrutalSpacing.small),
        FractionallySizedBox(
          widthFactor: i == lines - 1 && lines > 1 ? 0.6 : 1,
          child: BrutalSkeleton(height: height),
        ),
      ],
    ],
  );

  @override
  State<BrutalSkeleton> createState() => _BrutalSkeletonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(DoubleProperty('height', height))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _BrutalSkeletonState extends State<BrutalSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // From build: iOS's Reduce Motion changes arrive as a build, never as
  // didChangeDependencies (rawReduceMotionOf).
  void _sync() {
    if (!_still(context)) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else if (_breath.isAnimating || _breath.value != 1) {
      _breath
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final theme = BrutalTheme.of(context);
    final fill =
        RawStyleOf([widget.style, theme.skeletonStyle], const {}).fill ??
        theme.colors.disabled;
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.55, end: 1).animate(_breath),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ColoredBox(color: fill),
        ),
      ),
    );
  }
}

/// A measure on a known scale, a row of ruled cells filled with ink up to
/// [value]; past [high] they fill with the danger colour. Unlike a
/// progress bar, it says how much, not how far along.
///
/// Reads [style]'s `fill` (the empty cells), `edge` (the rules),
/// `foreground` (the full cells under [high]), `minimumSize` (the scale's
/// height) and `textStyle` (the label), then
/// [BrutalThemeData.meterStyle]'s.
///
/// ```dart
/// BrutalMeter(value: 0.82, label: 'Capacity', valueText: '410 of 500', high: 0.9)
/// ```
class BrutalMeter extends StatelessWidget {
  /// A meter at [value] of 0 to [max].
  const BrutalMeter({
    super.key,
    required this.value,
    required this.label,
    this.max = 1,
    this.high,
    this.valueText,
    this.cells = 10,
    this.style,
  }) : assert(max > 0),
       assert(cells > 0);

  /// The measure.
  final double value;

  /// What it measures.
  final String label;

  /// The top of the scale.
  final double max;

  /// From this value up, the cells fill with the danger colour.
  final double? high;

  /// The value in words; null shows the percent.
  final String? valueText;

  /// How many cells the scale has.
  final int cells;

  /// Its style, over [BrutalThemeData.meterStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layered = RawStyleOf([style, theme.meterStyle], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    final f = (value / max).clamp(0.0, 1.0);
    final over = high != null && value >= high!;
    final full = (f * cells).round();
    final words = valueText ?? '${(f * 100).round()}%';
    return Semantics(
      label: label,
      value: words,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: layered.text(t.label).copyWith(color: c.ink),
                ),
              ),
              Text(
                words,
                style: t.secondary.copyWith(
                  color: over ? c.danger : c.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: BrutalSpacing.small),
          SizedBox(
            height: layered.minimumSize?.height ?? 20,
            child: BrutalSurface(
              face: BrutalFace(
                fill: layered.fill ?? c.surface,
                border: rule,
                foreground: c.ink,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cells; i++) ...[
                    if (i > 0) BrutalRule(vertical: true, color: rule),
                    Expanded(
                      child: ColoredBox(
                        color: i < full
                            ? (over ? c.danger : layered.foreground ?? c.ink)
                            : c.ink.withValues(alpha: 0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('max', max));
  }
}
