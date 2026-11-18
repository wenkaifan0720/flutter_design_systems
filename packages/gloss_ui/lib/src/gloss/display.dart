/// Gloss's ways of showing things: the disclosure, the table, the
/// description list, the timeline, avatars, the badge and the tag, media in
/// a sunken frame, the divider engraved in the page, the skeleton and the
/// meter.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'fonts.dart';
import 'internal/chevron.dart';
import 'surface.dart';
import 'theme.dart';

/// A disclosure: a title that opens to [child] under it, its chevron in a
/// small pearl bead turning over as it opens.
///
/// ```dart
/// GlossDisclosure(title: 'Storage', child: Text('Keeps three days in the fridge.'))
/// ```
class GlossDisclosure extends StatefulWidget {
  /// A disclosure titled [title] over [child].
  const GlossDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.expanded,
    this.initiallyExpanded = false,
    this.onChanged,
    this.style,
  });

  /// What it is about.
  final String title;

  /// A line under the title.
  final String? subtitle;

  /// What it opens to.
  final Widget child;

  /// Whether it is open, when the caller holds it; null: it holds its own.
  final bool? expanded;

  /// Whether it starts open, when it holds its own.
  final bool initiallyExpanded;

  /// Called with whether it is now open.
  final ValueChanged<bool>? onChanged;

  /// Its own style, over [GlossThemeData.disclosureStyle].
  final GlossStyle? style;

  @override
  State<GlossDisclosure> createState() => _GlossDisclosureState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(
        DiagnosticsProperty<bool>('expanded', expanded, defaultValue: null),
      );
  }
}

class _GlossDisclosureState extends State<GlossDisclosure> {
  late bool _own = widget.initiallyExpanded;

  bool get _open => widget.expanded ?? _own;

  void _toggle() {
    final next = !_open;
    if (widget.expanded == null) setState(() => _own = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignPressable(
          onPressed: _toggle,
          expanded: _open,
          semanticLabel: widget.title,
          builder: (context, states, _) {
            final layered = DesignStyleOf([
              widget.style,
              theme.disclosureStyle,
            ], states);
            final clear = c.page.withValues(alpha: 0);
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: theme.controlHeight + 4),
              child: AnimatedGlossSurface(
                face: GlossFace(
                  top: clear,
                  middle: clear,
                  bottom: clear,
                  foreground: c.ink,
                  radius: GlossMetrics.fieldRadius,
                  focus: glossFocusOf(
                    c,
                    focused: states.contains(WidgetState.focused),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GlossSpacing.tight,
                    vertical: GlossSpacing.small,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.label
                                  .copyWith(color: c.ink)
                                  .merge(layered.textStyle),
                            ),
                            if (widget.subtitle != null)
                              Text(
                                widget.subtitle!,
                                style: theme.textTheme.secondary,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: GlossSpacing.medium),
                      SizedBox.square(
                        dimension: 28,
                        child: AnimatedGlossSurface(
                          face: GlossFace.pearl(c).copyWith(
                            travel: states.contains(WidgetState.pressed)
                                ? 1
                                : 0,
                          ),
                          child: Center(
                            child: GlossChevron(
                              open: _open,
                              color: c.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: still ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.topStart,
            heightFactor: _open ? 1 : 0,
            child: AnimatedOpacity(
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              opacity: _open ? 1 : 0,
              child: ExcludeSemantics(
                excluding: !_open,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GlossSpacing.tight,
                    0,
                    GlossSpacing.tight,
                    GlossSpacing.regular,
                  ),
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.body.copyWith(color: c.inkSecondary),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Disclosures stacked in one well, engraved lines between them.
///
/// ```dart
/// GlossDisclosureGroup(children: [GlossDisclosure(title: 'Storage', child: Text('Three days.')), GlossDisclosure(title: 'Freezing', child: Text('A month.'))])
/// ```
class GlossDisclosureGroup extends StatelessWidget {
  /// A group of [children].
  const GlossDisclosureGroup({super.key, required this.children});

  /// The disclosures.
  final List<GlossDisclosure> children;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    // A group sits in a well below the page (law 3), not on a raised card.
    return GlossSurface(
      face: GlossFace.well(c, radius: GlossMetrics.wellRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GlossSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, d) in children.indexed) ...[
              if (i > 0) const GlossDivider(),
              d,
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('children', children.length));
  }
}

/// A line engraved in the page: a dark cut with the light catching its
/// lower lip. [GlossDivider.vertical] stands upright.
///
/// ```dart
/// const GlossDivider()
/// ```
class GlossDivider extends StatelessWidget {
  /// A level line, [indent] in from its start and [endIndent] from its end.
  const GlossDivider({super.key, this.indent = 0, this.endIndent = 0})
    : _axis = Axis.horizontal;

  /// An upright line.
  const GlossDivider.vertical({super.key, this.indent = 0, this.endIndent = 0})
    : _axis = Axis.vertical;

  /// Room before the line.
  final double indent;

  /// Room after the line.
  final double endIndent;

  final Axis _axis;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final cut = ColoredBox(color: c.hairline);
    final lip = ColoredBox(color: c.lip.withValues(alpha: c.lip.a * 0.8));
    // The cut and the lip stretch across the line: a bare ColoredBox takes
    // the least room it is given, so a loose cross axis would leave the
    // line nothing to paint.
    if (_axis == Axis.vertical) {
      return Padding(
        padding: EdgeInsets.only(top: indent, bottom: endIndent),
        child: LimitedBox(
          maxHeight: 0,
          child: SizedBox(
            width: 2,
            height: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cut),
                Expanded(child: lip),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        height: 2,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cut),
            Expanded(child: lip),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('axis', _axis))
      ..add(DoubleProperty('indent', indent, defaultValue: 0));
  }
}

/// A column of a [GlossTable].
@immutable
class GlossTableColumn {
  /// A column headed [label].
  const GlossTableColumn(this.label, {this.numeric = false, this.flex = 1});

  /// Its heading.
  final String label;

  /// Whether it holds figures: set at its end, in even widths.
  final bool numeric;

  /// Its share of the width.
  final double flex;
}

/// A table of words: a well, the headings letterpressed along its
/// top, the rows parted by engraved lines. Narrower than its columns need,
/// it scrolls sideways.
///
/// ```dart
/// GlossTable(columns: const [GlossTableColumn('Day'), GlossTableColumn('Minutes', numeric: true)], rows: const [['Monday', '35'], ['Tuesday', '20']])
/// ```
class GlossTable extends StatelessWidget {
  /// A table of [rows] under [columns].
  const GlossTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minColumnWidth = 112,
    this.style,
  });

  /// The columns.
  final List<GlossTableColumn> columns;

  /// The rows, a string per column.
  final List<List<String>> rows;

  /// The narrowest a column gets before the table scrolls.
  final double minColumnWidth;

  /// Its own style, over [GlossThemeData.tableStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tableStyle], const {});
    // The rows sit in a well below the page (law 3), not on a raised card.
    var card = GlossFace.well(c, radius: GlossMetrics.wellRadius);
    if (layered.fill != null) card = card.glazed(layered.fill!);
    Widget cell(String text, GlossTableColumn col, {bool head = false}) =>
        Expanded(
          flex: (col.flex * 100).round(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GlossSpacing.medium,
            ),
            child: Text(
              text,
              textAlign: col.numeric ? TextAlign.end : TextAlign.start,
              maxLines: head ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: head
                  ? glossLetterpress(
                      theme.textTheme.caption.copyWith(
                        color: c.inkSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      c,
                    )
                  : theme.textTheme.body
                        .copyWith(
                          color: c.ink,
                          fontFeatures: col.numeric
                              ? const [FontFeature.tabularFigures()]
                              : null,
                        )
                        .merge(layered.textStyle),
            ),
          ),
        );
    return LayoutBuilder(
      builder: (context, box) {
        final need = columns.length * minColumnWidth;
        final width = box.maxWidth.isFinite && box.maxWidth > need
            ? box.maxWidth
            : need;
        final table = SizedBox(
          width: width,
          child: GlossSurface(
            face: card,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GlossSpacing.tight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        for (final col in columns)
                          cell(col.label, col, head: true),
                      ],
                    ),
                  ),
                  for (final row in rows) ...[
                    const GlossDivider(
                      indent: GlossSpacing.medium,
                      endIndent: GlossSpacing.medium,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          for (final (i, col) in columns.indexed)
                            cell(i < row.length ? row[i] : '', col),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
        if (width <= box.maxWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: table,
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

/// One line of a [GlossDescriptionList].
@immutable
class GlossDescription {
  /// [term] and what it is.
  const GlossDescription(this.term, this.detail);

  /// What is described.
  final String term;

  /// What it is.
  final String detail;
}

/// Facts as term and detail, a line each, in a well with engraved lines
/// between: on a phone the detail under its term, wider beside it.
///
/// ```dart
/// GlossDescriptionList(entries: const [GlossDescription('Serves', '4'), GlossDescription('Time', '35 min')])
/// ```
class GlossDescriptionList extends StatelessWidget {
  /// A list of [entries].
  const GlossDescriptionList({super.key, required this.entries});

  /// The lines.
  final List<GlossDescription> entries;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    // The facts are a group, so they sit in a well, the lines between them
    // engraved in its floor.
    return GlossSurface(
      face: GlossFace.well(c, radius: GlossMetrics.wellRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GlossSpacing.medium),
        child: LayoutBuilder(
          builder: (context, box) {
            final beside = box.maxWidth >= 420;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, e) in entries.indexed) ...[
                  if (i > 0) const GlossEngravedLine(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: GlossSpacing.medium,
                    ),
                    child: MergeSemantics(
                      // Beside each other, the term and its detail share a
                      // baseline.
                      child: beside
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                SizedBox(
                                  width: box.maxWidth * 0.36,
                                  child: Text(
                                    e.term,
                                    style: theme.textTheme.secondary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.detail,
                                    style: theme.textTheme.body.copyWith(
                                      color: c.ink,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.term, style: theme.textTheme.secondary),
                                const SizedBox(height: GlossMetrics.lineGap),
                                Text(
                                  e.detail,
                                  style: theme.textTheme.body.copyWith(
                                    color: c.ink,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('entries', entries.length));
  }
}

/// One event of a [GlossTimeline].
@immutable
class GlossTimelineEntry {
  /// An event titled [title].
  const GlossTimelineEntry({
    required this.title,
    this.time,
    this.body,
    this.done = false,
  });

  /// What happened or will.
  final String title;

  /// When, as words.
  final String? time;

  /// More about it.
  final String? body;

  /// Whether it has happened.
  final bool done;
}

/// A timeline: events down a groove pressed into the page, a socket at
/// each; the ones done hold a jade gel bead.
///
/// ```dart
/// GlossTimeline(entries: const [GlossTimelineEntry(title: 'Soak the beans', time: '08:00', done: true), GlossTimelineEntry(title: 'Simmer', time: '18:30')])
/// ```
class GlossTimeline extends StatelessWidget {
  /// A timeline of [entries].
  const GlossTimeline({super.key, required this.entries});

  /// The events, in order.
  final List<GlossTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    const bead = 18.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in entries.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: bead + 8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The socket's room, so a one-line event is no shorter.
                      const SizedBox(height: 4 + bead),
                      // One engraved groove runs from socket to socket,
                      // unbroken behind them: a dark line with the light
                      // caught beside it.
                      if (entries.length > 1)
                        PositionedDirectional(
                          top: i == 0 ? 4 + bead / 2 : 0,
                          bottom: i == entries.length - 1 ? null : 0,
                          height: i == entries.length - 1 ? 4 + bead / 2 : null,
                          start: (bead + 8) / 2 - 1,
                          width: 2,
                          // Stretched: a bare ColoredBox has no height of
                          // its own and would draw nothing.
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: ColoredBox(color: c.hairline)),
                              Expanded(child: ColoredBox(color: c.lip)),
                            ],
                          ),
                        ),
                      // Every node is a socket; a done one holds a jade
                      // bead, as a chosen radio does.
                      PositionedDirectional(
                        top: 4,
                        start: 4,
                        width: bead,
                        height: bead,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GlossSurface(face: GlossFace.well(c)),
                            if (e.done)
                              Padding(
                                padding: const EdgeInsets.all(
                                  GlossSpacing.tight,
                                ),
                                child: GlossSurface(
                                  face: GlossFace.gel(c).copyWith(lift: 0.2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GlossSpacing.medium),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < entries.length - 1 ? GlossSpacing.large : 0,
                    ),
                    child: MergeSemantics(
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
                                  style: theme.textTheme.label.copyWith(
                                    color: e.done ? c.inkSecondary : c.ink,
                                  ),
                                ),
                              ),
                              if (e.time != null)
                                Text(
                                  e.time!,
                                  style: theme.textTheme.caption.copyWith(
                                    color: c.inkSecondary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (e.body != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: GlossMetrics.lineGap,
                              ),
                              child: Text(
                                e.body!,
                                style: theme.textTheme.secondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '';
  final first = parts.first.characters.first;
  final last = parts.length > 1 ? parts.last.characters.first : '';
  return (first + last).toUpperCase();
}

/// An avatar: a round pearl bead with a person's initials, or their
/// picture under a clear lens with the top light on it.
///
/// ```dart
/// const GlossAvatar(name: 'Noa Ferreira')
/// ```
class GlossAvatar extends StatelessWidget {
  /// An avatar for [name].
  const GlossAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = 40,
    this.style,
  });

  /// Whose it is: a screen reader says it, the initials come from it.
  final String name;

  /// Their picture.
  final ImageProvider? image;

  /// Its width and height.
  final double size;

  /// Its own style, over [GlossThemeData.avatarStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.avatarStyle], const {});
    // A face is read, not pressed: a level pearl disc (no lift, no shine
    // across it), apart from the beads a finger meets.
    var face = GlossFace.pearl(c).copyWith(lift: 0, lens: 0);
    if (layered.fill != null) face = face.glazed(layered.fill!);
    return Semantics(
      label: name,
      image: image != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: image == null
            ? GlossSurface(
                face: face.copyWith(foreground: layered.foreground ?? c.ink),
                child: Center(
                  // The initials are the disc's picture, sized to it: they
                  // do not grow with the reader's text size (the name is
                  // what a screen reader says).
                  child: Text(
                    _initials(name),
                    textScaler: TextScaler.noScaling,
                    style: theme.textTheme.label.copyWith(
                      fontSize: size * 0.38,
                      height: 1,
                      color: layered.foreground ?? c.inkSecondary,
                    ),
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipOval(
                    child: Image(
                      image: image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, _) => GlossSurface(
                        face: GlossFace.pearl(c).copyWith(lift: 0, lens: 0),
                      ),
                    ),
                  ),
                  // The lens: clear glass over the picture, rim and sheen.
                  GlossSurface(
                    face: GlossFace(
                      top: const Color(0x00FFFFFF),
                      middle: const Color(0x00FFFFFF),
                      bottom: const Color(0x00FFFFFF),
                      edge: c.pearlEdge,
                      foreground: c.ink,
                      lens: 0.55,
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
      ..add(StringProperty('name', name))
      ..add(DoubleProperty('size', size));
  }
}

/// Avatars overlapping in a row, each ringed in the page's colour, the
/// ones past [max] counted on a last pearl bead.
///
/// ```dart
/// const GlossAvatarGroup(avatars: [GlossAvatar(name: 'Noa Ferreira'), GlossAvatar(name: 'Ivo Matos')])
/// ```
class GlossAvatarGroup extends StatelessWidget {
  /// A group of [avatars].
  const GlossAvatarGroup({
    super.key,
    required this.avatars,
    this.max = 4,
    this.size = 40,
  });

  /// The avatars.
  final List<GlossAvatar> avatars;

  /// How many show before the rest are counted.
  final int max;

  /// Each one's size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final shown = avatars.take(max).toList();
    final rest = avatars.length - shown.length;
    // Each tucks under the next by an eighth: the next one's ring stops
    // short of the initials, so every face still reads.
    final step = size * 0.875;
    final count = shown.length + (rest > 0 ? 1 : 0);
    Widget ringed(Widget child) => Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(GlossMetrics.rimRoom),
      decoration: ShapeDecoration(shape: const CircleBorder(), color: c.page),
      child: child,
    );
    return Semantics(
      label: avatars.map((a) => a.name).join(', '),
      excludeSemantics: true,
      child: SizedBox(
        height: size + 4,
        width: count == 0 ? 0 : step * (count - 1) + size + 4,
        child: Stack(
          children: [
            for (final (i, a) in shown.indexed)
              PositionedDirectional(
                start: step * i,
                top: 0,
                child: ringed(
                  GlossAvatar(name: a.name, image: a.image, size: size),
                ),
              ),
            if (rest > 0)
              PositionedDirectional(
                start: step * shown.length,
                top: 0,
                // Level, as the faces it follows.
                child: ringed(
                  GlossSurface(
                    face: GlossFace.pearl(c).copyWith(lift: 0, lens: 0),
                    child: Center(
                      child: Text(
                        '+$rest',
                        textScaler: TextScaler.noScaling,
                        style: theme.textTheme.caption.copyWith(
                          color: c.inkSecondary,
                          fontWeight: FontWeight.w600,
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
      ..add(IntProperty('avatars', avatars.length))
      ..add(IntProperty('max', max));
  }
}

/// A badge: a small ruby gel bead with a count, set on [child]'s top end
/// corner (or alone). Past [max] it reads max+.
///
/// ```dart
/// GlossBadge(count: 3, child: Icon(LucideIcons.bell))
/// ```
class GlossBadge extends StatelessWidget {
  /// A badge counting [count].
  const GlossBadge({
    super.key,
    required this.count,
    this.child,
    this.max = 99,
    this.semanticLabel,
    this.style,
  });

  /// What it counts; 0 hides the bead.
  final int count;

  /// What it sits on.
  final Widget? child;

  /// The most it shows.
  final int max;

  /// What a screen reader says; null: the count.
  final String? semanticLabel;

  /// Its own style, over [GlossThemeData.badgeStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.badgeStyle], const {});
    var face = GlossFace.ruby(c).copyWith(lift: 0.6);
    if (layered.fill != null) face = face.glazed(layered.fill!);
    final words = count > max ? '$max+' : '$count';
    final bead = Semantics(
      label: semanticLabel ?? words,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        child: GlossSurface(
          face: face.copyWith(foreground: layered.foreground ?? c.onDanger),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GlossSpacing.tight + GlossMetrics.rimRoom,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                words,
                style: theme.textTheme.caption.copyWith(
                  color: layered.foreground ?? c.onDanger,
                  fontWeight: FontWeight.w700,
                  fontVariations: glossWeightAxis(FontWeight.w700),
                  height: 20 / 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (child == null) return count > 0 ? bead : const SizedBox.shrink();
    if (count == 0) return child!;
    // The bead starts a little inside what it sits on, at its top end, and
    // runs outward: however wide the count, the icon under it still reads.
    // A point 10 px in from what it sits on's top end, 8 px above it; the
    // bead hangs from it outward (an OverflowBox on a box of no size).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        PositionedDirectional(
          top: -8,
          end: 10,
          width: 0,
          height: 0,
          child: OverflowBox(
            alignment: AlignmentDirectional.topStart,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: bead,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('max', max));
  }
}

/// A tag's glaze.
enum GlossTagTone {
  /// Pearl, second ink: a plain fact.
  neutral,

  /// Pale jade: something good or chosen.
  jade,

  /// Pale ruby: something to watch.
  danger,
}

/// A tag: a small level enamel capsule naming a fact about a thing (Vegetarian,
/// 3 left).
///
/// ```dart
/// const GlossTag('Vegetarian', tone: GlossTagTone.jade)
/// ```
class GlossTag extends StatelessWidget {
  /// A tag reading [label].
  const GlossTag(
    this.label, {
    super.key,
    this.tone = GlossTagTone.neutral,
    this.icon,
    this.style,
  });

  /// Its words.
  final String label;

  /// Its glaze.
  final GlossTagTone tone;

  /// A glyph before the words.
  final IconData? icon;

  /// Its own style, over [GlossThemeData.tagStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tagStyle], const {});
    final light = c.brightness == Brightness.light;
    var face = switch (tone) {
      // A plain tag is enamel in the page's own grey, as the toned ones are
      // in theirs: never a pearl, which a finger would reach for.
      GlossTagTone.neutral => GlossFace.pearl(
        c,
      ).glazed(light ? const Color(0xFFE4E8ED) : const Color(0xFF2B3036)),
      GlossTagTone.jade => GlossFace.pearl(
        c,
      ).glazed(light ? const Color(0xFFD5F2E6) : const Color(0xFF1F4A3C)),
      GlossTagTone.danger => GlossFace.pearl(
        c,
      ).glazed(light ? const Color(0xFFF8DEDD) : const Color(0xFF55282A)),
    };
    if (layered.fill != null) face = face.glazed(layered.fill!);
    final ink =
        layered.foreground ??
        switch (tone) {
          GlossTagTone.neutral => c.inkSecondary,
          GlossTagTone.jade => c.jadeInk,
          GlossTagTone.danger => c.danger,
        };
    // A tag is read, not pressed: a level enamel label on the surface, no
    // lift and no shine across its words (only what a finger meets stands
    // up glossy).
    // 26 high at most sizes; large words make it taller, never clipped.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26),
      child: GlossSurface(
        face: face.copyWith(foreground: ink, lift: 0, lens: 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 2,
            horizontal: GlossSpacing.small + GlossMetrics.rimRoom,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: ink),
                const SizedBox(width: GlossSpacing.tight),
              ],
              DesignCapCenter(
                capHeightFactor: glossCapHeightFactor,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.caption
                      .copyWith(color: ink, fontWeight: FontWeight.w600)
                      .merge(layered.textStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<GlossTagTone>('tone', tone));
  }
}

/// A picture set in a sunken frame, the top light glazing it; with no
/// picture yet, the frame's floor with a picture glyph pressed into it.
///
/// ```dart
/// const GlossMedia(image: null, semanticLabel: 'Lemon risotto in a bowl')
/// ```
class GlossMedia extends StatelessWidget {
  /// A frame for [image].
  const GlossMedia({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.radius = GlossMetrics.cardRadius,
  });

  /// The picture; null: the empty frame.
  final ImageProvider? image;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// Its width over its height.
  final double aspectRatio;

  /// How the picture fills the frame.
  final BoxFit fit;

  /// The frame's corner.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final empty = Center(
      child: Icon(
        LucideIcons.image,
        size: 28,
        color: c.inkSecondary.withValues(alpha: 0.6),
        shadows: [
          Shadow(
            color: c.letterpress,
            offset: Offset(0, c.letterpressBelow ? 1 : -1),
          ),
        ],
      ),
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: GlossSurface(
          face: GlossFace.well(c, radius: radius),
          child: Padding(
            padding: const EdgeInsets.all(GlossMetrics.frameRim),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 3),
              child: image == null
                  ? empty
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image(
                          image: image!,
                          fit: fit,
                          errorBuilder: (context, _, _) => empty,
                        ),
                        // The glaze: a faint sheen across the picture's top.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(DoubleProperty('aspectRatio', aspectRatio));
  }
}

/// A skeleton: a shallow well where words or a picture will be, a soft
/// sheen passing along it while it waits (still under Reduce Motion).
///
/// ```dart
/// const GlossSkeleton(width: 200)
/// ```
class GlossSkeleton extends StatefulWidget {
  /// A skeleton [width] by [height].
  const GlossSkeleton({super.key, this.width, this.height = 16, this.radius});

  /// Its width; null: the room it has.
  final double? width;

  /// Its height.
  final double height;

  /// Its corner; null: a capsule.
  final double? radius;

  @override
  State<GlossSkeleton> createState() => _GlossSkeletonState();
}

class _GlossSkeletonState extends State<GlossSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ticking = TickerMode.valuesOf(context).enabled;
    if (still || !ticking) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final well = GlossFace.well(c, radius: widget.radius).copyWith(lift: -0.5);
    final light = c.brightness == Brightness.light;
    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: GlossSurface(
          face: well,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              widget.radius ?? widget.height / 2,
            ),
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-3 + 6 * _sweep.value, 0),
                    end: Alignment(-1 + 6 * _sweep.value, 0),
                    colors: [
                      const Color(0x00FFFFFF),
                      light ? const Color(0x59FFFFFF) : const Color(0x14FFFFFF),
                      const Color(0x00FFFFFF),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A meter: how full something is, as jade gel standing in a groove, turning
/// ruby past [high]. Its label and value read above it.
///
/// ```dart
/// const GlossMeter(value: 0.6, label: 'Pantry space')
/// ```
class GlossMeter extends StatelessWidget {
  /// A meter at [value] of [max].
  const GlossMeter({
    super.key,
    required this.value,
    required this.label,
    this.max = 1,
    this.high,
    this.valueText,
    this.style,
  });

  /// How full.
  final double value;

  /// What it measures.
  final String label;

  /// Full.
  final double max;

  /// Past this the gel turns ruby; null: never.
  final double? high;

  /// The value as words; null: a percentage.
  final String? valueText;

  /// Its own style, over [GlossThemeData.meterStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.meterStyle], const {});
    final share = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final over = high != null && value > high!;
    final said = valueText ?? '${(share * 100).round()}%';
    var gel = over ? GlossFace.ruby(c) : GlossFace.gel(c);
    if (layered.fill != null) gel = gel.glazed(layered.fill!);
    return Semantics(
      label: label,
      value: said,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.label.copyWith(color: c.ink),
                ),
              ),
              Text(
                said,
                style: theme.textTheme.secondary.copyWith(
                  color: over ? c.danger : c.inkSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: GlossSpacing.small),
          SizedBox(
            height: 14,
            child: GlossSurface(
              face: GlossFace.well(c),
              child: Padding(
                padding: const EdgeInsets.all(GlossMetrics.rimRoom),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: share),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => FractionallySizedBox(
                      widthFactor: t,
                      heightFactor: 1,
                      child: t <= 0.001
                          ? null
                          : AnimatedGlossSurface(
                              face: gel.copyWith(lift: 0, lens: 0.65),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(DoubleProperty('max', max))
      ..add(StringProperty('label', label));
  }
}
