/// The frames a text field and a select share: three lines, the label cut
/// into the top one and the help or the error into the bottom one; or one
/// line, the label before the value in brackets.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../internal/frame_edge.dart';
import '../internal/list_open.dart';
import '../theme.dart';
import 'box.dart';
import 'control.dart';
import 'spring.dart';

/// Frames a field's [child] (its one line) with [parts]' label and note.
///
/// The line goes heavy in the accent while [active], twice its stroke (as
/// Material's outline goes from 1 to 2 px), and stays one line: the input's
/// own cursor says where the keys are, and a doubled line is a pane's, for
/// the pane the keys are in. It draws in the danger ink while there is an
/// error. While the list the field opens is up, the
/// field stands on the list's raised ground, its whole cells, so the two
/// read as one block. A note too long for the bottom line drops under the
/// frame, wrapped.
class TermFieldFrame extends StatelessWidget {
  /// A frame for [parts] round [child].
  const TermFieldFrame({
    super.key,
    required this.parts,
    required this.active,
    this.edge,
    this.lines = 1,
    required this.child,
  });

  /// The field's label, help and error, from a `RawInputDecorator`.
  final RawInputDecoratorDetails parts;

  /// Whether the field is the one being worked: focused, or its menu open.
  final bool active;

  /// The line's colour in place of the look's.
  final Color? edge;

  /// The lines of words inside the frame: one for a field, more for a
  /// text area.
  final int lines;

  /// The field's line: the input, or the chosen value.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final stroke = termStrokeWidth(theme, grid);
    final direction = Directionality.of(context);
    final enabled = parts.enabled;
    final hasError = parts.hasError;
    final raised = TermListOpen.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = grid.cellWidth;
        final lh = grid.lineHeight;
        // As wide as it is given, as a pane is: a field's frame ends on the
        // line its pane's, a banner's and a list's end on, never a part of
        // a cell short of them.
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : grid.cols(40);
        // Words in the frame's lines start two cells in and end two cells
        // before the far side.
        final room = math.max(0.0, width - cw * 4);
        final note = hasError ? '✗ ${parts.errorText}' : parts.helperText;
        final noteFits = note != null && grid.widthOf(note) <= room;
        TermGap gap(String text) => (
          start: cw * 1.5,
          end: math.min(cw * 2 + grid.widthOf(text) + cw / 2, width - cw * 1.5),
        );
        // A label longer than the frame is cut to it with an ellipsis.
        final label = parts.labelText == null
            ? null
            : grid.fit(parts.labelText!, room);

        Widget line(Widget child, TextStyle style) => SizedBox(
          height: lh,
          child: DefaultTextStyle(
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: child,
          ),
        );

        final noteWidget = hasError
            ? Row(
                mainAxisSize: MainAxisSize.min,
                // The mark on the note's first line, where a wrapped note
                // starts, as a terminal prints it.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcludeSemantics(child: Text('✗ ')),
                  Flexible(child: parts.error!),
                ],
              )
            : parts.helper;
        final noteStyle = hasError
            ? theme.textStyle.copyWith(color: theme.danger)
            : theme.dimStyle;

        final frame = TermSpring(
          target: active ? 1 : 0,
          token: TermMotion.move,
          focus: true,
          builder: (context, t, child) => Stack(
            children: [
              // While the list is up, the field stands on its ground out to
              // where the list's frame has its outer edge, so the two read
              // as one block, edge on edge; its frame stays drawn on it.
              if (raised)
                Positioned(
                  left: termRaisedEdge(grid, stroke),
                  right: termRaisedEdge(grid, stroke),
                  top: lh / 2,
                  bottom: lh / 2,
                  child: ColoredBox(color: theme.surface),
                ),
              CustomPaint(
                painter: TermFramePainter(
                  grid: grid,
                  color: _edgeColor(theme, parts, edge, t),
                  stroke: stroke * (1 + t.clamp(0.0, 1.0)),
                  topGaps: [if (label != null) gap(label)],
                  bottomGaps: [if (noteFits) gap(note)],
                  textDirection: direction,
                ),
                child: child,
              ),
            ],
          ),
          child: SizedBox(
            width: width,
            height: lh * (lines + 2),
            child: Stack(
              children: [
                // The label is words only: the control carries its name.
                if (label != null)
                  PositionedDirectional(
                    top: 0,
                    start: cw * 2,
                    end: cw * 2,
                    child: line(
                      ExcludeSemantics(child: Text(label)),
                      theme.textStyle.copyWith(
                        color: enabled ? theme.foreground : theme.rule,
                      ),
                    ),
                  ),
                if (noteFits && noteWidget != null)
                  PositionedDirectional(
                    top: lh * (lines + 1),
                    start: cw * 2,
                    end: cw * 2,
                    child: line(noteWidget, noteStyle),
                  ),
                // The input over the whole frame, its words on the middle
                // line: a tap anywhere in the frame reaches it (three lines,
                // over a finger's floor), and a screen reader outlines the
                // frame.
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  start: cw * 2,
                  end: cw * 2,
                  child: child,
                ),
              ],
            ),
          ),
        );
        // From the start, under a parent that sets the width too.
        if (noteFits || noteWidget == null) {
          return Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: 1,
            child: frame,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            frame,
            Padding(
              padding: EdgeInsetsDirectional.only(start: cw * 2, end: cw * 2),
              child: DefaultTextStyle(style: noteStyle, child: noteWidget),
            ),
          ],
        );
      },
    );
  }
}

/// A field's line colour: [edge] if given, else faded while disabled, the
/// danger ink with an error, else from the rule to the accent as [t] (the
/// focus) comes.
Color _edgeColor(
  TermThemeData theme,
  RawInputDecoratorDetails parts,
  Color? edge,
  double t,
) =>
    edge ??
    (!parts.enabled
        ? theme.rule.withValues(alpha: 0.6)
        : parts.invalid
        ? theme.danger
        : Color.lerp(theme.rule, theme.accent, t.clamp(0, 1))!);

/// A field on one line, as a config file or a terminal program's form lays
/// one out: [parts]' label, then the value in brackets, `[ value ]`, and
/// the help or the error on the line under the value.
///
/// [labelCols] gives the label a width in cells, so that the brackets of
/// the fields above and below line up; without it the label takes its own
/// width. When the line has fewer than twelve cells left for the value, the
/// label stands on a line of its own above it. The brackets go heavy in the
/// accent while [active], and stand on the list's raised ground while the
/// list the field opens is up; the line is as tall as the tap target's
/// floor. [control] puts the field's control round the brackets alone (a
/// select's press, its menu hung from them), so the label is the line's
/// words, not the control's.
class TermFieldLine extends StatelessWidget {
  /// A one-line field for [parts] round [child].
  const TermFieldLine({
    super.key,
    required this.parts,
    required this.active,
    this.edge,
    this.labelCols,
    this.control,
    required this.child,
  });

  /// Puts the control round the brackets: given `brackets`, which draws
  /// them for the control's `active` and `edge`, the control's widget. Null:
  /// the brackets drawn for [active] and [edge], the control round the whole
  /// line.
  final Widget Function(Widget Function(bool active, Color? edge) brackets)?
  control;

  /// The field's label, help and error, from a `RawInputDecorator`.
  final RawInputDecoratorDetails parts;

  /// Whether the field is the one being worked: focused, or its menu open.
  final bool active;

  /// The brackets' colour in place of the look's.
  final Color? edge;

  /// The label's width in cells, or null for the label's own.
  final int? labelCols;

  /// The value: the input, or the chosen value.
  final Widget child;

  /// How far from the start the brackets stand on a line [width] wide,
  /// for a label [labelText] [labelCols] wide: zero when the label stands
  /// above. A select's menu starts there.
  static double indentOf(
    TermGrid grid,
    double width,
    String? labelText,
    int? labelCols,
  ) {
    if (labelText == null) return 0;
    final cols = width.isFinite ? grid.colsIn(width) : 60;
    final key = labelCols ?? (grid.widthOf(labelText) / grid.cellWidth).ceil();
    return cols - key - 1 < 12 ? 0 : grid.cols(key + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final stroke = termStrokeWidth(theme, grid);
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final floor = DesignTapTargets.of(context).floorOn();
    final height = math.max(lh, grid.ceil(floor).height);
    final labelText = parts.labelText;
    final raised = TermListOpen.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth.isFinite
            ? grid.colsIn(constraints.maxWidth)
            : 60;
        final indent = indentOf(
          grid,
          constraints.maxWidth,
          labelText,
          labelCols,
        );
        final stacked = labelText != null && indent == 0;
        final boxWidth = grid.cols(cols) - indent;

        // The label is words only: the control carries its name.
        Widget? label;
        if (labelText != null) {
          label = ExcludeSemantics(
            child: Text(
              labelText,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: theme.textStyle.copyWith(
                color: parts.enabled ? theme.foreground : theme.rule,
              ),
            ),
          );
        }

        // While the list is up, the field stands on its ground out to where
        // the list's frame (a raised pane's double line) has its outer edge,
        // so the two read as one block, and its brackets stay drawn on it.
        final groundInset = termRaisedEdge(grid, stroke);
        Widget brackets(bool active, Color? edge) => TermSpring(
          target: active ? 1 : 0,
          token: TermMotion.move,
          focus: true,
          builder: (context, t, child) => CustomPaint(
            foregroundPainter: TermBracketPainter(
              grid: grid,
              color: _edgeColor(theme, parts, edge, t),
              stroke: stroke * (1 + t.clamp(0.0, 1.0)),
            ),
            child: child,
          ),
          child: SizedBox(
            width: boxWidth,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (raised)
                  Positioned.fill(
                    left: groundInset,
                    right: groundInset,
                    child: ColoredBox(color: theme.surface),
                  ),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: cw * 2),
                  child: child,
                ),
              ],
            ),
          ),
        );
        final box = control?.call(brackets) ?? brackets(active, edge);

        final note = parts.hasError
            ? Row(
                mainAxisSize: MainAxisSize.min,
                // The mark on the note's first line, where a wrapped note
                // starts, as a terminal prints it.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcludeSemantics(child: Text('✗ ')),
                  Flexible(child: parts.error!),
                ],
              )
            : parts.helper;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stacked && label != null) SizedBox(height: lh, child: label),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!stacked && label != null) ...[
                  SizedBox(
                    width: indent - cw,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: label,
                    ),
                  ),
                  SizedBox(width: cw),
                ],
                box,
              ],
            ),
            if (note != null)
              Padding(
                padding: EdgeInsetsDirectional.only(start: indent + cw * 2),
                child: DefaultTextStyle(
                  style: parts.hasError
                      ? theme.textStyle.copyWith(color: theme.danger)
                      : theme.dimStyle,
                  child: note,
                ),
              ),
          ],
        );
      },
    );
  }
}
