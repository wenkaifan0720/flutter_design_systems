/// The pane: a box-drawn frame with its title cut into the top line, the
/// look's card, window and group.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../grid.dart';
import '../primitives/box.dart';
import '../internal/snap.dart';
import '../primitives/spring.dart';
import '../style.dart';
import '../theme.dart';

/// Room inside a pane, in whole cells across and whole lines down, so what
/// a pane holds stays on the grid.
///
/// ```dart
/// const TermPane(padding: TermInset(start: 2, end: 2), child: Text('ready'))
/// ```
@immutable
class TermInset {
  /// [start] and [end] cells, [top] and [bottom] lines.
  const TermInset({this.start = 1, this.end = 1, this.top = 0, this.bottom = 0})
    : assert(start >= 0 && end >= 0 && top >= 0 && bottom >= 0);

  /// No room: rows that run from line to line.
  static const zero = TermInset(start: 0, end: 0);

  /// Cells at the start.
  final int start;

  /// Cells at the end.
  final int end;

  /// Lines at the top.
  final int top;

  /// Lines at the bottom.
  final int bottom;

  /// The room on [grid], in logical pixels.
  EdgeInsetsDirectional on(TermGrid grid) => EdgeInsetsDirectional.fromSTEB(
    grid.cols(start),
    grid.lines(top),
    grid.cols(end),
    grid.lines(bottom),
  );

  @override
  bool operator ==(Object other) =>
      other is TermInset &&
      other.start == start &&
      other.end == end &&
      other.top == top &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(start, end, top, bottom);

  @override
  String toString() => 'TermInset($start, $top, $end, $bottom)';
}

/// A box-drawn frame round [child], one cell thick, with [title] cut into
/// its top line and [footer] into its bottom one: Terminal's card, group
/// and window.
///
/// The line is single at rest and doubles, in the accent, while the pane is
/// active: while focus is anywhere inside it, as the pane a terminal program
/// is typing into ([focused] null), or as [focused] says. The frame takes
/// whole cells: inside its line, the child stands one cell in from the
/// sides ([padding]) and starts on the line under the title.
///
/// ```dart
/// const TermPane(
///   title: 'atlas-api',
///   trailing: 'main',
///   child: Text('last deploy 4m ago'),
/// )
/// ```
///
/// For rows that run to the frame's line (a list, whose selected row is
/// filled edge to edge), use [TermPane.list].
class TermPane extends StatefulWidget {
  /// A frame round [child].
  const TermPane({
    super.key,
    this.title,
    this.trailing,
    this.trailingColor,
    this.footer,
    this.focused,
    this.raised = false,
    this.padding,
    this.style,
    required this.child,
  });

  /// A frame round [children], rows that run from line to line inside it:
  /// a list's rows, each holding its own one-cell inset.
  TermPane.list({
    super.key,
    this.title,
    this.trailing,
    this.trailingColor,
    this.footer,
    this.focused,
    this.raised = false,
    this.style,
    required List<Widget> children,
  }) : padding = TermInset.zero,
       child = Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: children,
       );

  /// The words cut into the top line, at the start, in bold: what the pane
  /// holds. A screen reader hears them as the pane's heading.
  final String? title;

  /// The words cut into the top line at the end, dim: a count, a branch, a
  /// state. Where they and [title] don't both fit on the top line, the
  /// title keeps it and these go to the bottom line's end.
  final String? trailing;

  /// The ink of [trailing] where it is a state to see at a glance (a run
  /// `failed` in the danger ink); null: dim.
  final Color? trailingColor;

  /// The words cut into the bottom line at the start, dim: the keys that
  /// work here, a note. Keys mean nothing under touch: give them only where
  /// [termKeysShown] is true.
  final String? footer;

  /// Whether the line is doubled; null: while focus is inside the pane.
  final bool? focused;

  /// Whether the pane floats over the screen (a dialog, a menu, a toast):
  /// filled with the theme's surface. It casts no shade: the page under it
  /// is not on its lattice, so a shade would cut the page's lines through
  /// their middle; its line and its fill set it off.
  final bool raised;

  /// The room between the line and [child], in cells and lines; null: one
  /// cell at each side.
  final TermInset? padding;

  /// Overrides, over the theme's [TermThemeData.paneStyle]: `edge` (the box
  /// lines; focused while the pane is active), `fill` (the ground) and
  /// `foreground` (the title).
  final TermStyle? style;

  /// What the pane holds.
  final Widget child;

  @override
  State<TermPane> createState() => _TermPaneState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('trailing', trailing, defaultValue: null))
      ..add(StringProperty('footer', footer, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('focused', focused, defaultValue: null))
      ..add(FlagProperty('raised', value: raised, ifTrue: 'raised'))
      ..add(
        DiagnosticsProperty<TermInset>('padding', padding, defaultValue: null),
      );
  }
}

class _TermPaneState extends State<TermPane> {
  bool _within = false;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final direction = Directionality.of(context);
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final pad = (widget.padding ?? const TermInset())
        .on(grid)
        .resolve(direction);
    final stroke = theme.strokeWidth * grid.fontSize / theme.grid.fontSize;
    final active = widget.focused ?? _within;
    final own = TermStyleOf(
      [widget.style, theme.paneStyle],
      {if (active) WidgetState.focused},
    );
    final resting = TermStyleOf([widget.style, theme.paneStyle], const {});
    final title = widget.title;
    final trailing = widget.trailing;
    final trailingColor = widget.trailingColor;
    final footer = widget.footer;
    // Words in a border start two cells in (the line's cell and the cell
    // the child is inset by), so a title stands on its pane's keyline.
    final wordsAt = cw * 2;
    final half = cw / 2;
    TermGap gapFor(String words) =>
        (start: wordsAt - half, end: wordsAt + grid.widthOf(words) + half);

    // Each run of words is isolated (first strong isolate), so a path or a
    // command in a right-to-left app keeps its own order: `~/.config`, not
    // `config./~`.
    // Words longer than their room are cut to it with an ellipsis, so a
    // title never stops mid-letter at the frame's corner.
    Widget border(String words, TextStyle style) => SizedBox(
      height: lh,
      child: LayoutBuilder(
        builder: (context, c) => Text(
          '\u2068${grid.fit(words, c.maxWidth)}\u2069',
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          style: style,
          semanticsLabel: words,
        ),
      ),
    );
    final trailingStyle = trailingColor == null
        ? theme.dimStyle
        : theme.textStyle.copyWith(color: trailingColor);
    // Where the title and the trailing words don't both fit on the top line
    // (a phone, large text), the title keeps the line whole and the
    // trailing words go to the bottom line's end: `#1481 api` stays a name
    // rather than `#1481 a…`, and the state still shows.
    final need = title == null || trailing == null
        ? null
        : wordsAt * 2 + grid.widthOf(title) + cw + grid.widthOf(trailing);
    bool below(double width) => need != null && width + 0.5 < need;
    final trailingRoom = trailing == null ? 0.0 : grid.widthOf(trailing) + cw;

    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        cw + pad.left,
        lh + pad.top,
        cw + pad.right,
        lh + pad.bottom,
      ),
      child: TermPaneScope(active: active, child: widget.child),
    );

    final content = Stack(
      children: [
        body,
        if (title != null || trailing != null)
          PositionedDirectional(
            top: 0,
            start: wordsAt,
            end: wordsAt,
            height: lh,
            child: LayoutBuilder(
              builder: (context, c) {
                final moved = below(c.maxWidth + wordsAt * 2);
                return Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Semantics(
                          container: true,
                          header: true,
                          child: border(
                            title,
                            theme.boldStyle.copyWith(color: own.foreground),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (trailing != null && !moved) ...[
                      SizedBox(width: cw),
                      border(trailing, trailingStyle),
                    ],
                  ],
                );
              },
            ),
          ),
        if (footer != null || need != null)
          PositionedDirectional(
            bottom: 0,
            start: wordsAt,
            end: wordsAt,
            height: lh,
            child: LayoutBuilder(
              builder: (context, c) {
                final moved = below(c.maxWidth + wordsAt * 2);
                return Row(
                  children: [
                    if (footer != null)
                      Expanded(child: border(footer, theme.dimStyle))
                    else
                      const Spacer(),
                    if (moved) ...[
                      SizedBox(width: cw),
                      border(trailing!, trailingStyle),
                    ],
                  ],
                );
              },
            ),
          ),
      ],
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (value) => setState(() => _within = value),
      child: TermSnap(
        grid: grid,
        child: TermSpring(
          target: active ? 1 : 0,
          token: TermMotion.move,
          spatial: true,
          builder: (context, t, child) {
            final color = Color.lerp(
              resting.edge ?? theme.rule,
              own.edge ?? theme.accent,
              t.clamp(0, 1),
            )!;
            final fill = own.fill ?? (widget.raised ? theme.surface : null);
            TermFramePainter frame({required bool moved}) => TermFramePainter(
              grid: grid,
              color: color,
              stroke: stroke,
              doubled: t,
              topGaps: [if (title != null) gapFor(title)],
              topGapsEndInset: wordsAt + (moved ? 0 : trailingRoom) - half,
              topEndGaps: [if (trailing != null && !moved) gapFor(trailing)],
              bottomGaps: [if (footer != null) gapFor(footer)],
              bottomGapsEndInset: wordsAt + (moved ? trailingRoom : 0) - half,
              bottomEndGaps: [if (moved) gapFor(trailing!)],
              fill: fill,
              textDirection: direction,
            );
            return CustomPaint(
              painter: need == null
                  ? frame(moved: false)
                  : _MovingFramePainter(
                      need: need,
                      atRest: frame(moved: false),
                      moved: frame(moved: true),
                    ),
              child: child,
            );
          },
          child: content,
        ),
      ),
    );
  }
}

/// A pane's frame whose top line breaks for the title and the trailing
/// words where both fit ([atRest]), and for the title alone, the trailing
/// words in the bottom line's end, where the pane is narrower than [need]
/// ([moved]).
class _MovingFramePainter extends CustomPainter {
  _MovingFramePainter({
    required this.need,
    required this.atRest,
    required this.moved,
  });

  final double need;
  final TermFramePainter atRest;
  final TermFramePainter moved;

  @override
  void paint(Canvas canvas, Size size) =>
      (size.width + 0.5 < need ? moved : atRest).paint(canvas, size);

  @override
  bool shouldRepaint(_MovingFramePainter old) =>
      old.need != need ||
      atRest.shouldRepaint(old.atRest) ||
      moved.shouldRepaint(old.moved);
}

/// Whether the pane round a part is the one with the keyboard: a list's
/// chosen row is in inverse video in the active pane and a faint shade in
/// the others, so one bright bar and one doubled line say where the keys
/// go. A part in no pane reads as active.
class TermPaneScope extends InheritedWidget {
  /// Says whether the pane round [child] is [active].
  const TermPaneScope({super.key, required this.active, required super.child});

  /// Whether the pane has the keyboard (or is drawn as having it).
  final bool active;

  /// Whether the pane round [context] is active; true outside any pane.
  static bool activeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TermPaneScope>()?.active ??
      true;

  @override
  bool updateShouldNotify(TermPaneScope oldWidget) =>
      active != oldWidget.active;
}
