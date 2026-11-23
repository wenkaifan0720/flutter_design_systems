/// Studio's lists: [StudioSectionHeader] (an engraved legend with a groove
/// after it), [StudioListGroup] (rows on a pane of glass) and
/// [StudioListTile] (a row: a press sinks a slot into the glass under it).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/control_light.dart';

import 'choices.dart';
import 'panel.dart';
import 'surface.dart';
import 'theme.dart';

/// A section's header: its name engraved on the metal as a legend, a
/// machined groove running on from it to the end, and an optional action at
/// the end.
///
/// Reads [style]'s `foreground` and `padding`, then
/// [StudioThemeData.sectionHeaderStyle].
///
/// ```dart
/// const StudioSectionHeader('Audio quality')
/// ```
class StudioSectionHeader extends StatelessWidget {
  /// A header naming its section [text].
  const StudioSectionHeader(this.text, {super.key, this.trailing, this.style});

  /// The section's name, in sentence case: the legend sets its capitals.
  final String text;

  /// An action at its end ("See all").
  final Widget? trailing;

  /// Its style, over [StudioThemeData.sectionHeaderStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final layered = DesignStyleOf([style, theme.sectionHeaderStyle], const {});
    return Semantics(
      header: true,
      child: Padding(
        padding:
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.only(
              top: StudioSpacing.small,
              bottom: StudioSpacing.small,
            ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          // The legend takes the width its words need, up to the line less a
          // groove's least; longer (larger text on a phone), it wraps. Beside
          // an action, it shares the line with the groove.
          child: LayoutBuilder(
            builder: (context, box) {
              final legend = StudioLegend(
                text,
                color: layered.foreground,
                maxLines: null,
              );
              return Row(
                children: [
                  if (trailing == null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.max(
                          0,
                          box.maxWidth - StudioSpacing.medium - _leastGroove,
                        ),
                      ),
                      child: legend,
                    )
                  else
                    Flexible(child: legend),
                  const SizedBox(width: StudioSpacing.medium),
                  const Expanded(child: StudioGroove()),
                  if (trailing != null) ...[
                    const SizedBox(width: StudioSpacing.small),
                    trailing!,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// The least of a section header's groove beside its legend.
const double _leastGroove = 24;

/// Rows on one pane of glass, parted by fine rules that start where the
/// rows' words do. A [header] stands above it as a [StudioSectionHeader], a
/// [footer] under it in small print.
///
/// ```dart
/// StudioListGroup(header: 'Notifications', children: [StudioListTile.toggle(title: 'New episodes', value: on, onChanged: set)])
/// ```
class StudioListGroup extends StatelessWidget {
  /// A group of [children].
  const StudioListGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.dividerIndent = StudioSpacing.regular,
  });

  /// The rows, usually [StudioListTile]s.
  final List<Widget> children;

  /// Its name, above it.
  final String? header;

  /// A note under it.
  final String? footer;

  /// Where the rules between rows start: the rows' words' start.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) StudioSectionHeader(header!),
        StudioDisplay(
          padding: const EdgeInsets.all(StudioMetrics.recessInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, row) in children.indexed) ...[
                if (i > 0)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: dividerIndent,
                      end: StudioSpacing.small,
                    ),
                    child: SizedBox(
                      height: 1,
                      child: ColoredBox(color: c.displayLine),
                    ),
                  ),
                row,
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: StudioSpacing.small,
              start: StudioSpacing.regular,
              end: StudioSpacing.regular,
            ),
            child: Text(
              footer!,
              style: theme.textTheme.caption.copyWith(color: c.legendMuted),
            ),
          ),
      ],
    );
  }
}

enum _RowKind { plain, toggle }

/// A row on a pane of glass: an optional [leading] glyph or picture, a
/// [title] with an optional [subtitle], and a value ([trailingText]) or a
/// control ([trailing]) at its end.
///
/// With [onTap] a press sinks a slot into the glass under it, its corners
/// concentric with the pane's, and a pointer over it shows the slot faintly.
/// [selected] keeps the slot sunk and lights a lamp at its end, before the
/// chevron: the row whose detail stands beside the list.
///
/// [StudioListTile.toggle] is a row that is a switch: the whole row turns
/// it, and a screen reader hears one switch named by the title.
///
/// Reads [style]'s `fill`, `foreground`, `padding` and `minimumSize`, then
/// [StudioThemeData.listTileStyle].
///
/// ```dart
/// StudioListTile(title: 'Audio quality', trailingText: 'High', onTap: () => pick())
/// ```
class StudioListTile extends StatelessWidget {
  /// A row.
  const StudioListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.selected = false,
    this.showChevron,
    this.isDestructiveAction = false,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  }) : value = false,
       onChanged = null,
       _kind = _RowKind.plain;

  /// A row that is a switch showing [value]; the whole row turns it.
  const StudioListTile.toggle({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  }) : trailing = null,
       trailingText = null,
       onTap = null,
       selected = false,
       showChevron = false,
       isDestructiveAction = false,
       _kind = _RowKind.toggle;

  /// What it is.
  final String title;

  /// A line more.
  final String? subtitle;

  /// A glyph or a picture at its start.
  final Widget? leading;

  /// A control at its end.
  final Widget? trailing;

  /// A value at its end, in the muted ink.
  final String? trailingText;

  /// What a press does.
  final VoidCallback? onTap;

  /// Whether it is the row shown beside the list.
  final bool selected;

  /// Whether it shows the arrow that says it opens something; by default
  /// when it has [onTap] and no [trailing].
  final bool? showChevron;

  /// Whether a press destroys something: its title in the danger colour.
  final bool isDestructiveAction;

  /// Whether it can be used.
  final bool enabled;

  /// What a screen reader calls it, when not its title.
  final String? semanticLabel;

  /// Its style, over [StudioThemeData.listTileStyle].
  final StudioStyle? style;

  /// A toggle row's value.
  final bool value;

  /// Called with a toggle row's new value; null disables it.
  final ValueChanged<bool>? onChanged;

  final _RowKind _kind;

  /// How far a row's words stand from its start when it has a 24 px
  /// [leading] glyph.
  static const double leadingExtent = 24 + StudioSpacing.medium;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final toggle = _kind == _RowKind.toggle;
    final action = toggle
        ? (enabled && onChanged != null ? () => onChanged!(!value) : null)
        : (enabled ? onTap : null);

    Widget body(Set<WidgetState> states) {
      final layered = DesignStyleOf(
        [style, theme.listTileStyle],
        {...states, if (selected) WidgetState.selected},
      );
      final disabled = !enabled || (toggle && onChanged == null);
      final pressed = states.contains(WidgetState.pressed);
      final cue = studioControlLight(states);
      final ink =
          layered.foreground ??
          (disabled
              ? c.disabled
              : isDestructiveAction
              ? c.dangerLegend
              : Color.lerp(c.onDisplay, c.litLegend, cue)!);
      final muted = disabled ? c.disabled : c.onDisplayMuted;
      final chevron =
          showChevron ?? (!toggle && onTap != null && trailing == null);
      final slot = StudioFace(
        fill: layered.fill ?? Color.lerp(c.displayLow, c.shadow, 0.06)!,
        fillLow: layered.fill ?? Color.lerp(c.display, c.shadow, 0.03)!,
        depth: StudioDepth.sunk,
        radius: StudioRadii.display - StudioMetrics.recessInset,
        foreground: ink,
        presence: pressed || selected ? 1 : 0,
      );
      return AnimatedStudioSurface(
        face: slot,
        stiffness: StudioMotion.lampStiffness,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                layered.minimumSize?.height ??
                (subtitle == null ? theme.rowHeight : theme.rowHeight + 12),
          ),
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsetsDirectional.only(
                  start: StudioSpacing.regular - StudioMetrics.recessInset,
                  end: StudioSpacing.medium - StudioMetrics.recessInset,
                  top: StudioSpacing.small,
                  bottom: StudioSpacing.small,
                ),
            // A value at the end takes its own width (up to under half the
            // row), the title the rest, so a short value leaves the title
            // the row.
            child: LayoutBuilder(
              builder: (context, box) => Row(
                children: [
                  if (leading != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(
                        size: layered.iconSize ?? 24,
                        color: ink,
                      ),
                      child: leading!,
                    ),
                    const SizedBox(width: StudioSpacing.medium),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DesignCapCenter(
                          capHeightFactor: theme.capHeightFactor,
                          child: Text(
                            title,
                            style: layered.text(
                              theme.textTheme.body.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w500,
                                height: 22 / 16,
                              ),
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: StudioSpacing.hair,
                            ),
                            child: Text(
                              subtitle!,
                              style: theme.textTheme.secondary.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailingText != null) ...[
                    const SizedBox(width: StudioSpacing.medium),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: box.maxWidth.isFinite
                            ? box.maxWidth * 0.45
                            : double.infinity,
                      ),
                      child: Text(
                        trailingText!,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.body.copyWith(color: muted),
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: StudioSpacing.medium),
                    trailing!,
                  ],
                  if (toggle) ...[
                    const SizedBox(width: StudioSpacing.medium),
                    // The row is the switch: the one in it only shows it.
                    ExcludeSemantics(
                      child: ExcludeFocus(
                        child: IgnorePointer(
                          child: StudioSwitch(
                            value: value,
                            onChanged: disabled ? null : (_) {},
                          ),
                        ),
                      ),
                    ),
                  ],
                  // The chosen row's lamp, at the end as a key's is.
                  if (selected) ...[
                    const SizedBox(width: StudioSpacing.medium),
                    StudioControlLamp(on: true, states: states),
                  ],
                  if (chevron) ...[
                    const SizedBox(width: StudioSpacing.small),
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: CustomPaint(
                        size: const Size(16, 16),
                        painter: _ChevronPainter(muted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final label =
        semanticLabel ??
        [title, ?subtitle, if (!toggle) ?trailingText].join(', ');
    if (action == null && !toggle) {
      return Semantics(
        container: true,
        selected: selected ? true : null,
        label: label,
        excludeSemantics: true,
        child: ExcludeSemantics(
          child: body({if (!enabled) WidgetState.disabled}),
        ),
      );
    }
    return RawButton(
      onPressed: action,
      selected: selected,
      semanticSelected: selected ? true : null,
      toggled: toggle ? value : null,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) => body(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.38, size.height * 0.22)
        ..lineTo(size.width * 0.66, size.height * 0.5)
        ..lineTo(size.width * 0.38, size.height * 0.78),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
