/// Gloss's other actions: a row of pearl keys set in one trough (a button
/// group, a toggle group), the split key, the link and the keycap that
/// names a key.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/chevron.dart';
import 'internal/menu_parts.dart';
import 'popovers.dart';
import 'surface.dart';
import 'theme.dart';

/// The inset between a trough and the keys set in it, all round.
const double _troughInset = 2;

/// One key of a [GlossButtonGroup].
@immutable
class GlossButtonGroupItem {
  /// A key named [label] that does [onPressed]; null disables it.
  const GlossButtonGroupItem({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  /// What the key says; with [GlossButtonGroup.iconsOnly], what a screen
  /// reader and the tooltip say.
  final String label;

  /// What the key does; null disables it.
  final VoidCallback? onPressed;

  /// The key's glyph, before its words.
  final IconData? icon;
}

/// A row of pearl keys set side by side in one trough: a toolbar.
///
/// Each key presses on its own, sinking into the trough; the trough stands
/// a control's height, so a group sits level with the fields beside it.
///
/// ```dart
/// GlossButtonGroup(items: [GlossButtonGroupItem(label: 'Copy', onPressed: () {}), GlossButtonGroupItem(label: 'Share', onPressed: () {})])
/// ```
class GlossButtonGroup extends StatelessWidget {
  /// A trough of [items].
  const GlossButtonGroup({
    super.key,
    required this.items,
    this.iconsOnly = false,
    this.style,
  });

  /// The keys, in order.
  final List<GlossButtonGroupItem> items;

  /// Whether the keys show their glyphs only (each item needs an icon).
  final bool iconsOnly;

  /// This group's own style, over [GlossThemeData.buttonGroupStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final height = theme.controlHeight;
    final corner = GlossMetrics.fieldRadius + _troughInset;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
        height: height,
        child: GlossSurface(
          face: GlossFace.well(c, radius: corner),
          child: Padding(
            padding: const EdgeInsets.all(_troughInset),
            // Keys too wide for their row (long words, large text) scroll
            // along the trough rather than spill out of it.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0) const SizedBox(width: _troughInset),
                    _GroupKey(
                      item: item,
                      iconOnly: iconsOnly && item.icon != null,
                      corner: corner - _troughInset,
                      style: style,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('items', items.length))
      ..add(FlagProperty('iconsOnly', value: iconsOnly, ifTrue: 'icons only'));
  }
}

class _GroupKey extends StatelessWidget {
  const _GroupKey({
    required this.item,
    required this.iconOnly,
    required this.corner,
    required this.style,
  });

  final GlossButtonGroupItem item;
  final bool iconOnly;
  final double corner;
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: item.onPressed,
      semanticLabel: iconOnly ? item.label : null,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.buttonGroupStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        var face = GlossFace.pearl(c, radius: corner);
        if (layered.fill != null) face = face.glazed(layered.fill!);
        face = face.copyWith(
          foreground: layered.foreground ?? (disabled ? c.inkDisabled : c.ink),
          lens: disabled ? 0.25 : null,
          lift: disabled ? 0.3 : null,
          travel: states.contains(WidgetState.pressed) ? 1 : 0,
          focus: glossFocusOf(c, focused: states.contains(WidgetState.focused)),
        );
        final glyph = item.icon == null
            ? null
            : Icon(item.icon, size: layered.iconSize ?? 20);
        return DesignTapTarget(
          child: AnimatedGlossSurface(
            face: face,
            child: SizedBox(
              height: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: iconOnly ? 0 : GlossSpacing.regular,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: iconOnly ? theme.controlHeight - 4 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ?glyph,
                      if (glyph != null && !iconOnly)
                        const SizedBox(width: GlossSpacing.small),
                      if (!iconOnly)
                        DefaultTextStyle.merge(
                          style: theme.textTheme.label.merge(layered.textStyle),
                          maxLines: 1,
                          child: Builder(
                            builder: (context) => DesignCapCenter(
                              capHeightFactor: glossCapHeightFactor,
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: DefaultTextStyle.of(context)
                                      .style
                                      .color,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One choice of a [GlossToggleGroup].
@immutable
class GlossToggle<T> {
  /// A choice [value] named [label].
  const GlossToggle({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  /// What choosing it means.
  final T value;

  /// What it says; with [GlossToggleGroup.iconsOnly], what a screen reader
  /// says.
  final String label;

  /// Its glyph.
  final IconData? icon;

  /// Whether it can be pressed.
  final bool enabled;
}

/// Toggles set in one trough: what is on stands up as a pearl key, what is
/// off lies flat in the trough. Any number at once (bold, italic) or one
/// of several.
///
/// ```dart
/// GlossToggleGroup<String>(toggles: const [GlossToggle(value: 'veg', label: 'Vegetarian'), GlossToggle(value: 'gf', label: 'Gluten-free')], selected: const {'veg'}, onSelectionChanged: (next) {})
/// ```
class GlossToggleGroup<T> extends StatelessWidget {
  /// A trough of [toggles], [selected] on.
  const GlossToggleGroup({
    super.key,
    required this.toggles,
    required this.selected,
    required this.onSelectionChanged,
    this.multiSelectionEnabled = true,
    this.emptySelectionAllowed = true,
    this.iconsOnly = false,
    this.semanticLabel,
    this.style,
  });

  /// The toggles, in order.
  final List<GlossToggle<T>> toggles;

  /// The values that are on.
  final Set<T> selected;

  /// The new set of values on; null disables the group.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Whether any number may be on; false makes it one choice of several.
  final bool multiSelectionEnabled;

  /// Whether every toggle may be off at once.
  final bool emptySelectionAllowed;

  /// Whether the toggles show their glyphs only.
  final bool iconsOnly;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// This group's own style, over [GlossThemeData.toggleGroupStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final corner = GlossMetrics.fieldRadius + _troughInset;
    final byValue = {for (final t in toggles) t.value: t};
    return SizedBox(
      height: theme.controlHeight,
      child: GlossSurface(
        face: GlossFace.well(c, radius: corner),
        child: Padding(
          padding: const EdgeInsets.all(_troughInset),
          child: DesignToggleGroup<T>(
            options: [for (final t in toggles) t.value],
            selected: selected,
            onSelectionChanged: onSelectionChanged,
            multiSelectionEnabled: multiSelectionEnabled,
            emptySelectionAllowed: emptySelectionAllowed,
            isEnabled: (v) =>
                onSelectionChanged != null && (byValue[v]?.enabled ?? true),
            labelOf: (v) => byValue[v]?.label ?? '$v',
            semanticLabel: semanticLabel,
            minimumSize: Size(0, theme.controlHeight - 2 * _troughInset),
            // Toggles too wide for their row scroll along the trough
            // rather than spill out of it.
            layoutBuilder: (context, items) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0) const SizedBox(width: _troughInset),
                    item,
                  ],
                ],
              ),
            ),
            itemBuilder: (context, value, states) {
              final toggle = byValue[value]!;
              final layered = DesignStyleOf([
                style,
                theme.toggleGroupStyle,
              ], states);
              final on = states.contains(WidgetState.selected);
              final disabled = states.contains(WidgetState.disabled);
              final clear = c.well.withValues(alpha: 0);
              var face = on
                  ? GlossFace.pearl(c, radius: corner - _troughInset)
                  : GlossFace(
                      top: clear,
                      middle: clear,
                      bottom: clear,
                      foreground: c.inkSecondary,
                      radius: corner - _troughInset,
                    );
              if (on && layered.fill != null) face = face.glazed(layered.fill!);
              face = face.copyWith(
                foreground:
                    layered.foreground ??
                    (disabled
                        ? c.inkDisabled
                        : on
                        ? c.ink
                        : c.inkSecondary),
                lens: disabled && on ? 0.25 : null,
                travel: states.contains(WidgetState.pressed) ? 1 : 0,
                focus: glossFocusOf(
                  c,
                  focused: states.contains(WidgetState.focused),
                ),
              );
              final only = iconsOnly && toggle.icon != null;
              return AnimatedGlossSurface(
                face: face,
                child: SizedBox(
                  height: double.infinity,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: only ? theme.controlHeight - 4 : 0,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: only ? 0 : GlossSpacing.regular,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (toggle.icon != null)
                            Icon(toggle.icon, size: layered.iconSize ?? 20),
                          if (toggle.icon != null && !only)
                            const SizedBox(width: GlossSpacing.small),
                          if (!only)
                            Builder(
                              builder: (context) => DesignCapCenter(
                                capHeightFactor: glossCapHeightFactor,
                                child: Text(
                                  toggle.label,
                                  maxLines: 1,
                                  style: theme.textTheme.label
                                      .copyWith(
                                        color: DefaultTextStyle.of(context)
                                            .style
                                            .color,
                                      )
                                      .merge(layered.textStyle),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('selected', selected))
      ..add(
        FlagProperty(
          'multiSelectionEnabled',
          value: multiSelectionEnabled,
          ifFalse: 'one choice',
        ),
      );
  }
}

/// One action in a [GlossSplitButton]'s menu.
typedef GlossSplitAction = DesignSplitAction;

/// A key with its menu beside it: the main action on the left, a narrow
/// key with a chevron that opens the others, moulded as one piece with a
/// seam between. Gel when it is the screen's action ([filled]), pearl
/// otherwise.
///
/// ```dart
/// GlossSplitButton(label: 'Add to week', onPressed: () {}, actions: [GlossSplitAction(label: 'Add to next week', onPressed: () {})])
/// ```
class GlossSplitButton extends StatelessWidget {
  /// A pearl split key.
  const GlossSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.style,
  }) : filled = false;

  /// A gel split key, for the one action a screen is for.
  const GlossSplitButton.filled({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.style,
  }) : filled = true;

  /// The main action's words.
  final String label;

  /// The main action; null disables the main key (the menu stays).
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<GlossSplitAction> actions;

  /// What a screen reader calls the menu key.
  final String? menuLabel;

  /// Whether it is the gel key.
  final bool filled;

  /// This key's own style, over [GlossThemeData.splitButtonStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final height = theme.controlHeight;
    final corner = height / 2;
    return SizedBox(
      height: height,
      child: DesignSplitButton(
        label: label,
        onPressed: onPressed,
        actions: actions,
        menuLabel: menuLabel,
        minimumSize: Size(height, height),
        layoutBuilder: (context, main, toggle) =>
            Row(mainAxisSize: MainAxisSize.min, children: [main, toggle]),
        buttonBuilder: (context, part, states, open) {
          final layered = DesignStyleOf([
            style,
            theme.splitButtonStyle,
          ], states);
          final disabled = states.contains(WidgetState.disabled);
          final main = part == DesignSplitPart.main;
          var face = filled && !disabled
              ? GlossFace.gel(c)
              : GlossFace.pearl(c);
          if (layered.fill != null) face = face.glazed(layered.fill!);
          face = face.copyWith(
            foreground:
                layered.foreground ??
                (disabled
                    ? c.inkDisabled
                    : filled
                    ? c.onJade
                    : c.ink),
            lens: disabled ? 0.25 : null,
            lift: disabled ? 0.3 : null,
            travel: states.contains(WidgetState.pressed) || (!main && open)
                ? 1
                : 0,
            focus: glossFocusOf(
              c,
              focused: states.contains(WidgetState.focused),
            ),
          );
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final leftRound = main != rtl;
          // One moulded piece: each half round on its outer side, nearly
          // square at the seam between them.
          final shape = BorderRadius.horizontal(
            left: Radius.circular(leftRound ? corner : 4),
            right: Radius.circular(leftRound ? 4 : corner),
          );
          final child = main
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: GlossSpacing.large - GlossMetrics.rimRoom,
                    end: GlossSpacing.regular + GlossMetrics.rimRoom,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Builder(
                      builder: (context) => DesignCapCenter(
                        capHeightFactor: glossCapHeightFactor,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: theme.textTheme.label
                              .copyWith(
                                color: DefaultTextStyle.of(context).style.color,
                              )
                              .merge(layered.textStyle),
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  width: height - 6,
                  child: Center(
                    child: Builder(
                      builder: (context) => GlossChevron(
                        open: open,
                        color: DefaultTextStyle.of(context).style.color!,
                      ),
                    ),
                  ),
                );
          return Padding(
            padding: EdgeInsetsDirectional.only(
              start: main ? 0 : GlossMetrics.seam,
            ),
            child: DesignTapTarget(
              child: AnimatedGlossSurface(
                face: face.copyWith(corners: shape),
                child: SizedBox(height: height, child: child),
              ),
            ),
          );
        },
        itemBuilder: (context, action, states) =>
            GlossMenuRow(label: action.label, states: states),
        surfaceBuilder: (context, info, items) => GlossSurface(
          face: glossPanelFace(c),
          child: Padding(
            padding: const EdgeInsets.all(glossPanelInset),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
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
      ..add(FlagProperty('filled', value: filled, ifTrue: 'gel'))
      ..add(IntProperty('actions', actions.length));
  }
}

/// A link: jade words with a line under them, for a way somewhere else in
/// running text or under a form. Under a press the words deepen and the
/// line fills; the focus ring rounds the words.
///
/// ```dart
/// GlossLink('Forgot your password?', onPressed: () {})
/// ```
class GlossLink extends StatelessWidget {
  /// A link named [label] that does [onPressed]; null disables it.
  const GlossLink(
    this.label, {
    super.key,
    required this.onPressed,
    this.focusNode,
    this.style,
  });

  /// The words.
  final String label;

  /// What it does; null disables it.
  final VoidCallback? onPressed;

  /// Its focus node, for an app that moves the focus itself.
  final FocusNode? focusNode;

  /// This link's own style, over [GlossThemeData.linkStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      button: false,
      link: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.linkStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final ink =
            layered.foreground ??
            (disabled
                ? c.inkDisabled
                : pressed
                ? Color.lerp(c.jadeInk, c.ink, 0.45)!
                : c.jadeInk);
        final clear = c.page.withValues(alpha: 0);
        // A link has no glaze to light: its focus washes a plate just
        // beyond its words and haloes it, clear of every letter.
        return DesignTapTarget(
          child: GlossFocusHalo(
            focused: states.contains(WidgetState.focused),
            inset: -2,
            radius: 8,
            tint: true,
            child: AnimatedGlossSurface(
              face: GlossFace(
                top: clear,
                middle: clear,
                bottom: clear,
                foreground: ink,
                radius: 6,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GlossMetrics.rimRoom,
                ),
                child: Text(
                  label,
                  style: theme.textTheme.body
                      .copyWith(
                        color: ink,
                        decoration: disabled ? null : TextDecoration.underline,
                        decorationColor: ink.withValues(
                          alpha: pressed ? 1 : 0.5,
                        ),
                        decorationThickness: pressed ? 2 : 1.2,
                      )
                      .merge(layered.textStyle),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      );
  }
}

/// A keycap that names a key on the keyboard (⌘, K, Esc), as a shortcut
/// is written beside a menu row or in help.
///
/// ```dart
/// Row(children: [GlossKbd('⌘'), SizedBox(width: 4), GlossKbd('K')])
/// ```
class GlossKbd extends StatelessWidget {
  /// A keycap reading [label].
  const GlossKbd(this.label, {super.key, this.semanticLabel, this.style});

  /// What is printed on the cap.
  final String label;

  /// What a screen reader says for it; null: [label].
  final String? semanticLabel;

  /// This cap's own style, over [GlossThemeData.kbdStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.kbdStyle], const {});
    var face = GlossFace.pearl(c, radius: 6);
    if (layered.fill != null) face = face.glazed(layered.fill!);
    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        child: GlossSurface(
          face: face.copyWith(foreground: layered.foreground ?? c.inkSecondary),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              GlossSpacing.small,
              0,
              GlossSpacing.small,
              GlossMetrics.rimRoom,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                style: theme.textTheme.caption
                    .copyWith(
                      color: layered.foreground ?? c.inkSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )
                    .merge(layered.textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
  }
}
