/// Appliance's other actions: [ApplianceToolbar] (keys set in one moulded
/// strip), [ApplianceToggleGroup] (keys that latch down), [ApplianceSplitButton]
/// (a key with its own menu key moulded beside it), [ApplianceLink] (words
/// printed in the signal's ink) and [ApplianceKbd] (a small key cap naming a
/// key on the keyboard).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'lists.dart';
import 'material.dart';
import 'menus.dart';
import 'select.dart';
import 'theme.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart' show RawSplitAction;

/// The trough a strip of keys is set in: sunk into the panel, the keys
/// standing in it [ApplianceMetrics.capInset] from its rim, concentric.
ApplianceFace _strip(ApplianceColors c) => ApplianceFace.well(
  c,
  radius: ApplianceMetrics.troughRadius,
  fill: c.trough,
);

/// A key's corner inside the strip: the trough's, less the room between.
const double _keyInStrip =
    ApplianceMetrics.troughRadius - ApplianceMetrics.capInset;

/// A toolbar: keys set side by side in one moulded strip, as the controls of
/// a device sit in one recess. Each child is a key ([ApplianceIconButton],
/// [ApplianceButton]); the strip holds them [ApplianceMetrics.capInset] from
/// its rim.
///
/// It is one group to a screen reader, named by [semanticLabel].
///
/// ```dart
/// ApplianceToolbar(semanticLabel: 'Text', children: [ApplianceIconButton(icon: const Icon(IconData(0x42)), semanticLabel: 'Bold', onPressed: () {})])
/// ```
class ApplianceToolbar extends StatelessWidget {
  /// A strip holding [children].
  const ApplianceToolbar({
    super.key,
    required this.children,
    this.semanticLabel,
    this.direction = Axis.horizontal,
    this.style,
  });

  /// The keys.
  final List<Widget> children;

  /// The group's name for a screen reader.
  final String? semanticLabel;

  /// Whether the keys stand in a row or a column.
  final Axis direction;

  /// Its style, over [ApplianceThemeData.toggleStyle]: fill (the strip).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).toggleStyle,
    ], const {});
    final c = ApplianceTheme.of(context).colors;
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: ApplianceSurface(
        face: _strip(c).copyWith(
          radius: BorderRadius.circular(
            ApplianceMetrics.keyRadius + ApplianceMetrics.capInset,
          ),
          top: look.fill,
          bottom: look.fill,
        ),
        child: Padding(
          padding: const EdgeInsets.all(ApplianceMetrics.capInset),
          child: Flex(
            direction: direction,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0)
                  const SizedBox.square(dimension: ApplianceMetrics.capInset),
                child,
              ],
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
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(EnumProperty<Axis>('direction', direction));
  }
}

/// One key of an [ApplianceToggleGroup]: its legend, a glyph, or both.
@immutable
class ApplianceToggleOption<T> {
  /// The key for [value].
  const ApplianceToggleOption({
    required this.value,
    required this.label,
    this.icon,
    this.showLabel = true,
    this.enabled = true,
  });

  /// What choosing it means.
  final T value;

  /// Its name: printed on the key, and said to a screen reader.
  final String label;

  /// A glyph on the key.
  final Widget? icon;

  /// Whether the key prints [label] (false: the glyph alone, the label said
  /// only to a screen reader).
  final bool showLabel;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A row of latching keys in one strip: pressed, a key stays down with its
/// lamp lit until it is pressed again (or, for one choice, until another is
/// pressed). Bold, italic and underline; a list's view; the days a timer
/// runs.
///
/// [multiSelectionEnabled] lets any number stay down; otherwise one does,
/// and a screen reader hears a radio group. Tab reaches the strip once; the
/// arrows move along it; Space and Enter press.
///
/// Reads [style] in each key's states, then [ApplianceThemeData.buttonStyle].
///
/// ```dart
/// ApplianceToggleGroup<String>(options: const [ApplianceToggleOption(value: 'day', label: 'Day'), ApplianceToggleOption(value: 'week', label: 'Week')], selected: const {'day'}, onSelectionChanged: (next) {})
/// ```
class ApplianceToggleGroup<T> extends StatelessWidget {
  /// A strip of latching keys over [options].
  const ApplianceToggleGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.semanticLabel,
    this.style,
  });

  /// The keys.
  final List<ApplianceToggleOption<T>> options;

  /// The keys down.
  final Set<T> selected;

  /// Called with the keys down after a press; null disables the strip.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Whether any number of keys may stay down.
  final bool multiSelectionEnabled;

  /// Whether every key may come up.
  final bool emptySelectionAllowed;

  /// The strip's name for a screen reader.
  final String? semanticLabel;

  /// Each key's style, over [ApplianceThemeData.buttonStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final byValue = {for (final o in options) o.value: o};
    final height = theme.controlHeight - 2 * ApplianceMetrics.capInset;
    return ApplianceSurface(
      face: _strip(c),
      // Each key reaches over the strip's inset above and below it: the
      // strip's whole height is its target.
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ApplianceMetrics.capInset,
        ),
        child: RawSegmentedButton<T>(
          options: [for (final o in options) o.value],
          selected: selected,
          onSelectionChanged: onSelectionChanged,
          multiSelectionEnabled: multiSelectionEnabled,
          emptySelectionAllowed: emptySelectionAllowed,
          isEnabled: (v) => byValue[v]?.enabled ?? false,
          labelOf: (v) => byValue[v]?.label ?? '$v',
          semanticLabel: semanticLabel,
          minimumSize: Size(height, theme.controlHeight),
          // One row while the keys fit; with large words, a second row of
          // keys in the same strip rather than keys past its end.
          layoutBuilder: (context, items) => Wrap(
            spacing: ApplianceMetrics.capInset,
            runSpacing: ApplianceMetrics.capInset,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: items,
          ),
          itemBuilder: (context, value, states) {
            final option = byValue[value]!;
            final layered = DesignStyleOf([style, theme.buttonStyle], states);
            final down = states.contains(WidgetState.selected);
            final disabled = states.contains(WidgetState.disabled);
            final held = states.contains(WidgetState.pressed);
            final base = down || held
                ? ApplianceFace.keyDown(c, radius: _keyInStrip)
                : ApplianceFace.key(c, radius: _keyInStrip);
            final face = layered.on(
              (disabled && !down ? base.asDisabled(c) : base).copyWith(
                foreground: disabled ? c.printDisabled : c.print,
                focus: states.contains(WidgetState.focused)
                    ? c.focus
                    : c.focus.withValues(alpha: 0),
              ),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ApplianceMetrics.capInset,
              ),
              child: SizedBox(
                height: height,
                child: AnimatedApplianceSurface(
                  face: face,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ApplianceSpacing.medium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Out of use, a key down keeps its lamp lit in the
                        // disabled print, as a radio's does.
                        ApplianceLamp(
                          lit: down,
                          size: ApplianceMetrics.lampSize - 2,
                          color: disabled ? c.printDisabled : null,
                        ),
                        if (option.icon != null) ...[
                          const SizedBox(width: ApplianceSpacing.small),
                          IconTheme.merge(
                            data: IconThemeData(
                              size: layered.iconSize ?? 18,
                              color: face.foreground,
                            ),
                            child: option.icon!,
                          ),
                        ],
                        if (option.showLabel) ...[
                          const SizedBox(width: ApplianceSpacing.small),
                          DesignCapCenter(
                            capHeightFactor: theme.capHeightFactor,
                            child: Text(
                              option.label,
                              maxLines: 1,
                              style: layered.text(
                                theme.textTheme.label.copyWith(
                                  color: face.foreground,
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
          },
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
          ifTrue: 'multiple',
        ),
      );
  }
}

/// A key with a second, narrow key moulded beside it at a parting line: the
/// first does the usual thing, the second opens a menu of the others ("Save"
/// and "Save as", "Save a copy").
///
/// [filled] makes both halves the signal key, for a screen's main action.
/// A null [onPressed] disables the main half; an action with a null
/// `onPressed` stands greyed in the menu.
///
/// ```dart
/// ApplianceSplitButton(label: 'Add to basket', onPressed: () {}, actions: [RawSplitAction(label: 'Add to a list', onPressed: () {})])
/// ```
class ApplianceSplitButton extends StatelessWidget {
  /// A split key: [label] and a menu of [actions].
  const ApplianceSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.filled = false,
    this.menuLabel,
    this.style,
  });

  /// The main half's legend.
  final String label;

  /// What the main half does; null disables it.
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<RawSplitAction> actions;

  /// Whether both halves are the signal key.
  final bool filled;

  /// The menu key's name for a screen reader.
  final String? menuLabel;

  /// Its style, over [ApplianceThemeData.filledButtonStyle]: textStyle.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).filledButtonStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    const r = Radius.circular(ApplianceMetrics.keyRadius);
    return RawSplitButton(
      label: label,
      onPressed: onPressed,
      actions: actions,
      menuLabel: menuLabel,
      minimumSize: Size(theme.controlHeight, theme.controlHeight),
      layoutBuilder: (context, main, menu) => IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            main,
            const SizedBox(width: ApplianceMetrics.seamWidth),
            menu,
          ],
        ),
      ),
      buttonBuilder: (context, part, states, open) {
        final main = part == RawSplitPart.main;
        final disabled = states.contains(WidgetState.disabled);
        final down = states.contains(WidgetState.pressed) || (!main && open);
        final radius = main
            ? const BorderRadiusDirectional.horizontal(start: r)
            : const BorderRadiusDirectional.horizontal(end: r);
        final face = applianceKeyFace(
          c,
          filled: filled,
          down: down,
          disabled: disabled,
          focused: states.contains(WidgetState.focused),
        ).copyWith(radius: radius.resolve(Directionality.of(context)));
        return TapTargetPadding(
          child: SizedBox(
            height: theme.controlHeight,
            width: main ? null : theme.controlHeight - ApplianceSpacing.small,
            child: AnimatedApplianceSurface(
              face: face,
              child: main
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ApplianceSpacing.large,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: DesignCapCenter(
                          capHeightFactor: theme.capHeightFactor,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: look
                                .text(theme.textTheme.label)
                                .copyWith(
                                  color: face.foreground,
                                  fontWeight: filled ? FontWeight.w600 : null,
                                ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: CustomPaint(
                          size: const Size.square(16),
                          painter: ApplianceChevronPainter(face.foreground),
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
      itemBuilder: (context, action, states) => ApplianceMenuRow(
        label: action.label,
        states: states,
        enabled: action.enabled,
      ),
      surfaceBuilder: (context, info, items) => ApplianceMenuReveal(
        animation: info.animation,
        below: info.side != RawPopoverSide.above,
        child: ApplianceMenuPlate(
          maxHeight: info.maxSize.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
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
      ..add(IntProperty('actions', actions.length))
      ..add(FlagProperty('filled', value: filled, ifTrue: 'filled'));
  }
}

/// A key's face as Appliance draws it in a state: the plain key or the
/// signal key ([filled]), [down] when held or latched, level, matte and
/// greyed when [disabled], its rim backlit when [focused].
ApplianceFace applianceKeyFace(
  ApplianceColors c, {
  bool filled = false,
  bool down = false,
  bool disabled = false,
  bool focused = false,
  double radius = ApplianceMetrics.keyRadius,
}) {
  final focus = focused ? c.focus : c.focus.withValues(alpha: 0);
  if (disabled) {
    return ApplianceFace.key(
      c,
      radius: radius,
    ).asDisabled(c).copyWith(focus: focus);
  }
  if (!filled) {
    return (down
            ? ApplianceFace.keyDown(c, radius: radius)
            : ApplianceFace.key(c, radius: radius))
        .copyWith(focus: focus);
  }
  return ApplianceFace(
    top: down ? Color.lerp(c.signalBottom, c.shade, 0.08)! : c.signalTop,
    bottom: down ? Color.lerp(c.signalTop, c.shade, 0.04)! : c.signalBottom,
    lift: down ? -0.5 : 1,
    travel: down ? 1 : 0,
    radius: BorderRadius.circular(radius),
    foreground: c.onSignal,
    focus: focus,
  );
}

/// Words that go somewhere: printed in the signal's ink and underlined, the
/// pointer a hand over them. A press darkens them to the print; the focus
/// bezel rings them for the keyboard.
///
/// A null [onPressed] prints them greyed, without the line.
///
/// ```dart
/// ApplianceLink('Delivery and returns', onPressed: () {})
/// ```
class ApplianceLink extends StatelessWidget {
  /// A link reading [label].
  const ApplianceLink(
    this.label, {
    super.key,
    required this.onPressed,
    this.style,
    this.focusNode,
  });

  /// The words.
  final String label;

  /// Where it goes; null disables it.
  final VoidCallback? onPressed;

  /// Its style, over [ApplianceThemeData.linkStyle].
  final ApplianceStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return RawButton(
      onPressed: onPressed,
      focusNode: focusNode,
      semanticLabel: label,
      excludeSemantics: true,
      button: false,
      link: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.linkStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final ink =
            layered.foreground ??
            (disabled
                ? c.printDisabled
                : states.contains(WidgetState.pressed)
                ? c.print
                : c.signalInk);
        return TapTargetPadding(
          child: AnimatedApplianceSurface(
            control: false,
            face: ApplianceFace(
              top: c.face.withValues(alpha: 0),
              bottom: c.face.withValues(alpha: 0),
              radius: BorderRadius.circular(ApplianceSpacing.tight),
              foreground: ink,
              focus: states.contains(WidgetState.focused)
                  ? c.focus
                  : c.focus.withValues(alpha: 0),
              focusReach: ApplianceSpacing.tight + ApplianceMetrics.focusWidth,
            ),
            child: Text(
              label,
              style: layered.text(
                theme.textTheme.body.copyWith(
                  color: ink,
                  decoration: disabled ? null : TextDecoration.underline,
                  decorationColor: ink,
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

/// A key on the keyboard, named: a small moulded key cap with its legend
/// ("Esc", "Ctrl", "K"). It shows a shortcut; it does not press.
///
/// [ApplianceKbd.shortcut] shows a whole shortcut, a cap for each key, as
/// the platform writes it (Cmd and Option on Apple's platforms, Ctrl and
/// Alt elsewhere), and a screen reader hears it as one.
///
/// ```dart
/// const Row(children: [ApplianceKbd('Ctrl'), ApplianceKbd('K')])
/// ```
class ApplianceKbd extends StatelessWidget {
  /// A cap reading [label].
  const ApplianceKbd(this.label, {super.key, this.style}) : shortcut = null;

  /// A cap for each key of [shortcut], in the platform's order and words.
  ///
  /// ```dart
  /// const ApplianceKbd.shortcut(SingleActivator(LogicalKeyboardKey.keyK, control: true))
  /// ```
  const ApplianceKbd.shortcut(
    MenuSerializableShortcut this.shortcut, {
    super.key,
    this.style,
  }) : label = '';

  /// The key's legend; empty for a [shortcut].
  final String label;

  /// The shortcut shown, a cap a key; null for one key's [label].
  final MenuSerializableShortcut? shortcut;

  /// Its style, over [ApplianceThemeData.tagStyle]: foreground, textStyle.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final keys = shortcut;
    if (keys == null) return _cap(context, label);
    // Barlow draws no ⌘ ⌥ ⇧ ⌃: Apple's keys go by their names.
    final caps = designShortcutKeys(context, keys, appleSymbols: false);
    return Semantics(
      label: designShortcutLabel(context, keys, appleSymbols: false),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, k) in caps.indexed) ...[
              if (i > 0) const SizedBox(width: ApplianceSpacing.nudge),
              _cap(context, k),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cap(BuildContext context, String legend) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).tagStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final t = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ApplianceSpacing.hair,
        vertical: ApplianceSpacing.nudge,
      ),
      child: ApplianceSurface(
        face: ApplianceFace.key(
          theme.colors,
          radius: ApplianceSpacing.tight,
        ).copyWith(lift: 0.6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ApplianceSpacing.small,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                legend,
                style: look
                    .text(t.legend)
                    .copyWith(
                      color: look.foreground ?? theme.colors.print,
                      letterSpacing: 0,
                    ),
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
      ..add(
        DiagnosticsProperty<MenuSerializableShortcut>(
          'shortcut',
          shortcut,
          defaultValue: null,
        ),
      );
  }
}
