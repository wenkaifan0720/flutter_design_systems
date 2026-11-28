/// Rows: a list's line, chosen in inverse video, and the header that heads
/// a run of them.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../internal/face_align.dart';
import '../internal/menu_marks.dart';
import '../internal/shell_face.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../primitives/spring.dart';
import '../style.dart';
import '../theme.dart';
import 'containers.dart';
import 'pane.dart';

/// A row of a list, as a terminal program lists things: [title] in the
/// words' ink, [subtitle] dim, [leading] (a status glyph) before them and
/// [trailing] (a time, a count, a key) at the end.
///
/// From [besideCols] cells wide (a desk's pane) it is one line, [subtitle]
/// beside [title] as a column (where it starts: [titleCols]); narrower (a
/// phone, a narrow window or pane, whatever the pointer) it is two lines,
/// [subtitle] under [title]. Under a finger it is two lines tall either way,
/// its floor. [trailing] takes at most half the row; in a two-line row with
/// a [subtitle] it stands at the end of the second line, in every row, and
/// where the subtitle and it don't both fit (an author on a phone at large
/// text), on a third line of its own, at the end, as it goes under the
/// title of a row without a subtitle. In a narrow row a [title] or
/// [subtitle] of plain `Text` longer than its line wraps at whole words, a
/// line more for each, as Material's `ListTile` does; a word longer than
/// the line is cut after its last whole letter, with `…`, and a screen
/// reader hears the words whole. Where the words wrap, [trailing] stands at
/// the end of their last line if it fits there, else on a line of its own.
/// The
/// row runs from edge to edge (put rows in a [TermPane.list]) and keeps a
/// one-cell gutter at each end. The keyboard's focus is the cursor over the
/// whole row, a pair of brackets cut out of its gutters (on a chosen row,
/// hollow). [selected] draws the row in inverse video, and a screen reader
/// hears it selected; a press fills it the same way. An [action] (the
/// row's menu key) stands at its end, on the chosen bar, on the title's
/// first line.
///
/// ```dart
/// TermListTile(
///   leading: const Text('✓'),
///   title: const Text('atlas-api'),
///   subtitle: const Text('main · 2m 14s'),
///   trailing: const Text('4m'),
///   selected: true,
///   onTap: () {},
/// )
/// ```
///
/// Reads [TermStyle]'s `fill` (the row's ground), `foreground` (the
/// words), `edge` (the focus block) and `textStyle`.
class TermListTile extends StatelessWidget {
  /// The cells from which a row stands on one line, its [subtitle] a
  /// column beside its [title].
  static const int besideCols = 56;

  /// A list row.
  const TermListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
    this.titleCols,
    this.option = false,
    this.action,
  });

  /// Before the words: a status glyph, a marker.
  final Widget? leading;

  /// What the row is.
  final Widget title;

  /// More about it, dim: beside [title] under a pointer, under it under a
  /// finger.
  final Widget? subtitle;

  /// At the end: a time, a count, a key.
  final Widget? trailing;

  /// A control after the row's end (the row's menu key). It stands on the
  /// chosen row's bar, drawn in inverse video with it, but is its own
  /// target and its own node, apart from the row's press and the words
  /// read with it. In a row of more than one line it stands on the title's
  /// first line.
  ///
  /// ```dart
  /// TermListTile(
  ///   title: const Text('atlas-api'),
  ///   selected: true,
  ///   onTap: open,
  ///   action: TermIconButton(
  ///     glyph: '⋯',
  ///     semanticLabel: 'actions',
  ///     onPressed: menu,
  ///   ),
  /// )
  /// ```
  final Widget? action;

  /// The cells [leading] and [title] take on a row whose [subtitle] stands
  /// beside them; null: three fifths of the row. Give a list's rows one
  /// number, so their subtitles start in one column: a list of short names
  /// with long messages gives the messages the room.
  final int? titleCols;

  /// Called on a press, Return or Space; null: the row only shows.
  final VoidCallback? onTap;

  /// Whether the row is the chosen one, drawn in inverse video.
  final bool selected;

  /// Whether the row is an option in a list a field opens (a
  /// [TermSelect]'s): the pointer over it marks it as the keys on it do,
  /// its words in the accent, so the row a press would take shows before
  /// the press, apart from the chosen one's bar; the keys add the cursor. A
  /// row in a page's list keeps its words, and only the keys mark it.
  /// In a list the pointer opened, the keys' mark waits for a key
  /// ([TermMenuMarks]).
  final bool option;

  /// Whether it takes presses; a disabled row is drawn in the rule's ink.
  final bool enabled;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// What a screen reader says in place of the row's words.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.listTileStyle]: `fill`
  /// (selected or pressed), `foreground` (the words), `edge` (the
  /// keyboard's cursor) and `textStyle` (the title's colour and weight).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final touch = RawTapTargets.of(context).inputOn() == RawInput.touch;
    final interactive = onTap != null && enabled;
    // Chosen in a pane without the keyboard: a faint shade, not the bright
    // bar the active pane's row has.
    final active = TermPaneScope.activeOf(context);
    // In a list the pointer opened, the keys are not shown until a key.
    final keysShown = !option || (TermMenuMarks.shownOf(context) ?? true);

    Widget row(Set<WidgetState> pressable) {
      final states = keysShown
          ? pressable
          : {...pressable}.difference(const {WidgetState.focused});
      final disabled = !enabled;
      final own = TermStyleOf([style, theme.listTileStyle], states);
      // An option the keys are on, or the pointer: its words in the accent.
      // Only the keys add the block, so the two never read as one mark.
      final marked =
          option &&
          !disabled &&
          (states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered));
      // Under the pointer, an option's chosen bar takes the accent.
      final pointer =
          option && !disabled && states.contains(WidgetState.hovered);
      return TermStateSprings(
        pressed: states.contains(WidgetState.pressed),
        focused: states.contains(WidgetState.focused),
        builder: (context, press, focus) => TermSpring(
          target: marked ? 1 : 0,
          token: TermMotion.move,
          builder: (context, mark, _) => TermSpring(
            target: selected ? 1 : 0,
            token: TermMotion.press,
            builder: (context, chosen, _) {
              final inverse = ((active ? chosen : 0.0) + press).clamp(0.0, 1.0);
              // With an action the chosen bar stands under the row and its
              // action both (_ActionRow); the row paints its press.
              final under = action == null ? chosen : 0.0;
              final filled = ((active ? under : 0.0) + press).clamp(0.0, 1.0);
              // The keys' cursor: a block of the accent over the row, a
              // pair of brackets cut out of its end cells; on the chosen
              // bar it goes hollow, the bar cleared under it.
              final hollow = active && selected;
              final cursor = disabled ? 0.0 : focus;
              final shade = termRowShade(theme);
              // The pointer over a row changes nothing (it says "this presses"
              // by its cursor), but over an option: its words take the
              // accent, or its chosen bar does; a style that resolves
              // `hovered` still can.
              final bar =
                  own.fill ??
                  Color.lerp(
                    Color.lerp(
                      shade.withValues(alpha: 0),
                      shade,
                      active ? 0.0 : under,
                    ),
                    pointer ? theme.accent : theme.foreground,
                    filled,
                  )!;
              final ground = hollow
                  ? bar.withValues(alpha: bar.a * (1 - cursor))
                  : bar;
              final ink =
                  own.foreground ??
                  (disabled
                      ? theme.rule
                      : termCursorInk(
                          theme,
                          Color.lerp(
                            // An option's marked words take the accent, off the
                            // chosen bar.
                            option
                                ? Color.lerp(
                                    theme.foreground,
                                    theme.accent,
                                    mark,
                                  )!
                                : theme.foreground,
                            theme.background,
                            inverse,
                          )!,
                          cursor,
                          hollow: hollow,
                        ));
              // On the chosen bar (this row's, or under its action) the
              // dim words step until they read on the shade.
              final dimOnBar = Color.lerp(
                theme.dim,
                RawPalette.readableTone(theme.dim, on: [shade]),
                active ? 0.0 : chosen,
              )!;
              final dim = disabled
                  ? theme.rule
                  : termCursorInk(
                      theme,
                      Color.lerp(dimOnBar, theme.background, inverse)!,
                      cursor,
                      hollow: hollow,
                    );
              final words = theme.textStyle
                  .merge(own.textStyle)
                  .copyWith(color: ink);
              final faint = theme.textStyle
                  .merge(own.textStyle)
                  .copyWith(color: dim);
              Widget slot(Widget child, TextStyle style) => DefaultTextStyle(
                style: style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: child,
              );
              final lead = [
                if (leading != null) ...[
                  slot(leading!, words),
                  SizedBox(width: cw),
                ],
              ];
              // The end's words take at most half the row they share: a long
              // one ellipsizes rather than push the title off. On a line of
              // their own ([alone]) they may take all of it.
              List<Widget> endIn(
                double width, {
                double? room,
                bool alone = false,
              }) => [
                if (trailing != null) ...[
                  SizedBox(width: cw),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.max(
                        0,
                        alone ? width - cw : math.min(width / 2, room ?? width),
                      ),
                    ),
                    child: slot(trailing!, faint),
                  ),
                ],
              ];
              // Under the title, not under the glyph.
              final indent = [
                if (leading != null) ...[
                  Opacity(
                    opacity: 0,
                    child: ExcludeSemantics(child: slot(leading!, words)),
                  ),
                  SizedBox(width: cw),
                ],
              ];
              // The words of a line of a wrapped [text]: the [i]th of [lines],
              // one line tall; the first line says the whole text to a
              // screen reader, the others nothing.
              Widget part(
                Text text,
                List<String> lines,
                int i,
                TextStyle style,
              ) {
                final shown = slot(
                  Text(
                    lines[i],
                    style: text.style,
                    textDirection: text.textDirection,
                    locale: text.locale,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                  ),
                  style,
                );
                return i == 0
                    ? Semantics(
                        label: text.semanticsLabel ?? text.data,
                        child: ExcludeSemantics(child: shown),
                      )
                    : ExcludeSemantics(child: shown);
              }

              Widget line(List<Widget> children) => SizedBox(
                height: lh,
                child: Row(children: children),
              );

              Widget body(bool stacked, double width, _Stack plan) {
                if (stacked) {
                  // A narrow row stands its words in lines: the title's (a
                  // long one wrapped at whole words), then the subtitle's,
                  // the words at the end beside the subtitle's line, in
                  // every row, so a list's ends keep one column, where both
                  // fit whole; else on a line of their own, at the end.
                  // Without a subtitle they stand on the title's line,
                  // going under it where both don't fit (a phone at large
                  // text).
                  final first = Row(
                    children: [
                      ...lead,
                      Expanded(child: slot(title, words)),
                      if (plan.beside) ...endIn(width),
                    ],
                  );
                  if (plan.beside) {
                    // One line of words, centred in the finger's two.
                    return first;
                  }
                  final rows = <Widget>[];
                  final titles = plan.title;
                  if (titles == null) {
                    rows.add(SizedBox(height: lh, child: first));
                  } else {
                    for (var i = 0; i < titles.length; i++) {
                      rows.add(
                        line([
                          ...(i == 0 ? lead : indent),
                          Expanded(
                            child: part(title as Text, titles, i, words),
                          ),
                          if (plan.endAfter && i == titles.length - 1)
                            ...endIn(width),
                        ]),
                      );
                    }
                  }
                  final more = subtitle;
                  if (more != null) {
                    final subtitles = plan.subtitle;
                    final endHere = !plan.endOwn;
                    if (subtitles == null) {
                      rows.add(
                        line([
                          ...indent,
                          Expanded(child: slot(more, faint)),
                          if (endHere) ...endIn(width),
                        ]),
                      );
                    } else {
                      for (var i = 0; i < subtitles.length; i++) {
                        rows.add(
                          line([
                            ...indent,
                            Expanded(
                              child: part(more as Text, subtitles, i, faint),
                            ),
                            if (endHere && i == subtitles.length - 1)
                              ...endIn(width),
                          ]),
                        );
                      }
                    }
                    if (plan.endOwn) {
                      rows.add(
                        line([const Spacer(), ...endIn(width, alone: true)]),
                      );
                    }
                  } else if (trailing != null && !plan.endAfter) {
                    rows.add(
                      line([...indent, const Spacer(), ...endIn(width)]),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rows,
                  );
                }
                // The glyph and title take three fifths of the row's cells,
                // counted from the row's own width, so the subtitles of a
                // list start in one column whatever stands at the end.
                return subtitle == null
                    ? Row(
                        children: [
                          ...lead,
                          Expanded(child: slot(title, words)),
                          ...endIn(width),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, c) {
                          final cols = grid.colsIn(c.maxWidth);
                          final start = titleCols == null
                              ? (cols - 1) * 3 ~/ 5
                              : titleCols!.clamp(0, cols - 1);
                          return Row(
                            children: [
                              SizedBox(
                                width: grid.cols(start),
                                child: Row(
                                  children: [
                                    ...lead,
                                    Expanded(child: slot(title, words)),
                                  ],
                                ),
                              ),
                              SizedBox(width: cw),
                              Expanded(child: slot(subtitle!, faint)),
                              ...endIn(
                                width,
                                room: c.maxWidth - grid.cols(start) - 2 * cw,
                              ),
                            ],
                          );
                        },
                      );
              }

              return LayoutBuilder(
                builder: (context, box) {
                  // The row's width decides its lines, whatever the
                  // pointer: a narrow one stacks; a finger's is two lines
                  // tall either way, its floor.
                  final stacked =
                      box.hasBoundedWidth &&
                      box.maxWidth < grid.cols(besideCols);
                  final width = box.maxWidth - 2 * cw;
                  final plan = stacked
                      ? _stack(grid, width)
                      : const _Stack(lines: 1);
                  // A line for each line of words; a finger's floor is two.
                  final lines = math.max(
                    stacked ? plan.lines : 1,
                    touch ? 2 : 1,
                  );
                  return CustomPaint(
                    painter: _RowPainter(
                      ground: ground,
                      cursor: TermCursorPainter(
                        grid: grid,
                        amount: cursor,
                        color: own.edge ?? theme.accent,
                        knockout: theme.onAccent,
                        stroke: termStrokeWidth(theme, grid),
                        hollow: hollow,
                      ),
                    ),
                    child: SizedBox(
                      height: lh * lines,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(start: cw, end: cw),
                        child: body(stacked, width, plan),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    }

    // A shell's destination: the shell presses it and speaks for it; the
    // row paints in its states.
    final given = onTap == null ? TermFaceStates.maybeOf(context) : null;
    if (given != null) return row(given);
    Widget tile(WidgetStatesController? states) => MergeSemantics(
      child: interactive
          ? RawButton(
              onPressed: onTap,
              focusNode: focusNode,
              autofocus: autofocus,
              selected: selected,
              semanticSelected: selected,
              semanticLabel: semanticLabel,
              excludeSemantics: semanticLabel != null,
              mouseCursor: SystemMouseCursors.click,
              statesController: states,
              builder: (context, states, _) => row(states),
            )
          : Semantics(
              container: true,
              selected: selected ? true : null,
              label: semanticLabel,
              enabled: enabled ? null : false,
              child: row({if (!enabled) WidgetState.disabled}),
            ),
    );
    final control = action;
    if (control == null) return tile(null);
    return _ActionRow(
      tile: tile,
      manyLines: (width) => _manyLines(context.termGrid, width),
      action: control,
      selected: selected,
      enabled: enabled,
      active: active,
      style: style,
    );
  }

  // How a narrow row [width] wide (its gutters aside) stands its words: the
  // title's lines and the subtitle's where they wrap, and where the words at
  // the end go.
  _Stack _stack(TermGrid grid, double width) {
    final glyph = leading == null
        ? 0.0
        : grid.widthOf(_plain(leading!) ?? ' ') + grid.cellWidth;
    final room = width - glyph;
    final titles = _wrapped(grid, title, room);
    final t = titles?.length ?? 1;
    final more = subtitle;
    if (more == null) {
      final beside = t == 1 && _fitsBeside(grid, width);
      // A wrapped title's last line takes the end's words where they fit.
      final endAfter =
          titles != null && _fitsAfter(grid, titles.last, room, width);
      return _Stack(
        title: titles,
        beside: beside,
        endAfter: endAfter,
        lines: beside ? 1 : t + (trailing == null || endAfter ? 0 : 1),
      );
    }
    final own = _endOwnLine(grid, width);
    // Beside the words at the end the subtitle fits whole (or keeps its one
    // line, as it did, where they aren't plain text); else it wraps, and
    // its last line takes the end's words where they fit.
    final subtitles = trailing != null && !own
        ? null
        : _wrapped(grid, more, room);
    final endOwn =
        own &&
        !(subtitles != null && _fitsAfter(grid, subtitles.last, room, width));
    return _Stack(
      title: titles,
      subtitle: subtitles,
      endOwn: endOwn,
      lines: t + (subtitles?.length ?? 1) + (endOwn ? 1 : 0),
    );
  }

  // Whether the row stands its words on more than one line at [width]
  // (its gutters counted): a narrow row whose words don't share one line.
  bool _manyLines(TermGrid grid, double width) =>
      width < grid.cols(besideCols) &&
      _stack(grid, width - 2 * grid.cellWidth).lines > 1;

  // [words]' lines where it is plain `Text` that doesn't stand whole on one
  // line [room] wide: broken between words, a word longer than the line cut
  // after its last whole letter that fits, with "…". Null where it keeps
  // one line as it is.
  static List<String>? _wrapped(TermGrid grid, Widget words, double room) {
    if (words is! Text) return null;
    final text = words.data;
    if (text == null || room < grid.cols(2)) return null;
    if (grid.widthOf(text) <= room + 0.5) return null;
    final lines = <String>[];
    var line = '';
    for (final word in text.split(RegExp('[ \t\n]+'))) {
      if (word.isEmpty) continue;
      final next = line.isEmpty ? word : '$line $word';
      if (grid.widthOf(next) <= room + 0.5) {
        line = next;
        continue;
      }
      if (line.isNotEmpty) lines.add(line);
      line = '';
      if (grid.widthOf(word) <= room + 0.5) {
        line = word;
      } else {
        var kept = '';
        for (final letter in word.characters) {
          if (grid.widthOf('$kept$letter…') > room + 0.5) break;
          kept += letter;
        }
        lines.add('$kept…');
      }
    }
    if (line.isNotEmpty) lines.add(line);
    return lines.isEmpty ? null : lines;
  }

  // Whether the title and the end's words fit on one line [width] wide, read
  // from their words where both are plain text (a glyph before them counted
  // as one cell); else they share the line, as they always did.
  bool _fitsBeside(TermGrid grid, double width) {
    final words = _plain(title);
    final end = trailing == null ? null : _plain(trailing!);
    if (words == null || end == null) return true;
    final glyph = leading == null
        ? 0.0
        : grid.widthOf(_plain(leading!) ?? ' ') + grid.cellWidth;
    return glyph + grid.widthOf(words) + grid.cellWidth + grid.widthOf(end) <=
        width + 0.5;
  }

  // Whether the end's words, where they are plain text, fit after [line]
  // (the last line of wrapped words) in [room], taking at most half the
  // row [width], as they do on a line they share.
  bool _fitsAfter(TermGrid grid, String line, double room, double width) {
    final end = trailing == null ? null : _plain(trailing!);
    if (end == null) return false;
    final ends = grid.widthOf(end);
    return ends <= width / 2 + 0.5 &&
        grid.widthOf(line) + grid.cellWidth + ends <= room + 0.5;
  }

  // Whether a narrow row's end words go to a line of their own: where its
  // subtitle and they don't both fit whole on its second line [width] wide
  // (after the glyph's indent), read from their words where both are plain
  // text, as a row without a subtitle moves them under its title.
  bool _endOwnLine(TermGrid grid, double width) {
    if (subtitle == null || trailing == null) return false;
    final words = _plain(subtitle!);
    final end = _plain(trailing!);
    if (words == null || end == null) return false;
    final glyph = leading == null
        ? 0.0
        : grid.widthOf(_plain(leading!) ?? ' ') + grid.cellWidth;
    return glyph + grid.widthOf(words) + grid.cellWidth + grid.widthOf(end) >
        width + 0.5;
  }

  static String? _plain(Widget w) => switch (w) {
    Text(:final data?) => data,
    Text(:final textSpan?) => textSpan.toPlainText(),
    _ => null,
  };

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(FlagProperty('option', value: option, ifTrue: 'option'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(IntProperty('titleCols', titleCols, defaultValue: null))
      ..add(DiagnosticsProperty<Widget>('action', action, defaultValue: null));
  }
}

// How a narrow row stands its words: [title] and [subtitle] line by line
// where they wrap (null where each keeps its one line), whether the words at
// the end stand [beside] the title, the row one line, after a wrapped
// title's last line ([endAfter]), or on a line of their own after the
// subtitle ([endOwn]), and the [lines] the words take.
class _Stack {
  const _Stack({
    this.title,
    this.subtitle,
    this.beside = false,
    this.endAfter = false,
    this.endOwn = false,
    required this.lines,
  });

  final List<String>? title;
  final List<String>? subtitle;
  final bool beside;
  final bool endAfter;
  final bool endOwn;
  final int lines;
}

// A row and the control after its end on one chosen bar: the control stands
// beside the row's press and its merged node, never inside them, and is
// drawn in inverse video on the inverse bar. The keys' cursor on the chosen
// row clears the bar under both, as it clears a row's own.
class _ActionRow extends StatefulWidget {
  const _ActionRow({
    required this.tile,
    required this.manyLines,
    required this.action,
    required this.selected,
    required this.enabled,
    required this.active,
    required this.style,
  });

  final Widget Function(WidgetStatesController states) tile;
  // Whether the row stands its words on more than one line at a width.
  final bool Function(double width) manyLines;
  final Widget action;
  final bool selected;
  final bool enabled;
  final bool active;
  final TermStyle? style;

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  final _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    // The action in inverse video: the words' ink and the ground swapped.
    final inverted = theme.copyWith(
      foreground: theme.background,
      background: theme.foreground,
      surface: theme.foreground,
      dim: theme.background,
      rule: Color.lerp(theme.rule, theme.background, 0.5),
    );
    return LayoutBuilder(
      builder: (context, box) {
        // The action's width: its tap target's floor, or a bracketed
        // glyph's three cells. In a row of more than one line it stands on
        // the title's line, its face at the top of its target.
        final floor = grid.ceil(RawTapTargets.of(context).floorOn());
        final room =
            box.maxWidth - math.max(floor.width, grid.cols(3)) - grid.cellWidth;
        final top = box.hasBoundedWidth && widget.manyLines(room);
        return _bar(context, theme, grid, inverted, top);
      },
    );
  }

  Widget _bar(
    BuildContext context,
    TermThemeData theme,
    TermGrid grid,
    TermThemeData inverted,
    bool top,
  ) {
    final active = widget.active;
    return ListenableBuilder(
      listenable: _states,
      builder: (context, _) => TermStateSprings(
        pressed: false,
        focused: _states.value.contains(WidgetState.focused),
        builder: (context, _, focus) => TermSpring(
          target: widget.selected ? 1 : 0,
          token: TermMotion.press,
          builder: (context, chosen, _) {
            final own = TermStyleOf(
              [widget.style, theme.listTileStyle],
              {if (widget.selected) WidgetState.selected},
            );
            final shade = termRowShade(theme);
            final inverse = active ? chosen : 0.0;
            final bar =
                own.fill ??
                Color.lerp(
                  Color.lerp(
                    shade.withValues(alpha: 0),
                    shade,
                    active ? 0.0 : chosen,
                  ),
                  theme.foreground,
                  inverse,
                )!;
            final cursor = widget.enabled ? focus : 0.0;
            final ground = active && widget.selected
                ? bar.withValues(alpha: bar.a * (1 - cursor))
                : bar;
            return ColoredBox(
              color: ground,
              child: Row(
                crossAxisAlignment: top
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(child: widget.tile(_states)),
                  TermTheme(
                    data: TermThemeData.lerp(
                      theme,
                      inverted,
                      inverse * (1 - cursor),
                    ),
                    child: TermFaceAlign(
                      alignment: top
                          ? AlignmentDirectional.topCenter
                          : AlignmentDirectional.center,
                      child: widget.action,
                    ),
                  ),
                  SizedBox(width: grid.cellWidth),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RowPainter extends CustomPainter {
  const _RowPainter({required this.ground, required this.cursor});

  final Color ground;
  final TermCursorPainter cursor;

  @override
  void paint(Canvas canvas, Size size) {
    if (ground.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    }
    cursor.paint(canvas, size);
  }

  @override
  bool shouldRepaint(_RowPainter old) =>
      old.ground != ground || cursor.shouldRepaint(old.cursor);
}

/// The heading over a run of rows: [title] in bold, then a rule to the end
/// of the line, then [trailing] dim (a count, a key), as `runs ──── 12`.
/// A screen reader hears [title] as a heading.
///
/// ```dart
/// const TermSectionHeader(title: 'recent runs', trailing: '12')
/// ```
class TermSectionHeader extends StatelessWidget {
  /// A heading with a rule.
  const TermSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.sectionHeaderStyle]:
  /// `foreground` (the title) and `edge` (the rule).
  final TermStyle? style;

  /// What the rows below are.
  final String title;

  /// Dim words at the line's end.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final own = TermStyleOf([style, theme.sectionHeaderStyle], const {});
    return SizedBox(
      height: grid.lineHeight,
      child: LayoutBuilder(
        builder: (context, c) => Row(
          children: [
            // Not flexible (that would split the line with the rule): the
            // title keeps its words up to all but three cells, the rule takes
            // the rest.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (c.maxWidth - cw * 3).clamp(0, double.infinity),
              ),
              child: Semantics(
                container: true,
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: theme.boldStyle.copyWith(color: own.foreground),
                ),
              ),
            ),
            SizedBox(width: cw),
            Expanded(
              child: CustomPaint(
                painter: TermRulePainter(
                  color: own.edge ?? theme.rule,
                  stroke: termStrokeWidth(theme, grid),
                  gaps: const [],
                ),
                child: SizedBox(height: grid.lineHeight),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: cw),
              Text(
                trailing!,
                maxLines: 1,
                softWrap: false,
                style: theme.dimStyle,
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
      ..add(StringProperty('title', title))
      ..add(StringProperty('trailing', trailing, defaultValue: null));
  }
}
