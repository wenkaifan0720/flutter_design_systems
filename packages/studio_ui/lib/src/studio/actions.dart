/// Studio's other actions: [StudioFloatingKey] (a large graphite key that
/// stands over the page), [StudioKeyRow] (a toolbar: momentary keys in one
/// recessed bank), [StudioToggleBank] (latching keys in a bank, each with its
/// own lamp), [StudioSplitKey] (a key and a narrow key beside it that opens
/// its other actions), [StudioLink] (printed words with an engraved rule)
/// and [StudioKbd] (keyboard keys as small caps).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'internal/strip.dart';
import 'menu.dart';
import 'select.dart';
import 'surface.dart';
import 'theme.dart';

Color _ring(StudioColors c, Set<WidgetState> states) =>
    states.contains(WidgetState.focused)
    ? c.focusRing
    : c.focusRing.withValues(alpha: 0);

// An ordinary key's face in [states]; [latched] holds it down.
StudioFace _keyFace(
  StudioColors c,
  Set<WidgetState> states, {
  bool latched = false,
  double radius = StudioRadii.key,
}) {
  final disabled = states.contains(WidgetState.disabled);
  return c.keyFace
      .copyWith(
        radius: radius,
        travel: latched || states.contains(WidgetState.pressed) ? 1 : 0,
        fill: disabled ? Color.lerp(c.key, c.panelLow, 0.5) : null,
        foreground: disabled
            ? c.disabled
            : latched
            ? c.litLegend
            : c.onKey,
        focus: _ring(c, states),
      )
      .backlitIf(c, latched && !disabled);
}

// The graphite main key's face in [states].
StudioFace _litFace(StudioColors c, Set<WidgetState> states, double radius) =>
    c.litKeyFace.copyWith(
      radius: radius,
      travel: states.contains(WidgetState.pressed) ? 1 : 0,
      foreground: states.contains(WidgetState.disabled)
          ? c.onLitKeyOff
          : c.onLitKey,
      focus: _ring(c, states),
    );

List<Shadow>? _glow(Color light, bool on) =>
    on ? [Shadow(color: light.withValues(alpha: 0.45), blurRadius: 6)] : null;

/// A floating key: the graphite main key made large and set over the page,
/// with a shadow under it so it reads as standing above the content; its
/// glyph and lamp lit. [StudioFloatingKey.extended] adds its legend.
///
/// Use one per screen, for its main action (record, a new episode). A null
/// [onPressed] disables it and puts its light out.
///
/// Reads [style]'s `fill`, `foreground` and `minimumSize`, then
/// [StudioThemeData.floatingKeyStyle].
///
/// ```dart
/// StudioFloatingKey(icon: const Icon(LucideIcons.mic), tooltip: 'New recording', onPressed: record)
/// ```
class StudioFloatingKey extends StatelessWidget {
  /// A round floating key showing [icon].
  const StudioFloatingKey({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.style,
    this.focusNode,
  }) : label = null;

  /// A floating key with [icon] and [label].
  const StudioFloatingKey.extended({
    super.key,
    required this.icon,
    required String this.label,
    required this.onPressed,
    this.style,
    this.focusNode,
  }) : tooltip = label;

  /// Its glyph.
  final Widget icon;

  /// Its legend, for an extended key.
  final String? label;

  /// What it does, for a screen reader.
  final String tooltip;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// Its style, over [StudioThemeData.floatingKeyStyle].
  final StudioStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final night = c.brightness == Brightness.dark;
    return DesignPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      semanticLabel: tooltip,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.floatingKeyStyle], states);
        final side = layered.minimumSize?.height ?? 56;
        final face = layered.on(_litFace(c, states, side / 2));
        final light = face.foreground ?? c.onLitKey;
        final on = !states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final glyph = IconTheme.merge(
          data: IconThemeData(
            size: 22,
            color: light,
            shadows: _glow(light, on),
          ),
          child: icon,
        );
        return AnimatedContainer(
          duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
              ? Duration.zero
              : const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(side / 2),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withValues(alpha: night ? 0.6 : 0.28),
                // It stands over the page a margin from its edges: its
                // shadow falls inside them (12 px aside, 16 px below).
                blurRadius: pressed ? 6 : 10,
                offset: Offset(0, pressed ? 3 : 5),
              ),
            ],
          ),
          child: SizedBox(
            height: side,
            width: label == null ? side : null,
            child: AnimatedStudioSurface(
              face: face,
              child: label == null
                  ? Center(child: glyph)
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: StudioSpacing.regular,
                        end: StudioSpacing.large,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StudioLamp(on: on, size: 6),
                          const SizedBox(width: StudioSpacing.small),
                          glyph,
                          const SizedBox(width: StudioSpacing.small),
                          DesignCapCenter(
                            capHeightFactor: theme.capHeightFactor,
                            child: Text(
                              label!,
                              maxLines: 1,
                              style: theme.textTheme.label
                                  .copyWith(
                                    color: light,
                                    fontWeight: FontWeight.w600,
                                    shadows: _glow(light, on),
                                  )
                                  .merge(layered.textStyle),
                            ),
                          ),
                        ],
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
      ..add(StringProperty('tooltip', tooltip))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      );
  }
}

/// One key of a [StudioKeyRow]: a legend, a glyph, or both.
@immutable
class StudioKeyRowItem {
  /// A key reading [label] (or showing [icon], [label] naming it).
  const StudioKeyRowItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconOnly = false,
  });

  /// Its legend, and its name to a screen reader.
  final String label;

  /// What a press does; null disables this key.
  final VoidCallback? onPressed;

  /// A glyph before the legend, or in its place with [iconOnly].
  final Widget? icon;

  /// Whether the key shows only its [icon].
  final bool iconOnly;
}

/// A toolbar: momentary keys side by side in one recessed bank, each inset
/// from the recess so their corners are concentric with it. A key sinks
/// while pressed and springs back; it never latches (that is
/// [StudioToggleBank]).
///
/// Reads [style]'s `fill`, `foreground`, `minimumSize` and `textStyle` for
/// each key, then [StudioThemeData.keyRowStyle].
///
/// ```dart
/// StudioKeyRow(semanticLabel: 'Clip', items: [StudioKeyRowItem(label: 'Cut', icon: const Icon(LucideIcons.scissors), onPressed: cut), StudioKeyRowItem(label: 'Split', onPressed: split)])
/// ```
class StudioKeyRow extends StatelessWidget {
  /// A bank of [items].
  const StudioKeyRow({
    super.key,
    required this.items,
    this.semanticLabel,
    this.style,
  });

  /// The keys, in order.
  final List<StudioKeyRowItem> items;

  /// What a screen reader calls the toolbar.
  final String? semanticLabel;

  /// Each key's style, over [StudioThemeData.keyRowStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    const inset = StudioMetrics.recessInset;
    final frame = DesignStyleOf([style, theme.keyRowStyle], const {});
    final height = frame.minimumSize?.height ?? theme.controlHeight;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: SizedBox(
        height: height,
        child: StudioSurface(
          face: c.recessFace,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.hair),
            child: StudioStrip(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items)
                    DesignPressable(
                      onPressed: item.onPressed,
                      semanticLabel: item.label,
                      excludeSemantics: true,
                      builder: (context, states, _) {
                        final layered = DesignStyleOf([
                          style,
                          theme.keyRowStyle,
                        ], states);
                        final face = layered.on(
                          _keyFace(c, states, radius: StudioRadii.bank - inset),
                        );
                        final ink = face.foreground ?? c.onKey;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: StudioSpacing.hair,
                            vertical: inset,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: height - 2 * inset,
                            ),
                            child: AnimatedStudioSurface(
                              face: face,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: item.iconOnly
                                      ? 0
                                      : StudioSpacing.medium,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (item.icon != null)
                                      IconTheme.merge(
                                        data: IconThemeData(
                                          size: layered.iconSize ?? 18,
                                          color: ink,
                                        ),
                                        child: item.icon!,
                                      ),
                                    if (item.icon != null && !item.iconOnly)
                                      const SizedBox(
                                        width: StudioSpacing.tight,
                                      ),
                                    if (!item.iconOnly)
                                      DesignCapCenter(
                                        capHeightFactor: theme.capHeightFactor,
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          style: theme.textTheme.label
                                              .copyWith(
                                                color: ink,
                                                fontWeight: FontWeight.w500,
                                              )
                                              .merge(layered.textStyle),
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
    properties.add(IntProperty('items', items.length));
  }
}

/// Latching keys in a recessed bank: a key pressed stays down with its own
/// lamp lit until it is pressed again. Several may be in at once unless
/// [multiSelectionEnabled] is false; then the bank is one choice, read as a
/// radio group. Given [iconOf], each key shows its glyph and [labelOf]
/// names it to a screen reader.
///
/// Built on ui_core's DesignToggleGroup: the arrows move along the bank,
/// Space and Enter press. A null [onSelectionChanged] disables it.
///
/// Reads [style]'s `fill`, `foreground`, `minimumSize` and `textStyle` for
/// each key, in its states (selected while latched), then
/// [StudioThemeData.toggleBankStyle].
///
/// ```dart
/// StudioToggleBank<String>(options: const ['Mute', 'Solo'], selected: on, labelOf: (s) => s, onSelectionChanged: (next) => setState(() => on = next))
/// ```
class StudioToggleBank<T> extends StatelessWidget {
  /// A bank over [options], [selected] latched in.
  const StudioToggleBank({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelectionChanged,
    required this.labelOf,
    this.iconOf,
    this.multiSelectionEnabled = true,
    this.emptySelectionAllowed = true,
    this.isEnabled,
    this.semanticLabel,
    this.style,
  });

  /// The keys' values, in order.
  final List<T> options;

  /// The values latched in.
  final Set<T> selected;

  /// Called with the next set; null disables the bank.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Each key's legend (its name, when it shows a glyph).
  final String Function(T value) labelOf;

  /// Each key's glyph; null shows legends.
  final Widget Function(T value)? iconOf;

  /// Whether several keys may be in at once.
  final bool multiSelectionEnabled;

  /// Whether every key may be out.
  final bool emptySelectionAllowed;

  /// Whether `value`'s key may be pressed.
  final bool Function(T value)? isEnabled;

  /// What a screen reader calls the bank.
  final String? semanticLabel;

  /// Each key's style, over [StudioThemeData.toggleBankStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    const inset = StudioMetrics.recessInset;
    final frame = DesignStyleOf([style, theme.toggleBankStyle], const {});
    final height = frame.minimumSize?.height ?? theme.controlHeight;
    return SizedBox(
      height: height,
      child: StudioSurface(
        face: c.recessFace,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.hair),
          child: DesignToggleGroup<T>(
            options: options,
            selected: selected,
            onSelectionChanged: onSelectionChanged,
            multiSelectionEnabled: multiSelectionEnabled,
            emptySelectionAllowed: emptySelectionAllowed,
            isEnabled: isEnabled,
            labelOf: labelOf,
            semanticLabel: semanticLabel,
            minimumSize: Size.zero,
            layoutBuilder: (context, items) => StudioStrip(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
            itemBuilder: (context, value, states) {
              final layered = DesignStyleOf([
                style,
                theme.toggleBankStyle,
              ], states);
              final on = states.contains(WidgetState.selected);
              final disabled = states.contains(WidgetState.disabled);
              final face = layered.on(
                _keyFace(
                  c,
                  states,
                  latched: on,
                  radius: StudioRadii.bank - inset,
                ),
              );
              final ink = face.foreground ?? c.onKey;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.hair,
                  vertical: inset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: height - 2 * inset),
                  child: AnimatedStudioSurface(
                    face: face,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.small + StudioSpacing.hair,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StudioLamp(on: on && !disabled, size: 6),
                          const SizedBox(width: StudioSpacing.small),
                          if (iconOf != null)
                            IconTheme.merge(
                              data: IconThemeData(
                                size: layered.iconSize ?? 18,
                                color: ink,
                              ),
                              child: iconOf!(value),
                            )
                          else
                            DesignCapCenter(
                              capHeightFactor: theme.capHeightFactor,
                              child: Text(
                                labelOf(value),
                                maxLines: 1,
                                style: theme.textTheme.label
                                    .copyWith(
                                      color: ink,
                                      // One weight latched or not: a latch
                                      // never moves the keys beside it.
                                      fontWeight: FontWeight.w500,
                                    )
                                    .merge(layered.textStyle),
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

/// A split key: a key for the usual action and, butted against it, a
/// narrow key with a chevron that opens the others in a glass list. The
/// narrow key stays down while its list is open; Down on the main key opens
/// it too. [lit] makes both halves the graphite main key.
///
/// Built on ui_core's DesignSplitButton. A null [onPressed] disables the
/// main half; the list stays.
///
/// Reads [style] for both halves, then the main key's theme slot
/// ([StudioThemeData.buttonStyle] or [StudioThemeData.litButtonStyle]).
///
/// ```dart
/// StudioSplitKey(label: 'Export', onPressed: exportMp3, actions: [StudioMenuItem(label: 'Export WAV', onPressed: exportWav)])
/// ```
class StudioSplitKey extends StatelessWidget {
  /// A split key whose main action is [onPressed].
  const StudioSplitKey({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.lit = false,
    this.menuLabel,
    this.style,
  });

  /// The main action's legend.
  final String label;

  /// The main action; null disables the main half.
  final VoidCallback? onPressed;

  /// The other actions.
  final List<StudioMenuItem> actions;

  /// Whether it is the screen's main action (graphite, lit).
  final bool lit;

  /// What a screen reader calls the narrow key; null: "More options".
  final String? menuLabel;

  /// Both halves' style.
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layers = [style, lit ? theme.litButtonStyle : theme.buttonStyle];
    return DesignSplitButton(
      label: label,
      onPressed: onPressed,
      actions: [
        for (final a in actions)
          DesignSplitAction(label: a.label, onPressed: a.onPressed, data: a),
      ],
      menuLabel: menuLabel,
      minimumSize: Size.zero,
      layoutBuilder: (context, main, toggle) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          main,
          const SizedBox(width: StudioSpacing.hair),
          toggle,
        ],
      ),
      buttonBuilder: (context, part, states, open) {
        final now = {
          ...states,
          if (open && part == DesignSplitPart.toggle) WidgetState.pressed,
        };
        final layered = DesignStyleOf(layers, now);
        final height = layered.minimumSize?.height ?? theme.controlHeight;
        final face = layered.on(
          lit ? _litFace(c, now, StudioRadii.key) : _keyFace(c, now),
        );
        final ink = face.foreground ?? c.onKey;
        final glowing = lit && !now.contains(WidgetState.disabled);
        return DesignTapTarget(
          child: SizedBox(
            height: height,
            width: part == DesignSplitPart.toggle ? height * 0.8 : null,
            child: AnimatedStudioSurface(
              face: face,
              child: part == DesignSplitPart.main
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.regular + 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lit) ...[
                            StudioLamp(on: glowing, size: 6),
                            const SizedBox(width: StudioSpacing.small),
                          ],
                          DesignCapCenter(
                            capHeightFactor: theme.capHeightFactor,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: theme.textTheme.label
                                  .copyWith(
                                    color: ink,
                                    fontWeight: lit
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    shadows: _glow(ink, glowing),
                                  )
                                  .merge(layered.textStyle),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration:
                            MediaQuery.maybeDisableAnimationsOf(context) ??
                                false
                            ? Duration.zero
                            : const Duration(milliseconds: 160),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: StudioIconSizes.medium,
                          color: ink,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
      itemBuilder: (context, action, states) {
        final a = action.data as StudioMenuItem?;
        return StudioMenuRow(
          label: action.label,
          icon: a?.icon,
          isDestructiveAction: a?.isDestructiveAction ?? false,
          trailing: a?.shortcut == null ? null : Text(a!.shortcut!),
          states: states,
        );
      },
      surfaceBuilder: (context, info, items) => FadeTransition(
        opacity: info.animation,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
          child: StudioListBezel(
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
      ..add(FlagProperty('lit', value: lit, ifTrue: 'lit'))
      ..add(IntProperty('actions', actions.length));
  }
}

/// Words that go somewhere, printed in the legend's ink over a fine
/// engraved rule. A press sinks a recess under them; the keyboard's link
/// has the focus ring round it. A null [onPressed] greys it.
///
/// Reads [style]'s `foreground` and `textStyle` in its states, then
/// [StudioThemeData.linkStyle].
///
/// ```dart
/// StudioLink('Show notes', onPressed: () => open(notes))
/// ```
class StudioLink extends StatelessWidget {
  /// A link reading [label].
  const StudioLink(
    this.label, {
    super.key,
    required this.onPressed,
    this.style,
  });

  /// Its words.
  final String label;

  /// Where it goes; null greys it.
  final VoidCallback? onPressed;

  /// Its style, over [StudioThemeData.linkStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      link: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.linkStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final ink = layered.foreground ?? (disabled ? c.disabled : c.legend);
        final text = theme.textTheme.body
            .copyWith(
              color: ink,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              // The pointer over it changes nothing it paints (polish3
              // §1); the cursor says it can be followed.
              decorationColor: disabled ? c.disabled : c.legendMuted,
            )
            .merge(layered.textStyle);
        return DesignTapTarget(
          child: AnimatedStudioSurface(
            face: c.recessFace.copyWith(
              radius: StudioRadii.small,
              presence: states.contains(WidgetState.pressed) ? 1 : 0,
              focus: _ring(c, states),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.hair,
              ),
              child: Text(label, style: text),
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

/// Keys to press together, each a small raised cap with its legend
/// engraved: `StudioKbd(['Ctrl', 'K'])`. A screen reader hears
/// [semanticLabel], or the keys one after another. [StudioKbd.shortcut]
/// shows a whole shortcut, a cap a key, in the platform's order and the
/// reader's words (ui_core's), and says it as a menu does.
///
/// Reads [style]'s `fill`, `foreground`, `minimumSize` and `textStyle` for
/// each cap, then [StudioThemeData.kbdStyle].
///
/// ```dart
/// const StudioKbd(['Ctrl', 'K'], semanticLabel: 'Control K')
/// ```
class StudioKbd extends StatelessWidget {
  /// Caps for [keys].
  const StudioKbd(this.keys, {super.key, this.semanticLabel, this.style})
    : shortcut = null;

  /// A cap for each key of [shortcut], in the platform's order and the
  /// reader's words; a screen reader hears it as a menu says it ("Ctrl+K").
  /// Apple's keys are words (Command, Option): Barlow draws no ⌘ ⌥ ⇧ ⌃.
  ///
  /// ```dart
  /// const StudioKbd.shortcut(SingleActivator(LogicalKeyboardKey.keyK, control: true))
  /// ```
  const StudioKbd.shortcut(
    MenuSerializableShortcut this.shortcut, {
    super.key,
    this.semanticLabel,
    this.style,
  }) : keys = const [];

  /// The keys' legends, in order; empty for a [shortcut].
  final List<String> keys;

  /// The shortcut shown, a cap a key; null for [keys].
  final MenuSerializableShortcut? shortcut;

  /// What a screen reader says.
  final String? semanticLabel;

  /// Each cap's style, over [StudioThemeData.kbdStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.kbdStyle], const {});
    final side = layered.minimumSize?.height ?? 24;
    final shortcut = this.shortcut;
    final keys = shortcut == null
        ? this.keys
        : designShortcutKeys(context, shortcut, appleSymbols: false);
    return Semantics(
      label:
          semanticLabel ??
          (shortcut == null
              ? keys.join(' ')
              : designShortcutLabel(context, shortcut, appleSymbols: false)),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, k) in keys.indexed) ...[
            if (i > 0) const SizedBox(width: StudioSpacing.tight),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: side, minHeight: side),
              child: StudioSurface(
                face: layered.on(c.keyFace.copyWith(radius: StudioRadii.small)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.tight + StudioSpacing.hair,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      k,
                      style: theme.textTheme.caption
                          .copyWith(
                            color: layered.foreground ?? c.onKey,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          )
                          .merge(layered.textStyle),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('keys', keys))
      ..add(
        DiagnosticsProperty<MenuSerializableShortcut>(
          'shortcut',
          shortcut,
          defaultValue: null,
        ),
      );
  }
}
