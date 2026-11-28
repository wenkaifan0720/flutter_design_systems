/// Clay's display parts: disclosures, a plain table, a description list, a
/// timeline, avatars, a count badge, tags, media, skeletons, a meter, a
/// banner and the state views (empty, error, loading, done).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'feedback.dart' show ClaySpinner;
import 'fonts.dart';
import 'internal/corners.dart';
import 'internal/menu.dart' show ClayChevronPainter;
import 'internal/spring.dart';
import 'internal/words_fit.dart';
import 'lists.dart' show ClayGroove;
import 'surface.dart';
import 'theme.dart';

/// A section that opens and closes: its title and a chevron on a row that
/// dents under a press; what it holds slides open under it on a spring.
/// Alone it is a clay card; in a [ClayDisclosureGroup] the group is.
///
/// ```dart
/// ClayDisclosure(title: 'Why it matters', child: const Text('A glass before coffee.'))
/// ```
class ClayDisclosure extends StatefulWidget {
  /// A disclosure titled [title] holding [child].
  const ClayDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.style,
  });

  /// Its title.
  final String title;

  /// What it holds.
  final Widget child;

  /// A line under the title.
  final String? subtitle;

  /// Whether it is open, when the caller keeps it; null: it keeps its own.
  final bool? expanded;

  /// Whether it starts open, when it keeps its own.
  final bool initiallyExpanded;

  /// It opened (true) or closed.
  final ValueChanged<bool>? onExpansionChanged;

  /// This disclosure's own style, over [ClayThemeData.disclosureStyle]:
  /// `fill` the card.
  final ClayStyle? style;

  @override
  State<ClayDisclosure> createState() => _ClayDisclosureState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('expanded', value: expanded, ifTrue: 'expanded'));
  }
}

class _ClayDisclosureState extends State<ClayDisclosure> {
  late bool _open = widget.expanded ?? widget.initiallyExpanded;

  bool get _expanded => widget.expanded ?? _open;

  void _toggle() {
    final next = !_expanded;
    if (widget.expanded == null) setState(() => _open = next);
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final grouped = _InGroup.of(context);
    final layered = RawStyleOf(
      [widget.style, theme.disclosureStyle],
      {if (_expanded) WidgetState.selected},
    );
    final open = _expanded;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RawButton(
          onPressed: _toggle,
          expanded: open,
          semanticLabel: widget.title,
          semanticHint: widget.subtitle,
          builder: (context, states, _) {
            final pressed = states.contains(WidgetState.pressed);
            final hovered = states.contains(WidgetState.hovered);
            final well = ClayFace.well(
              c,
              radius: theme.shapeScheme.corners.medium,
            );
            final show = pressed ? 1.0 : (hovered ? 0.4 : 0.0);
            return Padding(
              padding: const EdgeInsets.all(ClaySpacing.tight),
              child: AnimatedClaySurface(
                face: well.copyWith(
                  color: well.color.withValues(alpha: well.color.a * show),
                  lightOpacity: well.lightOpacity * show,
                  shadeOpacity: well.shadeOpacity * show,
                  focus: states.contains(WidgetState.focused) ? 1 : 0,
                  focusColor: c.focus,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: theme.rowHeight - 8),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: ClaySpacing.medium,
                      end: ClaySpacing.medium,
                      top: ClaySpacing.small,
                      bottom: ClaySpacing.small,
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
                                style: theme.textTheme.label.copyWith(
                                  color: layered.foreground ?? c.ink,
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
                        const SizedBox(width: ClaySpacing.small),
                        ClaySpring(
                          target: open ? 1 : 0,
                          builder: (context, t) => SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(
                              painter: ClayChevronPainter(
                                c.inkSecondary,
                                t.clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ClaySpring(
          target: open ? 1 : 0,
          damping: ClayMotion.panelDamping,
          stiffness: ClayMotion.panelStiffness,
          builder: (context, t) {
            final shown = t.clamp(0.0, 1.0);
            if (!open && shown < 0.002) return const SizedBox.shrink();
            return ExcludeFocus(
              excluding: !open,
              child: ExcludeSemantics(
                excluding: !open,
                child: ClipRect(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    heightFactor: shown,
                    child: Opacity(
                      opacity: shown,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          ClaySpacing.regular,
                          ClaySpacing.tight,
                          ClaySpacing.regular,
                          ClaySpacing.regular,
                        ),
                        child: DefaultTextStyle.merge(
                          style: theme.textTheme.body.copyWith(color: c.ink),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
    if (grouped) return body;
    return ClaySurface(
      face: ClayFace.raised(
        c,
        color: layered.fill,
        radius: clayCornerRadius(theme, layered, RawCorner.large),
      ),
      child: body,
    );
  }
}

class _InGroup extends InheritedWidget {
  const _InGroup({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InGroup>() != null;

  @override
  bool updateShouldNotify(_InGroup old) => false;
}

/// Disclosures on one clay card, a groove between each.
///
/// ```dart
/// ClayDisclosureGroup(children: [ClayDisclosure(title: 'Reminders', child: const Text('Each habit sets its own.'))])
/// ```
class ClayDisclosureGroup extends StatelessWidget {
  /// A card of [children].
  const ClayDisclosureGroup({super.key, required this.children, this.style});

  /// The disclosures.
  final List<Widget> children;

  /// This group's own style, over [ClayThemeData.disclosureStyle]: `fill`
  /// the card.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final layered = RawStyleOf([style, theme.disclosureStyle], const {});
    return ClaySurface(
      face: ClayFace.raised(
        theme.colors,
        color: layered.fill,
        radius: clayCornerRadius(theme, layered, RawCorner.large),
      ),
      child: _InGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0)
                const ClayGroove(
                  indent: ClaySpacing.regular,
                  endIndent: ClaySpacing.regular,
                ),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// A column of a [ClayTable].
@immutable
class ClayTableColumn {
  /// A column headed [label].
  const ClayTableColumn(this.label, {this.numeric = false, this.flex = 1});

  /// Its heading.
  final String label;

  /// Whether it holds figures: they stand at its end, in even widths.
  final bool numeric;

  /// Its share of the width.
  final int flex;
}

/// A plain table on a clay card: headings, then rows between soft grooves.
/// Narrower than [minColumnWidth] a column, it scrolls sideways.
///
/// ```dart
/// ClayTable(columns: const [ClayTableColumn('Habit'), ClayTableColumn('Streak', numeric: true)], rows: const [['Walk', '12'], ['Read', '4']])
/// ```
class ClayTable extends StatelessWidget {
  /// A table of [rows] under [columns].
  const ClayTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minColumnWidth = 96,
    this.style,
  });

  /// The columns.
  final List<ClayTableColumn> columns;

  /// The rows, a cell's words per column.
  final List<List<String>> rows;

  /// The narrowest a column may be before the table scrolls.
  final double minColumnWidth;

  /// This table's own style, over [ClayThemeData.tableStyle]: `fill` the
  /// card.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.tableStyle], const {});
    final headStyle = theme.textTheme.caption.copyWith(
      color: c.inkSecondary,
      fontWeight: FontWeight.w600,
      fontVariations: clayWeight(FontWeight.w600),
    );
    TextStyle bodyStyle(ClayTableColumn col) => theme.textTheme.body.copyWith(
      color: c.ink,
      fontFeatures: col.numeric ? const [FontFeature.tabularFigures()] : null,
    );
    Widget row(List<String> cells, {required bool head}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClaySpacing.small),
      child: Row(
        children: [
          for (final (i, col) in columns.indexed)
            Expanded(
              flex: col.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClaySpacing.small,
                  vertical: ClaySpacing.medium,
                ),
                child: Text(
                  i < cells.length ? cells[i] : '',
                  textAlign: col.numeric ? TextAlign.end : TextAlign.start,
                  style: head ? headStyle : bodyStyle(col),
                ),
              ),
            ),
        ],
      ),
    );
    final table = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          child: row([for (final col in columns) col.label], head: true),
        ),
        for (final cells in rows) ...[
          const ClayGroove(
            indent: ClaySpacing.regular,
            endIndent: ClaySpacing.regular,
          ),
          Semantics(container: true, child: row(cells, head: false)),
        ],
      ],
    );
    return ClaySurface(
      face: ClayFace.raised(
        c,
        color: layered.fill,
        radius: clayCornerRadius(theme, layered, RawCorner.large),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ClaySpacing.small),
        child: LayoutBuilder(
          builder: (context, box) {
            // Each column as wide as its widest word (large text on a phone),
            // a figure whole ("6 of 7" on one line), and [minColumnWidth]:
            // narrower, the table scrolls rather than break a word or a
            // figure, as a Material table scrolls.
            final shares = columns.fold(0, (sum, col) => sum + col.flex);
            var least = columns.length * minColumnWidth;
            for (final (i, col) in columns.indexed) {
              final word = math.max(
                clayWidestWord(context, [col.label], headStyle),
                clayWidestWord(
                  context,
                  [
                    for (final cells in rows)
                      if (i < cells.length) cells[i],
                  ],
                  bodyStyle(col),
                  whole: col.numeric,
                ),
              );
              least = math.max(
                least,
                // A pixel spare: text widths round, and a figure a hair too
                // wide breaks.
                (word + 1 + 2 * ClaySpacing.small) *
                    shares /
                    math.max(1, col.flex),
              );
            }
            least += 2 * ClaySpacing.small;
            if (!box.hasBoundedWidth || box.maxWidth >= least) return table;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: least, child: table),
            );
          },
        ),
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

/// One pair of a [ClayDescriptionList].
@immutable
class ClayDescription {
  /// [term], described by [description].
  const ClayDescription(this.term, this.description);

  /// What is described.
  final String term;

  /// What it is.
  final String description;
}

/// Terms and what they are, between soft grooves: side by side where there
/// is room, the term over its description where there is not.
///
/// ```dart
/// ClayDescriptionList(entries: const [ClayDescription('Started', '2 November'), ClayDescription('Best streak', '21 days')])
/// ```
class ClayDescriptionList extends StatelessWidget {
  /// A list of [entries].
  const ClayDescriptionList({super.key, required this.entries, this.style});

  /// The pairs, in order.
  final List<ClayDescription> entries;

  /// This list's own style, over [ClayThemeData.descriptionListStyle]:
  /// `foreground` the descriptions, `textStyle` their words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.descriptionListStyle], const {});
    final said = theme.textTheme.body
        .merge(layered.textStyle)
        .copyWith(color: layered.foreground ?? c.ink);
    return LayoutBuilder(
      builder: (context, box) {
        final wide = !box.hasBoundedWidth || box.maxWidth >= 360;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, e) in entries.indexed) ...[
              if (i > 0) const ClayGroove(),
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: ClaySpacing.medium,
                  ),
                  child: wide
                      ? Row(
                          // The term and its description on one baseline.
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                e.term,
                                style: theme.textTheme.secondary,
                              ),
                            ),
                            const SizedBox(width: ClaySpacing.regular),
                            Expanded(
                              flex: 3,
                              child: Text(e.description, style: said),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.term, style: theme.textTheme.secondary),
                            const SizedBox(height: ClaySpacing.hairline),
                            Text(e.description, style: said),
                          ],
                        ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('entries', entries.length));
  }
}

/// One event of a [ClayTimeline].
@immutable
class ClayTimelineEntry {
  /// An event titled [title].
  const ClayTimelineEntry({
    required this.title,
    this.time,
    this.body,
    this.done = true,
  });

  /// What happened.
  final String title;

  /// When, in the reader's words.
  final String? time;

  /// More about it.
  final String? body;

  /// Whether it has happened: a coral ball; else a cup still to fill.
  final bool done;
}

/// Events down a soft groove: each a ball on the groove (coral once done, a
/// cup before), its title, time and words beside it.
///
/// ```dart
/// ClayTimeline(entries: const [ClayTimelineEntry(title: 'Started Drink water', time: '2 Nov'), ClayTimelineEntry(title: 'First week kept', time: '9 Nov')])
/// ```
class ClayTimeline extends StatelessWidget {
  /// A timeline of [entries], oldest first.
  const ClayTimeline({super.key, required this.entries, this.style});

  /// The events.
  final List<ClayTimelineEntry> entries;

  /// This timeline's own style, over [ClayThemeData.timelineStyle]: `fill`
  /// the balls of events done.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.timelineStyle], const {});
    final fill = layered.fill ?? c.accent;
    const ball = 20.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in entries.indexed)
          MergeSemantics(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 32,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        if (i < entries.length - 1)
                          Positioned(
                            top: ball + 4,
                            bottom: 0,
                            child: SizedBox(
                              width: 4,
                              child: ClaySurface(
                                face: ClayFace.well(
                                  c,
                                  color: Color.lerp(c.well, c.track, 0.4),
                                  radius: 2,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: ClaySpacing.hairline,
                          ),
                          child: SizedBox.square(
                            dimension: ball,
                            child: ClaySurface(
                              face: e.done
                                  ? ClayFace.raised(
                                      c,
                                      color: fill,
                                      radius: ball / 2,
                                    ).copyWith(elevation: 0.6)
                                  : ClayFace.well(
                                      c,
                                      color: c.track,
                                      radius: ball / 2,
                                    ),
                              child: e.done
                                  ? Icon(
                                      LucideIcons.check,
                                      size: 12,
                                      color: c.onColor(fill),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ClaySpacing.medium),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < entries.length - 1 ? ClaySpacing.large : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: theme.textTheme.label.copyWith(color: c.ink),
                          ),
                          if (e.time != null)
                            Text(e.time!, style: theme.textTheme.caption),
                          if (e.body != null) ...[
                            const SizedBox(height: ClaySpacing.tight),
                            Text(e.body!, style: theme.textTheme.secondary),
                          ],
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
    properties.add(IntProperty('entries', entries.length));
  }
}

/// [name]'s initials, one or two.
String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = [for (final w in words.take(2)) w.characters.first];
  return letters.join().toUpperCase();
}

/// A person as a ball of tinted clay: their picture set in it, or their
/// initials on a pastel picked from their name.
///
/// ```dart
/// const ClayAvatar(name: 'Mia Okafor')
/// ```
class ClayAvatar extends StatelessWidget {
  /// [name]'s avatar.
  const ClayAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = 40,
    this.tint,
    this.style,
  });

  /// Who it is: said to a screen reader, and their initials.
  final String name;

  /// Their picture.
  final ImageProvider? image;

  /// Its side.
  final double size;

  /// Its pastel; null: one picked from [name].
  final ClayTint? tint;

  /// This avatar's own style, over [ClayThemeData.avatarStyle]: `fill` the
  /// ball.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.avatarStyle], const {});
    final picked =
        tint ??
        ClayTint.values[name.codeUnits.fold<int>(0, (a, b) => a + b) %
            ClayTint.values.length];
    final fill = layered.fill ?? c.tint(picked);
    return Semantics(
      label: name,
      image: image != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: ClaySurface(
          face: ClayFace.raised(
            c,
            color: fill,
            radius: size / 2,
          ).copyWith(elevation: 0.6),
          child: image != null
              ? Padding(
                  padding: EdgeInsets.all(size * 0.06),
                  child: ClipOval(
                    child: Image(image: image!, fit: BoxFit.cover),
                  ),
                )
              // The initials keep their size at any text size, as Material's
              // CircleAvatar keeps them: the ball is fixed, and letters grown
              // with the text would break and spill out of it.
              : Center(
                  child: MediaQuery.withNoTextScaling(
                    child: Text(
                      _initials(name),
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.label.copyWith(
                        color: layered.foreground ?? c.onColor(fill),
                        fontSize: size * 0.38,
                        height: 1,
                      ),
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
      ..add(StringProperty('name', name))
      ..add(DoubleProperty('size', size));
  }
}

/// Avatars overlapping in a row, each ringed in the ground so they part;
/// past [max], one ball counts the rest.
///
/// ```dart
/// ClayAvatarGroup(avatars: const [ClayAvatar(name: 'Mia'), ClayAvatar(name: 'Sam'), ClayAvatar(name: 'Lee')])
/// ```
class ClayAvatarGroup extends StatelessWidget {
  /// A row of [avatars].
  const ClayAvatarGroup({
    super.key,
    required this.avatars,
    this.max = 4,
    this.size = 36,
    this.style,
  });

  /// The people.
  final List<ClayAvatar> avatars;

  /// How many show before the count.
  final int max;

  /// Each ball's side.
  final double size;

  /// This group's own style, over [ClayThemeData.avatarGroupStyle]: `edge`
  /// the ring round each face (the ground's colour by default), `fill` the
  /// ball that counts the rest, `foreground` its words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.avatarGroupStyle], const {});
    final shown = avatars.take(max).toList();
    final rest = avatars.length - shown.length;
    // Each face over a sixth of the one before: enough to read as a group,
    // little enough that initials stay whole.
    final step = size * 0.84;
    final count = shown.length + (rest > 0 ? 1 : 0);
    Widget ring(Widget child) => Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(ClaySpacing.hairline),
      decoration: ShapeDecoration(
        shape: const CircleBorder(),
        color: layered.edge ?? c.ground,
      ),
      child: child,
    );
    return Semantics(
      label: [for (final a in avatars) a.name].join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: step * (count - 1) + size + 4,
        height: size + 4,
        child: Stack(
          children: [
            for (final (i, a) in shown.indexed)
              PositionedDirectional(
                start: step * i,
                child: ring(
                  ClayAvatar(
                    name: a.name,
                    image: a.image,
                    tint: a.tint,
                    size: size,
                  ),
                ),
              ),
            if (rest > 0)
              PositionedDirectional(
                start: step * shown.length,
                child: ring(
                  SizedBox.square(
                    dimension: size,
                    child: ClaySurface(
                      face: ClayFace.raised(
                        c,
                        color: layered.fill,
                        radius: size / 2,
                      ),
                      // The count keeps its size, as a face's initials do.
                      child: Center(
                        child: MediaQuery.withNoTextScaling(
                          child: Text(
                            '+$rest',
                            maxLines: 1,
                            softWrap: false,
                            style: theme.textTheme.caption.copyWith(
                              color: layered.foreground ?? c.ink,
                              fontWeight: FontWeight.w600,
                              fontVariations: clayWeight(FontWeight.w600),
                            ),
                          ),
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
}

/// A count on a small raised coral pill: alone, or over [child]'s top end
/// corner. Past [max] it reads "99+"; at 0 it hides.
///
/// ```dart
/// const ClayBadge(count: 3, child: Icon(IconData(0x1F514)))
/// ```
class ClayBadge extends StatelessWidget {
  /// A badge of [count].
  const ClayBadge({
    super.key,
    required this.count,
    this.child,
    this.maxCount = 99,
    this.semanticLabel,
    this.style,
  });

  /// The number.
  final int count;

  /// What it sits on.
  final Widget? child;

  /// The most it shows before "+".
  final int maxCount;

  /// What a screen reader says; null: "[count] new".
  final String? semanticLabel;

  /// This badge's own style, over [ClayThemeData.badgeStyle]: `fill` the
  /// pill.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.badgeStyle], const {});
    final fill = layered.fill ?? c.accent;
    final words = count > maxCount ? '$maxCount+' : '$count';
    final pill = count <= 0
        ? null
        : ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20),
            child: SizedBox(
              height: 20,
              child: ClaySurface(
                face: ClayFace.raised(
                  c,
                  color: fill,
                  radius: 10,
                ).copyWith(elevation: 0.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClaySpacing.tight,
                  ),
                  child: Center(
                    widthFactor: 1,
                    // The count grows with the text up to 1.3 times, as
                    // Material's NavigationBar caps its labels: past that a
                    // count would outgrow the small mark it is.
                    child: Text(
                      words,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.3),
                      style: theme.textTheme.caption.copyWith(
                        color: layered.foreground ?? c.onColor(fill),
                        fontWeight: FontWeight.w600,
                        fontVariations: clayWeight(FontWeight.w600),
                        fontSize: 11,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
    final said = semanticLabel ?? '$count new';
    if (child == null) {
      return pill == null
          ? const SizedBox.shrink()
          : Semantics(label: said, excludeSemantics: true, child: pill);
    }
    return Semantics(
      label: count > 0 ? said : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          // The pill starts 12 inside the part's top end corner and a longer
          // count runs on past it, as Material's Badge grows: the part it
          // marks stays in sight.
          if (pill != null)
            PositionedDirectional(
              top: -6,
              end: 12,
              width: 0,
              height: 20,
              child: OverflowBox(
                alignment: AlignmentDirectional.centerStart,
                maxWidth: double.infinity,
                child: ExcludeSemantics(child: pill),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', count));
  }
}

/// The colour a [ClayTag] says itself in.
enum ClayTagTone {
  /// Plain clay.
  neutral,

  /// The accent: new, chosen.
  accent,

  /// Done, kept.
  success,

  /// Wrong, behind.
  danger,
}

/// A tag: a short word on a small pill pressed into the clay, tinted by its
/// [tone]; the word says it too.
///
/// ```dart
/// const ClayTag('Morning')
/// ```
class ClayTag extends StatelessWidget {
  /// A tag reading [label].
  const ClayTag(
    this.label, {
    super.key,
    this.tone = ClayTagTone.neutral,
    this.icon,
    this.style,
  });

  /// Its word.
  final String label;

  /// Its tint.
  final ClayTagTone tone;

  /// A glyph before the word.
  final IconData? icon;

  /// This tag's own style, over [ClayThemeData.tagStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.tagStyle], const {});
    final (hue, ink) = switch (tone) {
      ClayTagTone.neutral => (c.track, c.inkSecondary),
      ClayTagTone.accent => (c.accent, c.accentInk),
      ClayTagTone.success => (c.success, c.ink),
      ClayTagTone.danger => (c.danger, c.dangerInk),
    };
    // A status takes a third of its tone, so the four stand apart in every
    // palette (Mint's accent and success are both green).
    final fill =
        layered.fill ??
        Color.lerp(c.well, hue, tone == ClayTagTone.neutral ? 0.3 : 0.34)!;
    // The word is read: its tone's ink, as dark (or as light) as reading on
    // the tag's fill takes, with a hair to spare for the well's inner shade,
    // which darkens the ground under the word a little.
    final words =
        layered.foreground ??
        RawPalette.readableTone(ink, on: [fill], ratio: 4.6);
    // 26 high, and taller with a large text size, as Material's chips grow:
    // the word is never cut. Any height is a pill.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26),
      child: ClaySurface(
        face: ClayFace.well(
          c,
          color: fill,
          radius: 999,
        ).copyWith(shadeOpacity: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClaySpacing.small + 2,
            vertical: ClaySpacing.tight,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                // The glyph grows with its word.
                Icon(
                  icon,
                  size: MediaQuery.textScalerOf(context).scale(14),
                  color: words,
                ),
                const SizedBox(width: ClaySpacing.tight),
              ],
              RawCapCenter(
                capHeightFactor: clayCapHeightFactor,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.caption
                      .copyWith(
                        color: words,
                        fontWeight: FontWeight.w600,
                        fontVariations: clayWeight(FontWeight.w600),
                      )
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
      ..add(EnumProperty<ClayTagTone>('tone', tone));
  }
}

/// A picture set into the clay: a well with rounded corners round it, a
/// quiet glyph in its place while it loads or if it cannot.
///
/// ```dart
/// const ClayMedia(image: AssetImage('images/walk.jpg'), semanticLabel: 'A path through birch trees')
/// ```
class ClayMedia extends StatelessWidget {
  /// [image], said as [semanticLabel]; with no image yet, its frame.
  const ClayMedia({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.aspectRatio = 4 / 3,
    this.fit = BoxFit.cover,
    this.radius,
    this.style,
  });

  /// The picture; null: the frame and its glyph alone.
  final ImageProvider? image;

  /// What it shows, for a screen reader; '' for a picture that only
  /// decorates.
  final String semanticLabel;

  /// Its shape.
  final double aspectRatio;

  /// How it fills its frame.
  final BoxFit fit;

  /// Its corners; null, the theme's large step ([RawCorner.large] of
  /// [ClayThemeData.shapeScheme]).
  final double? radius;

  /// Its own style, over [ClayThemeData.mediaStyle]: `fill` the frame's
  /// well, `foreground` the glyph shown while there is no picture, `shape`
  /// its corners (over [radius]).
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.mediaStyle], const {});
    final radius = clayCornerRadius(
      theme,
      layered,
      RawCorner.large,
      own: this.radius,
    );
    final blank = Center(
      child: Icon(
        LucideIcons.image,
        size: 28,
        color: layered.foreground ?? c.inkDisabled,
      ),
    );
    return Semantics(
      image: semanticLabel.isNotEmpty,
      label: semanticLabel.isEmpty ? null : semanticLabel,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClaySurface(
          face: ClayFace.well(c, color: layered.fill, radius: radius),
          child: Padding(
            padding: const EdgeInsets.all(ClaySpacing.tight),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(math.max(0, radius - 4)),
              child: image == null
                  ? blank
                  : Image(
                      image: image!,
                      fit: fit,
                      width: double.infinity,
                      height: double.infinity,
                      frameBuilder: (context, child, frame, sync) =>
                          sync || frame != null ? child : blank,
                      errorBuilder: (context, error, stack) => blank,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A place holding the shape of what is loading: a soft cup that breathes
/// slowly (still under Reduce Motion).
///
/// ```dart
/// const ClaySkeleton(width: 160, height: 16)
/// ```
class ClaySkeleton extends StatefulWidget {
  /// A skeleton [width] by [height]; null width spans its parent.
  const ClaySkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius,
    this.style,
  });

  /// Its width; null spans its parent.
  final double? width;

  /// Its height.
  final double height;

  /// Its corners; null: half its height.
  final double? radius;

  /// Its own style, over [ClayThemeData.skeletonStyle]: `fill` the deeper
  /// end of its breath.
  final ClayStyle? style;

  @override
  State<ClaySkeleton> createState() => _ClaySkeletonState();
}

class _ClaySkeletonState extends State<ClaySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _breath.value = 0.5;
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([widget.style, theme.skeletonStyle], const {});
    final base = layered.fill ?? Color.lerp(c.well, c.track, 0.25)!;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, _) => ClaySurface(
            face: ClayFace.well(
              c,
              color: Color.lerp(
                base,
                c.well,
                Curves.easeInOut.transform(_breath.value),
              ),
              radius: widget.radius ?? widget.height / 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A meter: how much of a known whole, as a groove filled in coral (in the
/// danger red past [high]), its name and value above it.
///
/// ```dart
/// const ClayMeter(value: 6, max: 8, label: 'Glasses today', valueText: '6 of 8')
/// ```
class ClayMeter extends StatelessWidget {
  /// A meter at [value] of [max].
  const ClayMeter({
    super.key,
    required this.value,
    required this.label,
    this.max = 1,
    this.high,
    this.valueText,
    this.style,
  });

  /// How much.
  final double value;

  /// What it measures.
  final String label;

  /// The whole.
  final double max;

  /// Past this it turns to the danger red.
  final double? high;

  /// The value in words; null: a percentage in the reader's digits.
  final String? valueText;

  /// This meter's own style, over [ClayThemeData.meterStyle]: `fill` the
  /// run.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.meterStyle], const {});
    final share = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final over = high != null && value > high!;
    final fill = over ? c.danger : (layered.fill ?? c.accent);
    final said =
        valueText ?? RawWidgetsLocalizations.of(context).formatPercent(share);
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
                  color: over ? c.dangerInk : c.inkSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClaySpacing.small),
          SizedBox(
            height: 12,
            width: double.infinity,
            child: ClaySurface(
              face: ClayFace.well(
                c,
                color: Color.lerp(c.well, c.track, 0.45),
                radius: 6,
              ),
              child: ClaySpring(
                target: share,
                damping: 1,
                stiffness: ClayMotion.liftStiffness,
                builder: (context, t) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: t.clamp(0.0, 1.0),
                  child: t <= 0.001
                      ? const SizedBox.shrink()
                      : ClaySurface(
                          face: ClayFace.raised(
                            c,
                            color: fill,
                            radius: 6,
                          ).copyWith(shadowOpacity: 0),
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

/// What a [ClayBanner] says itself as.
enum ClayBannerTone {
  /// Something to know.
  info,

  /// Something done.
  success,

  /// Something to watch.
  warning,

  /// Something wrong.
  danger,
}

/// A banner across a page: a clay card faintly tinted by its [tone], a ball
/// with its glyph, its title and message, and keys to act on it. A [live]
/// banner is said as it appears.
///
/// ```dart
/// const ClayBanner(title: 'Reminders are off', message: 'Turn them on in Settings to be nudged.', tone: ClayBannerTone.warning)
/// ```
class ClayBanner extends StatelessWidget {
  /// A banner titled [title].
  const ClayBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = ClayBannerTone.info,
    this.icon,
    this.actions = const [],
    this.live = false,
    this.style,
  });

  /// What it says first.
  final String title;

  /// More.
  final String? message;

  /// Its tint and glyph.
  final ClayBannerTone tone;

  /// Its glyph; null: its tone's.
  final IconData? icon;

  /// Keys to act on it, at its foot.
  final List<Widget> actions;

  /// Whether a screen reader says it as it appears.
  final bool live;

  /// This banner's own style, over [ClayThemeData.bannerStyle]: `fill` the
  /// card.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.bannerStyle], const {});
    final (hue, glyph) = switch (tone) {
      ClayBannerTone.info => (c.tint(ClayTint.sky), LucideIcons.info),
      ClayBannerTone.success => (c.success, LucideIcons.circleCheck),
      ClayBannerTone.warning => (
        c.tint(ClayTint.butter),
        LucideIcons.triangleAlert,
      ),
      ClayBannerTone.danger => (c.danger, LucideIcons.circleAlert),
    };
    return Semantics(
      liveRegion: live,
      container: true,
      child: ClaySurface(
        face: ClayFace.raised(
          c,
          color: layered.fill ?? Color.lerp(c.clay, hue, 0.12),
          radius: clayCornerRadius(theme, layered, RawCorner.large),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ClaySpacing.regular),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 36,
                child: ClaySurface(
                  face: ClayFace.raised(
                    c,
                    color: hue,
                    radius: 18,
                  ).copyWith(elevation: 0.6),
                  child: Icon(icon ?? glyph, size: 18, color: c.onColor(hue)),
                ),
              ),
              const SizedBox(width: ClaySpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        // The title's cap height level with the ball.
                        top: ClaySpacing.tight + ClaySpacing.hairline,
                      ),
                      child: Text(
                        title,
                        style: theme.textTheme.label.copyWith(color: c.ink),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: ClaySpacing.hairline),
                      Text(message!, style: theme.textTheme.secondary),
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: ClaySpacing.medium),
                      Wrap(
                        spacing: ClaySpacing.small,
                        runSpacing: ClaySpacing.small,
                        children: actions,
                      ),
                    ],
                  ],
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
      ..add(StringProperty('title', title))
      ..add(EnumProperty<ClayBannerTone>('tone', tone));
  }
}

/// Which state a [ClayStateView] shows.
enum ClayState {
  /// Nothing here yet.
  empty,

  /// Something went wrong.
  error,

  /// On its way.
  loading,

  /// Done.
  success,
}

/// What a place says when it has nothing to show: a big ball of clay (a cup
/// pressed in when empty, coral when done, rose when wrong, a spinner while
/// loading), a title, a line and the keys to move on. It spans its parent,
/// its words centred.
///
/// ```dart
/// ClayStateView(state: ClayState.empty, title: 'No habits yet', message: 'Start with one small thing.', actions: [ClayButton.filled('New habit', onPressed: () {})])
/// ```
class ClayStateView extends StatelessWidget {
  /// A [state] view titled [title].
  const ClayStateView({
    super.key,
    required this.state,
    required this.title,
    this.message,
    this.icon,
    this.actions = const [],
    this.style,
  });

  /// Which state.
  final ClayState state;

  /// What it says first.
  final String title;

  /// More.
  final String? message;

  /// Its glyph; null: its state's.
  final IconData? icon;

  /// Keys to move on.
  final List<Widget> actions;

  /// This view's own style, over [ClayThemeData.stateViewStyle]: `fill`
  /// the ball.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.stateViewStyle], const {});
    const ball = 72.0;
    final glyph =
        icon ??
        switch (state) {
          ClayState.empty => LucideIcons.inbox,
          ClayState.error => LucideIcons.cloudOff,
          ClayState.loading => LucideIcons.loader,
          ClayState.success => LucideIcons.check,
        };
    final face = switch (state) {
      ClayState.empty => ClayFace.well(
        c,
        color: layered.fill,
        radius: ball / 2,
      ),
      ClayState.error => ClayFace.raised(
        c,
        color: layered.fill ?? c.tint(ClayTint.rose),
        radius: ball / 2,
      ),
      ClayState.loading => ClayFace.raised(
        c,
        color: layered.fill,
        radius: ball / 2,
      ),
      ClayState.success => ClayFace.raised(
        c,
        color: layered.fill ?? c.accent,
        radius: ball / 2,
      ),
    };
    final ink = state == ClayState.empty
        ? c.inkSecondary
        : c.onColor(face.color);
    return Semantics(
      container: true,
      liveRegion: state != ClayState.empty,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClaySpacing.regular,
          vertical: ClaySpacing.extraLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox.square(
                dimension: ball,
                child: ClaySurface(
                  face: face,
                  child: Center(
                    child: state == ClayState.loading
                        ? const ClaySpinner(size: 32)
                        : ExcludeSemantics(
                            child: Icon(glyph, size: 30, color: ink),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ClaySpacing.large),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.title.copyWith(color: c.ink),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: ClaySpacing.small),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.secondary,
                  ),
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: ClaySpacing.large),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: ClaySpacing.small,
                runSpacing: ClaySpacing.small,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<ClayState>('state', state))
      ..add(StringProperty('title', title));
  }
}
