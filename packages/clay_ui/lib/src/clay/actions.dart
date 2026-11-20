/// Clay's other actions: keys moulded side by side in one slab (a button
/// group), toggles that rise out of one groove (a toggle group), the split
/// key, the link and the keycap that names a key.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'button.dart';
import 'fonts.dart';
import 'internal/menu.dart';
import 'surface.dart';
import 'theme.dart';

/// The inset between a slab or a groove and the keys in it, all round.
const double _inset = 4;

/// One key of a [ClayButtonGroup].
@immutable
class ClayButtonGroupItem {
  /// A key named [label] that does [onPressed]; null disables it.
  const ClayButtonGroupItem({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  /// What the key says; with [ClayButtonGroup.iconsOnly], what a screen
  /// reader and the tooltip say.
  final String label;

  /// What the key does; null disables it.
  final VoidCallback? onPressed;

  /// The key's glyph, before its words.
  final IconData? icon;
}

/// Keys moulded side by side in one slab of clay, a groove between each: a
/// toolbar. A key pressed dents its own part of the slab.
///
/// The slab stands a control's height, so a group sits level with the
/// fields and keys beside it.
///
/// ```dart
/// ClayButtonGroup(items: [ClayButtonGroupItem(label: 'Copy', onPressed: () {}), ClayButtonGroupItem(label: 'Share', onPressed: () {})])
/// ```
class ClayButtonGroup extends StatelessWidget {
  /// A slab of [items].
  const ClayButtonGroup({
    super.key,
    required this.items,
    this.iconsOnly = false,
    this.style,
  });

  /// The keys, in order.
  final List<ClayButtonGroupItem> items;

  /// Whether the keys show their glyphs only (each item needs an icon).
  final bool iconsOnly;

  /// This group's own style, over [ClayThemeData.buttonGroupStyle]: `fill`
  /// the slab, `foreground` the words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.buttonGroupStyle], const {});
    final radius = clayRadiusOf(layered.shape, ClayRadius.control);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
        height: theme.controlHeight,
        child: ClaySurface(
          face: ClayFace.raised(c, color: layered.fill, radius: radius),
          child: Padding(
            // Inset at the ends only: each key takes a tap over the slab's
            // whole height and draws its dent inset from it.
            padding: const EdgeInsets.symmetric(horizontal: _inset),
            // Keys too wide for their row (long words, large text) scroll
            // along the slab rather than spill out of it.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0) const _Seam(),
                    _DentKey(
                      label: item.label,
                      icon: item.icon,
                      onPressed: item.onPressed,
                      iconOnly: iconsOnly && item.icon != null,
                      radius: radius - _inset,
                      style: style,
                      themeStyle: theme.buttonGroupStyle,
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

// The groove between two keys of one slab.
class _Seam extends StatelessWidget {
  const _Seam();

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    final night = c.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: ClaySpacing.medium,
      ),
      child: SizedBox(
        width: 1.5,
        child: ColoredBox(
          color: night ? c.well : c.track.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// The face of a part of a slab: bare at rest, a faint dent under the
// pointer, a soft well pressed in under a press, a rim under focus.
ClayFace _dent(
  ClayColors c,
  Set<WidgetState> states,
  double radius,
  Color? on,
) {
  final well = ClayFace.well(
    c,
    color: on == null ? null : Color.lerp(on, c.shadeOf(on), 0.12),
    radius: radius,
  );
  final pressed = states.contains(WidgetState.pressed);
  final hovered = states.contains(WidgetState.hovered);
  final show = pressed ? 1.0 : (hovered ? 0.45 : 0.0);
  return well.copyWith(
    color: well.color.withValues(alpha: well.color.a * show),
    lightOpacity: well.lightOpacity * show,
    shadeOpacity: well.shadeOpacity * show * (pressed ? 1.3 : 1),
    focus: states.contains(WidgetState.focused) ? 1 : 0,
    focusColor: on == null ? null : c.onColor(on),
  );
}

class _DentKey extends StatelessWidget {
  const _DentKey({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.iconOnly,
    required this.radius,
    required this.style,
    required this.themeStyle,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool iconOnly;
  final double radius;
  final ClayStyle? style;
  final ClayStyle? themeStyle;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      semanticLabel: iconOnly ? label : null,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, themeStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final words = layered.foreground ?? (disabled ? c.inkDisabled : c.ink);
        return DesignTapTarget(
          child: _inSlab(
            AnimatedClaySurface(
              face: _dent(c, states, radius, layered.fill),
              child: ClayPressDepth(
                pressed: states.contains(WidgetState.pressed),
                builder: (depth) => Transform.translate(
                  offset: Offset(0, depth),
                  child: _KeyLabel(
                    label: label,
                    icon: icon,
                    iconOnly: iconOnly,
                    color: words,
                    layered: layered,
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

// A key's face inside its slab: it takes a tap over the slab's whole
// height, the face drawn inset from the slab's top and bottom.
Widget _inSlab(Widget face) => Padding(
  padding: const EdgeInsets.symmetric(vertical: _inset),
  child: face,
);

// A key's glyph and words, centred on the cap height.
class _KeyLabel extends StatelessWidget {
  const _KeyLabel({
    required this.label,
    required this.icon,
    required this.iconOnly,
    required this.color,
    required this.layered,
    this.weight = FontWeight.w600,
  });

  final String label;
  final IconData? icon;
  final bool iconOnly;
  final Color color;
  final DesignStyleOf layered;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final side = theme.controlHeight - 2 * _inset;
    return SizedBox(
      height: double.infinity,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: iconOnly ? side : 0),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: iconOnly ? 0 : ClaySpacing.regular,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: layered.iconSize ?? 20, color: color),
              if (icon != null && !iconOnly)
                const SizedBox(width: ClaySpacing.small),
              if (!iconOnly)
                DesignCapCenter(
                  capHeightFactor: clayCapHeightFactor,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.label
                        .copyWith(
                          color: color,
                          fontWeight: weight,
                          fontVariations: clayWeight(weight),
                        )
                        .merge(layered.textStyle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One choice of a [ClayToggleGroup].
@immutable
class ClayToggle<T> {
  /// A choice [value] named [label].
  const ClayToggle({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  /// What choosing it means.
  final T value;

  /// What it says; with [ClayToggleGroup.iconsOnly], what a screen reader
  /// says.
  final String label;

  /// Its glyph.
  final IconData? icon;

  /// Whether it can be pressed.
  final bool enabled;
}

/// Toggles pressed into one groove: what is on rises out of it as clay,
/// what is off lies in it. Any number at once (bold, italic), each a toggle
/// a screen reader hears on or off; or one of several
/// ([multiSelectionEnabled] false), a radio group: one Tab stop, on the
/// choice, and arrows that choose as they move.
///
/// ```dart
/// ClayToggleGroup<String>(toggles: const [ClayToggle(value: 'b', label: 'Bold'), ClayToggle(value: 'i', label: 'Italic')], selected: const {'b'}, onSelectionChanged: (next) {})
/// ```
class ClayToggleGroup<T> extends StatelessWidget {
  /// A groove of [toggles], [selected] on.
  const ClayToggleGroup({
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
  final List<ClayToggle<T>> toggles;

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

  /// This group's own style, over [ClayThemeData.toggleGroupStyle]: `fill`
  /// what is on.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final radius = ClayRadius.control;
    final byValue = {for (final t in toggles) t.value: t};
    final values = [for (final t in toggles) t.value];
    bool enabled(T v) =>
        onSelectionChanged != null && (byValue[v]?.enabled ?? true);
    Widget layout(BuildContext context, List<Widget> items) =>
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const SizedBox(width: _inset),
                item,
              ],
            ],
          ),
        );
    Widget toggleFace(T value, Set<WidgetState> states) {
      final toggle = byValue[value]!;
      final layered = DesignStyleOf([style, theme.toggleGroupStyle], states);
      final on = states.contains(WidgetState.selected);
      final disabled = states.contains(WidgetState.disabled);
      final inner = radius - _inset;
      final rest = ClayFace.raised(
        c,
        color: c.risen.withValues(alpha: 0),
        radius: inner,
      ).copyWith(elevation: 0, lightOpacity: 0, shadeOpacity: 0);
      final face =
          (on
                  ? (disabled
                        ? ClayFace.flat(c, radius: inner)
                        : ClayFace.raised(
                            c,
                            color: layered.fill ?? c.risen,
                            radius: inner,
                          ))
                  : rest)
              .copyWith(
                press: states.contains(WidgetState.pressed) ? 1 : 0,
                focus: states.contains(WidgetState.focused) ? 1 : 0,
              );
      final words =
          layered.foreground ??
          (disabled
              ? c.inkDisabled
              : on
              ? c.ink
              : c.inkSecondary);
      return _inSlab(
        AnimatedClaySurface(
          face: face,
          child: _KeyLabel(
            label: toggle.label,
            icon: toggle.icon,
            iconOnly: iconsOnly && toggle.icon != null,
            color: words,
            layered: layered,
            weight: on ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      );
    }

    final change = onSelectionChanged;
    final Widget group;
    if (multiSelectionEnabled) {
      group = DesignToggleGroup<T>(
        options: values,
        selected: selected,
        onSelectionChanged: change,
        emptySelectionAllowed: emptySelectionAllowed,
        isEnabled: enabled,
        labelOf: (v) => byValue[v]?.label ?? '$v',
        semanticLabel: semanticLabel,
        minimumSize: Size(0, theme.controlHeight),
        layoutBuilder: layout,
        itemBuilder: (context, value, states) => toggleFace(value, states),
      );
    } else {
      // One of several: a radio group. A press on the choice turns it off
      // where none may be on.
      final chosen = selected.isEmpty ? null : selected.first;
      group = DesignRadioGroup<T>(
        options: values,
        value: chosen,
        onChanged: change == null ? null : (v) => change({v}),
        isEnabled: enabled,
        semanticLabel: semanticLabel,
        layoutBuilder: layout,
        itemBuilder: (context, value, node, select) {
          final on = value == chosen;
          return DesignPressable(
            focusNode: node,
            onPressed: select == null
                ? null
                : on && emptySelectionAllowed
                ? () => change!(<T>{})
                : select,
            semanticLabel: byValue[value]!.label,
            excludeSemantics: true,
            checked: on,
            selected: on,
            inMutuallyExclusiveGroup: true,
            builder: (context, states, _) => ConstrainedBox(
              constraints: BoxConstraints(minHeight: theme.controlHeight),
              child: toggleFace(value, states),
            ),
          );
        },
      );
    }
    return SizedBox(
      height: theme.controlHeight,
      child: ClaySurface(
        face: ClayFace.well(c, radius: radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _inset),
          child: group,
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

/// One action in a [ClaySplitButton]'s menu.
typedef ClaySplitAction = DesignSplitAction;

/// A key with its menu beside it, moulded as one slab: the main action, a
/// groove, then a narrow part with a chevron that opens the others. Each
/// part dents on its own press. Coral when it is the screen's action
/// ([ClaySplitButton.filled]), white clay otherwise.
///
/// ```dart
/// ClaySplitButton(label: 'Save', onPressed: () {}, actions: [ClaySplitAction(label: 'Save as copy', onPressed: () {})])
/// ```
class ClaySplitButton extends StatelessWidget {
  /// A clay split key.
  const ClaySplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.style,
  }) : filled = false;

  /// A coral split key, for the one action a screen is for.
  const ClaySplitButton.filled({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.style,
  }) : filled = true;

  /// The main action's words.
  final String label;

  /// The main action; null disables the main part (the menu stays).
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<ClaySplitAction> actions;

  /// What a screen reader calls the menu part.
  final String? menuLabel;

  /// Whether it is the coral key.
  final bool filled;

  /// This key's own style, over [ClayThemeData.splitButtonStyle]: `fill`
  /// the slab, `foreground` the words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final height = theme.controlHeight;
    final layered = DesignStyleOf([style, theme.splitButtonStyle], const {});
    final fill = layered.fill ?? (filled ? c.accent : c.clay);
    final radius = clayRadiusOf(layered.shape, ClayRadius.control);
    final words = layered.foreground ?? (filled ? c.onColor(fill) : c.ink);
    return SizedBox(
      height: height,
      child: ClaySurface(
        face: ClayFace.raised(c, color: fill, radius: radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _inset),
          child: DesignSplitButton(
            label: label,
            onPressed: onPressed,
            actions: actions,
            menuLabel: menuLabel,
            minimumSize: Size(height - 2 * _inset, height),
            layoutBuilder: (context, main, toggle) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [main, const _Seam(), toggle],
            ),
            buttonBuilder: (context, part, states, open) {
              final disabled = states.contains(WidgetState.disabled);
              final colour = disabled ? c.inkDisabled : words;
              final main = part == DesignSplitPart.main;
              final shown = {...states, if (!main && open) WidgetState.pressed};
              return DesignTapTarget(
                child: _inSlab(
                  AnimatedClaySurface(
                    face: _dent(
                      c,
                      shown,
                      radius - _inset,
                      filled ? fill : null,
                    ),
                    child: main
                        ? _KeyLabel(
                            label: label,
                            icon: null,
                            iconOnly: false,
                            color: colour,
                            layered: layered,
                          )
                        : SizedBox(
                            width: height - 2 * _inset,
                            height: double.infinity,
                            child: Center(
                              child: SizedBox.square(
                                dimension: 18,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: open ? 1 : 0),
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  builder: (context, t, _) => CustomPaint(
                                    painter: ClayChevronPainter(colour, t),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              );
            },
            itemBuilder: (context, action, states) =>
                ClayMenuRow(label: action.label, states: states),
            surfaceBuilder: (context, info, items) =>
                clayMenuPanel(context, items),
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
      ..add(FlagProperty('filled', value: filled, ifTrue: 'coral'))
      ..add(IntProperty('actions', actions.length));
  }
}

/// A link: words in the accent's ink with a soft line under them, for a way
/// somewhere else in running text or under a form. A press sinks the words
/// a little and fills the line; focus puts the quiet rim round them.
///
/// ```dart
/// ClayLink('Forgot your password?', onPressed: () {})
/// ```
class ClayLink extends StatelessWidget {
  /// A link named [label] that does [onPressed]; null disables it.
  const ClayLink(
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

  /// This link's own style, over [ClayThemeData.linkStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
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
        final hovered = states.contains(WidgetState.hovered);
        final ink =
            layered.foreground ??
            (disabled
                ? c.inkDisabled
                : pressed
                ? Color.lerp(c.accentInk, c.ink, 0.35)!
                : c.accentInk);
        return DesignTapTarget(
          child: AnimatedClaySurface(
            face: ClayFace.well(c, radius: 8).copyWith(
              color: c.well.withValues(alpha: 0),
              lightOpacity: 0,
              shadeOpacity: 0,
              focus: states.contains(WidgetState.focused) ? 1 : 0,
            ),
            child: ClayPressDepth(
              pressed: pressed,
              builder: (depth) => Transform.translate(
                offset: Offset(0, depth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClaySpacing.tight,
                    vertical: 2,
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.body
                        .copyWith(
                          color: ink,
                          decoration: disabled
                              ? null
                              : TextDecoration.underline,
                          decorationColor: ink.withValues(
                            alpha: pressed || hovered ? 1 : 0.45,
                          ),
                          decorationThickness: pressed || hovered ? 2 : 1.4,
                        )
                        .merge(layered.textStyle),
                  ),
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

/// A keycap that names a key on the keyboard (⌘, K, Esc), as a shortcut is
/// written beside a menu row or in help: a small raised volume of clay.
///
/// ```dart
/// Row(children: [ClayKbd('⌘'), SizedBox(width: 4), ClayKbd('K')])
/// ```
class ClayKbd extends StatelessWidget {
  /// A keycap reading [label].
  const ClayKbd(this.label, {super.key, this.semanticLabel, this.style});

  /// What is printed on the cap.
  final String label;

  /// What a screen reader says for it; null: [label].
  final String? semanticLabel;

  /// This cap's own style, over [ClayThemeData.kbdStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.kbdStyle], const {});
    final ink = layered.foreground ?? c.inkSecondary;
    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        child: ClaySurface(
          face: ClayFace.raised(
            c,
            color: layered.fill,
            radius: 7,
          ).copyWith(elevation: 0.6),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClaySpacing.small,
              vertical: 3,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                style: theme.textTheme.caption
                    .copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                      fontVariations: clayWeight(FontWeight.w600),
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
