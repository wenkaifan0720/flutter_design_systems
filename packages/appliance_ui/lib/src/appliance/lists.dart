/// Appliance's panels and lists: [AppliancePanel] (a faceplate seated in the
/// housing, the look's card), [ApplianceSectionHeader] (a caps legend
/// printed over a group), [ApplianceListGroup] (rows on one faceplate,
/// split by hairline seams), [ApplianceListTile] and [ApplianceDivider].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'material.dart';
import 'theme.dart';

Color _none(Color c) => c.withValues(alpha: 0);

/// A faceplate: a smooth plastic panel seated flush in the grained housing
/// at a parting line, its top edge catching the light. The look's card:
/// content always stands on one, never on the housing.
///
/// With [onTap] the whole plate is pressable (a product, an order): a press
/// sinks it a touch into its seat, and the keyboard's bezel runs round it.
/// [clip] clips [child] to the plate's corners (a picture at its top).
///
/// Reads [style]'s `fill`, `edge` and `padding` in its states, then
/// [ApplianceThemeData.panelStyle]'s.
///
/// ```dart
/// AppliancePanel(child: Text('Free delivery over £40', style: context.applianceTheme.textTheme.body))
/// ```
class AppliancePanel extends StatelessWidget {
  /// A faceplate holding [child].
  const AppliancePanel({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.clip = false,
    this.style,
  });

  /// What it holds.
  final Widget child;

  /// The room round [child]; 16 on every side when null.
  final EdgeInsetsGeometry? padding;

  /// What a press does; null: a plate that only holds.
  final VoidCallback? onTap;

  /// What a screen reader calls a pressable plate.
  final String? semanticLabel;

  /// Whether [child] is clipped to the plate's corners.
  final bool clip;

  /// Its style, over [ApplianceThemeData.panelStyle].
  final ApplianceStyle? style;

  /// The room a plate leaves round its content.
  static const EdgeInsets defaultPadding = EdgeInsets.all(
    ApplianceSpacing.regular,
  );

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    Widget plate(Set<WidgetState> states) {
      final layered = DesignStyleOf([style, theme.panelStyle], states);
      final pressed = states.contains(WidgetState.pressed);
      final face = layered.on(
        ApplianceFace.plate(c).copyWith(
          top: pressed ? Color.lerp(c.face, c.keyDownTop, 0.5) : null,
          bottom: pressed ? Color.lerp(c.face, c.keyDownBottom, 0.5) : null,
          lift: pressed ? -0.3 : 0,
          travel: pressed ? 0.5 : 0,
          focus: states.contains(WidgetState.focused)
              ? c.focus
              : _none(c.focus),
        ),
      );
      Widget inner = Padding(
        padding:
            layered.padding(Directionality.of(context)) ??
            padding ??
            defaultPadding,
        child: child,
      );
      if (clip) {
        inner = ClipRRect(
          borderRadius: BorderRadius.circular(ApplianceMetrics.panelRadius),
          child: inner,
        );
      }
      return AnimatedApplianceSurface(face: face, control: false, child: inner);
    }

    if (onTap == null) return plate(const {});
    return DesignPressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => plate(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty('pressable', value: onTap != null, ifTrue: 'pressable'),
      )
      ..add(FlagProperty('clip', value: clip, ifTrue: 'clip'));
  }
}

/// A caps legend printed on the housing over a group, as a panel's
/// function is printed over its keys: 12 px, tracked, muted, its start on
/// the rows' words. [trailing] stands at its end (a text button: "See
/// all"). A screen reader hears it as a heading.
///
/// ```dart
/// const ApplianceSectionHeader('Delivery')
/// ```
class ApplianceSectionHeader extends StatelessWidget {
  /// A legend reading [text], set in capitals.
  const ApplianceSectionHeader(
    this.text, {
    super.key,
    this.trailing,
    this.style,
  });

  /// The words (set in capitals as printed; a screen reader hears them as
  /// written).
  final String text;

  /// What stands at its end.
  final Widget? trailing;

  /// Its style: `foreground`, `padding` and `textStyle`.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final layered = DesignStyleOf([style], const {});
    final legend = Semantics(
      header: true,
      label: text,
      excludeSemantics: true,
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: layered.text(
          theme.textTheme.legend.copyWith(color: layered.foreground),
        ),
      ),
    );
    return Padding(
      padding:
          layered.padding(Directionality.of(context)) ??
          EdgeInsetsDirectional.only(
            start: ApplianceSpacing.regular,
            end: trailing == null ? ApplianceSpacing.regular : 0,
            top: ApplianceSpacing.small,
            bottom: ApplianceSpacing.small,
          ),
      child: trailing == null
          ? legend
          : Row(
              children: [
                Expanded(child: legend),
                const SizedBox(width: ApplianceSpacing.small),
                trailing!,
              ],
            ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

/// Rows on one faceplate, split by hairline seams, with a caps [header]
/// printed over the plate and a [footer] note under it.
///
/// ```dart
/// ApplianceListGroup(header: 'Account', children: [ApplianceListTile(title: 'Name', trailingText: 'Rosa Lind', onTap: () {})])
/// ```
class ApplianceListGroup extends StatelessWidget {
  /// A group of [children].
  const ApplianceListGroup({
    super.key,
    required this.children,
    this.header,
    this.headerTrailing,
    this.footer,
    this.style,
  });

  /// The rows.
  final List<Widget> children;

  /// The caps legend over the plate.
  final String? header;

  /// What stands at the legend's end.
  final Widget? headerTrailing;

  /// A note under the plate.
  final String? footer;

  /// The plate's style, over [ApplianceThemeData.panelStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          ApplianceSectionHeader(header!, trailing: headerTrailing),
        AppliancePanel(
          padding: EdgeInsets.zero,
          style: style,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, row) in children.indexed) ...[
                if (i > 0)
                  const ApplianceDivider(
                    indent: ApplianceSpacing.regular,
                    endIndent: ApplianceSpacing.regular,
                  ),
                row,
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: ApplianceSpacing.regular,
              end: ApplianceSpacing.regular,
              top: ApplianceSpacing.small,
            ),
            child: Text(footer!, style: theme.textTheme.secondary),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('header', header, defaultValue: null))
      ..add(IntProperty('rows', children.length));
  }
}

/// A hairline seam between rows of one faceplate: a shaded line with a lit
/// one under it, as a moulded groove catches the light.
///
/// ```dart
/// const ApplianceDivider(indent: 16)
/// ```
class ApplianceDivider extends StatelessWidget {
  /// A seam.
  const ApplianceDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.vertical = false,
    this.style,
  });

  /// The room before it.
  final double indent;

  /// The room after it.
  final double endIndent;

  /// Whether it runs down instead of across.
  final bool vertical;

  /// Its style, over [ApplianceThemeData.listTileStyle]: foreground (the seam).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).listTileStyle,
    ], const {});
    final c = ApplianceTheme.of(context).colors;
    final contrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final dark = look.foreground ?? (contrast ? c.printMuted : c.hairline);
    Widget line(Color color) => vertical
        ? SizedBox(width: 1, child: ColoredBox(color: color))
        : SizedBox(height: 1, child: ColoredBox(color: color));
    final lines = [line(dark), line(_lit(c))];
    return Padding(
      padding: vertical
          ? EdgeInsets.only(top: indent, bottom: endIndent)
          : EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: vertical
          ? Row(mainAxisSize: MainAxisSize.min, children: lines)
          : Column(mainAxisSize: MainAxisSize.min, children: lines),
    );
  }

  Color _lit(ApplianceColors c) => c.brightness == Brightness.light
      ? c.seamLight.withValues(alpha: 0.7)
      : c.seamLight;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('indent', indent, defaultValue: 0))
      ..add(DoubleProperty('endIndent', endIndent, defaultValue: 0))
      ..add(FlagProperty('vertical', value: vertical, ifTrue: 'vertical'));
  }
}

/// One row of an [ApplianceListGroup]: an optional [leading] glyph, a
/// [title] and a [subtitle], and at the end a [trailingText] value, a
/// [trailing] control or, when it opens something, a chevron.
///
/// With [onTap] it is a key the width of the plate: a press sinks it, inset
/// from the plate's edges with its own corners, and its keyboard bezel runs
/// round that key inside the row (rows share their seams, so a bezel outside
/// would sit on a neighbour). [selected] latches it down, as the current
/// choice in a list.
///
/// Reads [style]'s `fill` (in its states: pressed, selected), `foreground`,
/// `padding`, `minimumSize` (its least height), `textStyle` (the title) and
/// `iconSize`, then [ApplianceThemeData.listTileStyle]'s.
///
/// ```dart
/// ApplianceListTile(leading: const Icon(LucideIcons.bell), title: 'Order updates', subtitle: 'When an order ships and arrives', trailing: ApplianceSwitch(value: on, onChanged: (v) => setState(() => on = v), semanticLabel: 'Order updates'))
/// ```
class ApplianceListTile extends StatelessWidget {
  /// A row.
  const ApplianceListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.selected = false,
    this.showChevron,
    this.destructive = false,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  });

  /// The row's words.
  final String title;

  /// A supporting line under the title.
  final String? subtitle;

  /// A glyph at the start, 20 px.
  final Widget? leading;

  /// A control at the end (a switch, a checkbox).
  final Widget? trailing;

  /// A value at the end, muted.
  final String? trailingText;

  /// What a press does; null: a row that only shows.
  final VoidCallback? onTap;

  /// Whether the row is latched down as the current choice.
  final bool selected;

  /// Whether a chevron says it opens something; null: when it has [onTap]
  /// and no [trailing].
  final bool? showChevron;

  /// Whether its action destroys something: printed in the danger colour.
  final bool destructive;

  /// Whether it can be pressed.
  final bool enabled;

  /// The row's name for a screen reader, in place of its words.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.listTileStyle].
  final ApplianceStyle? style;

  /// How far a pressed row's key stands in from the plate's edges.
  static const double keyInset = 4;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final named = semanticLabel != null;
    Widget body(Set<WidgetState> states) {
      final layered = DesignStyleOf(
        [style, theme.listTileStyle],
        {...states, if (selected) WidgetState.selected},
      );
      final disabled = !enabled;
      final down =
          !disabled && (selected || states.contains(WidgetState.pressed));
      final ink =
          layered.foreground ??
          (disabled
              ? c.printDisabled
              : destructive
              ? c.danger
              : c.print);
      final muted = disabled ? c.printDisabled : c.printMuted;
      final chevron = showChevron ?? (onTap != null && trailing == null);
      final face = layered.on(
        ApplianceFace(
          top: down ? c.keyDownTop : _none(c.keyDownTop),
          bottom: down ? c.keyDownBottom : _none(c.keyDownBottom),
          lift: down ? -0.6 : 0,
          travel: down ? 0.6 : 0,
          radius: BorderRadius.circular(
            ApplianceMetrics.panelRadius - keyInset,
          ),
          foreground: ink,
          focus: states.contains(WidgetState.focused)
              ? c.focus
              : _none(c.focus),
        ),
      );
      final hasRoom = subtitle != null;
      return Padding(
        // Room for the bezel inside the row.
        padding: const EdgeInsets.all(keyInset),
        child: AnimatedApplianceSurface(
          control: false,
          face: face,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  (layered.minimumSize?.height ?? (hasRoom ? 72 : 56)) -
                  2 * keyInset,
            ),
            child: Padding(
              padding:
                  layered.padding(Directionality.of(context)) ??
                  const EdgeInsets.symmetric(
                    horizontal: ApplianceSpacing.medium,
                    vertical: ApplianceSpacing.small,
                  ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(
                        size: layered.iconSize ?? 20,
                        color: disabled ? c.printDisabled : c.printMuted,
                      ),
                      child: SizedBox.square(
                        dimension: 24,
                        child: Center(child: leading),
                      ),
                    ),
                    const SizedBox(width: ApplianceSpacing.medium),
                  ],
                  Expanded(
                    child: ExcludeSemantics(
                      excluding: named,
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
                                ),
                              ),
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: ApplianceSpacing.tight / 2,
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
                  ),
                  if (trailingText != null) ...[
                    const SizedBox(width: ApplianceSpacing.medium),
                    Flexible(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ExcludeSemantics(
                          excluding: named,
                          child: Text(
                            trailingText!,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.body.copyWith(color: muted),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: ApplianceSpacing.medium),
                    trailing!,
                  ],
                  if (chevron) ...[
                    const SizedBox(width: ApplianceSpacing.small),
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: SizedBox.square(
                        dimension: 16,
                        child: CustomPaint(
                          painter: ApplianceChevronPainter(
                            disabled ? c.printDisabled : c.printMuted,
                          ),
                        ),
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

    if (onTap == null) {
      return Semantics(
        container: true,
        selected: selected ? true : null,
        label: semanticLabel,
        value: named ? trailingText : null,
        child: body({if (!enabled) WidgetState.disabled}),
      );
    }
    return DesignPressable(
      onPressed: enabled ? onTap : null,
      selected: selected,
      semanticSelected: selected ? true : null,
      semanticLabel: semanticLabel,
      semanticValue: named ? trailingText : null,
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

/// A chevron pointing to the end side, drawn with round caps: a row opens
/// something. Flip it for right-to-left text.
class ApplianceChevronPainter extends CustomPainter {
  /// A chevron in [color].
  ApplianceChevronPainter(this.color);

  /// Its colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, h * 0.2)
        ..lineTo(w * 0.68, h * 0.5)
        ..lineTo(w * 0.35, h * 0.8),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(ApplianceChevronPainter old) => old.color != color;
}
