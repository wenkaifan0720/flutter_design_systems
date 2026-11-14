// Rows and small sets: the engraved list, its rows, stats in small wells, the one figure, the nudge. Every number that
// aligns in a column is tabular; a figure standing alone stays proportional.
import 'component_themes.dart';

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'chrome_metrics.dart';
import 'controls.dart';
import 'frames.dart';
import 'heads.dart';
import 'internal/beside.dart';
import 'internal/cell_bank.dart';
import 'internal/geometry.dart';
import 'internal/group_rows.dart';
import 'layout.dart';
import 'ornaments.dart';
import 'theme.dart';
import 'internal/cap_label.dart';

class _TopRule extends CustomPainter {
  _TopRule(this.c, this.flat, this.thickness);
  final double thickness;
  final NeumorphicColors c;
  final bool flat;
  @override
  void paint(Canvas canvas, Size s) => neumorphicPaintEngraved(
    canvas,
    Offset.zero,
    s.width,
    c,
    flat: flat,
    thickness: thickness,
  );
  @override
  bool shouldRepaint(_TopRule o) =>
      o.c != c || o.flat != flat || o.thickness != thickness;
}

/// A child under the one line the look has: a crease over a catch-light. [rule] off: the first of a list.
///
/// ```dart
/// NeumorphicRuled(child: Text('A row'))
/// ```
class NeumorphicRuled extends StatelessWidget {
  /// Creates a [NeumorphicRuled].
  const NeumorphicRuled({super.key, required this.child, this.rule = true});

  /// The content placed inside this component.
  final Widget child;

  /// Whether to draw the leading separator.
  final bool rule;
  @override
  Widget build(BuildContext context) {
    const width = neumorphicRuleWidth;
    if (!rule) return child;
    // The rule is a box of its own, the crease and its catch-light high: the row under it paints nothing, so it reads
    // as a divider over a row, not as a face holding the row.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: width),
          child: child,
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          height: 2 * width,
          child: CustomPaint(
            painter: _TopRule(
              NeumorphicTheme.of(context).colors,
              NeumorphicFlatScope.of(context),
              width,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rows on the column they're given: each row draws its own rule.
///
/// ```dart
/// NeumorphicList(children: [NeumorphicKvRow('A', '1', isFirst: true), NeumorphicKvRow('B', '2')])
/// ```
class NeumorphicList extends StatelessWidget {
  /// Creates a [NeumorphicList].
  const NeumorphicList({super.key, required this.children});

  /// The content widgets, in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => NeumorphicColumn(children: children);
}

/// A label and its value on one line, the value at the end and bold. When they can't share a line the value drops under
/// and reads from the start, as the label does.
///
/// ```dart
/// NeumorphicKvRow('A label', 'A value', isFirst: true)
/// ```
class NeumorphicKvRow extends StatelessWidget {
  /// Creates a [NeumorphicKvRow].
  const NeumorphicKvRow(
    this.label,
    this.value, {
    super.key,
    this.isFirst = false,
    this.live = false,
  });

  /// The text identifying this item or control.
  final String label;

  /// The formatted value paired with the label.
  final String value;

  /// No line above: the first row of a list.
  final bool isFirst;

  /// The value is live: pigment words.
  final bool live;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicRuled(
      rule: !isFirst,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: NeumorphicSplit(
          gap: 12,
          start: Text(
            label,
            style: t.textTheme.caption.copyWith(color: t.colors.inkSecondary),
          ),
          end: live
              ? NeumorphicLiveText(value, large: true)
              // A value that wraps has dropped under (it was laid out the row's width), so its lines start where
              // the label's do; on one line beside the label it stands at the end either way.
              : Text(
                  value,
                  style: t.textTheme.caption
                      .copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.colors.ink,
                      )
                      .tabular,
                ),
        ),
      ),
    );
  }
}

/// A list's last line: what it adds up to, in the value size.
///
/// ```dart
/// NeumorphicTotalRow('Total', '1,204')
/// ```
class NeumorphicTotalRow extends StatelessWidget {
  /// Creates a [NeumorphicTotalRow].
  const NeumorphicTotalRow(this.label, this.value, {super.key});

  /// The text identifying this item or control.
  final String label;

  /// The formatted total paired with the label.
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicRuled(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: NeumorphicSplit(
          gap: 12,
          start: Text(label, style: t.textTheme.title),
          end: Text(value, style: t.textTheme.value.tabular),
        ),
      ),
    );
  }
}

/// Where a step stands: done and gone, the one that's live, or the one ahead.
/// The progress state of a timeline step.
enum NeumorphicStepStatus {
  /// A completed step.
  past,

  /// The current step.
  live,

  /// An upcoming step.
  next,
}

/// One timed step of a list: a time, a dot, the words, a value. The live one goes to the pigment whole. Put them in a `NeumorphicWell`.
///
/// ```dart
/// NeumorphicStepRow(time: '19:45', title: 'A step, now', value: '21.5', state: NeumorphicStepStatus.live)
/// ```
class NeumorphicStepRow extends StatelessWidget {
  /// Creates a [NeumorphicStepRow].
  const NeumorphicStepRow({
    super.key,
    required this.time,
    required this.title,
    this.value,
    this.state = NeumorphicStepStatus.past,
    this.isFirst = false,
  });

  /// The displayed time of this step.
  final String time;

  /// The primary heading.
  final String title;

  /// An optional formatted value at the end of the row.
  final String? value;

  /// Whether this step is past, current or upcoming.
  final NeumorphicStepStatus state;

  /// Whether this is the first row, without a preceding separator.
  final bool isFirst;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final live = state == NeumorphicStepStatus.live;
    final strong = t.textTheme.caption
        .copyWith(
          fontWeight: FontWeight.w700,
          color: live ? c.pigmentInk : c.ink,
        )
        .tabular;
    final words = t.textTheme.caption.copyWith(
      color: live ? c.pigmentInk : c.inkSecondary,
      fontWeight: live ? FontWeight.w700 : FontWeight.w500,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final timeWidth = neumorphicWidestWord(
      time,
      strong,
      textScaler: scaler,
    ).clamp(44.0, 96.0);
    final valueWidth = value == null
        ? 0.0
        : neumorphicWidestWord(
            value!,
            strong,
            textScaler: scaler,
          ).clamp(0.0, 112.0);
    final titleWidth = neumorphicWidestWord(title, words, textScaler: scaler);
    final dot = neumorphicPaint(8, 8, (c, state), (canvas, s) {
      final mid = s.center(Offset.zero);
      switch (state) {
        case NeumorphicStepStatus.past:
          canvas.drawCircle(mid, 4, neumorphicFillPaint(c.quiet));
        case NeumorphicStepStatus.live:
          canvas.drawCircle(mid, 4, neumorphicFillPaint(c.pigment));
        case NeumorphicStepStatus.next:
          canvas.drawCircle(mid, 3, neumorphicStrokePaint(c.inkTertiary, 2));
      }
    });
    return NeumorphicRuled(
      rule: !isFirst,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: LayoutBuilder(
          builder: (context, box) {
            // A desktop sidebar can be narrower than a phone. Keep the
            // title's longest word intact by moving its facts above it.
            final needed =
                timeWidth +
                32 +
                titleWidth +
                (value == null ? 0 : 12 + valueWidth);
            if (box.maxWidth < needed) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(time, style: strong),
                      dot,
                      if (value != null) Text(value!, style: strong),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: words),
                ],
              );
            }
            return Row(
              children: [
                SizedBox(
                  width: timeWidth,
                  child: Text(time, style: strong),
                ),
                const SizedBox(width: 12),
                dot,
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: words)),
                if (value != null) ...[
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      style: strong,
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
}

/// A person: a monogram, a name, a line about them. Their LED says they're here.
///
/// ```dart
/// NeumorphicWhoRow(initials: 'MA', name: 'A name', note: 'Here since 17:40', led: true, isFirst: true)
/// ```
class NeumorphicWhoRow extends StatelessWidget {
  /// Creates a [NeumorphicWhoRow].
  const NeumorphicWhoRow({
    super.key,
    required this.initials,
    required this.name,
    this.note,
    this.led = false,
    this.isFirst = false,
  });

  /// The initials shown when no usable image is available.
  final String initials;

  /// The name displayed for this item.
  final String name;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// Whether to show the live indicator.
  final bool led;

  /// Whether this is the first row, without a preceding separator.
  final bool isFirst;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // Up and down only: its monogram starts on the list's keyline, as every row's first item does. It stands under
    // the list's one line and keeps a row's height, as its neighbours do: at 6 up and down and with no line it read
    // as a squeezed head of the row under it.
    return NeumorphicRuled(
      rule: !isFirst,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: NeumorphicFitRow(
          fill: 1,
          gap: 14,
          children: [
            // The list's one leading slot: a mark of any width, its words on the same line as every row's.
            SizedBox(
              width: 44,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: NeumorphicMonogram(initials, led: led),
              ),
            ),
            NeumorphicColumn(
              children: [
                Text(name, style: t.textTheme.title),
                if (note != null)
                  Text(note!, style: t.textTheme.caption.tabular),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The list row: a mark, a title and its meta, a state beside them, an action. It measures its own width: from 520 wide the action
/// sits at the end; under that it goes under the words, so the title keeps its line. A hand-written `Row` of words and a button
/// leaves the title a few letters a line. [selected]: the row a list beside its detail has open; its band goes in, as a
/// bank's chosen cell does.
///
/// ```dart
/// NeumorphicListTile(title: 'A title', subtitle: 'A small line', leading: const NeumorphicIconWell(NeumorphicGlyphs.lock, live: true), trailing: const NeumorphicStatus('Held'), action: NeumorphicButton('Open', onPressed: () {}))
/// ```
class NeumorphicListTile extends StatelessWidget {
  /// Creates a [NeumorphicListTile].
  const NeumorphicListTile({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.title,
    this.subtitle,
    this.note,
    this.leading,
    this.trailing,
    this.action,
    this.onPressed,
    this.selected = false,
    this.isFirst = false,
    this.dense = false,
    this.top = false,
  });

  /// The primary heading.
  final String title;

  /// Secondary information displayed beside the heading.
  final String? subtitle;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// A monogram, an icon well, a `NeumorphicMedia(width: 56)`: its own width stays.
  final Widget? leading;

  /// A figure or a `NeumorphicStatus` beside the title, held to a share of the row.
  final Widget? trailing;

  /// A `NeumorphicButton`, one or two words, or a control the row's thing needs: a cart line's
  /// `NeumorphicNumberField`. Under 520 wide it goes under the words.
  final Widget? action;

  /// The whole row opens something.
  final VoidCallback? onPressed;

  /// The row that is open beside the list: its band is pressed in, under the wash, and it is announced selected. In a
  /// grouped list the band is the row's cell of the card; elsewhere it runs 12 past the row on each side.
  final bool selected;

  /// No line above: the first of a list.
  final bool isFirst;

  /// A list inside a rail or a small card: a caption's title over a micro's meta.
  final bool dense;

  /// The mark stands at the row's top, for a meta that may wrap.
  final bool top;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final titleStyle = dense
        ? t.textTheme.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: t.colors.ink,
          )
        : t.textTheme.title;
    final told = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A one-line row's title stands on the row's middle by its capitals.
        neumorphicLabel(Text(title, style: titleStyle)),
        if (subtitle != null)
          Text(
            subtitle!,
            style: (dense ? t.textTheme.micro : t.textTheme.caption).tabular,
          ),
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(note!, style: t.textTheme.caption),
        ],
      ],
    );
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 520;
          final mark = leading == null
              ? const <Widget>[]
              : <Widget>[leading!, const SizedBox(width: 14)];
          final align = top
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center;
          // The figure stands beside the words, or under them when beside them the title's longest word would no
          // longer fit: 'On \u00b7 70%' at twice the text squeezed a title until 'Pendants' broke in two, while an
          // onward glyph never needs to move.
          final Widget words = trailing == null
              ? told
              : wide
              ? Row(
                  crossAxisAlignment: align,
                  children: [
                    Expanded(child: told),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: c.maxWidth * .3),
                      child: trailing,
                    ),
                  ],
                )
              : BesideOrUnder(
                  need:
                      neumorphicWidestWord(
                        title,
                        DefaultTextStyle.of(context).style.merge(titleStyle),
                        textScaler: MediaQuery.textScalerOf(context),
                      ) +
                      1,
                  centre: !top,
                  children: [told, trailing!],
                );
          if (wide || action == null) {
            return Row(
              crossAxisAlignment: align,
              children: [
                ...mark,
                Expanded(child: words),
                if (action != null) ...[const SizedBox(width: 14), action!],
              ],
            );
          }
          // The words and the action under them start on a keyline of their own, after the mark: one region, so the
          // action keeps the words' keyline. The mark stands on the words' middle alone, as it does in a row with no
          // action: on words and action together, a row with a stepper under it set its mark at the top while its
          // neighbour's stood centred. The words are measured as their lines at the reader's size.
          double lineOf(TextStyle style) {
            final painter = TextPainter(
              text: TextSpan(text: 'Hg', style: style),
              textDirection: TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 1,
            )..layout();
            final h = painter.height;
            painter.dispose();
            return h;
          }

          final wordsTall =
              lineOf(titleStyle) +
              (subtitle == null
                  ? 0
                  : lineOf(dense ? t.textTheme.micro : t.textTheme.caption));
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                if (top)
                  leading!
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: wordsTall),
                    child: Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: leading,
                    ),
                  ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: DesignKeylineRegion(
                  label: 'words',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The figure stands where it stands without an action, beside the words; the action goes under.
                      words,
                      const SizedBox(height: 10),
                      action!,
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    // In a grouped list the row is a band of the card, a breath inside its rim: the focus lift goes round that band, as a
    // bank's cell's does, and the press sinks the whole band; both follow the card's corners where they meet them. A chosen
    // row outside a group takes a band of its own, a control's corners, 12 past it on each side; its lift stays the
    // row's. The band's wrapper is always there, so choosing a row never remounts it (and never drops its focus).
    final cell = NeumorphicGroupRowScope.cellOf(context);
    if (onPressed != null) {
      // A row that presses is at least a target tall, so its face fills its tap: a shorter face would be centred in the
      // target and stand a pixel off the card's padding.
      row = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: NeumorphicChromeMetrics.targetSize,
        ),
        child: row,
      );
      row = NeumorphicTap(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label: title,
        selected: selected,
        // The chosen band is already in; a press on another row shows it going in.
        pressRelief: !selected,
        shape: cell?.border,
        faceOutset: cell?.outset ?? EdgeInsets.zero,
        focusReach: cell == null ? 1 : .5,
        child: row,
      );
    } else if (selected) {
      row = Semantics(selected: true, child: row);
    }
    row = NeumorphicChosenBand(
      chosen: selected,
      border: cell?.border ?? t.shapes.corner(NeumorphicRadii.control),
      outset: cell?.outset ?? const EdgeInsets.symmetric(horizontal: 12),
      child: row,
    );
    return NeumorphicRuled(rule: !isFirst, child: row);
  }
}

/// A thing to do: a round check and its words. Done: pressed, with an ink tick, its words struck. [live]: the note is due now.
///
/// ```dart
/// NeumorphicTodoRow(title: 'A thing to do', note: 'Due today', live: true, onChanged: (v) {})
/// ```
class NeumorphicTodoRow extends StatelessWidget {
  /// Creates a [NeumorphicTodoRow].
  const NeumorphicTodoRow({
    super.key,
    required this.title,
    this.note,
    this.value = false,
    this.live = false,
    this.onChanged,
    this.isFirst = false,
  });

  /// The primary heading.
  final String title;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// Whether the task is complete.
  final bool value;

  /// Whether to emphasize the active state with the pigment colour.
  final bool live;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool>? onChanged;

  /// Whether this is the first row, without a preceding separator.
  final bool isFirst;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    return MergeSemantics(
      child: NeumorphicRuled(
        rule: !isFirst,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              // The list's one leading slot, so the title stands where every row's does.
              SizedBox(
                width: 44,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: NeumorphicRoundCheckbox(
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: t.textTheme.title.copyWith(
                        color: value ? c.inkTertiary : c.ink,
                        decoration: value ? TextDecoration.lineThrough : null,
                        decorationColor: c.inkTertiary,
                      ),
                    ),
                    if (note != null)
                      Text(
                        note!,
                        style: t.textTheme.caption
                            .copyWith(
                              color: live ? c.pigmentInk : c.inkTertiary,
                            )
                            .tabular,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thing that's on or off and has a level: a pressed round icon, its name and state, a switch, and while on a slider and its
/// figure. On reads three ways with no shadow: the pigment in the icon and the words, the words themselves, the filled slot.
///
/// ```dart
/// NeumorphicLevelRow(icon: NeumorphicGlyphs.lamp, title: 'A lamp', state: 'On, 30%', value: true, level: .3, figure: '30%', onChanged: (v) {}, onLevel: (v) {})
/// ```
class NeumorphicLevelRow extends StatelessWidget {
  /// Creates a [NeumorphicLevelRow].
  const NeumorphicLevelRow({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.icon,
    required this.title,
    required this.state,
    this.value = false,
    this.level,
    this.figure,
    this.onChanged,
    this.onLevel,
    this.isFirst = false,
  });

  /// The glyph displayed with the content.
  final IconData icon;

  /// The primary heading.
  final String title;

  /// A short description of the current setting.
  final String state;

  /// Whether the setting is on.
  final bool value;

  /// 0 to 1. With no level, or while off, there's no slider.
  final double? level;

  /// The level in words, at the slider's end.
  final String? figure;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<bool>? onChanged;

  /// Reports a user-requested level change.
  final ValueChanged<double>? onLevel;

  /// Whether this is the first row, without a preceding separator.
  final bool isFirst;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    // Under a level the row's foot is the slider's own target below its thumb: 14 more stood 50 of dead floor under
    // the thumb against 14 under a row's words.
    final leveled = value && level != null;
    return NeumorphicRuled(
      rule: !isFirst,
      child: Padding(
        padding: EdgeInsets.only(top: 14, bottom: leveled ? 3 : 14),
        child: NeumorphicColumn(
          gap: 12,
          children: [
            Row(
              children: [
                NeumorphicIconWell(icon, live: value),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: t.textTheme.title),
                      Text(
                        state,
                        style: t.textTheme.caption
                            .copyWith(
                              color: value ? c.pigmentInk : c.inkTertiary,
                              fontWeight: value
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            )
                            .tabular,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                NeumorphicSwitch(
                  focusNode: focusNode,
                  autofocus: autofocus,
                  label: title,
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
            // The level stands under the words: a keyline of its own, after the well.
            if (leveled)
              DesignKeylineRegion(
                label: 'level',
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 58),
                  child: Row(
                    children: [
                      Expanded(
                        child: NeumorphicSlider(
                          label: title,
                          value: level!,
                          onChanged: onLevel,
                        ),
                      ),
                      if (figure != null) ...[
                        const SizedBox(width: 14),
                        SizedBox(
                          width: neumorphicWidestWord(
                            figure!,
                            t.textTheme.caption
                                .copyWith(fontWeight: FontWeight.w700)
                                .tabular,
                            textScaler: MediaQuery.textScalerOf(context),
                          ).clamp(40.0, 96.0),
                          child: Text(
                            figure!,
                            textAlign: TextAlign.end,
                            style: t.textTheme.caption
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: c.ink,
                                )
                                .tabular,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One stat of a [NeumorphicStats].
class NeumorphicStat {
  /// Creates a [NeumorphicStat].
  const NeumorphicStat(this.label, this.value, [this.unit]);

  /// The text identifying this item or control.
  final String label;

  /// The formatted numeric value.
  final String value;

  /// A unit displayed alongside the value.
  final String? unit;
}

/// A few stats, each in a small pressed well: a label over a figure and its unit. As many on a row as hold their widest words.
///
/// ```dart
/// NeumorphicStats(const [NeumorphicStat('Using now', '1.8', 'kW'), NeumorphicStat('Made', '3.0', 'kWh')])
/// ```
class NeumorphicStats extends StatelessWidget {
  /// Creates a [NeumorphicStats].
  const NeumorphicStats(
    this.items, {
    super.key,
    this.style,
    this.gap = 10,
    this.side = 14,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The statistics, in display order.
  final List<NeumorphicStat> items;

  /// Space between adjacent children, in logical pixels.
  final double gap;

  /// A stat's side padding.
  final double side;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        var need = 0.0;
        for (final e in items) {
          need = math.max(
            need,
            neumorphicWidestWord(
              e.label,
              t.textTheme.micro,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          );
          need = math.max(
            need,
            neumorphicWidestWord(
              e.value,
              t.textTheme.value,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          );
        }
        final w = box.hasBoundedWidth ? box.maxWidth : 390.0;
        final fit = ((w + gap) / (need + 2 * side + gap)).floor().clamp(
          1,
          items.length,
        );
        // Full rows where a narrower count gives them: three stats two to a row left a hole beside the third, so
        // they stand one to a row; four stand two and two. Three or more to a row keep their count.
        var columns = fit;
        if (fit < items.length) {
          for (var c = fit; c >= (fit < 3 ? 1 : 2); c--) {
            if (items.length % c == 0) {
              columns = c;
              break;
            }
          }
        }
        return NeumorphicGridOf(
          columns: columns,
          gap: gap,
          runGap: gap,
          children: [
            for (final e in items)
              NeumorphicWell(
                style: style,
                small: true,
                padding: EdgeInsets.symmetric(horizontal: side, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.label, style: t.textTheme.micro),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: e.value),
                            if (e.unit != null)
                              TextSpan(
                                text: ' ${e.unit}',
                                style: t.textTheme.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: t.colors.inkSecondary,
                                ),
                              ),
                          ],
                        ),
                        style: t.textTheme.value.tabular,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A card's one hero number: 48 at weight 300, its unit, and what it did. One a card. It stays proportional, not tabular.
///
/// ```dart
/// NeumorphicFigure('17.8', unit: 'kWh used', delta: '9% below yesterday', icon: NeumorphicGlyphs.trendingDown)
/// ```
class NeumorphicFigure extends StatelessWidget {
  /// Creates a [NeumorphicFigure].
  const NeumorphicFigure(
    this.value, {
    super.key,
    this.unit,
    this.delta,
    this.icon,
  });

  /// The main formatted value.
  final String value;

  /// A unit displayed alongside the value.
  final String? unit;

  /// An optional formatted change from a prior value.
  final String? delta;

  /// The glyph displayed with the content.
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final style = t.textTheme.caption.copyWith(
      fontWeight: FontWeight.w700,
      color: c.ink,
    );
    return NeumorphicColumn(
      gap: 2,
      children: [
        NeumorphicFitRow(
          fill: unit == null ? 0 : 1,
          gap: 8,
          shrink: true,
          align: NeumorphicFitAlign.baseline,
          children: [
            Text(value, style: t.textTheme.figure),
            if (unit != null)
              Text(
                unit!,
                style: t.textTheme.value.copyWith(
                  color: c.inkSecondary,
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
        if (delta != null)
          NeumorphicFitRow(
            fill: icon == null ? 0 : 1,
            gap: 6,
            shrink: true,
            children: [
              if (icon != null) Icon(icon, size: 16, color: c.ink),
              Text(delta!, style: style),
            ],
          ),
      ],
    );
  }
}

/// A short note and its act, on a slab: the one thing the page thinks you should do. Carries the page's one `NeumorphicButton.filled`. On a
/// phone its icon well stands first and the act drops under the words.
///
/// ```dart
/// NeumorphicNudge(title: 'This has been on since 16:10.', note: 'Nobody is using it.', icon: NeumorphicGlyphs.lamp, action: NeumorphicButton.filled('Turn off', icon: NeumorphicGlyphs.power, onPressed: () {}))
/// ```
class NeumorphicNudge extends StatelessWidget {
  /// Creates a [NeumorphicNudge].
  const NeumorphicNudge({
    super.key,
    this.style,
    required this.title,
    this.eyebrow,
    this.note,
    this.icon,
    this.action,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The primary heading.
  final String title;

  /// A short introductory line inside the same face as the heading.
  final String? eyebrow;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// An optional action beside the message.
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicColumn(
      gap: 2,
      children: [
        if (eyebrow != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NeumorphicEyebrow(eyebrow!),
          ),
        Text(title, style: t.textTheme.title),
        if (note != null) Text(note!, style: t.textTheme.caption),
      ],
    );
    return NeumorphicSlab(
      style: style,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth >= 380 && t.desk) {
            return Row(
              children: [
                Expanded(child: words),
                if (action != null) ...[const SizedBox(width: 14), action!],
              ],
            );
          }
          final top = icon == null
              ? words
              : NeumorphicFitRow(
                  fill: 1,
                  gap: 14,
                  children: [NeumorphicIconWell(icon!, live: true), words],
                );
          return NeumorphicColumn(
            gap: 14,
            children: [
              top,
              if (action != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: icon == null ? 0 : 58,
                  ),
                  child: action,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A control with its label and help: one line of a form, for a control that draws no label of its own (a segmented
/// button, a stepper, a slider). The label and the help are a text field's own, so the form keeps one label style.
///
/// ```dart
/// NeumorphicFormGroup(label: 'Pay with', child: NeumorphicSegmentedButton<String>(label: 'Pay with', segments: ways, value: way, onChanged: setWay))
/// ```
class NeumorphicFormGroup extends StatelessWidget {
  /// Creates a [NeumorphicFormGroup].
  const NeumorphicFormGroup({
    super.key,
    required this.label,
    this.help,
    required this.child,
  });

  /// The text identifying this item or control.
  final String label;

  /// Supporting instructions below the group label.
  final String? help;

  /// The content placed inside this component.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicColumn(
      gap: 8,
      children: [
        Text(
          label,
          style: t.textTheme.caption.copyWith(fontWeight: FontWeight.w700),
        ),
        child,
        if (help != null) Text(help!, style: t.textTheme.caption),
      ],
    );
  }
}

/// A section with nothing in it yet: the look's mark in a well, a title, a line. A chart with no data draws this, not an empty axis.
///
/// ```dart
/// NeumorphicEmptyState(title: 'Nothing here yet', body: 'It will show up here when the first one comes in.')
/// ```
class NeumorphicEmptyState extends StatelessWidget {
  /// Creates a [NeumorphicEmptyState].
  const NeumorphicEmptyState({
    super.key,
    this.style,
    required this.title,
    this.body,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The primary heading.
  final String title;

  /// Supporting text explaining the empty state.
  final String? body;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return NeumorphicWell(
      style: style,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: NeumorphicColumn(
          gap: 10,
          children: [
            const Center(child: NeumorphicMark(size: 44)),
            Text(title, textAlign: TextAlign.center, style: t.textTheme.title),
            if (body != null)
              Text(
                body!,
                textAlign: TextAlign.center,
                style: t.textTheme.caption,
              ),
          ],
        ),
      ),
    );
  }
}
