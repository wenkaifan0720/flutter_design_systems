// The action rows round 4 added (coverage, 11-10): the floating act, a bank of related buttons, a keycap, a bank of
// toggles and a split button. The banks are the segmented control's bank of cells; the toggle group and the split
// button stand on ui_core's behaviours (DesignToggleGroup, DesignSplitButton) and paint them in the look's relief.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'chrome_metrics.dart';
import 'component_themes.dart';
import 'controls.dart';
import 'entries.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'internal/cell_bank.dart';
import 'internal/geometry.dart';
import 'internal/panel.dart';
import 'knobs.dart';
import 'styled.dart';
import 'layout.dart';
import 'localizations.dart';
import 'shapes.dart';
import 'theme.dart';
import 'internal/cap_label.dart';
import 'internal/out_of_use.dart';

/// One button of a [NeumorphicButtonGroup].
@immutable
class NeumorphicButtonGroupItem {
  /// A button saying [label] that runs [onPressed]; null draws it out of use.
  const NeumorphicButtonGroupItem(
    this.label, {
    this.icon,
    this.onPressed,
    this.semanticLabel,
  });

  /// Its words.
  final String label;

  /// A glyph before its words.
  final IconData? icon;

  /// What it runs; null: out of use.
  final VoidCallback? onPressed;

  /// What a screen reader hears, when not [label].
  final String? semanticLabel;
}

/// Related actions joined in one raised bank, with engraved seams between them (previous, today, next): a toolbar.
/// Each acts on its own and goes in when pressed; none stays in. Narrow, the bank wraps to a second row.
///
/// ```dart
/// NeumorphicButtonGroup(label: 'Week', items: [NeumorphicButtonGroupItem('Previous', onPressed: back), NeumorphicButtonGroupItem('Next', onPressed: on)])
/// ```
class NeumorphicButtonGroup extends StatelessWidget {
  /// A group named [label] of [items].
  const NeumorphicButtonGroup({
    super.key,
    required this.label,
    required this.items,
    this.style,
  });

  /// What a screen reader calls the group.
  final String label;

  /// The buttons, in reading order.
  final List<NeumorphicButtonGroupItem> items;

  /// Cell faces and words before the segmented-button theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final metrics = _BankMetrics.of(context, style, [
      for (final i in items) (i.label, i.icon != null),
    ]);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: NeumorphicOutOfUse(
        off: items.every((i) => i.onPressed == null),
        child: NeumorphicCellBank(
          selected: -1,
          minCellWidth: metrics.least,
          side: metrics.look.side,
          edge: metrics.look.edge,
          naturalWidth: items.length * 120.0,
          contentHeight: metrics.contentHeight,
          children: [
            for (final item in items)
              Builder(
                builder: (context) {
                  final cell = NeumorphicCellScope.of(context);
                  final enabled = item.onPressed != null;
                  return NeumorphicTap(
                    style: style,
                    themeStyle: t.segmentedButtonTheme,
                    shape: cell.border,
                    focusReach: .5,
                    label: item.semanticLabel ?? item.label,
                    onPressed: item.onPressed,
                    child: Builder(
                      builder: (context) => _cellContent(
                        context,
                        style,
                        label: item.label,
                        icon: item.icon,
                        enabled: enabled,
                        selected: false,
                        states: NeumorphicStatesScope.of(context),
                        padding: metrics.padding,
                        border: cell.border,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A keyboard key, or keys pressed together, as small raised keycaps joined by a +: what a shortcut is. It shows a
/// key; it does not press anything. A screen reader hears the keys joined by plus.
///
/// ```dart
/// NeumorphicKbd(['Ctrl', 'K'])
/// ```
class NeumorphicKbd extends StatelessWidget {
  /// The keycaps for [keys], in the order they are held.
  const NeumorphicKbd(this.keys, {super.key, this.semanticLabel, this.style});

  /// The keys' names or signs ('Ctrl', '⌘', 'K').
  final List<String> keys;

  /// What a screen reader hears; null: the keys joined by plus.
  final String? semanticLabel;

  /// The caps' face and words before the chip theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final look = NeumorphicStyleOf([style, t.chipTheme], const {});
    final words = t.textTheme.micro.tabular
        .copyWith(color: c.inkSecondary, fontWeight: FontWeight.w700)
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    Widget cap(String key) => NeumorphicSurface(
      cast: NeumorphicSurfaceLevel.part,
      style: style,
      themeStyle: t.chipTheme,
      // A cap is a small square object: the theme's mark corner, never a pill.
      shape: t.shapes.corner(6),
      radius: 6,
      outlined: true,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 12),
        child: neumorphicLabel(
          Text(key, style: words, textAlign: TextAlign.center),
        ),
      ),
    );
    return Semantics(
      label: semanticLabel ?? keys.join(' plus '),
      child: ExcludeSemantics(
        child: Padding(
          // Room for the caps' own cast inside the line they stand in, up and down; the first cap's face starts on
          // the edge, its cast past it as every face's is.
          padding: const EdgeInsets.symmetric(vertical: 3),
          // A chord is pressed in the order it is written, Ctrl before K, in either direction: laid in the page's
          // direction it read "K + Ctrl" right to left. The joining plus is in the secondary ink: in the micro's
          // tertiary ink, between two caps, it all but vanished.
          // The chord stands at the page's start: its row is written left to right, and stretched it put the caps at the
          // left edge of a right-to-left page, away from their words.
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                for (var i = 0; i < keys.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        '+',
                        style: t.textTheme.caption.copyWith(
                          color: t.colors.inkSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  cap(keys[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggles in one raised bank: each one pressed in while it is on, with the pigment's wash, several at once
/// ([multiple]), or one with [multiple] false (and [allowEmpty] false keeps one in). One tab stop; the arrows move
/// along it. Narrow, the bank wraps to a second row.
///
/// ```dart
/// NeumorphicToggleGroup<String>(label: 'Text', items: const [NeumorphicButtonSegment('b', 'Bold'), NeumorphicButtonSegment('i', 'Italic')], selected: const {'b'}, onChanged: (next) {})
/// ```
class NeumorphicToggleGroup<T> extends StatelessWidget {
  /// A group named [label] of [items], [selected] on.
  const NeumorphicToggleGroup({
    super.key,
    required this.label,
    required this.items,
    required this.selected,
    this.onChanged,
    this.multiple = true,
    this.allowEmpty = true,
    this.style,
  });

  /// What a screen reader calls the group.
  final String label;

  /// The toggles, in reading order.
  final List<NeumorphicButtonSegment<T>> items;

  /// The values that are on.
  final Set<T> selected;

  /// Reports the values on after a press; null draws the group out of use.
  final ValueChanged<Set<T>>? onChanged;

  /// Whether any number may be on.
  final bool multiple;

  /// Whether a one-choice group may be left with none on.
  final bool allowEmpty;

  /// Cell faces and words before the segmented-button theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final metrics = _BankMetrics.of(context, style, [
      for (final i in items) (i.label, i.icon != null),
    ]);
    NeumorphicButtonSegment<T> item(T value) =>
        items.firstWhere((i) => i.value == value);
    return DesignToggleGroup<T>(
      options: [for (final i in items) i.value],
      selected: selected,
      onSelectionChanged: onChanged,
      multiSelectionEnabled: multiple,
      emptySelectionAllowed: allowEmpty,
      isEnabled: (v) => item(v).enabled,
      labelOf: (v) => item(v).semanticLabel ?? item(v).label,
      semanticLabel: label,
      minimumSize: Size.zero,
      // Out of use the whole bank lies flat: its groove and the cells that are in with the words.
      layoutBuilder: (context, cells) => NeumorphicOutOfUse(
        off: onChanged == null,
        child: NeumorphicCellBank(
          selected: -1,
          minCellWidth: metrics.least,
          side: metrics.look.side,
          edge: metrics.look.edge,
          naturalWidth: items.length * 104.0,
          contentHeight: metrics.contentHeight,
          children: cells,
        ),
      ),
      itemBuilder: (context, value, states) {
        final cell = NeumorphicCellScope.of(context);
        final on = states.contains(WidgetState.selected);
        final i = item(value);
        return NeumorphicTapFace(
          states: states,
          style: style,
          themeStyle: t.segmentedButtonTheme,
          shape: cell.border,
          focusReach: .5,
          // An item that is in is already pressed; a press on one that is out shows it going in.
          pressRelief: !on,
          child: NeumorphicCellFace(
            chosen: on,
            child: _cellContent(
              context,
              style,
              label: i.label,
              icon: i.icon,
              enabled: !states.contains(WidgetState.disabled),
              selected: on,
              states: states,
              padding: metrics.padding,
              border: cell.border,
            ),
          ),
        );
      },
    );
  }
}

/// One action in a [NeumorphicSplitButton]'s menu.
@immutable
class NeumorphicSplitAction {
  /// An action saying [label] that [onPressed] runs, after the menu closes. With no [onPressed] it is out of use.
  const NeumorphicSplitAction(this.label, {required this.onPressed, this.icon});

  /// Its words.
  final String label;

  /// What it runs; null puts it out of use.
  final VoidCallback? onPressed;

  /// A glyph before its words.
  final IconData? icon;
}

/// The act with its alternatives: the pigment act button, and joined to it a narrow key with a chevron that raises a
/// menu of the [actions]. Both halves are tab stops; Down opens the menu at its first action, Escape closes it and the
/// focus goes back.
///
/// ```dart
/// NeumorphicSplitButton('Save', onPressed: save, actions: [NeumorphicSplitAction('Save as copy', onPressed: copy)])
/// ```
class NeumorphicSplitButton extends StatelessWidget {
  /// The act [label] that [onPressed] runs, with [actions] beside it.
  const NeumorphicSplitButton(
    this.label, {
    super.key,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.style,
  });

  /// The main act's words.
  final String label;

  /// The main act; null draws that half out of use.
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<NeumorphicSplitAction> actions;

  /// What a screen reader calls the menu's key; null says the localized 'More options'.
  final String? menuLabel;

  /// State-resolved visual overrides before the act button theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final words = NeumorphicLocalizations.of(context);
    final themeStyle = NeumorphicStyle.cascade([
      t.filledButtonTheme,
      t.buttonTheme,
    ]);
    final height = t.density.height(48);
    // One capsule (or the theme's small frame) cut in two: the main half keeps the start's corners, the key the end's.
    final whole = t.shapes.corner(NeumorphicRadii.control);
    final source = {for (final a in actions) a.label: a};
    return DesignSplitButton(
      label: label,
      onPressed: onPressed,
      menuLabel: menuLabel ?? words.moreOptions,
      minimumSize: Size(NeumorphicChromeMetrics.targetSize, height),
      actions: [
        for (final a in actions)
          DesignSplitAction(
            label: a.label,
            onPressed: a.onPressed,
            data: a.icon,
          ),
      ],
      // One moulded body: one light and one shadow round the whole capsule, each half only its face over it. The body
      // is as wide as its two halves: in a stretching column it filled the column, its words huddled at the start.
      layoutBuilder: (context, main, toggle) => Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: CustomPaint(
          painter: _SplitBody(
            c,
            whole,
            t.elevation,
            NeumorphicFlatScope.of(context) ||
                (onPressed == null &&
                    actions.every((a) => a.onPressed == null)),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [main, toggle],
            ),
          ),
        ),
      ),
      buttonBuilder: (context, part, states, open) {
        final isMain = part == DesignSplitPart.main;
        final look = NeumorphicStyleOf([style, themeStyle], states);
        final enabled = !states.contains(WidgetState.disabled);
        final dir = Directionality.of(context);
        final shape = NeumorphicCellBorder(
          bank: whole,
          frame: 0,
          reach: isMain
              ? const EdgeInsetsDirectional.only(end: 44).resolve(dir)
              : const EdgeInsetsDirectional.only(start: 200).resolve(dir),
        );
        final ink = look.foreground ?? c.onPigment;
        final content = isMain
            ? Padding(
                padding:
                    look.padding(dir) ??
                    t.density.padding(
                      const EdgeInsets.symmetric(horizontal: 18),
                    ),
                child: Center(
                  widthFactor: 1,
                  child: neumorphicLabel(
                    Text(
                      label,
                      style: t.textTheme.title
                          .merge(look.textStyle)
                          .copyWith(color: ink),
                    ),
                  ),
                ),
              )
            : SizedBox(
                width: 40,
                child: Center(
                  child: AnimatedRotation(
                    turns: open ? .5 : 0,
                    duration: NeumorphicMotion.of(context).state,
                    child: Icon(
                      NeumorphicGlyphs.chevronDown,
                      size: look.iconSize ?? 18,
                      color: ink,
                    ),
                  ),
                ),
              );
        return NeumorphicTapFace(
          states: {...states, if (open) WidgetState.pressed},
          style: style,
          themeStyle: themeStyle,
          shape: shape,
          child: NeumorphicOutOfUse(
            off: !enabled,
            // Each half sinks on its own when pressed, into the body's one face.
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                end: states.contains(WidgetState.pressed) || open ? 1 : 0,
              ),
              duration: NeumorphicMotion.of(context).press,
              curve: NeumorphicMotion.of(context).standard,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: content,
              ),
              builder: (context, down, child) => CustomPaint(
                painter: _SplitHalf(
                  c,
                  shape,
                  look.fill,
                  t.elevation,
                  NeumorphicFlatScope.of(context),
                  isMain,
                  dir,
                  down,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      surfaceBuilder: (context, info, items) => NeumorphicPanel(
        presence: info.animation,
        side: info.side,
        width: 240,
        maxHeight: info.maxSize.height,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          ),
        ),
      ),
      itemBuilder: (context, action, states) => NeumorphicPanelRow(
        label: action.label,
        icon: (action.data as IconData?) ?? source[action.label]?.icon,
        states: states,
      ),
    );
  }
}

/// A split button's half: the act's pigment face in its share of the whole outline, with a seam of the face's own
/// dark at the join.
/// The split button's one body: the whole capsule's light and shadow, under both halves' faces.
class _SplitBody extends CustomPainter {
  const _SplitBody(this.c, this.whole, this.elevation, this.flat);
  final NeumorphicColors c;
  final OutlinedBorder whole;
  final NeumorphicElevation elevation;
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    neumorphicPaintRaised(
      canvas,
      whole.getOuterPath(box),
      c,
      light: (const Offset(-4, -4), 10),
      dark: (const Offset(5, 5), 12),
      face: cssLinear(box, 145, [c.pigment, c.pigmentDk]),
      elevation: elevation,
      flat: flat,
      rim: false,
    );
  }

  @override
  bool shouldRepaint(_SplitBody o) =>
      o.c != c ||
      o.whole != whole ||
      o.elevation != elevation ||
      o.flat != flat;
}

/// One half's face of the split button: the body's colour, sunk by [down] when it is pressed, and its side of the thin
/// pressed groove between the halves (shade on the left wall, the colour's own light on the right).
class _SplitHalf extends CustomPainter {
  const _SplitHalf(
    this.c,
    this.shape,
    this.fill,
    this.elevation,
    this.flat,
    this.main,
    this.dir,
    this.down,
  );
  final NeumorphicColors c;
  final OutlinedBorder shape;
  final Color? fill;
  final NeumorphicElevation elevation;
  final bool flat, main;
  final TextDirection dir;
  final double down;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final path = shape.getOuterPath(box);
    final colour = fill ?? c.pigment;
    neumorphicPaintPressed(
      canvas,
      path,
      c,
      light: (const Offset(-3, -3), 7),
      dark: (const Offset(3, 3), 7),
      face: cssLinear(box, 145, [colour, fill ?? c.pigmentDk]),
      tone: colour,
      elevation: elevation.copyWith(
        depth: elevation.depth * down,
        strength: elevation.strength * down,
      ),
      flat: flat || down == 0,
    );
    final (hi, lo) = neumorphicTones(colour, c);
    final left = (dir == TextDirection.ltr) == main;
    canvas.save();
    canvas.clipPath(path);
    canvas.drawLine(
      Offset(left ? size.width - .75 : .5, 0),
      Offset(left ? size.width - .75 : .5, size.height),
      Paint()
        ..color = left ? lo.withValues(alpha: .9) : hi.withValues(alpha: .8)
        ..strokeWidth = left ? 1.5 : 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplitHalf o) =>
      o.c != c ||
      o.shape != shape ||
      o.fill != fill ||
      o.elevation != elevation ||
      o.flat != flat ||
      o.main != main ||
      o.dir != dir ||
      o.down != down;
}

/// The least cell width and a cell's content height for a bank of labelled cells.
class _BankMetrics {
  _BankMetrics(this.look, this.padding, this.least, this.contentHeight);

  factory _BankMetrics.of(
    BuildContext context,
    NeumorphicStyle? style,
    List<(String, bool)> cells,
  ) {
    final t = NeumorphicTheme.of(context);
    final dir = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final look = NeumorphicStyleOf([style, t.segmentedButtonTheme], const {});
    final padding =
        look.padding(dir) ??
        t.density.padding(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        );
    final words = _words(t, look);
    final icon = (look.iconSize ?? 18) + 8;
    var least = 48.0;
    for (final (label, hasIcon) in cells) {
      least = math.max(
        least,
        neumorphicWidestWord(label, words, textScaler: scaler) +
            padding.horizontal +
            (hasIcon ? icon : 0),
      );
    }
    double contentHeight(double cellWidth) {
      var tallest = 0.0;
      for (final (label, hasIcon) in cells) {
        final painter =
            TextPainter(
              text: TextSpan(text: label, style: words),
              textDirection: dir,
              textScaler: scaler,
            )..layout(
              maxWidth: math.max(
                0,
                cellWidth - padding.horizontal - (hasIcon ? icon : 0),
              ),
            );
        tallest = math.max(tallest, painter.height);
        painter.dispose();
      }
      return tallest + padding.vertical;
    }

    return _BankMetrics(look, padding, least, contentHeight);
  }

  final NeumorphicStyleOf look;
  final EdgeInsets padding;
  final double least;
  final double Function(double cellWidth) contentHeight;
}

/// A bank cell's words: one weight in and out, so a label never reflows when its cell goes in.
TextStyle _words(NeumorphicThemeData t, NeumorphicStyleOf look) => t
    .textTheme
    .body
    .copyWith(fontWeight: FontWeight.w600)
    .merge(look.textStyle);

/// A bank cell's content: its glyph and words, in the pigment's ink while it is in, flat with the relief while it is
/// out of use; a style's own fill for the state in the cell's exact outline.
Widget _cellContent(
  BuildContext context,
  NeumorphicStyle? style, {
  required String label,
  required IconData? icon,
  required bool enabled,
  required bool selected,
  required Set<WidgetState> states,
  required EdgeInsets padding,
  required OutlinedBorder border,
}) {
  final t = NeumorphicTheme.of(context);
  final c = t.colors;
  final look = NeumorphicStyleOf(
    [style, t.segmentedButtonTheme],
    {...states, if (selected) WidgetState.selected},
  );
  Widget face = NeumorphicOutOfUse(
    off: !enabled,
    child: Padding(
      padding: padding,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: look.iconSize ?? 18,
                color: look.foreground ?? (selected ? c.pigmentInkLit : c.ink),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: neumorphicLabel(
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _words(
                    t,
                    look,
                  ).copyWith(color: c.ink).copyWith(color: look.foreground),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (look.fill != null) {
    face = DecoratedBox(
      decoration: ShapeDecoration(color: look.fill, shape: border),
      child: face,
    );
  }
  return face;
}
