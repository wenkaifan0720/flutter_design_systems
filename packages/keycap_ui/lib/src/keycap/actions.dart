/// Keycap's other actions: [KeycapToolbar] (a cluster of keys set side by
/// side, as a keyboard sets its keys), [KeycapToggleGroup] (keys that latch
/// down and stay there) and [KeycapSplitButton] (a key with its own menu
/// key moulded beside it).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'internal/group_radio.dart';
import 'select.dart';
import 'theme.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart' show RawSplitAction;

/// A cluster of keys set side by side at the keyboard's key gap: an
/// editor's formatting keys, a list's bulk actions. It names the cluster
/// for a screen reader. Below 600 wide the keys share the row
/// ([expand]); from 600 each keeps its own width.
///
/// ```dart
/// KeycapToolbar(semanticLabel: 'Formatting', children: [KeycapIconButton(icon: const Icon(LucideIcons.bold), semanticLabel: 'Bold', isSelected: bold, onPressed: toggleBold)])
/// ```
class KeycapToolbar extends StatelessWidget {
  /// A cluster of [children].
  const KeycapToolbar({
    super.key,
    required this.children,
    required this.semanticLabel,
    this.expand,
    this.trailing,
  });

  /// The keys.
  final List<Widget> children;

  /// The cluster's name, for a screen reader.
  final String semanticLabel;

  /// Whether the keys share the row's width; by the screen's width when
  /// null (below 600 they do).
  final bool? expand;

  /// Something set at the row's far end (a word count), only when the keys
  /// keep their own widths.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final wide = expand ?? MediaQuery.sizeOf(context).width < 600;
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: wide || trailing != null
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          for (final (i, k) in children.indexed) ...[
            if (i > 0) const SizedBox(width: KeycapMetrics.keyGap),
            wide ? Expanded(child: k) : k,
          ],
          if (!wide && trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('keys', children.length));
  }
}

/// One key of a [KeycapToggleGroup]: a glyph, words, or both.
///
/// ```dart
/// const KeycapToggleOption(value: 'bold', icon: LucideIcons.bold, semanticLabel: 'Bold')
/// ```
@immutable
class KeycapToggleOption<T> {
  /// A key for [value].
  const KeycapToggleOption({
    required this.value,
    this.icon,
    this.label,
    this.semanticLabel,
    this.enabled = true,
  }) : assert(icon != null || label != null);

  /// What latching this key chooses.
  final T value;

  /// Its glyph.
  final IconData? icon;

  /// Its words.
  final String? label;

  /// What a screen reader says; [label] when null (needed for a glyph
  /// alone).
  final String? semanticLabel;

  /// Whether it can be pressed.
  final bool enabled;
}

/// Keys that latch: each press sends a key part way down, in the modifier
/// plastic, and it stays down until pressed again (as a keyboard's lock
/// keys do). Several can be down at once ([multiSelectionEnabled], the
/// default), or one at a time. The arrows move between keys; Space or
/// Enter latches. One at a time, the keys are radios of one group: Tab
/// reaches the group once, at the key that is down, and the arrows choose
/// as they move. Built on ui_core's `RawSegmentedButton`, and on Flutter's
/// `RadioGroup` for one at a time, with ui_core's `RadioGroupKeyboardFix`.
///
/// ```dart
/// KeycapToggleGroup<String>(options: const [KeycapToggleOption(value: 'bold', icon: LucideIcons.bold, semanticLabel: 'Bold')], selected: on, onSelectionChanged: setOn)
/// ```
class KeycapToggleGroup<T> extends StatelessWidget {
  /// A group of latching keys.
  const KeycapToggleGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelectionChanged,
    this.multiSelectionEnabled = true,
    this.emptySelectionAllowed = true,
    this.semanticLabel,
    this.style,
  });

  /// The keys.
  final List<KeycapToggleOption<T>> options;

  /// The keys that are down.
  final Set<T> selected;

  /// Called with the keys now down; null turns the group off.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Whether several keys can be down at once.
  final bool multiSelectionEnabled;

  /// Whether every key can be let up.
  final bool emptySelectionAllowed;

  /// The group's name, for a screen reader.
  final String? semanticLabel;

  /// Overrides for the keys, over [KeycapThemeData.toggleStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final backlit = !MediaQuery.highContrastOf(context);
    KeycapToggleOption<T> of(T v) => options.firstWhere((o) => o.value == v);
    String labelOf(T v) => of(v).semanticLabel ?? of(v).label ?? '$v';
    Widget layout(BuildContext context, List<Widget> keys) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, k) in keys.indexed) ...[
          if (i > 0) const SizedBox(width: KeycapMetrics.keyGap),
          k,
        ],
      ],
    );
    Widget keyFor(BuildContext context, T v, Set<WidgetState> states) {
      final o = of(v);
      final latched = states.contains(WidgetState.selected);
      final layered = DesignStyleOf([style, theme.toggleStyle], states);
      final side = KeycapMetrics.grown(
        context,
        layered.minimumSize?.height ?? theme.controlHeight,
        theme.textTheme.label,
      );
      var face = keycapKeyFace(
        theme,
        KeycapKind.alpha,
        states,
        latched: latched,
        backlit: backlit,
      );
      face = layered.on(face);
      final glyph = o.icon == null
          ? null
          : Icon(o.icon, size: layered.iconSize ?? 20, color: face.legend);
      final words = o.label == null
          ? null
          : DesignCapCenter(
              capHeightFactor: theme.capHeightFactor,
              child: Text(
                o.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.label
                    .merge(layered.textStyle)
                    .copyWith(
                      color: face.legend,
                      fontWeight: latched ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            );
      return TapTargetPadding(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: side),
          child: SizedBox(
            height: side,
            child: AnimatedKeycapCap(
              face: face,
              walls: KeycapMetrics.walls(theme.controlHeight),
              child: Padding(
                padding: words == null
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                        horizontal: KeycapSpacing.regular,
                      ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ?glyph,
                    if (glyph != null && words != null)
                      const SizedBox(width: KeycapSpacing.small),
                    if (words != null) Flexible(child: words),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final values = [for (final o in options) o.value];
    if (multiSelectionEnabled) {
      return RawSegmentedButton<T>(
        options: values,
        selected: selected,
        onSelectionChanged: onSelectionChanged,
        multiSelectionEnabled: true,
        emptySelectionAllowed: emptySelectionAllowed,
        isEnabled: (v) => of(v).enabled,
        labelOf: labelOf,
        semanticLabel: semanticLabel,
        minimumSize: Size.zero,
        layoutBuilder: layout,
        itemBuilder: keyFor,
      );
    }
    // One at a time: the keys are radios of one group, as Flutter's
    // RadioGroup makes them (one Tab stop, the arrows choose).
    final change = onSelectionChanged;
    final down = selected.isEmpty ? null : selected.first;
    return KeycapGroupRadios<T>(
      value: down,
      onChanged: (v) {
        if (v != null) {
          change?.call({v});
        } else if (emptySelectionAllowed) {
          change?.call(<T>{});
        }
      },
      semanticLabel: semanticLabel,
      child: Builder(
        builder: (context) => layout(context, [
          for (final v in values)
            KeycapGroupRadio<T>(
              key: ObjectKey(v),
              value: v,
              enabled: change != null && of(v).enabled,
              // The key that is down lets up when the group may be left
              // empty.
              toggleable: emptySelectionAllowed,
              label: labelOf(v),
              builder: (context, states) => keyFor(context, v, states),
            ),
        ]),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('selected', selected))
      ..add(IntProperty('options', options.length))
      ..add(
        FlagProperty(
          'enabled',
          value: onSelectionChanged != null,
          ifFalse: 'disabled',
        ),
      );
  }
}

/// A key with its menu key moulded beside it: the main action on the
/// first, the other ways to do it in a list the second lays over the
/// keyboard ("Export" and, behind its menu key, "Export as PDF"). The menu
/// key latches down while its list is open. [accent] moulds both in the
/// accent, for the screen's main action. Built on ui_core's
/// `RawSplitButton`.
///
/// ```dart
/// KeycapSplitButton(label: 'Export', onPressed: export, actions: [RawSplitAction(label: 'Export as PDF', onPressed: exportPdf)])
/// ```
class KeycapSplitButton extends StatelessWidget {
  /// A key and its menu key.
  const KeycapSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.accent = false,
    this.style,
  });

  /// The main action's words.
  final String label;

  /// The main action; null turns the main key off (the menu key stays).
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<RawSplitAction> actions;

  /// What a screen reader calls the menu key.
  final String? menuLabel;

  /// Whether both keys are moulded in the accent.
  final bool accent;

  /// Overrides for both keys, over [KeycapThemeData.buttonStyle] (or
  /// [KeycapThemeData.accentButtonStyle]).
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final backlit = !MediaQuery.highContrastOf(context);
    final h = KeycapMetrics.grown(
      context,
      theme.controlHeight,
      theme.textTheme.label,
    );
    final walls = KeycapMetrics.walls(h);
    final rowHeight = theme.controlHeight - KeycapSpacing.tight;
    return RawSplitButton(
      label: label,
      onPressed: onPressed,
      actions: actions,
      menuLabel: menuLabel,
      minimumSize: Size(h, h),
      placement: const RawPopoverPlacement(
        align: RawPopoverAlign.end,
        matchAnchorWidth: false,
        maxWidth: 320,
      ),
      layoutBuilder: (context, main, menu) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          main,
          const SizedBox(width: KeycapMetrics.keyGap),
          menu,
        ],
      ),
      buttonBuilder: (context, part, states, open) {
        final isMain = part == RawSplitPart.main;
        final layered = DesignStyleOf([
          style,
          accent ? theme.accentButtonStyle : theme.buttonStyle,
        ], states);
        var face = keycapKeyFace(
          theme,
          accent ? KeycapKind.accent : KeycapKind.alpha,
          states,
          latched: !isMain && open && !accent,
          backlit: backlit,
        );
        if (!isMain && open && accent) {
          face = face.copyWith(travel: keycapLatchTravel);
        }
        face = layered.on(face);
        return TapTargetPadding(
          child: SizedBox(
            height: h,
            width: isMain ? null : h - KeycapSpacing.small,
            child: AnimatedKeycapCap(
              face: face,
              walls: walls,
              child: isMain
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18 + theme.density.paddingDelta,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: DesignCapCenter(
                          capHeightFactor: theme.capHeightFactor,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.label
                                .merge(layered.textStyle)
                                .copyWith(color: face.legend),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: face.legend,
                      ),
                    ),
            ),
          ),
        );
      },
      itemBuilder: (context, action, states) => KeycapMenuRow(
        label: action.label,
        height: rowHeight,
        enabled: action.enabled,
        lit:
            action.enabled &&
            (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused) ||
                states.contains(WidgetState.pressed)),
      ),
      surfaceBuilder: (context, info, items) => KeycapMenuReveal(
        animation: info.animation,
        below: info.side != RawPopoverSide.above,
        child: KeycapMenuPanel(
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
      ..add(FlagProperty('accent', value: accent, ifTrue: 'accent'));
  }
}
