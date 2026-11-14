// Rows: what fills a well. Each is drawn from the concept's `.task`, `.lk`, `.pl`, `.kv` and `.stats`. A rule goes between rows,
// a selected row takes the highlight, and everything in it reads there by itself.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'press.dart';
import 'component_themes.dart';
import 'internal/face.dart';
import 'internal/caps.dart';

import 'glyphs.dart';

import 'controls.dart';
import 'heads.dart';
import 'layout.dart';
import 'pixels.dart';
import 'theme.dart';

/// Tells the first row of a list that nothing stands above it.
class _FirstRow extends InheritedWidget {
  const _FirstRow({required super.child});
  @override
  bool updateShouldNotify(_FirstRow old) => false;
  static bool here(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_FirstRow>() != null;
}

/// One row's ground and the rule above it, unless it's the first.
class _RowFrame extends StatelessWidget {
  const _RowFrame({
    required this.child,
    this.isFirst = false,
    this.selected = false,
    this.enabled = true,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });
  final Widget child;
  final bool isFirst, selected, enabled;
  final VoidCallback? onPressed;
  final String? label;
  final RetroDesktopStyle? style;

  /// The focus node this part uses; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final top = isFirst || _FirstRow.here(context);
    final shape = retroDesktopRowShape(context);
    Widget draw(Set<WidgetState> states) {
      // Held, a row shows the press as the appearance's buttons do: Platinum a
      // darker fill, Chisel a sunken two-step bevel over the row, its words
      // unmoved. A chosen row keeps the highlight.
      final held = states.contains(WidgetState.pressed) && !selected;
      final face = retroDesktopFace(
        states: states,
        style: style,
        bevel: false,
        ringInside: true,
        padding: EdgeInsets.zero,
        component: t.listTileTheme.merge(
          RetroDesktopStyle(
            fill: WidgetStatePropertyAll(
              selected
                  ? c.highlight
                  : held && !t.chisel
                  ? (c.dark ? c.platinumLight : c.platinumDark)
                  : const Color(0x00000000),
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
            shape: WidgetStatePropertyAll(shape),
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: top
                ? null
                : Border(
                    top: BorderSide(
                      color: c.divider,
                      width: t.strokes.hairline,
                    ),
                  ),
          ),
          child: selected ? RetroDesktopOnHighlight(child: child) : child,
        ),
      );
      if (!held || !t.chisel) return face;
      return CustomPaint(foregroundPainter: _SunkenRow(c), child: face);
    }

    if (onPressed == null) return draw({if (selected) WidgetState.selected});
    return RetroDesktopPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      // Disabled, the press dims the row as it dims a line button.
      onPressed: enabled ? onPressed : null,
      selected: selected,
      label: label,
      builder: (context, states) => draw(states),
    );
  }
}

/// Chisel's held row: the sunken two-step bevel of a field, drawn over the
/// row's own box so nothing in it moves.
class _SunkenRow extends CustomPainter {
  const _SunkenRow(this.c);
  final RetroDesktopColors c;
  @override
  void paint(Canvas canvas, Size size) => retroDesktopPaintChiselRect(
    canvas,
    Offset.zero & size,
    retroDesktopChiselEdge(c, sunken: true),
  );

  @override
  bool shouldRepaint(_SunkenRow old) => old.c != c;
}

/// Rows in a well, one under another, a rule between them. With [share] the rows split the height a stretched window gives
/// it, so a list that's short of a column's end stands open rather than stopping in a hole. A row knows it is the first.
///
/// ```dart
/// RetroDesktopWell(child: RetroDesktopList(children: rows))
/// ```
class RetroDesktopList extends StatelessWidget {
  /// Creates a [RetroDesktopList].
  const RetroDesktopList({
    super.key,
    required this.children,
    this.share = false,
  });

  /// The child widgets in reading order.
  final List<Widget> children;

  /// Whether the rows split the height a stretched window gives the list, so a short list stands open.
  final bool share;
  @override
  Widget build(BuildContext context) {
    final desk = RetroDesktopTheme.of(context).desk;
    final outer = RetroDesktopRowPlace.maybeOf(context);
    Widget rowAt(int i, Widget row) => RetroDesktopRowPlace(
      first: (outer?.first ?? true) && i == 0,
      last: (outer?.last ?? true) && i == children.length - 1,
      child: i == 0 ? _FirstRow(child: row) : row,
    );
    return RetroDesktopColumn(
      children: [
        for (var i = 0; i < children.length; i++)
          if (share && desk)
            RetroDesktopGrow(child: rowAt(i, children[i]))
          else
            rowAt(i, children[i]),
      ],
    );
  }
}

/// A list row with its action: words at the start, a `RetroDesktopButton` at the end, or under the words on a phone.
/// [leading] keeps its width; [trailing] is held to a share of the row; [figure] is one big number in the system face. The
/// row is for a well, and takes the highlight when [selected].
///
/// ```dart
/// RetroDesktopListTile(title: 'Port Linden', subtitle: 'Cloudy', figure: '10°', leading: const Icon(RetroDesktopGlyphs.cloud), onPressed: () {})
/// ```
class RetroDesktopListTile extends StatelessWidget {
  /// Creates a [RetroDesktopListTile].
  const RetroDesktopListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.label,
    this.note,
    this.leading,
    this.trailing,
    this.figure,
    this.action,
    this.onPressed,
    this.isFirst = false,
    this.selected = false,
    this.enabled = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// Whether a row that opens something ([onPressed] set) can be opened now;
  /// when false it is dimmed and takes no input. A row with no [onPressed] is
  /// a still row of words and is never dimmed.
  final bool enabled;

  /// The heading displayed above the content.
  final String title;

  /// Secondary information displayed with the main content.
  final String? subtitle;

  /// Supporting text shown with the main content.
  final String? note;

  /// The main figure displayed by this part.
  final String? figure;

  /// The visible or accessible name of this part.
  final String? label;

  /// An icon, a monogram, a `RetroDesktopMedia(width: 56)`: its own width stays.
  final Widget? leading;

  /// A figure or a `RetroDesktopFlag` beside the title, held to a share of the row.
  final Widget? trailing;

  /// A `RetroDesktopButton` or `RetroDesktopButton`, one or two words.
  final Widget? action;

  /// The whole row opens something.
  final VoidCallback? onPressed;

  /// No rule above: `RetroDesktopList` tells its first row by itself.
  final bool isFirst;

  /// Whether the part represents the current selection.
  final bool selected;

  /// The focus node this part uses; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    if (action != null && onPressed != null) {
      return Row(
        children: [
          Expanded(
            child: RetroDesktopListTile(
              focusNode: focusNode,
              autofocus: autofocus,
              title: title,
              label: label,
              subtitle: subtitle,
              note: note,
              leading: leading,
              trailing: trailing,
              figure: figure,
              onPressed: onPressed,
              style: style,
              isFirst: isFirst,
              selected: selected,
              enabled: enabled,
            ),
          ),
          const SizedBox(width: 8),
          action!,
        ],
      );
    }
    return _RowFrame(
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      isFirst: isFirst,
      selected: selected,
      enabled: enabled,
      onPressed: onPressed,
      label: label ?? title,
      child: Builder(
        builder: (context) {
          final t = RetroDesktopTheme.of(context);
          final states = <WidgetState>{if (selected) WidgetState.selected};
          T? slot<T>(
            WidgetStateProperty<T?>? Function(RetroDesktopStyle) get,
          ) => RetroDesktopStyle.first([style, t.listTileTheme], get, states);
          final ink = slot((s) => s.foreground);
          final appearance = slot((s) => s.textStyle);
          final titleStyle = t.type
              .text(16, 22, weight: FontWeight.w600)
              .merge(appearance)
              .copyWith(color: ink);
          // A narrow pane at twice the text broke "Documents" in two: the
          // title's longest word keeps its line (the tile is already laid out
          // by its room, so this asks nothing more of a menu around it).
          final named = retroDesktopWholeWords(
            title,
            titleStyle,
            RetroDesktopText(title, style: titleStyle),
          );
          final words = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A title alone is the row's label: its capitals on the row's
              // middle, beside the leading glyph's.
              if (subtitle == null && note == null)
                RetroDesktopCaps(
                  style: t.type.text(16, 22, weight: FontWeight.w600),
                  named,
                )
              else
                named,
              if (subtitle != null)
                RetroDesktopText(
                  subtitle!,
                  style: t.type.meta.merge(appearance).copyWith(color: ink),
                ),
              if (note != null) ...[
                const SizedBox(height: 4),
                RetroDesktopText(
                  note!,
                  style: t.type.meta.merge(appearance).copyWith(color: ink),
                ),
              ],
            ],
          );
          final big = figure == null
              ? null
              : Text(
                  figure!,
                  style: t.type.pixel(28, 24),
                  maxLines: 1,
                  softWrap: false,
                );
          return Padding(
            padding: t.density.apply(
              const EdgeInsets.fromLTRB(10, 8, 10, 8),
              Directionality.of(context),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 520;
                final side = trailing == null
                    ? null
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: c.maxWidth * (wide ? .3 : .4),
                        ),
                        child: trailing,
                      );
                final mark = leading == null
                    ? const <Widget>[]
                    : <Widget>[leading!, const SizedBox(width: 10)];
                if (wide) {
                  return Row(
                    children: [
                      ...mark,
                      Expanded(child: words),
                      if (side != null) ...[const SizedBox(width: 10), side],
                      if (big != null) ...[const SizedBox(width: 10), big],
                      if (action != null) ...[
                        const SizedBox(width: 10),
                        action!,
                      ],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: action == null
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    ...mark,
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: words),
                              if (side != null) ...[
                                const SizedBox(width: 10),
                                side,
                              ],
                              if (big != null) ...[
                                const SizedBox(width: 10),
                                big,
                              ],
                            ],
                          ),
                          if (action != null) ...[
                            const SizedBox(height: 8),
                            action!,
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// A task: a checkbox, its name, when it's due, and its priority in bars. [overdue] is the inverted chip, [time] a clock time
/// with an optional [bell], [flexibleTime] a quiet "any time". Done, it goes grey and struck through; [selected] is the highlight.
///
/// ```dart
/// RetroDesktopTaskRow(title: 'Renew the card', subtitle: 'Home · due Tue', overdue: '1 day late', priority: 3, onChanged: (v) {})
/// ```
class RetroDesktopTaskRow extends StatelessWidget {
  /// Creates a [RetroDesktopTaskRow].
  const RetroDesktopTaskRow({
    super.key,
    required this.title,
    this.subtitle,
    this.overdue,
    this.time,
    this.flexibleTime,
    this.bell = false,
    this.priority,
    this.value = false,
    this.selected = false,
    this.isFirst = false,
    this.onChanged,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// The heading displayed above the content.
  final String title;

  /// Secondary information displayed with the main content.
  final String? subtitle;

  /// How late the task is, such as '1 day late', shown in the inverted chip; null when it is on time.
  final String? overdue;

  /// The time label displayed with the item.
  final String? time;

  /// The flexible-time label shown when no exact time is required.
  final String? flexibleTime;

  /// Whether a reminder bell accompanies the due time.
  final bool bell;

  /// Whether the task is complete; completed titles are struck through.
  final bool value;

  /// Whether this row uses the selection highlight.
  final bool selected;

  /// Omits the top separator when this row starts a list.
  final bool isFirst;

  /// The priority represented by the item.
  final int? priority;

  /// Reports a request to change the completion state.
  final ValueChanged<bool>? onChanged;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The focus node this part uses; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    // The checkbox keeps its own face in the chosen row.
    final outer = RetroDesktopTheme.of(context);
    return _RowFrame(
      isFirst: isFirst,
      selected: selected,
      onPressed: onPressed,
      label: title,
      child: Builder(
        builder: (context) {
          final t = RetroDesktopTheme.of(context);
          final c = t.colors;
          final name = RetroDesktopText(
            title,
            style: value
                ? t.type.body.copyWith(
                    color: c.textTertiary,
                    decoration: TextDecoration.lineThrough,
                    decorationThickness: 1,
                    decorationColor: c.textTertiary,
                  )
                : t.type.row,
            maxLines: t.desk ? 1 : null,
            overflow: t.desk ? TextOverflow.ellipsis : null,
          );
          final metaLine = subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: t.type.meta,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                );
          final due = <Widget>[
            if (overdue != null) Flexible(child: RetroDesktopFlag(overdue!)),
            if (bell)
              Icon(RetroDesktopGlyphs.bell, size: 13, color: c.textSecondary),
            if (bell && time != null) const SizedBox(width: 6),
            if (time != null)
              Flexible(
                child: Text(
                  time!,
                  style: t.type.mono(
                    12,
                    16,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (flexibleTime != null)
              Flexible(
                child: Text(
                  flexibleTime!,
                  style: t.type.caption.copyWith(color: c.textTertiary),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ];
          final Widget mid;
          if (t.desk) {
            mid = Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [name, ?metaLine],
                  ),
                ),
                if (due.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Row(mainAxisSize: MainAxisSize.min, children: due),
                  ),
                ],
              ],
            );
          } else {
            mid = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                name,
                const SizedBox(height: 2),
                RetroDesktopFitRow(
                  fill: due.isEmpty ? 0 : 1,
                  gap: 8,
                  children: [
                    if (due.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: due),
                    metaLine ?? const SizedBox.shrink(),
                  ],
                ),
              ],
            );
          }
          // Where the box's reach is laid out across (a touch screen), its 44 lp stand where the margin was: the box 4
          // lp further in, the words 6. Where it isn't (a narrow window on a desk), the row keeps its own margins.
          final reach =
              RetroDesktopReach.padsAcross(context) && onChanged != null;
          return Padding(
            padding: reach
                ? const EdgeInsetsDirectional.fromSTEB(0, 9, 12, 9)
                : EdgeInsets.fromLTRB(10, t.desk ? 7 : 9, 12, t.desk ? 7 : 9),
            child: LayoutBuilder(
              builder: (context, room) {
                final narrow = room.maxWidth < 160;
                final priorityView = SizedBox(
                  width: 18,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    heightFactor: 1,
                    child: priority == null
                        ? null
                        : RetroDesktopPriority(priority!),
                  ),
                );
                // The box 10 in, where other lists' leading parts stand.
                final box = RetroDesktopCheckbox(
                  focusNode: focusNode,
                  autofocus: autofocus,
                  value: value,
                  onChanged: onChanged == null
                      ? null
                      : (value) => onChanged!(value ?? false),
                  label: title,
                );
                return Row(
                  children: [
                    selected
                        ? RetroDesktopOffHighlight(data: outer, child: box)
                        : box,
                    SizedBox(width: reach ? 0 : 12),
                    Expanded(
                      child: narrow
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                mid,
                                if (priority != null) priorityView,
                              ],
                            )
                          : mid,
                    ),
                    if (!narrow) ...[const SizedBox(width: 12), priorityView],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// A fact of a list: a label, a value, and a small [icon]. [figures] sets the value in mono, for a date or a number.
class RetroDesktopFact {
  /// Creates a [RetroDesktopFact].
  const RetroDesktopFact(
    this.label,
    this.value, {
    this.icon,
    this.figures = false,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// The current value to display or edit.
  final String value;

  /// The glyph shown with the content.
  final IconData? icon;

  /// Whether [value] is set in the fixed-width face, as a figure is.
  final bool figures;
}

// At the reader's text size: measured at 1x, a label at twice the size had half its room and vanished.
double _lineWidth(String text, TextStyle style, TextScaler scaler) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = tp.width;
  tp.dispose();
  return width;
}

class _Dotted extends RetroDesktopPixelPainter {
  const _Dotted(this.color);
  final Color color;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final y = s.height / 2;
    for (var x = 0.0; x < s.width; x += 2) {
      px.fill(Rect.fromLTWH(x, y, 1, 1), color);
    }
  }

  @override
  bool shouldRepaint(_Dotted o) => o.color != color;
}

/// Facts in one quiet block: an info window's. By default the labels stand right and the values read from them; [leaders]
/// runs a dotted line to a value set in mono at the end, for numbers to compare down a column.
///
/// ```dart
/// RetroDesktopDescriptionList(const [RetroDesktopFact('Wind', 'SW 24 km/h', icon: RetroDesktopGlyphs.wind)], leaders: true)
/// ```
class RetroDesktopDescriptionList extends StatelessWidget {
  /// Creates a [RetroDesktopDescriptionList].
  const RetroDesktopDescriptionList(
    this.facts, {
    super.key,
    this.leaders = false,
  });

  /// The labelled facts displayed in order.
  final List<RetroDesktopFact> facts;

  /// Whether dotted leaders connect labels and values.
  final bool leaders;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final label = t.type.caption;
    if (leaders) {
      final scaler = MediaQuery.textScalerOf(context);
      var labels = 0.0, values = 0.0;
      for (final f in facts) {
        labels = math.max(
          labels,
          _lineWidth(f.label, label, scaler) + (f.icon == null ? 0 : 20),
        );
        values = math.max(values, _lineWidth(f.value, t.type.figure, scaler));
      }
      return LayoutBuilder(
        builder: (context, box) {
          // Stacked, label over value, where a label, a short leader and its value can't all stand whole on a line.
          if (box.maxWidth < 96 || labels + values + 40 > box.maxWidth) {
            return RetroDesktopColumn(
              gap: 7,
              children: [
                for (final fact in facts)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (fact.icon != null)
                            Icon(fact.icon, size: 14, color: c.textTertiary),
                          Text(fact.label, style: label),
                        ],
                      ),
                      Text(fact.value, style: t.type.figure),
                    ],
                  ),
              ],
            );
          }
          final labelW = math.min(labels.ceilToDouble(), box.maxWidth * .5);
          final valueW = math.min(
            values.ceilToDouble(),
            math.min(
              math.max(0.0, box.maxWidth - labelW - 20),
              math.max(box.maxWidth * .4, box.maxWidth - labelW - 30),
            ),
          );
          return RetroDesktopColumn(
            gap: 7,
            children: [
              for (final f in facts)
                Row(
                  children: [
                    // Each label at the start, its glyph on the column's
                    // edge, its leader running from its own last word to
                    // the value (end-aligned labels left a short one's glyph
                    // in from a long one's).
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: labelW),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (f.icon != null) ...[
                            Icon(f.icon, size: 14, color: c.textTertiary),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              f.label,
                              style: label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 3,
                        child: RetroDesktopPixelPaint(
                          painter: _Dotted(c.dark ? c.bevelLight : c.bevelDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: valueW,
                      child: Text(
                        f.value,
                        style: t.type.figure,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        var widest = 0.0;
        for (final f in facts) {
          final tp = TextPainter(
            text: TextSpan(text: f.label, style: label),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          widest = math.max(widest, tp.width);
          tp.dispose();
        }
        final col = math.min(widest.ceilToDouble(), box.maxWidth * .4);
        return RetroDesktopColumn(
          gap: 5,
          children: [
            for (final f in facts)
              RetroDesktopGrow(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: col,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          f.label,
                          style: label,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // The value is what's read: in the reading size, never smaller than its label.
                    Expanded(
                      child: Text(
                        f.value,
                        style: f.figures
                            ? t.type.mono(14, 18, weight: FontWeight.w600)
                            : t.type.text(14, 18),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatRule extends RetroDesktopPixelPainter {
  const _StatRule(this.c, this.across, {this.rtl = false});
  final RetroDesktopColors c;
  final bool across;

  /// A rule down a cell stands at its reading start, between it and the one before (in right-to-left at its right:
  /// at its left it dangled beside the first cell and left none between the last two).
  final bool rtl;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    if (across) {
      px.ruleAcross(0, s.width, 0, c.bevelDark);
      px.ruleAcross(0, s.width, px.hair, c.bevelLight);
    } else {
      final x = rtl ? s.width - 2 * px.hairX : 0.0;
      px.ruleDown(0, s.height, x, c.bevelDark);
      px.ruleDown(0, s.height, x + px.hairX, c.bevelLight);
    }
  }

  @override
  bool shouldRepaint(_StatRule o) =>
      o.c != c || o.across != across || o.rtl != rtl;
}

/// Three or four figures in a row, the system face over a small label, under an etched line. A figure never breaks: if the
/// row can't hold them they take two rows. `(label, value)`, or `(label, value, unit)`.
///
/// ```dart
/// RetroDesktopStats(const [('Open tasks', '18', null), ('Rain today', '6.4', 'mm')])
/// ```
class RetroDesktopStats extends StatelessWidget {
  /// Creates a [RetroDesktopStats].
  const RetroDesktopStats(this.stats, {super.key, this.etched = true});

  /// The statistics displayed in order.
  final List<(String, String, String?)> stats;

  /// An etched line above them.
  final bool etched;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    Widget cell((String, String, String?) s) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.$1,
          style: t.type.caption.copyWith(color: c.textTertiary),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text.rich(
            TextSpan(
              text: s.$2,
              style: t.type.big,
              children: [
                if (s.$3 != null)
                  TextSpan(
                    text: ' ${s.$3}',
                    style: t.type.chrome.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
    return RetroDesktopPixelPaint(
      painter: etched ? _StatRule(c, true) : const _Blank(),
      foreground: true,
      child: Padding(
        padding: EdgeInsets.only(top: etched ? 11 : 0),
        child: LayoutBuilder(
          builder: (context, box) {
            final n = stats.isEmpty ? 1 : stats.length;
            final holds =
                box.maxWidth / n >=
                _widestLine(
                  context,
                  [for (final s in stats) s.$1],
                  t.type.caption,
                  74,
                );
            final columns = holds ? n : math.max(1, n ~/ 2);
            return RetroDesktopGridOf(
              columns: columns,
              gap: 0,
              runGap: 10,
              children: [
                for (final s in stats)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: cell(s),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// The room a column of figures needs: [least], or its widest label whole at the reader's size and a gap (kept to 74,
// twice the text cut "Rain today" to "Rain t…" and "This week" to "This …").
double _widestLine(
  BuildContext context,
  Iterable<String> lines,
  TextStyle style,
  double least,
) {
  var widest = least;
  for (final line in lines) {
    final tp = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    widest = math.max(widest, tp.width + 12);
    tp.dispose();
  }
  return widest;
}

/// The readings of the moment, cut apart by etched lines, set beside a page's big figure. `(label, value, unit)`.
///
/// ```dart
/// RetroDesktopReadings(const [('High', '11°', null), ('Rain today', '6.4', 'mm')])
/// ```
class RetroDesktopReadings extends StatelessWidget {
  /// Creates a [RetroDesktopReadings].
  const RetroDesktopReadings(this.reads, {super.key});

  /// The readings displayed in order.
  final List<(String, String, String?)> reads;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final n = reads.isEmpty ? 1 : reads.length;
        final holds =
            box.maxWidth / n >=
            _widestLine(
              context,
              [for (final r in reads) r.$1],
              t.type.caption,
              74,
            );
        final columns = holds ? n : math.max(1, n ~/ 2);
        return RetroDesktopGridOf(
          columns: columns,
          gap: 0,
          runGap: 10,
          children: [
            for (var i = 0; i < reads.length; i++)
              RetroDesktopPixelPaint(
                painter: i % columns == 0
                    ? const _Blank()
                    : _StatRule(
                        c,
                        false,
                        rtl: Directionality.of(context) == TextDirection.rtl,
                      ),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    i % columns == 0 ? 0 : 11,
                    0,
                    8,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reads[i].$1,
                        style: t.type.caption.copyWith(color: c.textTertiary),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text.rich(
                          TextSpan(
                            text: reads[i].$2,
                            style: t.type.big,
                            children: [
                              if (reads[i].$3 != null)
                                TextSpan(
                                  text: ' ${reads[i].$3}',
                                  style: t.type.pixel(
                                    16,
                                    16,
                                    color: c.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      // A small unit on the line stands the line 4 lp taller, in every cell of the row.
                      if (reads.any((r) => r.$3 != null))
                        const SizedBox(height: 4),
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

class _Blank extends RetroDesktopPixelPainter {
  const _Blank();
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {}
  @override
  bool shouldRepaint(_Blank o) => false;
}

/// The reading faces have no subscript digits: 'O₃' sets its 3 small and low.
TextSpan _subscripted(String text, TextStyle style, TextStyle small) {
  final out = <InlineSpan>[];
  final run = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x2080 && rune <= 0x2089) {
      if (run.isNotEmpty) out.add(TextSpan(text: run.toString()));
      run.clear();
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Transform.translate(
            offset: const Offset(1, 2),
            child: Text('${rune - 0x2080}', style: small),
          ),
        ),
      );
      // A placeholder is neutral to the bidi algorithm: in a right-to-left
      // paragraph the one ending "NO₂" took the paragraph's direction and
      // stood before the letters ("₂NO"). A left-to-right mark after it holds
      // it to the formula, which reads left to right in every language.
      out.add(const TextSpan(text: '‎'));
    } else {
      run.writeCharCode(rune);
    }
  }
  if (run.isNotEmpty) out.add(TextSpan(text: run.toString()));
  return TextSpan(style: style, children: out);
}

/// Pairs in small sunk cells: a reading and its measure. Two to a row. `(label, value, unit)`.
///
/// ```dart
/// RetroDesktopMeasures(const [('PM2.5', '6', 'µg/m³'), ('NO₂', '17', 'µg/m³')])
/// ```
class RetroDesktopMeasures extends StatelessWidget {
  /// Creates a [RetroDesktopMeasures].
  const RetroDesktopMeasures(this.items, {super.key});

  /// The items displayed in their supplied order.
  final List<(String, String, String?)> items;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    // Two to a row while the widest reading stands whole in half the column; else one to a row (twice the text on a
    // phone cut every name and unit to a letter: "P… 6 µg…").
    double widthOf(String text, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final w = tp.width;
      tp.dispose();
      return w;
    }

    var widest = 0.0;
    for (final m in items) {
      widest = math.max(
        widest,
        widthOf(m.$1, t.type.text(13, 18, weight: FontWeight.w700)) +
            6 +
            widthOf(m.$2, t.type.figure) +
            (m.$3 == null ? 0 : widthOf(' ${m.$3}', t.type.mono(12, 16))) +
            16 +
            4,
      );
    }
    return LayoutBuilder(
      builder: (context, box) => RetroDesktopGridOf(
        columns: !box.hasBoundedWidth || 2 * widest + 6 <= box.maxWidth ? 2 : 1,
        gap: 6,
        runGap: 6,
        children: [
          for (final m in items)
            // A sunk cell in the family's control shape, its bevel following it,
            // framed as a well is: without its outline the bevel's light edges,
            // white on white paper, left the cell open at its foot and end.
            retroDesktopFace(
              states: const {},
              sunken: true,
              component: t.wellTheme.merge(
                RetroDesktopStyle(fill: WidgetStatePropertyAll(c.paper)),
              ),
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                child: RetroDesktopFitRow(
                  fill: 0,
                  gap: 6,
                  align: RetroDesktopFitAlign.baseline,
                  fillShare: .35,
                  children: [
                    Text.rich(
                      _subscripted(
                        m.$1,
                        t.type.text(13, 18, weight: FontWeight.w700),
                        t.type.text(10, 10, weight: FontWeight.w700),
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text.rich(
                      TextSpan(
                        text: m.$2,
                        style: t.type.figure,
                        children: [
                          if (m.$3 != null)
                            TextSpan(
                              // The micro sign (U+00B5) as its compatibility
                              // form, Greek mu, which the bundled faces carry.
                              text: ' ${m.$3!.replaceAll('\u00b5', '\u03bc')}',
                              style: t.type.mono(12, 16, color: c.textTertiary),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What a window holds, one under another on the window's gap. A window stretched to its column's end has them spread over
/// the height, so nothing leaves a hole at the foot.
///
/// ```dart
/// RetroDesktopSections(children: [const RetroDesktopSectionHeader('Storage'), gauge, const RetroDesktopDivider.etched(), tree])
/// ```
class RetroDesktopSections extends StatelessWidget {
  /// Creates a [RetroDesktopSections].
  const RetroDesktopSections({
    super.key,
    required this.children,
    this.gap = 12,
  });

  /// The child widgets in reading order.
  final List<Widget> children;

  /// Space between adjacent items in logical pixels.
  final double gap;
  @override
  Widget build(BuildContext context) => RetroDesktopColumn(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0)
          RetroDesktopGrow(
            most: gap * 2,
            child: SizedBox(height: gap),
          ),
        children[i],
      ],
    ],
  );
}
