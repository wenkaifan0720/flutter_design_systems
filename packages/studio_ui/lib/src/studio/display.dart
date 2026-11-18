/// Studio's display parts: [StudioDisclosure] (a row that opens to show
/// more), [StudioTable] (rows of words on glass), [StudioDescriptionList]
/// (terms printed as legends, their values beside them), [StudioTimeline]
/// (lamps down an engraved line), [StudioAvatar] and [StudioAvatarGroup]
/// (portholes), [StudioBadge] (a count in a small readout), [StudioTag] (a
/// small engraved plate) and [StudioMedia] (a picture behind glass).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'surface.dart';
import 'theme.dart';

bool _still(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// A row that opens to show more: its title, a wedge at its end that
/// turns as it opens, and [child] sliding out under it. A press, Space or
/// Enter opens and closes it; a screen reader hears it expanded or not.
///
/// ```dart
/// StudioDisclosure(title: 'Show notes', child: Text(notes))
/// ```
class StudioDisclosure extends StatefulWidget {
  /// A disclosure titled [title].
  const StudioDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  /// What it is about.
  final String title;

  /// What it shows open.
  final Widget child;

  /// Whether it starts open.
  final bool initiallyExpanded;

  /// Called as it opens or closes.
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<StudioDisclosure> createState() => _StudioDisclosureState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

class _StudioDisclosureState extends State<StudioDisclosure> {
  late bool _open = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _open = !_open);
    widget.onExpansionChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final time = _still(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignPressable(
          onPressed: _toggle,
          expanded: _open,
          semanticLabel: widget.title,
          excludeSemantics: true,
          builder: (context, states, _) => AnimatedStudioSurface(
            stiffness: StudioMotion.lampStiffness,
            face: c.recessFace.copyWith(
              radius: StudioRadii.small,
              presence: states.contains(WidgetState.pressed) ? 1 : 0,
              focus: states.contains(WidgetState.focused)
                  ? c.focusRing
                  : c.focusRing.withValues(alpha: 0),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: theme.controlHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.small,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.body.copyWith(
                          color: c.legend,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: time,
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: StudioIconSizes.medium,
                        color: _open ? c.litLegend : c.legendMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: time,
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.topStart,
            heightFactor: _open ? 1 : 0,
            child: Visibility(
              visible: _open,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  StudioSpacing.small,
                  StudioSpacing.small,
                  StudioSpacing.small,
                  StudioSpacing.medium,
                ),
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.body.copyWith(color: c.legend),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A column of a [StudioTable].
@immutable
class StudioTableColumn {
  /// A column [label]led.
  const StudioTableColumn(this.label, {this.numeric = false, this.flex = 1});

  /// Its name, printed at its head.
  final String label;

  /// Whether it holds figures (set to the end, tabular).
  final bool numeric;

  /// Its share of the width.
  final int flex;
}

/// Rows of words on a glass panel: the columns' names printed small along
/// the top, the rows parted by fine lines, figures to the end. It only
/// shows; [StudioDataTable] sorts and chooses.
///
/// ```dart
/// StudioTable(columns: const [StudioTableColumn('Episode'), StudioTableColumn('Plays', numeric: true)], rows: const [['Pilot', '1,204']])
/// ```
class StudioTable extends StatelessWidget {
  /// A table of [rows] under [columns].
  const StudioTable({super.key, required this.columns, required this.rows});

  /// The columns.
  final List<StudioTableColumn> columns;

  /// Each row's words, one per column.
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    const pad = EdgeInsets.symmetric(
      horizontal: StudioSpacing.medium,
      vertical: StudioSpacing.medium - 2,
    );
    Widget row(List<Widget> cells) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, cell) in cells.indexed)
          Expanded(flex: columns[i].flex, child: cell),
      ],
    );
    return StudioSurface(
      face: c.displayFace.copyWith(radius: StudioRadii.display),
      child: Padding(
        padding: const EdgeInsets.all(StudioMetrics.recessInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              child: row([
                for (final col in columns)
                  Padding(
                    padding: pad,
                    child: Align(
                      alignment: col.numeric
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: StudioLegend(col.label, color: c.onDisplayMuted),
                    ),
                  ),
              ]),
            ),
            for (final words in rows) ...[
              Container(height: 1, color: c.displayLine),
              Semantics(
                container: true,
                child: row([
                  for (final (i, w) in words.indexed)
                    Padding(
                      padding: pad,
                      child: Text(
                        w,
                        textAlign: columns[i].numeric
                            ? TextAlign.end
                            : TextAlign.start,
                        style: theme.textTheme.body.copyWith(
                          color: c.onDisplay,
                          fontFeatures: columns[i].numeric
                              ? const [FontFeature.tabularFigures()]
                              : null,
                        ),
                      ),
                    ),
                ]),
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
      ..add(IntProperty('columns', columns.length))
      ..add(IntProperty('rows', rows.length));
  }
}

/// A term and its value in a [StudioDescriptionList].
@immutable
class StudioDescription {
  /// [term] described by [detail].
  const StudioDescription(this.term, this.detail);

  /// What it is.
  final String term;

  /// Its value.
  final String detail;
}

/// Terms and their values, as a spec plate: each term printed small as a
/// legend, its value in the body's words beside it (under it on a narrow
/// column), the pairs parted by fine grooves.
///
/// ```dart
/// StudioDescriptionList(entries: const [StudioDescription('Length', '42 min'), StudioDescription('Format', 'Stereo, 48 kHz')])
/// ```
class StudioDescriptionList extends StatelessWidget {
  /// A list of [entries].
  const StudioDescriptionList({super.key, required this.entries});

  /// The pairs, in order.
  final List<StudioDescription> entries;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth >= 420;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, e) in entries.indexed) ...[
              if (i > 0) const StudioGroove(),
              Semantics(
                container: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: StudioSpacing.medium - 2,
                  ),
                  child: Flex(
                    direction: side ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: side ? 160 : null,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: side ? 3 : 0,
                            bottom: side ? 0 : StudioSpacing.tight,
                          ),
                          child: StudioLegend(e.term),
                        ),
                      ),
                      if (side)
                        Expanded(child: _detail(theme, c, e.detail))
                      else
                        _detail(theme, c, e.detail),
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

  Widget _detail(StudioThemeData theme, StudioColors c, String words) =>
      Text(words, style: theme.textTheme.body.copyWith(color: c.legend));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('entries', entries.length));
  }
}

/// One event on a [StudioTimeline].
@immutable
class StudioTimelineEntry {
  /// An event [title]d, at [time].
  const StudioTimelineEntry({
    required this.title,
    this.time,
    this.detail,
    this.done = false,
  });

  /// What happened.
  final String title;

  /// When, as it reads.
  final String? time;

  /// More on it.
  final String? detail;

  /// Whether it has happened: its lamp lit.
  final bool done;
}

/// Events down an engraved line, each a lamp with its title and time beside
/// it: the ones that have happened lit, the line lit down to the last of
/// them.
///
/// ```dart
/// StudioTimeline(entries: const [StudioTimelineEntry(title: 'Recorded', time: 'Mon 14:00', done: true), StudioTimelineEntry(title: 'Published', time: 'Thu 09:00')])
/// ```
class StudioTimeline extends StatelessWidget {
  /// A timeline of [entries].
  const StudioTimeline({super.key, required this.entries});

  /// The events, first to last.
  final List<StudioTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in entries.indexed)
          Semantics(
            container: true,
            label: e.done ? 'Done' : null,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        const SizedBox(height: StudioMetrics.lampDrop),
                        StudioLamp(on: e.done, size: 10),
                        if (i < entries.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(
                                vertical: StudioSpacing.hair,
                              ),
                              decoration: BoxDecoration(
                                color: e.done && entries[i + 1].done
                                    ? c.indicator
                                    : c.groove,
                                boxShadow: e.done && entries[i + 1].done
                                    ? [
                                        BoxShadow(
                                          color: c.indicator.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.medium),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < entries.length - 1
                            ? StudioSpacing.large
                            : 0,
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
                                    color: c.legend,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (e.time != null)
                                Text(
                                  e.time!,
                                  style: theme.textTheme.caption.copyWith(
                                    color: c.legendMuted,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (e.detail != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: StudioSpacing.tight,
                              ),
                              child: Text(
                                e.detail!,
                                style: theme.textTheme.secondary.copyWith(
                                  color: c.legendMuted,
                                ),
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
  final letters = [for (final p in parts) p.characters.first.toUpperCase()];
  if (letters.isEmpty) return '?';
  if (letters.length == 1) return letters.first;
  return letters.first + letters.last;
}

/// A person: a round porthole of dark glass set in a metal bezel, their
/// picture in it or, without one, their initials glowing in it.
///
/// ```dart
/// const StudioAvatar(name: 'Noor Haddad')
/// ```
class StudioAvatar extends StatelessWidget {
  /// [name]'s avatar.
  const StudioAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = 40,
  });

  /// Their name: the initials, and what a screen reader says.
  final String name;

  /// Their picture.
  final ImageProvider? image;

  /// Its diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final initials = Center(
      // The initials are sized to the disc, not to the reader's text: the
      // name is read whole by a screen reader.
      child: Text(
        _initials(name),
        textScaler: TextScaler.noScaling,
        style: theme.textTheme.label.copyWith(
          fontSize: size * 0.36,
          height: 1,
          color: c.onReadout,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Semantics(
      image: true,
      label: name,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: StudioSurface(
          face: c.keyFace.copyWith(radius: size / 2),
          child: Padding(
            padding: EdgeInsets.all(
              size < StudioMetrics.smallAvatar
                  ? StudioSpacing.hair
                  : StudioMetrics.lip,
            ),
            child: ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.readout),
                child: image == null
                    ? initials
                    : Image(
                        image: image!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        errorBuilder: (_, _, _) => initials,
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

/// People together: their portholes overlapping, the first on top, and a
/// readout porthole of how many more past [max].
///
/// ```dart
/// StudioAvatarGroup(names: const ['Noor Haddad', 'Teo Park', 'Ama Boateng'])
/// ```
class StudioAvatarGroup extends StatelessWidget {
  /// A group of [names].
  const StudioAvatarGroup({
    super.key,
    required this.names,
    this.max = 4,
    this.size = 36,
  });

  /// The people.
  final List<String> names;

  /// The most portholes shown.
  final int max;

  /// A porthole's diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final shown = names.take(max).toList();
    final more = names.length - shown.length;
    final step = size * 0.68;
    final count = shown.length + (more > 0 ? 1 : 0);
    return Semantics(
      label: names.join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: step * (count - 1) + size,
        height: size,
        child: Stack(
          children: [
            if (more > 0)
              PositionedDirectional(
                start: step * shown.length,
                child: SizedBox.square(
                  dimension: size,
                  child: StudioSurface(
                    face: c.keyFace.copyWith(radius: size / 2),
                    child: Padding(
                      padding: const EdgeInsets.all(StudioMetrics.lip),
                      child: ClipOval(
                        child: ColoredBox(
                          color: c.readout,
                          child: Center(
                            child: Text(
                              '+$more',
                              style: theme.textTheme.readout.copyWith(
                                fontSize: size * 0.32,
                                height: 1,
                                color: c.indicator,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            for (var i = shown.length - 1; i >= 0; i--)
              PositionedDirectional(
                start: step * i,
                child: StudioAvatar(name: shown[i], size: size),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>('names', names));
  }
}

/// A count on something: a small dark readout at [child]'s top end, its
/// figures lit (or, with no [count], a lit lamp alone). Over 99 it reads
/// `99+`.
///
/// ```dart
/// StudioBadge(count: 3, child: const Icon(LucideIcons.bell))
/// ```
class StudioBadge extends StatelessWidget {
  /// [child] badged with [count].
  const StudioBadge({
    super.key,
    required this.child,
    this.count,
    this.show = true,
    this.semanticLabel,
  });

  /// What it is on.
  final Widget child;

  /// The count; null for a lamp alone.
  final int? count;

  /// Whether it shows.
  final bool show;

  /// What a screen reader adds ("3 new").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    if (!show) return child;
    final n = count;
    return Semantics(
      value: semanticLabel ?? (n == null ? 'New' : '$n'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          PositionedDirectional(
            top: n == null ? -2 : -7,
            end: n == null ? -2 : -10,
            child: ExcludeSemantics(
              child: n == null
                  ? const StudioLamp(on: true, size: 8)
                  : Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 18,
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.tight,
                      ),
                      decoration: BoxDecoration(
                        color: c.readout,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: c.panel, width: 1.5),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          n > 99 ? '99+' : '$n',
                          style: theme.textTheme.readout.copyWith(
                            fontSize: 11,
                            height: 1,
                            color: c.indicator,
                            shadows: [
                              Shadow(
                                color: c.indicator.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
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
    properties.add(IntProperty('count', count, defaultValue: null));
  }
}

/// How a [StudioTag] reads.
enum StudioTagTone {
  /// Engraved, unlit.
  plain,

  /// Its lamp lit: something live (new, on air).
  lit,

  /// Its lamp red: something wrong.
  danger,
}

/// A small legend window: a few words backlit on dark glass in both rooms
/// (a state, a kind), its lamp lit for [StudioTagTone.lit] or red for
/// [StudioTagTone.danger]. It is not a key.
///
/// Reads [style]'s `fill`, `foreground` and `textStyle`, then
/// [StudioThemeData.tagStyle].
///
/// ```dart
/// const StudioTag('On air', tone: StudioTagTone.lit)
/// ```
class StudioTag extends StatelessWidget {
  /// A tag reading [label].
  const StudioTag(
    this.label, {
    super.key,
    this.tone = StudioTagTone.plain,
    this.style,
  });

  /// Its words.
  final String label;

  /// How it reads.
  final StudioTagTone tone;

  /// Its style, over [StudioThemeData.tagStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tagStyle], const {});
    final ink =
        layered.foreground ??
        switch (tone) {
          StudioTagTone.plain => c.onReadout,
          StudioTagTone.lit => c.onReadout,
          // The failure's red, lifted until it reads on the dark glass.
          StudioTagTone.danger =>
            c.brightness == Brightness.dark
                ? c.danger
                : Color.lerp(c.danger, const Color(0xFFFFFFFF), 0.35)!,
        };
    return StudioSurface(
      face: c.readoutFace.copyWith(radius: 4, fill: layered.fill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StudioSpacing.small,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tone != StudioTagTone.plain) ...[
              StudioLamp(
                on: true,
                size: 6,
                color: tone == StudioTagTone.danger ? c.danger : null,
              ),
              const SizedBox(width: StudioSpacing.tight + 2),
            ],
            Text(
              label,
              style: layered.text(
                theme.textTheme.caption.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
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
      ..add(StringProperty('label', label))
      ..add(EnumProperty<StudioTagTone>('tone', tone));
  }
}

/// A picture behind glass: [image] in a dark window set into the metal at
/// [aspectRatio], a faint reflection across its top. While it loads (or
/// with none) the window shows an engraved picture glyph.
///
/// ```dart
/// StudioMedia(image: const AssetImage('assets/cover.jpg'), semanticLabel: 'The cover: a microphone in a dark room')
/// ```
class StudioMedia extends StatelessWidget {
  /// [image] in a window.
  const StudioMedia({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
  });

  /// The picture; null shows the stand-in.
  final ImageProvider? image;

  /// What the picture shows, for a screen reader.
  final String semanticLabel;

  /// The window's shape.
  final double aspectRatio;

  /// How the picture fills it.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    final standIn = Center(
      child: Icon(
        LucideIcons.image,
        size: StudioIconSizes.huge,
        color: c.onReadoutMuted,
      ),
    );
    const inset = StudioMetrics.recessInset;
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: StudioSurface(
          face: c.recessFace.copyWith(radius: StudioRadii.display),
          child: Padding(
            padding: const EdgeInsets.all(inset - 1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                StudioRadii.display - inset + 1,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: c.readout),
                  if (image == null)
                    standIn
                  else
                    Image(
                      image: image!,
                      fit: fit,
                      frameBuilder: (context, child, frame, sync) =>
                          sync || frame != null ? child : standIn,
                      errorBuilder: (_, _, _) => standIn,
                    ),
                  // The glass: a faint sheen across its top.
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
                        ),
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
