/// A row of toggles: one choice of several, or any number (bold, italic,
/// underline), painted on ui_core's toggle group.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/give_way_row.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';

/// One toggle of a [MinimalToggleGroup]: the [value] it stands for, its
/// [label], a 16 px [icon], or both. An icon alone needs a [semanticLabel].
///
/// ```dart
/// MinimalToggleItem('bold', icon: LucideIcons.bold, semanticLabel: 'Bold')
/// ```
@immutable
class MinimalToggleItem<T> {
  /// A toggle for [value].
  const MinimalToggleItem(
    this.value, {
    this.label,
    this.icon,
    this.semanticLabel,
    this.enabled = true,
  }) : assert(label != null || icon != null, 'a toggle shows words or a glyph');

  /// What turning this toggle on reports.
  final T value;

  /// The toggle's words.
  final String? label;

  /// A glyph before the words, or alone.
  final IconData? icon;

  /// What a screen reader calls it; the [label] unstated.
  final String? semanticLabel;

  /// Whether it can be pressed.
  final bool enabled;
}

/// A strip of toggles, as a toolbar holds them: text formats (any number on,
/// `multiple: true`), or one view of several (one on). An outlined 32 px
/// strip (28 with `small: true`) of cells edge to edge, a hairline between
/// them; an on cell's glyph and words take the full ink (the words at medium
/// weight), an off one the muted ink. `outlined: false` leaves the strip out: loose ghost
/// toggles for a toolbar that draws its own frame.
///
/// One tab stop for the group, at its chosen item (or its first); the arrows
/// move along it, Home and End go to its ends, Space and Enter press. One
/// choice announces a radio group; several, a set of toggle buttons. The
/// behaviour is ui_core's ([DesignToggleGroup]); Minimal paints it. A
/// segmented control that slides a thumb is [MinimalSegmentedButton].
///
/// [style] dresses one group. Per toggle, resolved with
/// [WidgetState.selected] on an on one: fill, foreground, textStyle,
/// iconSize and padding. The strip: edge or side, shape (else
/// `shapes.small`; each cell takes its share of the outline) and
/// minimumSize (its height).
///
/// ```dart
/// MinimalToggleGroup<String>(items: const [MinimalToggleItem('b', icon: LucideIcons.bold, semanticLabel: 'Bold'), MinimalToggleItem('i', icon: LucideIcons.italic, semanticLabel: 'Italic')], selected: formats, multiple: true, onChanged: setFormats)
/// ```
class MinimalToggleGroup<T> extends StatelessWidget {
  /// A group of [items], [selected] on.
  const MinimalToggleGroup({
    super.key,
    required this.items,
    required this.selected,
    this.onChanged,
    this.multiple = false,
    this.allowEmpty = false,
    this.label,
    this.small = false,
    this.outlined = true,
    this.style,
  });

  /// The toggles, in order.
  final List<MinimalToggleItem<T>> items;

  /// The values that are on.
  final Set<T> selected;

  /// A press's new set; null disables the group.
  final ValueChanged<Set<T>>? onChanged;

  /// Whether any number may be on.
  final bool multiple;

  /// Whether a one-choice group may be left with none on.
  final bool allowEmpty;

  /// What the group is about, announced before its toggles.
  final String? label;

  /// The 28 px register, for a dense toolbar.
  final bool small;

  /// Draw the strip around the toggles (the default), or leave them loose.
  final bool outlined;

  /// This group's style.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final enabled = onChanged != null;
    final layers = <MinimalStyle?>[style];
    final strip = MinimalStyleOf(layers, minimalStates(enabled: enabled));
    final height =
        strip.minimumSize?.height ??
        minimalGrownHeight(
          context,
          t.density.height(
            small
                ? MinimalChromeMetrics.controlSm
                : MinimalChromeMetrics.control,
          ),
        );
    final outline = strip.shape ?? t.shapes.small;
    final byValue = {for (final item in items) item.value: item};
    final n = items.length;
    int indexOf(T value) => items.indexWhere((item) => item.value == value);

    Widget face(T value, Set<WidgetState> states) {
      final item = byValue[value]!;
      final i = indexOf(value);
      final so = MinimalStyleOf(layers, states);
      final on = states.chosen;
      final inkTo =
          so.foreground ??
          (states.off
              ? t.textTertiary
              : on
              ? t.foreground
              : t.mutedForeground);
      final cell = outlined
          ? minimalCell(outline, index: i, count: n, inset: t.rim)
          : outline;
      final glyph = item.icon;
      final words = item.label;
      // The cell's fill and ink lerp to each state (Minimal's short fade).
      return MinimalFace(
        ink: inkTo,
        height: outlined ? height - 2 * t.rim : height,
        constraints: BoxConstraints(
          minWidth: outlined ? height - 2 * t.rim : height,
        ),
        alignment: Alignment.center,
        padding:
            so.padding ??
            EdgeInsets.symmetric(
              horizontal: words == null ? 0 : MinimalControlMetrics.segmentPad,
            ),
        // On is said in ink and weight, not a fill (no tinted cell).
        decoration: minimalFrame(cell, fill: so.fill),
        foregroundDecoration: minimalStateLayer(
          t,
          cell,
          states,
          inside: outlined,
          ground: minimalGround(context),
        ),
        builder: (context, lerped) {
          final ink = lerped ?? inkTo;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (glyph != null)
                MinimalIcon(
                  glyph,
                  size: so.iconSize ?? MinimalIconSize.i16,
                  color: ink,
                ),
              if (glyph != null && words != null)
                const MinimalGap(MinimalSpacing.s4),
              if (words != null)
                Flexible(
                  child: minimalCapLabel(
                    Text(
                      words,
                      style: so.text(
                        on
                            ? (small ? t.caption : t.bodySmall).medium
                            : (small ? t.caption : t.bodySmall),
                        ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    final group = DesignToggleGroup<T>(
      options: [for (final item in items) item.value],
      selected: selected,
      onSelectionChanged: onChanged,
      multiSelectionEnabled: multiple,
      emptySelectionAllowed: allowEmpty,
      semanticLabel: label,
      minimumSize: Size.zero,
      isEnabled: (v) => byValue[v]!.enabled,
      labelOf: items.any((i) => i.semanticLabel != null)
          ? (v) => byValue[v]!.semanticLabel ?? byValue[v]!.label ?? ''
          : null,
      itemBuilder: (context, value, states) => face(value, states),
      // Each toggle keeps its width where the words fit; where they do not
      // (large text, a phone's column) the toggles give way in proportion
      // and ellipsize, the hairlines between them kept.
      layoutBuilder: (context, cells) => MinimalGiveWayRow(
        fixed: {for (var i = 1; i < cells.length; i++) 2 * i - 1},
        children: [
          for (final (i, cell) in cells.indexed) ...[
            if (i > 0)
              outlined
                  ? Container(
                      width: t.hairline,
                      height: height - 2 * t.rim,
                      color: strip.edge ?? t.border,
                    )
                  : const MinimalGap(MinimalSpacing.s2),
            cell,
          ],
        ],
      ),
    );

    Widget body = group;
    if (outlined) {
      body = Container(
        padding: EdgeInsets.all(t.rim),
        decoration: minimalFrame(outline, side: strip.rim(t.border, t.rim)),
        child: group,
      );
    }
    if (!enabled) body = Opacity(opacity: 0.45, child: body);
    // The frame hugs its toggles, also in a column that stretches it.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: MinimalHitTarget(child: body),
    );
  }
}
