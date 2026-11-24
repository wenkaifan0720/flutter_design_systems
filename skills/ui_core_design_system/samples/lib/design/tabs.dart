import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'button.dart';
import 'face.dart';
import 'theme.dart';

/// One tab of a [TendTabs]: the value it stands for and its words.
@immutable
class TendTab<T> {
  /// A tab standing for [value], saying [label].
  const TendTab({
    required this.value,
    required this.label,
    this.enabled = true,
    this.order,
  });

  /// What choosing it chooses.
  final T value;

  /// What it says.
  final String label;

  /// Whether it can be chosen.
  final bool enabled;

  /// Its place for the arrows, Home and End, where the tabs are not laid
  /// out in the order they are read (a grid, a wrap the design fills its own
  /// way); null: the order they are laid out in. Give every tab one, or
  /// none.
  final int? order;
}

/// A row of tabs drawn as words over a rule, the chosen one underlined in
/// ink: ui_core's [RawTabGroup] for a tab bar's behaviour (one tab stop,
/// the arrows, Home and End, the selection, a tab bar of tabs to a screen
/// reader), round tabs the design lays out itself.
///
/// ```dart
/// TendTabs<String>(value: 'all', onChanged: (next) {}, tabs: const [TendTab(value: 'all', label: 'All'), TendTab(value: 'open', label: 'Open')])
/// ```
class TendTabs<T> extends StatelessWidget {
  /// Tabs choosing [value] among [tabs].
  const TendTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.tabs,
    this.semanticLabel,
  });

  /// The chosen tab's value; null: none yet.
  final T? value;

  /// Called with the tab chosen; null turns the tabs off.
  final ValueChanged<T>? onChanged;

  /// The tabs, in reading order.
  final List<TendTab<T>> tabs;

  /// What a screen reader calls the row.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    return RawTabGroup<T>(
      groupValue: value,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.colors.rule)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tab in tabs)
              RawTabGroupTab<T>(
                value: tab.value,
                enabled: onChanged != null && tab.enabled,
                order: tab.order,
                builder: (context, states, _) =>
                    _tendTab(context, theme, states, tab.label),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged));
  }
}

/// A tab's face: its words, a rule round it under the keyboard (the
/// design's focus), and an underline in ink once chosen. A chosen tab is a
/// state, so it never takes the accent of the screen's main action.
Widget _tendTab(
  BuildContext context,
  TendThemeData theme,
  Set<WidgetState> states,
  String label,
) {
  final c = theme.colors;
  const clear = Color(0x00000000);
  final chosen = states.contains(WidgetState.selected);
  final ink = states.contains(WidgetState.disabled)
      ? c.mutedInk
      : chosen
      ? c.ink
      : c.mutedInk;
  return AnimatedTendSurface(
    face: TendFace(
      fill: states.contains(WidgetState.pressed)
          ? c.ink.withValues(alpha: .08)
          : clear,
      rule: states.contains(WidgetState.focused) ? c.ink : clear,
      ruleWidth: 2,
      foreground: ink,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(theme.radius / 2),
    ),
    // As wide as its words; the underline spans that width.
    child: IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RawControlBox(
              // The tab is its own target: it stands at the floor.
              minHeight: math.max(
                theme.density.height(theme.controlHeight),
                RawTapTargets.of(context).floorOn().height,
              ),
              child: RawCapCenter(
                capHeightFactor: theme.capHeightFactor,
                child: Text(label, style: theme.label),
              ),
            ),
          ),
          AnimatedTendSurface(
            face: TendFace(
              fill: chosen ? c.ink : clear,
              rule: clear,
              foreground: ink,
            ),
            shape: const RoundedRectangleBorder(),
            child: const SizedBox(height: 2),
          ),
        ],
      ),
    ),
  );
}

/// One toggle of a [TendToolbar]: a glyph that is on or off (Bold, Italic).
@immutable
class TendToolbarToggle {
  /// A toggle showing [icon], named [semanticLabel].
  const TendToolbarToggle({
    required this.icon,
    required this.semanticLabel,
    required this.isSelected,
    required this.onPressed,
  });

  /// The glyph.
  final IconData icon;

  /// What a screen reader calls it.
  final String semanticLabel;

  /// Whether it is on.
  final bool isSelected;

  /// What a press does; null turns it off.
  final VoidCallback? onPressed;
}

/// A row of toggles that is one Tab stop, the arrows moving along it, as a
/// formatting bar is: ui_core's [RawRovingFocusGroup] round the design's
/// [TendIconButton]s, each a [RawRovingFocusItem] sharing its button's
/// focus node. The group moves the focus; a press still toggles.
///
/// ```dart
/// TendToolbar(toggles: [TendToolbarToggle(icon: const IconData(0xe238), semanticLabel: 'Bold', isSelected: bold, onPressed: () {})])
/// ```
class TendToolbar extends StatefulWidget {
  /// A bar of [toggles].
  const TendToolbar({super.key, required this.toggles});

  /// The toggles, in reading order.
  final List<TendToolbarToggle> toggles;

  @override
  State<TendToolbar> createState() => _TendToolbarState();
}

class _TendToolbarState extends State<TendToolbar> {
  // One node a toggle: the group moves the focus through them, and each
  // button takes the same node. The bar owns them and disposes them.
  final List<FocusNode> _nodes = [];

  void _match() {
    while (_nodes.length < widget.toggles.length) {
      _nodes.add(FocusNode(debugLabel: 'TendToolbar ${_nodes.length}'));
    }
    while (_nodes.length > widget.toggles.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _match();
  }

  @override
  void didUpdateWidget(TendToolbar old) {
    super.didUpdateWidget(old);
    _match();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawRovingFocusGroup(
    orientation: Axis.horizontal,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, toggle) in widget.toggles.indexed)
          RawRovingFocusItem(
            focusNode: _nodes[i],
            enabled: toggle.onPressed != null,
            child: TendIconButton(
              icon: toggle.icon,
              semanticLabel: toggle.semanticLabel,
              isSelected: toggle.isSelected,
              onPressed: toggle.onPressed,
              focusNode: _nodes[i],
            ),
          ),
      ],
    ),
  );
}
