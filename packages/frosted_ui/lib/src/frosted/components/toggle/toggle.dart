import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/css_shadow.dart';
import '../../internal/face.dart';
import '../../internal/menu_wake.dart';
import '../../internal/panel.dart';
import '../../theme.dart';
import '../controls/controls.dart';
import '../pressable/pressable.dart' show FrostedPointerHover;
import '../../internal/dim.dart';
import '../../internal/cap.dart';

// ---------------------------------------------------------------------------
// Toggle group
// ---------------------------------------------------------------------------

/// A strip of toggles (shadcn's ToggleGroup, a toolbar's Bold, Italic,
/// Underline): [segments] on the wash, the ones that are on raised as white
/// plates with the ink and semibold, as [FrostedSegmentedButton] draws its
/// choice. With [multiSelectionEnabled] each toggles on its own; without, it is one
/// choice and a press on the chosen one keeps it unless [emptySelectionAllowed]. One
/// Tab stop for the strip, Space or Return to press. Several at once,
/// ui_core's [RawSegmentedButton] is the behaviour: the arrows move between
/// the toggles. One at a time it is a group of radio buttons, Flutter's
/// [RadioGroup] with ui_core's [RadioGroupKeyboardFix] inside: Tab lands on
/// the chosen toggle and the four arrows choose as they move, wrapping.
///
/// ```dart
/// FrostedToggleGroup<String>(label: 'Text style', multiSelectionEnabled: true, segments: const [FrostedButtonSegment('b', 'Bold'), FrostedButtonSegment('i', 'Italic')], selected: styles, onSelectionChanged: (v) => setState(() => styles = v))
/// ```
class FrostedToggleGroup<T> extends StatelessWidget {
  /// A strip of [segments], [selected] on.
  const FrostedToggleGroup({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.label,
    super.key,
  });

  /// The toggles, in order.
  final List<FrostedButtonSegment<T>> segments;

  /// The values that are on.
  final Set<T> selected;

  /// Called with the values on after a press; null leaves the strip inert.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Whether any number may be on (else one).
  final bool multiSelectionEnabled;

  /// Whether none may be on.
  final bool emptySelectionAllowed;

  /// What a screen reader calls the strip.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // Large text grows the plates by its extra line (200% cut the words).
    final height = frostedGrownHeight(
      context,
      t.density.height(FrostedChromeMetrics.segmentHeight),
      t.textTheme.labelSmall,
    );
    const inset = FrostedChromeMetrics.segmentsInset;
    final labels = {for (final s in segments) s.value: s.label};
    // The strip is drawn at the plates' height and the inset round them;
    // each toggle's target (48 under a finger) overhangs it, centred.
    final target = FrostedBreakpoints.hitTargetOf(context);
    final strip = height + 2 * inset;
    final reach = math.max(strip, target);
    // The strip stands at its toggles' width at the start of a wider field,
    // as the segmented strip does, its wash no wider than they are.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        height: reach,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: (reach - strip) / 2,
              bottom: (reach - strip) / 2,
              child: FrostedFace(
                material: FrostedMaterial.paint,
                radius: BorderRadius.circular(height / 2 + inset),
                color: t.glass.wash,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: inset),
              child: _group(context, t, height, reach, target, labels),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(
    BuildContext context,
    FrostedThemeData t,
    double height,
    double reach,
    double target,
    Map<T, String> labels,
  ) {
    Widget row(BuildContext context, List<Widget> items) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.segmentsGap,
      children: items,
    );
    Widget toggle(T value, Set<WidgetState> states) {
      final on = states.contains(WidgetState.selected);
      final lit = states.contains(WidgetState.pressed);
      var words = t.textTheme.labelSmall;
      if (on) words = words.semibold.c(t.colorScheme.textPrimary);
      final plate = SizedBox(
        height: height,
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(height / 2),
          color: on ? t.glass.plane : (lit ? t.glass.fill : null),
          shadows: on
              ? [
                  frostedShadow(
                    color: t.glass.edge,
                    spread: FrostedChromeMetrics.outline,
                  ),
                  ...t.shadows.raised,
                ]
              : const <BoxShadow>[],
          padding: t.density.padding(
            const EdgeInsets.symmetric(
              horizontal: FrostedChromeMetrics.segmentInset,
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: frostedCapCentred(
              Text(
                labels[value] ?? '$value',
                maxLines: 1,
                softWrap: false,
                style: words,
              ),
            ),
          ),
        ),
      );
      final face = FrostedDim(
        off: states.contains(WidgetState.disabled),
        child: plate,
      );
      // The toggle answers the whole target round its plate: at least
      // as wide, as tall as the reach.
      return SizedBox(
        height: reach,
        child: Center(
          widthFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: target),
            child: frostedRingFor(states, face, radius: height / 2),
          ),
        ),
      );
    }

    final values = [for (final s in segments) s.value];
    final minimum = Size(FrostedChromeMetrics.segmentMinWidth, height);
    if (multiSelectionEnabled) {
      return RawSegmentedButton<T>(
        options: values,
        selected: selected,
        onSelectionChanged: onSelectionChanged,
        multiSelectionEnabled: true,
        emptySelectionAllowed: emptySelectionAllowed,
        labelOf: (value) => labels[value] ?? '$value',
        semanticLabel: label,
        minimumSize: minimum,
        layoutBuilder: row,
        itemBuilder: (context, value, states) => toggle(value, states),
      );
    }
    // One at a time: a group of radio buttons, each toggle one of Flutter's
    // radios drawing the same plate as before.
    final change = onSelectionChanged;
    final chosen = selected.isEmpty ? null : selected.first;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: RadioGroup<T>(
        groupValue: chosen,
        onChanged: (value) {
          if (change == null) return;
          // A press on the chosen toggle keeps it, or with [allowEmpty]
          // clears it.
          if (value != null) {
            change({value});
          } else if (emptySelectionAllowed) {
            change(<T>{});
          }
        },
        child: RadioGroupKeyboardFix<T>(
          child: row(context, [
            for (final value in values)
              _ToggleRadio<T>(
                key: ObjectKey(value),
                value: value,
                enabled: change != null,
                toggleable: emptySelectionAllowed,
                label: labels[value] ?? '$value',
                minimumSize: minimum,
                face: (states) => toggle(value, states),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedButtonSegment<T>>('segments', segments))
      ..add(IterableProperty<T>('selected', selected))
      ..add(
        ObjectFlagProperty<ValueChanged<Set<T>>>.has(
          'onSelectionChanged',
          onSelectionChanged,
        ),
      )
      ..add(
        FlagProperty(
          'multiSelectionEnabled',
          value: multiSelectionEnabled,
          ifTrue: 'multiple',
        ),
      )
      ..add(
        FlagProperty(
          'emptySelectionAllowed',
          value: emptySelectionAllowed,
          ifTrue: 'allowEmpty',
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

// One toggle of a one-at-a-time [FrostedToggleGroup]: a RawRadio of the
// group's RadioGroup, at least [minimumSize] (its plate centred in it), the
// whole of it its target, named [label] and drawn by [face] from the radio's
// states.
class _ToggleRadio<T> extends StatefulWidget {
  const _ToggleRadio({
    required this.value,
    required this.enabled,
    required this.toggleable,
    required this.label,
    required this.minimumSize,
    required this.face,
    super.key,
  });

  final T value;
  final bool enabled;
  final bool toggleable;
  final String label;
  final Size minimumSize;
  final Widget Function(Set<WidgetState> states) face;

  @override
  State<_ToggleRadio<T>> createState() => _ToggleRadioState<T>();
}

class _ToggleRadioState<T> extends State<_ToggleRadio<T>> {
  final FocusNode _node = FocusNode();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: RawRadio<T>(
      value: widget.value,
      mouseCursor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? MouseCursor.defer
            : SystemMouseCursors.click,
      ),
      toggleable: widget.toggleable,
      focusNode: _node,
      autofocus: false,
      groupRegistry: RadioGroup.maybeOf<T>(context),
      enabled: widget.enabled,
      // RawRadio shows a hover only while Flutter's highlight mode is
      // traditional; the face shows one wherever a pointer rests on it, as
      // before.
      builder: (context, radio) => FrostedPointerHover(
        builder: (context, hovered) => Semantics(
          label: widget.label,
          child: ExcludeSemantics(
            child: MetaData(
              behavior: HitTestBehavior.opaque,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: widget.minimumSize.width,
                  minHeight: widget.minimumSize.height,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: widget.face({
                    ...radio.states,
                    if (hovered && radio.isInteractive) WidgetState.hovered,
                    if (radio.downPosition != null) WidgetState.pressed,
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Split button
// ---------------------------------------------------------------------------

/// A button with a second half that opens more ways to do it (Save | Save
/// as…, Save all): the ink act and, past a hairline, a narrow half with a
/// chevron that drops [actions] on the look's panel. Each half is its own
/// Tab stop and target (the chevron's named "More"); the menu walks
/// with the arrows and closes on Escape, focus going back to the chevron.
/// ui_core's [RawSplitButton] is the behaviour.
///
/// ```dart
/// FrostedSplitButton(label: 'Save', onPressed: save, actions: [FrostedSplitAction(label: 'Save as…', onPressed: saveAs), FrostedSplitAction(label: 'Save all', onPressed: saveAll)])
/// ```
class FrostedSplitButton extends StatelessWidget {
  /// A split button saying [label], its menu holding [actions].
  const FrostedSplitButton({
    required this.label,
    required this.onPressed,
    required this.actions,
    this.glass = false,
    super.key,
  });

  /// The main half's words.
  final String label;

  /// What the main half does; null disables it.
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<FrostedSplitAction> actions;

  /// Whether both halves stand on the glass (a quieter act) in place of
  /// the ink.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    // Its menu tells a key's opening from a pointer's (FrostedMenuWake).
    FrostedLastInput.watch();
    final t = context.frostedTheme;
    final height = frostedGrownHeight(
      context,
      t.density.height(FrostedChromeMetrics.buttonHeight),
      t.textTheme.labelLarge,
    );
    final radius = Radius.circular(height / 2);
    final ink = glass ? t.colorScheme.textPrimary : t.colorScheme.onButton;
    // Each half answers the touch target (48 under a finger): the chevron's
    // half is drawn that wide, and both reach above and below the button.
    final target = FrostedBreakpoints.hitTargetOf(context);
    final reach = math.max(height, target);
    return RawSplitButton(
      label: label,
      onPressed: onPressed,
      menuLabel: RawWidgetsLocalizations.of(context).moreButtonTooltip,
      // Frosted's rows follow a moving pointer (FrostedPanelRow, woken by
      // FrostedMenuWake), as the menu bar's: ui_core's follow would light the
      // row a key-opened menu appears under.
      highlightFollowsPointer: false,
      minimumSize: Size(height, height),
      actions: [
        for (final a in actions)
          RawSplitAction(label: a.label, onPressed: a.onPressed),
      ],
      layoutBuilder: (context, main, toggle) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          main,
          SizedBox(
            width: FrostedStrokes.hairline,
            height: height,
            child: ColoredBox(
              color: glass
                  ? t.colorScheme.border
                  : t.colorScheme.onButton.withValues(alpha: .24),
            ),
          ),
          toggle,
        ],
      ),
      buttonBuilder: (context, part, states, open) {
        final main = part == RawSplitPart.main;
        final pressed = states.contains(WidgetState.pressed);
        final off = states.contains(WidgetState.disabled);
        final corners = Directionality.of(context) == TextDirection.ltr
            ? (main
                  ? BorderRadius.horizontal(left: radius)
                  : BorderRadius.horizontal(right: radius))
            : (main
                  ? BorderRadius.horizontal(right: radius)
                  : BorderRadius.horizontal(left: radius));
        final face = SizedBox(
          height: height,
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: corners,
            color: glass
                ? (pressed || open ? t.glass.fill : t.glass.fillHigh)
                : null,
            gradients: glass ? const <Gradient>[] : [t.colorScheme.buttonFill],
            sheen: glass ? null : t.colorScheme.buttonSheen,
            ring: glass ? t.glass.edge : null,
            shadows: glass ? const <BoxShadow>[] : t.shadows.button,
            wash: !glass && (pressed || open)
                ? t.colorScheme.onButton.withValues(alpha: .12)
                : null,
            padding: EdgeInsets.symmetric(
              horizontal: main
                  ? FrostedChromeMetrics.buttonInset
                  : FrostedSpacing.s12,
            ),
            child: Center(
              widthFactor: 1,
              child: main
                  ? frostedCapCentred(
                      Text(
                        label,
                        style: t.textTheme.labelLarge.semibold.c(ink),
                      ),
                    )
                  : Icon(
                      open
                          ? FrostedGlyphs.chevronUp
                          : FrostedGlyphs.chevronDown,
                      size: FrostedIconSize.i18,
                      color: ink,
                    ),
            ),
          ),
        );
        final shown = FrostedDim(off: off, child: face);
        return SizedBox(
          height: reach,
          child: Center(
            widthFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: target),
              // The ring follows the half's own outline: round at its
              // outer end, square at the divider.
              child: frostedRingFor(
                states,
                shown,
                shape: RoundedRectangleBorder(borderRadius: corners),
              ),
            ),
          ),
        );
      },
      itemBuilder: (context, action, states) => SizedBox(
        width:
            FrostedChromeMetrics.menuWidth - 2 * FrostedChromeMetrics.menuInset,
        child: FrostedPanelRow(
          label: action.label,
          states: states,
          checkable: false,
          followsPointer: true,
        ),
      ),
      surfaceBuilder: (context, info, items) => FrostedPanel(
        presence: info.animation,
        child: FrostedMenuWake(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostedChromeMetrics.menuItemsGap,
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
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(IterableProperty<FrostedSplitAction>('actions', actions))
      ..add(FlagProperty('glass', value: glass, ifTrue: 'glass'));
  }
}

/// One way a [FrostedSplitButton]'s menu offers to do it.
@immutable
class FrostedSplitAction {
  /// An action saying [label].
  const FrostedSplitAction({required this.label, required this.onPressed});

  /// The row's words.
  final String label;

  /// What it does; null disables the row, as ui_core's [RawSplitAction].
  final VoidCallback? onPressed;
}
