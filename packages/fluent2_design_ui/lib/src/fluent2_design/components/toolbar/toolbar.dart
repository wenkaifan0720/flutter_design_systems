import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/icon_fill.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../menu/menu.dart';
import '../pressable/pressable.dart';

import 'package:ui_core/ui_core.dart';

/// A toolbar's size, Fluent's `size`, which sets its room alone (Fluent's
/// ToolbarButton is a medium button, 32, at every size): [small] 4 at its
/// sides and none over and under; [medium] 4 over and under and 8 at its
/// sides (the default); [large] 4 over and under and 20 at its sides.
enum Fluent2ToolbarSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,
}

enum _ToolbarKind { button, toggle, divider }

/// One part of a [Fluent2Toolbar]: a command ([Fluent2ToolbarItem.button]),
/// an on/off command ([Fluent2ToolbarItem.toggle]) or Fluent's
/// `ToolbarDivider` between groups ([Fluent2ToolbarItem.divider]). A
/// command is its glyph alone (named by its label for a screen reader) or,
/// with [showLabel], its glyph and its words.
///
/// ```dart
/// Fluent2ToolbarItem.button(icon: Fluent2Icons.share, label: 'Share', onPressed: share)
/// ```
@immutable
class Fluent2ToolbarItem {
  /// A command: [icon], named by [label], doing [onPressed].
  const Fluent2ToolbarItem.button({
    required IconData this.icon,
    required String this.label,
    required this.onPressed,
    this.showLabel = false,
  }) : _kind = _ToolbarKind.button,
       checked = false,
       onChanged = null,
       checkedIcon = null;

  /// An on/off command: [checked] wears [checkedIcon] on the subtle
  /// selected face; a press asks [onChanged] for the other state.
  const Fluent2ToolbarItem.toggle({
    required IconData this.icon,
    required String this.label,
    required this.checked,
    required this.onChanged,
    this.checkedIcon,
    this.showLabel = false,
  }) : _kind = _ToolbarKind.toggle,
       onPressed = null;

  /// The hairline between two groups of commands.
  const Fluent2ToolbarItem.divider()
    : _kind = _ToolbarKind.divider,
      icon = null,
      label = null,
      onPressed = null,
      checked = false,
      onChanged = null,
      checkedIcon = null,
      showLabel = false;

  final _ToolbarKind _kind;

  /// The item's glyph; null for a word-only item.
  final IconData? icon;

  /// The item's words, shown or read as its name.
  final String? label;

  /// Called when the item is pressed; null puts it out of use.
  final VoidCallback? onPressed;

  /// Whether a toggle item is on.
  final bool checked;

  /// Called with a toggle item's new state; null makes the item a plain button.
  final ValueChanged<bool>? onChanged;

  /// The glyph a toggle item shows while on; null keeps [icon].
  final IconData? checkedIcon;

  /// Draws the words after the glyph.
  final bool showLabel;

  bool get _isDivider => _kind == _ToolbarKind.divider;
}

/// Fluent 2's Toolbar: a row of subtle commands (icon buttons, toggles
/// that stay pressed, labelled buttons) in groups split by its dividers,
/// 4 over and under it and 8 at its sides. When the row runs out of room
/// its last commands fold into the more button at its end, which opens a
/// [Fluent2Menu] of them (a toggle a checkable item). [vertical] stacks it
/// in a column. 44 tall on a phone. Read as a toolbar of buttons.
///
/// ```dart
/// Fluent2Toolbar(items: [Fluent2ToolbarItem.button(icon: Fluent2Icons.add, label: 'New', onPressed: create), const Fluent2ToolbarItem.divider(), Fluent2ToolbarItem.button(icon: Fluent2Icons.share, label: 'Share', onPressed: share)])
/// ```
class Fluent2Toolbar extends StatelessWidget {
  /// A toolbar of [items].
  const Fluent2Toolbar({
    required this.items,
    this.size = Fluent2ToolbarSize.medium,
    this.vertical = false,
    this.label,
    super.key,
  });

  /// The toolbar's buttons, toggles and dividers, in order.
  final List<Fluent2ToolbarItem> items;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2ToolbarSize size;

  /// Whether the items stand one under another.
  final bool vertical;

  /// What a screen reader calls the toolbar; null is "Toolbar" in the app's
  /// language.
  final String? label;

  Fluent2ButtonSize get _buttonSize => _toolbarButtonSize;

  EdgeInsets _padding(bool wide, bool touch) {
    final side = switch (size) {
      Fluent2ToolbarSize.small => Fluent2Spacing.xs,
      Fluent2ToolbarSize.medium => Fluent2Spacing.s,
      Fluent2ToolbarSize.large => Fluent2Spacing.xl,
    };
    final m = Fluent2ButtonMetrics.of(_buttonSize);
    final base = size == Fluent2ToolbarSize.small ? 0.0 : Fluent2Spacing.xs;
    // A narrow toolbar is a touch row: its commands' 44 targets fit in it.
    // Under a finger the commands stand in their own 48 already.
    final over = wide || touch
        ? base
        : math.max(base, (Fluent2Layout.minHitTarget - m.height) / 2);
    return EdgeInsets.symmetric(horizontal: side, vertical: over);
  }

  /// The width [item] takes in the row at [scaler]; under a finger
  /// ([touch]) a command is at least its 48 target wide.
  double _widthOf(
    Fluent2ToolbarItem item,
    Fluent2ThemeData t,
    TextScaler scaler,
    TextDirection direction,
    bool touch,
  ) {
    final m = Fluent2ButtonMetrics.of(_buttonSize);
    final least = touch ? Fluent2Layout.touchHitTarget : 0.0;
    if (item._isDivider) return 25;
    if (!item.showLabel) return math.max(m.height, least);
    final painter = TextPainter(
      text: TextSpan(
        text: item.label,
        style: Fluent2ButtonMetrics.typeOf(t, _buttonSize),
      ),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = math.max(
      math.max(m.minWidth, least),
      painter.width + 2 * m.side + m.glyph + m.gap + 1,
    );
    painter.dispose();
    return w;
  }

  Widget _part(Fluent2ToolbarItem item) =>
      _toolbarPart(item, vertical: vertical);

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final wide = Fluent2Layout.isWide(context);
    final touch = Fluent2Layout.padded(context);
    final padding = _padding(wide, touch);
    final label = this.label ?? Fluent2Localizations.of(context).toolbar;
    if (vertical) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: label,
        child: Padding(
          padding: EdgeInsets.all(padding.top),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final item in items) _part(item)],
          ),
        ),
      );
    }
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final room = box.maxWidth - padding.horizontal;
        final widths = [
          for (final item in items) _widthOf(item, t, scaler, direction, touch),
        ];
        var shown = items.length;
        if (room.isFinite &&
            widths.fold<double>(0, (s, w) => s + w) > room + 0.5) {
          final more = math.max(
            Fluent2ButtonMetrics.of(_buttonSize).height,
            touch ? Fluent2Layout.touchHitTarget : 0.0,
          );
          var used = more;
          shown = 0;
          for (final w in widths) {
            if (used + w > room) break;
            used += w;
            shown += 1;
          }
          // A divider never ends the row before the more button.
          while (shown > 0 && items[shown - 1]._isDivider) {
            shown -= 1;
          }
        }
        final folded = items.skip(shown).toList();
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: label,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items.take(shown)) _part(item),
                if (shown < items.length)
                  _More(items: folded, size: _buttonSize),
              ],
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
      ..add(IterableProperty<Fluent2ToolbarItem>('items', items))
      ..add(
        EnumProperty<Fluent2ToolbarSize>(
          'size',
          size,
          defaultValue: Fluent2ToolbarSize.medium,
        ),
      )
      ..add(FlagProperty('vertical', value: vertical, ifTrue: 'vertical'))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

// Fluent's ToolbarButton is a medium button at every toolbar size.
const _toolbarButtonSize = Fluent2ButtonSize.medium;

/// One part of a toolbar or a toolbar group: a subtle command, a toggle or
/// a divider.
Widget _toolbarPart(Fluent2ToolbarItem item, {required bool vertical}) {
  if (item._isDivider) {
    return vertical
        ? const _ToolbarDivider(vertical: false)
        : const _ToolbarDivider(vertical: true);
  }
  final label = item.label!;
  final icon = item.icon!;
  if (item._kind == _ToolbarKind.toggle) {
    final change = item.onChanged;
    if (item.showLabel) {
      return Fluent2ToggleButton(
        label,
        value: item.checked,
        appearance: Fluent2ButtonAppearance.subtle,
        size: _toolbarButtonSize,
        icon: icon,
        checkedIcon: item.checkedIcon,
        onChanged: change,
      );
    }
    return Fluent2IconButton(
      icon,
      label: label,
      size: _toolbarButtonSize,
      selected: item.checked,
      filled: item.checkedIcon,
      onPressed: change == null ? null : () => change(!item.checked),
    );
  }
  if (item.showLabel) {
    return Fluent2Button(
      label,
      icon: icon,
      appearance: Fluent2ButtonAppearance.subtle,
      size: _toolbarButtonSize,
      onPressed: item.onPressed,
    );
  }
  return Fluent2IconButton(
    icon,
    label: label,
    size: _toolbarButtonSize,
    onPressed: item.onPressed,
  );
}

/// Fluent 2's ToolbarGroup: commands that belong together (a document's
/// text formatting, a file's sharing) standing side by side as a
/// toolbar's subtle buttons, toggles and dividers, read as a group named
/// [label]. It has no room of its own: it stands in a row or a
/// [Fluent2Toolbar]'s place, and unlike a toolbar it never folds its
/// commands into a more button: where they don't fit on one line (large
/// text on a phone) they run on to the next. It keeps to its commands'
/// width. Fluent joins no buttons in one frame: related acts share a
/// toolbar's group, not a border.
///
/// ```dart
/// Fluent2ToolbarGroup(label: 'Share', items: [Fluent2ToolbarItem.button(icon: Fluent2Icons.link, label: 'Copy link', onPressed: copy), Fluent2ToolbarItem.button(icon: Fluent2Icons.mail, label: 'Email', onPressed: email)])
/// ```
class Fluent2ToolbarGroup extends StatelessWidget {
  /// A group of [items], read as [label].
  const Fluent2ToolbarGroup({
    required this.items,
    required this.label,
    this.vertical = false,
    super.key,
  });

  /// The group's commands, toggles and dividers, in order.
  final List<Fluent2ToolbarItem> items;

  /// What a screen reader calls the group.
  final String label;

  /// Whether the items stand one under another.
  final bool vertical;

  @override
  Widget build(BuildContext context) => _OwnWidth(
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Wrap(
        direction: vertical ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final item in items) _toolbarPart(item, vertical: vertical),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Fluent2ToolbarItem>('items', items))
      ..add(StringProperty('label', label))
      ..add(FlagProperty('vertical', value: vertical, ifTrue: 'vertical'));
  }
}

/// One toggle of a [Fluent2ToolbarToggleGroup]: Fluent's
/// ToolbarRadioButton in a one-choice group, its ToolbarToggleButton in a
/// group of any number. Its [icon] alone (named by [label] for a screen
/// reader) or, with [showLabel], its glyph and its words; while chosen it
/// wears [checkedIcon], else [icon]'s filled twin.
///
/// ```dart
/// Fluent2ToolbarToggle('flagged', icon: Fluent2Icons.flag, label: 'Flagged')
/// ```
@immutable
class Fluent2ToolbarToggle<T> {
  /// A toggle that stands for [value].
  const Fluent2ToolbarToggle(
    this.value, {
    required this.icon,
    required this.label,
    this.checkedIcon,
    this.showLabel = false,
    this.enabled = true,
  });

  /// What the toggle stands for in the group's selection.
  final T value;

  /// The toggle's glyph.
  final IconData icon;

  /// The toggle's words, shown with [showLabel] or read as its name.
  final String label;

  /// The glyph it wears while chosen; null wears [icon]'s filled twin.
  final IconData? checkedIcon;

  /// Draws the words after the glyph.
  final bool showLabel;

  /// False puts this toggle out of use.
  final bool enabled;
}

/// Fluent 2's toolbar toggles that belong together, on the toolbar's
/// subtle faces: a ToolbarRadioGroup (one choice of several: a list's
/// layout) or, with [multiSelectionEnabled], ToolbarToggleButtons that
/// share a name (such as mail filters). A chosen toggle uses the selected
/// face and filled glyph. Tab enters the group once. Arrows choose in a
/// single-choice group and move focus among independent toggles.
/// Space and Enter activate the focused item. Read as a radio group or a group of toggles
/// named [label]. It keeps to its toggles' width, and where they don't
/// fit on one line (large text on a phone) they run on to the next. One
/// choice of a view's few modes with a sliding thumb is the segmented
/// control ([Fluent2SegmentedButton]) instead.
///
/// ```dart
/// Fluent2ToolbarToggleGroup<String>(label: 'Show', multiSelectionEnabled: true, toggles: const [Fluent2ToolbarToggle('flagged', icon: Fluent2Icons.flag, label: 'Flagged'), Fluent2ToolbarToggle('attached', icon: Fluent2Icons.attach, label: 'With files')], selected: shown, onSelectionChanged: (next) => setState(() => shown = next))
/// ```
class Fluent2ToolbarToggleGroup<T> extends StatelessWidget {
  /// A group of [toggles], [selected] chosen.
  const Fluent2ToolbarToggleGroup({
    required this.toggles,
    required this.selected,
    required this.onSelectionChanged,
    required this.label,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.vertical = false,
    super.key,
  });

  /// The toggles, in order.
  final List<Fluent2ToolbarToggle<T>> toggles;

  /// The values of the chosen toggles.
  final Set<T> selected;

  /// Called with the new selection when the user changes it; null puts the
  /// group out of use.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// What a screen reader calls the group.
  final String label;

  /// Whether any number may be chosen (ToolbarToggleButtons); false is one
  /// choice (a ToolbarRadioGroup).
  final bool multiSelectionEnabled;

  /// Whether a one-choice group may be left with none chosen.
  final bool emptySelectionAllowed;

  /// Whether the toggles stand one under another.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final touch = Fluent2Layout.padded(context);
    final byValue = {for (final toggle in toggles) toggle.value: toggle};
    final values = [for (final toggle in toggles) toggle.value];
    final axis = vertical ? Axis.vertical : Axis.horizontal;
    Widget layout(BuildContext context, List<Widget> items) => Wrap(
      direction: axis,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
    Widget face(T value, Set<WidgetState> states) =>
        _ToggleFace(toggle: byValue[value]!, states: states, touch: touch);

    if (multiSelectionEnabled) {
      return _OwnWidth(
        child: DesignToggleGroup<T>(
          options: values,
          selected: selected,
          onSelectionChanged: onSelectionChanged,
          multiSelectionEnabled: true,
          isEnabled: (value) => byValue[value]!.enabled,
          labelOf: (value) => byValue[value]!.label,
          semanticLabel: label,
          direction: axis,
          minimumSize: Size.zero,
          layoutBuilder: layout,
          itemBuilder: (context, value, states) => face(value, states),
        ),
      );
    }

    final change = onSelectionChanged;
    // Home and End still move to the first and last enabled toolbar items.
    final enabled = toggles.where((toggle) => toggle.enabled);
    final nodes = <T, FocusNode>{};
    return _OwnWidth(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: label,
        child: CallbackShortcuts(
          bindings: {
            if (enabled.isNotEmpty) ...{
              const SingleActivator(LogicalKeyboardKey.home): () =>
                  nodes[enabled.first.value]?.requestFocus(),
              const SingleActivator(LogicalKeyboardKey.end): () =>
                  nodes[enabled.last.value]?.requestFocus(),
            },
          },
          child: DesignRadioGroup<T>(
            options: values,
            value: values.where(selected.contains).firstOrNull,
            onChanged: change == null ? null : (value) => change({value}),
            isEnabled: (value) => byValue[value]!.enabled,
            layoutBuilder: layout,
            itemBuilder: (context, value, node, select) {
              nodes[value] = node;
              final on = selected.contains(value);
              return DesignPressable(
                focusNode: node,
                onPressed: select != null && on && emptySelectionAllowed
                    ? () => change?.call(<T>{})
                    : select,
                selected: on,
                checked: on,
                inMutuallyExclusiveGroup: true,
                semanticLabel: byValue[value]!.label,
                excludeSemantics: true,
                builder: (context, states, _) => face(value, states),
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
      ..add(IterableProperty<Fluent2ToolbarToggle<T>>('toggles', toggles))
      ..add(IterableProperty<T>('selected', selected))
      ..add(
        ObjectFlagProperty<ValueChanged<Set<T>>?>.has(
          'onSelectionChanged',
          onSelectionChanged,
        ),
      )
      ..add(StringProperty('label', label))
      ..add(
        FlagProperty(
          'multiSelectionEnabled',
          value: multiSelectionEnabled,
          ifTrue: 'multiSelectionEnabled',
        ),
      )
      ..add(
        FlagProperty(
          'emptySelectionAllowed',
          value: emptySelectionAllowed,
          ifTrue: 'emptySelectionAllowed',
        ),
      )
      ..add(FlagProperty('vertical', value: vertical, ifTrue: 'vertical'));
  }
}

/// A toolbar toggle's face in its states: an icon button's, or a toggle
/// button's with its words, on the subtle appearance, ringed while the
/// keyboard holds it.
class _ToggleFace<T> extends StatelessWidget {
  const _ToggleFace({
    required this.toggle,
    required this.states,
    required this.touch,
  });

  final Fluent2ToolbarToggle<T> toggle;
  final Set<WidgetState> states;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final on = states.contains(WidgetState.selected);
    final look = Fluent2ButtonLook(
      context.fluent2Theme,
      appearance: Fluent2ButtonAppearance.subtle,
      size: _toolbarButtonSize,
      icon: !toggle.showLabel,
      touch: touch,
    );
    final face = Fluent2Eased<Fluent2ButtonFace>(
      value: look.face(states, checked: on),
      lerp: Fluent2ButtonFace.lerp,
      builder: (context, face) {
        final glyph = Icon(
          on
              ? (toggle.checkedIcon ?? fluent2Filled(toggle.icon))
              : fluent2FillOn(toggle.icon, states),
          size: look.glyph(states),
          color: face.glyph,
        );
        if (!toggle.showLabel) {
          return look.box(
            states,
            face: face,
            width: look.minWidth(states, look.height),
            child: glyph,
          );
        }
        return look.box(
          states,
          face: face,
          minWidth: look.metrics.minWidth,
          padding: EdgeInsets.symmetric(horizontal: look.sideRoom),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: look.metrics.gap,
            children: [
              glyph,
              Flexible(
                child: fluent2CapCentred(
                  Text(
                    toggle.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: look.type(states, face.ink),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!states.contains(WidgetState.focused)) return face;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        face,
        Positioned.fill(
          child: IgnorePointer(
            child: Fluent2FocusRing(
              radius: look.radius,
              shape: look.outline(states),
            ),
          ),
        ),
      ],
    );
  }
}

/// The more button a toolbar folds its last commands into.
class _More extends StatelessWidget {
  const _More({required this.items, required this.size});

  final List<Fluent2ToolbarItem> items;
  final Fluent2ButtonSize size;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (anchor) => Fluent2IconButton(
      Fluent2Icons.moreHorizontal,
      label: DesignLocalizations.of(anchor).moreButtonTooltip,
      size: size,
      onPressed: () async {
        final menu = <Fluent2MenuItem<int>>[];
        var divider = false;
        for (final (i, item) in items.indexed) {
          if (item._isDivider) {
            divider = menu.isNotEmpty;
            continue;
          }
          final toggle = item._kind == _ToolbarKind.toggle;
          menu.add(
            Fluent2MenuItem(
              i,
              item.label!,
              icon: item.icon,
              checked: toggle ? item.checked : null,
              divider: divider,
              enabled: toggle ? item.onChanged != null : item.onPressed != null,
            ),
          );
          divider = false;
        }
        final picked = await Fluent2Menu.show<int>(anchor, items: menu);
        if (picked == null) return;
        final item = items[picked];
        if (item._kind == _ToolbarKind.toggle) {
          item.onChanged?.call(!item.checked);
        } else {
          item.onPressed?.call();
        }
      },
    ),
  );
}

/// Fluent's `ToolbarDivider`: a vertical hairline in the default divider's
/// stroke with 12 either side (a horizontal one in a vertical toolbar).
class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final line = ColoredBox(color: fluent2Step(t, t.colors.neutralStroke2));
    return vertical
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: Fluent2Spacing.m),
            child: SizedBox(width: 1, height: 20, child: line),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.m),
            child: SizedBox(width: 20, height: 1, child: line),
          );
  }
}

/// A group at its own parts' width, at the start of a row or column that
/// would stretch it, so neither its node nor its focus reaches past them.
class _OwnWidth extends StatelessWidget {
  const _OwnWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    widthFactor: 1,
    heightFactor: 1,
    child: child,
  );
}
