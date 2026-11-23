// Rows and small sets: the engraved list, its rows, stats in small wells, the one figure, the nudge. Every number that
// aligns in a column is tabular; a figure standing alone stays proportional.
import 'component_themes.dart';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('rule', rule, defaultValue: true));
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('value', value))
      ..add(DiagnosticsProperty<bool>('isFirst', isFirst, defaultValue: false))
      ..add(DiagnosticsProperty<bool>('live', live, defaultValue: false));
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('value', value));
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('time', time))
      ..add(StringProperty('title', title))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(
        EnumProperty<NeumorphicStepStatus>(
          'state',
          state,
          defaultValue: NeumorphicStepStatus.past,
        ),
      )
      ..add(DiagnosticsProperty<bool>('isFirst', isFirst, defaultValue: false));
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
    // Up and down only: its monogram starts on the list's keyline, as every row's first item does. It stands under the
    // list's one line and keeps a row's height, as its neighbours do: at 6 up and down and with no line it would read
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('initials', initials))
      ..add(StringProperty('name', name))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('led', led, defaultValue: false))
      ..add(DiagnosticsProperty<bool>('isFirst', isFirst, defaultValue: false));
  }
}

/// The list row: a mark, a title and its meta, a state beside them, an action. A compact action (an icon key, no wider
/// than a touch target) stands at the row's end beside the words at every width; a wider one sits at the end from 520
/// wide and goes under the words below that, so the title keeps its line. A hand-written `Row` of words and a button
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
    this.semanticLabel,
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

  /// The accessible name for a tappable row. By default it includes the title,
  /// subtitle and note, in reading order.
  final String? semanticLabel;

  /// A monogram, an icon well, a `NeumorphicMedia(width: 56)`: its own width stays.
  final Widget? leading;

  /// A figure or a `NeumorphicStatus` beside the title, held to a share of the row.
  final Widget? trailing;

  /// A row's menu key (a `NeumorphicIconButton`), a `NeumorphicButton` of one or two words, or a control the row's
  /// thing needs: a cart line's `NeumorphicNumberField`. A key no wider than its touch target stays at the row's end,
  /// beside the words, at every width; its target stands in the row's padding, so a row of a title and its line keeps
  /// the height it has without it. A wider action goes under the words below 520 wide. In a row that opens
  /// ([onPressed]) it stays a key of its own, inside the row's band: a screen reader hears the row and the control
  /// as two buttons.
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

  /// The mark and the key stand at the row's top even while the words keep to two lines. Words of three lines or
  /// more (a title, its line and a note, or a title that wraps) stand them there by themselves, as Material 3's list
  /// items do.
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
    // A row that opens and holds a control of its own: the press lies under the row as its own key, and the words
    // and mark only show, so the control stays a key a screen reader reaches, inside the row's band.
    final split = onPressed != null && action != null;
    Widget passive(Widget part) =>
        split ? IgnorePointer(child: ExcludeSemantics(child: part)) : part;
    final lead = leading == null ? null : passive(leading!);
    final told = passive(
      Column(
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
      ),
    );
    Widget layout(BuildContext context, BoxConstraints c) {
      final wide = c.maxWidth >= 520;
      // A title, its line and a note are three lines: the figure beside them stands at their top, as the mark does.
      final align = top || (subtitle != null && note != null)
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center;
      // The title's widest word at the reader's size: the room the words keep beside a figure or a key.
      late final need =
          neumorphicWidestWord(
            title,
            DefaultTextStyle.of(context).style.merge(titleStyle),
            textScaler: MediaQuery.textScalerOf(context),
          ) +
          1;
      // The figure stands beside the words, or under them when beside them the title's longest word would no longer
      // fit: 'On \u00b7 70%' at twice the text would squeeze a title until 'Pendants' breaks in two, while an
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
                  child: passive(trailing!),
                ),
              ],
            )
          : BesideOrUnder(
              need: need,
              centre: !top,
              children: [told, passive(trailing!)],
            );
      // One line of [style] at the reader's size.
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

      final metaStyle = dense ? t.textTheme.micro : t.textTheme.caption;
      // Words this tall run to three lines (a title and two of its meta's): the mark and the key stand at the top.
      final threeTall = lineOf(titleStyle) + 2 * lineOf(metaStyle) - 1;
      if (action == null) {
        // The words start on a keyline of their own, after the mark, as they do beside an action.
        return _MarkRow(
          top: top,
          threeTall: threeTall,
          firstLine: lineOf(titleStyle),
          children: [
            ?lead,
            DesignKeylineRegion(label: 'words', child: words),
          ],
        );
      }
      // The words and the action start on a keyline of their own, after the mark: one region, so an action under the
      // words keeps their keyline. When the action goes under, the mark stands on the words' first lines alone, as it
      // does in a row with no action: on words and action together, a row with a stepper under it would set its mark
      // at the top while its neighbour's stands centred. The lines are measured at the reader's size.
      final wordsTall =
          lineOf(titleStyle) + (subtitle == null ? 0 : lineOf(metaStyle));
      return _ActionRow(
        centre: !top,
        wordsTall: wordsTall,
        threeTall: threeTall,
        firstLine: lineOf(titleStyle),
        children: [
          ?lead,
          DesignKeylineRegion(
            label: 'words',
            child: _WordsAndAction(
              wide: wide,
              need: need,
              centre: !top,
              threeTall: threeTall,
              firstLine: lineOf(titleStyle),
              // The figure stands where it stands without an action, beside the words or under them.
              children: [words, action!],
            ),
          ),
        ],
      );
    }

    // A row with an action lays out its own padding: a compact key's target may stand in it.
    Widget row = action == null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: _tilePadding),
            child: LayoutBuilder(builder: layout),
          )
        : LayoutBuilder(builder: layout);
    // In a grouped list the row is a band of the card, a breath inside its rim: the focus lift goes round that band, as a
    // bank's cell's does, and the press sinks the whole band; both follow the card's corners where they meet them. A chosen
    // row outside a group takes a band of its own, a control's corners, 12 past it on each side, and its lift and press
    // go round that band, so they never meet its words. The band's wrapper is always there, so choosing a row never
    // remounts it (and never drops its focus).
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
      final press = NeumorphicTap(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label:
            semanticLabel ??
            [
              title,
              ?subtitle,
              ?note,
            ].where((text) => text.isNotEmpty).join(', '),
        selected: selected,
        // The chosen band is already in; a press on another row shows it going in.
        pressRelief: !selected,
        shape: cell?.border ?? t.shapes.corner(NeumorphicRadii.control),
        faceOutset: cell?.outset ?? const EdgeInsets.symmetric(horizontal: 12),
        focusReach: cell == null ? 1 : .5,
        child: split ? const SizedBox.expand() : row,
      );
      row = split
          ? Stack(
              children: [
                Positioned.fill(child: press),
                row,
              ],
            )
          : press;
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<bool>('selected', selected, defaultValue: false),
      )
      ..add(DiagnosticsProperty<bool>('isFirst', isFirst, defaultValue: false))
      ..add(DiagnosticsProperty<bool>('dense', dense, defaultValue: false))
      ..add(DiagnosticsProperty<bool>('top', top, defaultValue: false))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
      );
  }
}

/// A list tile's padding above and below its words.
const double _tilePadding = 12;

/// The widest action that stays beside a list tile's words at every width: an icon key, as wide as its touch target.
const double _compactAction = NeumorphicChromeMetrics.touchTarget;

/// How far a compact action's target stands into a list tile's padding, above and below the words: the look's icon key
/// is a 40 to 44 face in a 48 target, so beside a title and its line it leaves the row the height it has without the
/// key, its face still clear of the rules.
const double _actionReach = 6;

/// A list tile with an action, inside the row's padding: its mark, when it has one, then its words and action
/// ([_WordsAndAction]). While the action stands beside the words, the mark stands on the row's middle with them, as in a
/// row without an action. When the action goes under the words, the mark stands on the words' first lines
/// ([wordsTall]) at the top, where its neighbours' marks stand. With [centre] off (the tile's `top`), the mark stands
/// at the top.
/// A row's mark beside its words, with no action: both on the row's middle, or at its top when [top] or once the
/// words are [threeTall], as Material 3's list items stand theirs.
class _MarkRow extends MultiChildRenderObjectWidget {
  const _MarkRow({
    required this.top,
    required this.threeTall,
    required this.firstLine,
    required super.children,
  });

  /// Whether the mark and the words stand at the row's top whatever the words' height.
  final bool top;

  /// The height of three lines of words.
  final double threeTall;

  /// The height of the title's first line: at the top, the mark stands on its middle.
  final double firstLine;

  @override
  _RenderMarkRow createRenderObject(BuildContext context) =>
      _RenderMarkRow(top, threeTall, firstLine, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderMarkRow renderObject) =>
      renderObject
        ..top = top
        ..threeTall = threeTall
        ..firstLine = firstLine
        ..direction = Directionality.of(context);
}

class _RenderMarkRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowSlot>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowSlot> {
  _RenderMarkRow(this._top, this._threeTall, this._firstLine, this._direction);

  static const _gap = 14.0;

  bool _top;
  set top(bool value) {
    if (value == _top) return;
    _top = value;
    markNeedsLayout();
  }

  double _threeTall;
  set threeTall(double value) {
    if (value == _threeTall) return;
    _threeTall = value;
    markNeedsLayout();
  }

  double _firstLine;
  set firstLine(double value) {
    if (value == _firstLine) return;
    _firstLine = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowSlot) child.parentData = _RowSlot();
  }

  RenderBox? get _mark => childCount == 2 ? firstChild : null;

  RenderBox get _words => lastChild!;

  // The words take the row's width less the mark and its gap, as an Expanded beside it would. At the top, the mark
  // stands on the middle of the title's first line, reaching into the row's padding over the words where it is
  // taller than that line.
  ({Size size, Size mark, Size words, double? markTop}) _arrange(
    BoxConstraints c,
    _Measure measure,
  ) {
    final w = c.maxWidth, mark = _mark;
    final m = mark == null
        ? Size.zero
        : measure(mark, BoxConstraints(maxWidth: w));
    final words = measure(
      _words,
      BoxConstraints.tightFor(
        width: math.max(0.0, w - (mark == null ? 0 : m.width + _gap)),
      ),
    );
    final atTop = _top || words.height >= _threeTall;
    final markTop = atTop
        ? math.max(-_tilePadding, (_firstLine - m.height) / 2)
        : null;
    return (
      size: c.constrain(
        Size(
          w,
          markTop == null
              ? math.max(m.height, words.height)
              : math.max(words.height, markTop + m.height),
        ),
      ),
      mark: m,
      words: words,
      markTop: markTop,
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _arrange(constraints, _dryLayOut).size;

  @override
  void performLayout() {
    final p = _arrange(constraints, _layOut);
    size = p.size;
    final markTop = p.markTop;
    final rtl = _direction == TextDirection.rtl;
    final mark = _mark;
    if (mark != null) {
      (mark.parentData! as _RowSlot).offset = Offset(
        rtl ? size.width - p.mark.width : 0,
        markTop ?? (size.height - p.mark.height) / 2,
      );
    }
    (_words.parentData! as _RowSlot).offset = Offset(
      rtl || mark == null ? 0 : p.mark.width + _gap,
      markTop == null ? (size.height - p.words.height) / 2 : 0,
    );
  }

  // A mark on the first line's middle may stand in the row's padding over this box; it takes its taps there too.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  double _markWidth(double height) =>
      _mark == null ? 0 : _mark!.getMaxIntrinsicWidth(height) + _gap;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _markWidth(height) + _words.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _markWidth(height) + _words.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _arrange(BoxConstraints(maxWidth: width), _dryLayOut).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

class _ActionRow extends MultiChildRenderObjectWidget {
  const _ActionRow({
    required this.centre,
    required this.wordsTall,
    required this.threeTall,
    required this.firstLine,
    required super.children,
  });

  /// Whether the mark, words and a key beside them stand on the row's middle (else at its top), while the words
  /// are shorter than [threeTall].
  final bool centre;

  /// The height of the title's and the subtitle's first lines at the reader's size.
  final double wordsTall;

  /// The height of three lines of words: words this tall stand the mark and the key at the top.
  final double threeTall;

  /// The height of the title's first line: at the top, the mark and a key beside the words stand on its middle.
  final double firstLine;

  @override
  _RenderActionRow createRenderObject(BuildContext context) => _RenderActionRow(
    centre,
    wordsTall,
    threeTall,
    firstLine,
    Directionality.of(context),
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderActionRow renderObject,
  ) => renderObject
    ..centre = centre
    ..wordsTall = wordsTall
    ..threeTall = threeTall
    ..firstLine = firstLine
    ..direction = Directionality.of(context);
}

class _RowSlot extends ContainerBoxParentData<RenderBox> {}

typedef _Measure = Size Function(RenderBox child, BoxConstraints constraints);

Size _layOut(RenderBox child, BoxConstraints constraints) {
  child.layout(constraints, parentUsesSize: true);
  return child.size;
}

Size _dryLayOut(RenderBox child, BoxConstraints constraints) =>
    child.getDryLayout(constraints);

class _RenderActionRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowSlot>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowSlot> {
  _RenderActionRow(
    this._centre,
    this._wordsTall,
    this._threeTall,
    this._firstLine,
    this._direction,
  );

  static const _gap = 14.0;

  bool _centre;
  set centre(bool value) {
    if (value == _centre) return;
    _centre = value;
    markNeedsLayout();
  }

  double _wordsTall;
  set wordsTall(double value) {
    if (value == _wordsTall) return;
    _wordsTall = value;
    markNeedsLayout();
  }

  double _threeTall;
  set threeTall(double value) {
    if (value == _threeTall) return;
    _threeTall = value;
    markNeedsLayout();
  }

  double _firstLine;
  set firstLine(double value) {
    if (value == _firstLine) return;
    _firstLine = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowSlot) child.parentData = _RowSlot();
  }

  RenderBox? get _mark => childCount == 2 ? firstChild : null;

  // The keyline region around the words and action lays out nothing, so their box is this box's last child.
  _RenderWordsAndAction get _body => lastChild! as _RenderWordsAndAction;

  /// The row's size and where its mark and body stand, the children measured (or, unless [dry], laid out) in [c].
  ({Size size, Size mark, double markY, double bodyY}) _arrange(
    BoxConstraints c, {
    required bool dry,
  }) {
    final measure = dry ? _dryLayOut : _layOut;
    final mark = _mark, body = _body;
    final w = c.maxWidth;
    final m = mark == null
        ? Size.zero
        : measure(mark, BoxConstraints(maxWidth: w));
    final room = BoxConstraints.tightFor(
      width: math.max(0.0, w - (mark == null ? 0 : m.width + _gap)),
    );
    final b = measure(body, room);
    final place = dry ? body._plan(room, _dryLayOut) : body._laidOut!;
    // The words' band: the body less the reach its key takes into the padding.
    final band = b.height - 2 * place.reach;
    final centre = _centre && place.words.height < _threeTall;
    if (place.beside && !centre) {
      // At the top the mark and the key stand on the middle of the title's first line; a key taller than that line
      // reaches over the words into the padding, and lower when it would reach past the row's top.
      final wordsTop = math.max(_tilePadding, place.top);
      final bodyY = wordsTop - place.top;
      final markY = math.max(0.0, wordsTop + (_firstLine - m.height) / 2);
      final bottom = math.max(
        math.max(wordsTop + place.words.height, markY + m.height),
        bodyY + b.height - place.reach,
      );
      return (
        size: c.constrain(Size(w, bottom + _tilePadding)),
        mark: m,
        markY: markY,
        bodyY: bodyY,
      );
    }
    final markBox = place.beside || !centre
        ? m.height
        : math.max(m.height, _wordsTall);
    final size = c.constrain(
      Size(w, math.max(markBox, band) + 2 * _tilePadding),
    );
    if (place.beside && centre) {
      return (
        size: size,
        mark: m,
        markY: (size.height - m.height) / 2,
        bodyY: (size.height - band) / 2 - place.reach,
      );
    }
    return (
      size: size,
      mark: m,
      markY: _tilePadding + (markBox - m.height) / 2,
      bodyY: _tilePadding - place.reach,
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _arrange(constraints, dry: true).size;

  @override
  void performLayout() {
    final p = _arrange(constraints, dry: false);
    size = p.size;
    final mark = _mark;
    final rtl = _direction == TextDirection.rtl;
    if (mark != null) {
      (mark.parentData! as _RowSlot).offset = Offset(
        rtl ? size.width - p.mark.width : 0,
        p.markY,
      );
    }
    (_body.parentData! as _RowSlot).offset = Offset(
      rtl || mark == null ? 0 : p.mark.width + _gap,
      p.bodyY,
    );
  }

  double _markWidth(double height) =>
      _mark == null ? 0 : _mark!.getMaxIntrinsicWidth(height) + _gap;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _markWidth(height) + _body.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _markWidth(height) + _body.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _arrange(BoxConstraints(maxWidth: width), dry: true).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// A list tile's words and its action. The action stands beside the words at the row's end when the row is [wide], or
/// when it is compact (no wider than an icon key's touch target) and the title's widest word ([need]) still fits beside
/// it; otherwise it goes under the words, at their start. Its width is measured by laying it out, not by its
/// intrinsics: an action may hold a LayoutBuilder, which has none. Beside the words, a compact action reaches
/// [_actionReach] above and below their band, into the row's padding, and this box reaches with it, so the key's whole
/// target takes taps.
///
/// What yields as the row narrows or the text grows: first the title wraps, word by word, down to its widest word, and
/// a figure beside the words goes under them ([BesideOrUnder]); the key keeps its place at the row's end and its whole
/// target. Only when even the title's widest word no longer fits beside the key does the key go under the words, at
/// their start, where a wider action stands, and the words take the row's whole width. That is the better failure: a
/// word broken where its line runs out, with no hyphen, is the one failure that costs reading, while a key under the
/// words costs the row a line of height and stays a whole target.
class _WordsAndAction extends MultiChildRenderObjectWidget {
  const _WordsAndAction({
    required this.wide,
    required this.need,
    required this.centre,
    required this.threeTall,
    required this.firstLine,
    required super.children,
  });

  /// Whether the row is 520 or more wide, where every action stands beside the words.
  final bool wide;

  /// The title's widest word: the least room the words keep beside a compact action.
  final double need;

  /// Whether, beside each other, the words and the action stand on their middle (else on their top), while the
  /// words are shorter than [threeTall].
  final bool centre;

  /// The height of three lines of words: words this tall stand the action at the top.
  final double threeTall;

  /// The height of the title's first line: at the top, an action beside the words stands on its middle.
  final double firstLine;

  @override
  _RenderWordsAndAction createRenderObject(BuildContext context) =>
      _RenderWordsAndAction(
        wide,
        need,
        centre,
        threeTall,
        firstLine,
        Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWordsAndAction renderObject,
  ) => renderObject
    ..wide = wide
    ..need = need
    ..centre = centre
    ..threeTall = threeTall
    ..firstLine = firstLine
    ..direction = Directionality.of(context);
}

/// Where a list tile's action stands: [beside] the words or under them; beside them, at the words' top ([atTop]) or
/// on their middle. [top] is how far the box reaches over the words (at the top, as far as a key on the middle of the
/// title's first line needs), [reach] how far under them.
typedef _ActionPlace = ({
  bool beside,
  bool atTop,
  double top,
  double reach,
  Size words,
  Size action,
});

class _RenderWordsAndAction extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowSlot>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowSlot> {
  _RenderWordsAndAction(
    this._wide,
    this._need,
    this._centre,
    this._threeTall,
    this._firstLine,
    this._direction,
  );

  static const _gap = 14.0, _under = 10.0;

  bool _wide;
  set wide(bool value) {
    if (value == _wide) return;
    _wide = value;
    markNeedsLayout();
  }

  double _need;
  set need(double value) {
    if (value == _need) return;
    _need = value;
    markNeedsLayout();
  }

  bool _centre;
  set centre(bool value) {
    if (value == _centre) return;
    _centre = value;
    markNeedsLayout();
  }

  double _threeTall;
  set threeTall(double value) {
    if (value == _threeTall) return;
    _threeTall = value;
    markNeedsLayout();
  }

  double _firstLine;
  set firstLine(double value) {
    if (value == _firstLine) return;
    _firstLine = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  /// The place the last layout chose: the row reads it to stand its mark.
  _ActionPlace? _laidOut;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowSlot) child.parentData = _RowSlot();
  }

  _ActionPlace _plan(BoxConstraints c, _Measure measure) {
    final words = firstChild!, action = lastChild!;
    final w = c.maxWidth;
    final a = measure(action, BoxConstraints(maxWidth: w));
    final compact = a.width <= _compactAction;
    final room = w - a.width - _gap;
    if (_wide || (compact && room >= _need)) {
      final said = measure(
        words,
        BoxConstraints.tightFor(width: math.max(0.0, room)),
      );
      final reach = compact ? _actionReach : 0.0;
      final atTop = !_centre || said.height >= _threeTall;
      return (
        beside: true,
        atTop: atTop,
        top: atTop ? math.max(reach, (a.height - _firstLine) / 2) : reach,
        reach: reach,
        words: said,
        action: a,
      );
    }
    return (
      beside: false,
      atTop: false,
      top: 0.0,
      reach: 0.0,
      words: measure(words, BoxConstraints(maxWidth: w)),
      action: a,
    );
  }

  Size _size(_ActionPlace p, BoxConstraints c) => c.constrain(
    Size(
      c.maxWidth,
      !p.beside
          ? p.words.height + _under + p.action.height
          : p.atTop
          ? math.max(
              p.top + p.words.height + p.reach,
              p.top + (_firstLine + p.action.height) / 2,
            )
          : math.max(p.words.height, p.action.height - 2 * p.reach) +
                2 * p.reach,
    ),
  );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _size(_plan(constraints, _dryLayOut), constraints);

  @override
  void performLayout() {
    final p = _laidOut = _plan(constraints, _layOut);
    size = _size(p, constraints);
    final words = firstChild!, action = lastChild!;
    final wordsAt = words.parentData! as _RowSlot;
    final actionAt = action.parentData! as _RowSlot;
    final rtl = _direction == TextDirection.rtl;
    double startOf(double width) => rtl ? size.width - width : 0;
    if (p.beside && p.atTop) {
      wordsAt.offset = Offset(startOf(p.words.width), p.top);
      actionAt.offset = Offset(
        rtl ? 0 : size.width - p.action.width,
        p.top + (_firstLine - p.action.height) / 2,
      );
    } else if (p.beside) {
      final band = size.height - 2 * p.reach;
      wordsAt.offset = Offset(
        startOf(p.words.width),
        p.reach + (band - p.words.height) / 2,
      );
      actionAt.offset = Offset(
        rtl ? 0 : size.width - p.action.width,
        (size.height - p.action.height) / 2,
      );
    } else {
      wordsAt.offset = Offset(startOf(p.words.width), 0);
      actionAt.offset = Offset(
        startOf(p.action.width),
        p.words.height + _under,
      );
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    firstChild!.getMinIntrinsicWidth(height),
    lastChild!.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild!.getMaxIntrinsicWidth(height) +
      _gap +
      lastChild!.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) {
    final c = BoxConstraints(maxWidth: width);
    return _size(_plan(c, _dryLayOut), c).height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
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
              // The list's one leading slot, so the title stands where every row's does (44 and 14 on): here as wide
              // as the check's whole target, which it is laid out at.
              SizedBox(
                width: NeumorphicChromeMetrics.touchTarget,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: NeumorphicRoundCheckbox(
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(
                width:
                    _leadingSlot +
                    _leadingGap -
                    NeumorphicChromeMetrics.touchTarget,
              ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('value', value, defaultValue: false))
      ..add(DiagnosticsProperty<bool>('live', live, defaultValue: false))
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged))
      ..add(DiagnosticsProperty<bool>('isFirst', isFirst, defaultValue: false));
  }
}

/// A thing that's on or off and has a level: a pressed round icon, its name and state, a switch, and while on a slider and its
/// figure. On reads three ways with no shadow: the pigment in the icon and the words, the words themselves, the filled slot.
///
/// ```dart
/// NeumorphicLevelRow(icon: NeumorphicGlyphs.lamp, title: 'A lamp', state: 'On, 30%', value: true, level: .3, figure: '30%', onChanged: (v) {}, onLevelChanged: (v) {})
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
    this.onLevelChanged,
    this.isFirst = false,
  }) : assert((level ?? 0) >= 0 && (level ?? 0) <= 1);

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
  final ValueChanged<double>? onLevelChanged;

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
    // Under a level the row's foot is the slider's own target below its thumb: 14 more would leave 50 of dead floor
    // under the thumb against 14 under a row's words.
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
                          onChanged: onLevelChanged,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('title', title))
      ..add(StringProperty('state', state))
      ..add(DiagnosticsProperty<bool>('value', value, defaultValue: false))
      ..add(DoubleProperty('level', level, defaultValue: null))
      ..add(StringProperty('figure', figure, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has(
          'onLevelChanged',
          onLevelChanged,
        ),
      )
      ..add(DiagnosticsProperty<bool>('isFirst', isFirst, defaultValue: false))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false),
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
  }) : assert(gap >= 0),
       assert(side >= 0);

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(IterableProperty<NeumorphicStat>('items', items))
      ..add(DoubleProperty('gap', gap, defaultValue: 10))
      ..add(DoubleProperty('side', side, defaultValue: 14));
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('value', value))
      ..add(StringProperty('unit', unit, defaultValue: null))
      ..add(StringProperty('delta', delta, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null));
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('title', title))
      ..add(StringProperty('eyebrow', eyebrow, defaultValue: null))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null));
  }
}

/// A control with its label and help: one line of a form, for a control that draws no label of its own (a segmented
/// button, a stepper, a slider). The label and the help are a text field's own, so the form keeps one label style.
///
/// ```dart
/// NeumorphicFormGroup(labelText: 'Pay with', child: NeumorphicSegmentedButton<String>(label: 'Pay with', segments: ways, value: way, onChanged: setWay))
/// ```
class NeumorphicFormGroup extends StatelessWidget {
  /// Creates a [NeumorphicFormGroup].
  const NeumorphicFormGroup({
    super.key,
    required this.labelText,
    this.helperText,
    required this.child,
  });

  /// The text identifying this item or control.
  final String labelText;

  /// Supporting instructions below the group label.
  final String? helperText;

  /// The content placed inside this component.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // ui_core's decorator names the control by the label (or a group of them, each keeping its node) and reads the
    // help as its hint.
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      builder: (context, parts) => NeumorphicColumn(
        gap: 8,
        children: [
          DefaultTextStyle.merge(
            style: t.textTheme.caption.copyWith(fontWeight: FontWeight.w700),
            child: parts.label!,
          ),
          parts.control,
          if (parts.helper case final helper?)
            DefaultTextStyle.merge(style: t.textTheme.caption, child: helper),
        ],
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(StringProperty('helperText', helperText, defaultValue: null));
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
    this.icon,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The primary heading.
  final String title;

  /// Supporting text explaining the empty state.
  final String? body;

  /// A glyph set on the mark's dome that says what is empty (a search's, a list's); null leaves the mark bare.
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final glyph = icon;
    return NeumorphicWell(
      style: style,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: NeumorphicColumn(
          gap: 10,
          children: [
            Center(
              child: glyph == null
                  ? const NeumorphicMark(size: 44)
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        const NeumorphicMark(size: 44),
                        Icon(glyph, size: 14, color: t.colors.inkSecondary),
                      ],
                    ),
            ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('title', title))
      ..add(StringProperty('body', body, defaultValue: null))
      ..add(IconDataProperty('icon', icon, ifNull: 'none'));
  }
}

/// A list row's leading slot (a mark of any width) and the gap after it: every row's words start this far in.
const double _leadingSlot = 44;
const double _leadingGap = 14;
