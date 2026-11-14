import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'chrome.dart' show RetroDesktopNavItem;
import 'component_themes.dart';
import 'internal/caps.dart';
import 'internal/face.dart';
import 'localizations.dart';
import 'press.dart';
import 'theme.dart';

/// A permanent side navigator made from the same destinations as the bottom bar.
///
/// ```dart
/// RetroDesktopNavigationDrawer(items: const [RetroDesktopNavItem(label: 'Files', short: 'Files', icon: RetroDesktopGlyphs.folder)], onDestinationSelected: (_) {})
/// ```
class RetroDesktopNavigationDrawer extends StatelessWidget {
  /// Creates a [RetroDesktopNavigationDrawer].
  const RetroDesktopNavigationDrawer({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.label,
    this.style,
  });

  /// The items displayed in their supplied order.
  final List<RetroDesktopNavItem> items;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// Reports the index of the navigation destination activated.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional content above the main items.
  final Widget? header;

  /// Optional content below the main items.
  final Widget? footer;

  /// The visible or accessible name of this part.
  final String? label;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => _SideNavigation(
    items: items,
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    header: header,
    footer: footer,
    label: label,
    style: style,
  );
}

/// A compact side navigator whose icon buttons retain each destination's name.
///
/// ```dart
/// RetroDesktopNavigationRail(items: const [RetroDesktopNavItem(label: 'Files', short: 'Files', icon: RetroDesktopGlyphs.folder)], onDestinationSelected: (_) {})
/// ```
class RetroDesktopNavigationRail extends StatelessWidget {
  /// Creates a [RetroDesktopNavigationRail].
  const RetroDesktopNavigationRail({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.label,
    this.style,
  });

  /// The items displayed in their supplied order.
  final List<RetroDesktopNavItem> items;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// Reports the index of the navigation destination activated.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional content above the main items.
  final Widget? header;

  /// Optional content below the main items.
  final Widget? footer;

  /// The visible or accessible name of this part.
  final String? label;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) => _SideNavigation(
    items: items,
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    header: header,
    footer: footer,
    label: label,
    style: style,
    rail: true,
  );
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.items,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.label,
    this.style,
    this.rail = false,
  });
  final List<RetroDesktopNavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? header, footer;
  final String? label;
  final RetroDesktopStyle? style;
  final bool rail;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    // Its own width at the start edge, even in a stretching column.
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      child: SizedBox(
        width: rail ? 64 : 248,
        child: Semantics(
          container: true,
          label: label ?? RetroDesktopLocalizations.of(context).mainNavigation,
          explicitChildNodes: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?header,
                for (var i = 0; i < items.length; i++)
                  RetroDesktopPressable(
                    key: items[i].key,
                    label: items[i].label,
                    selected: selectedIndex == i,
                    value: items[i].badgeLabel,
                    onPressed: onDestinationSelected != null
                        ? () => onDestinationSelected!(i)
                        : items[i].onPressed,
                    // A row of a list, as both desktops drew a list of
                    // places: no button face, the chosen one in the
                    // selection fill, a held one a shade darker; focus rings
                    // inside the row, which meets its neighbours.
                    builder: (context, states) => retroDesktopFace(
                      states: states,
                      bevel: false,
                      ringInside: true,
                      component: t.navigationBarTheme.merge(
                        RetroDesktopStyle(
                          fill: WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected)
                                ? t.colors.highlight
                                : s.contains(WidgetState.pressed)
                                ? t.colors.platinumDark
                                : const Color(0x00000000),
                          ),
                          side: const WidgetStatePropertyAll(BorderSide.none),
                        ),
                      ),
                      style: style,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisAlignment: rail
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          if (rail)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(items[i].icon),
                                if (items[i].badgeLabel != null)
                                  Text(
                                    items[i].badgeLabel!,
                                    style: t.type.caption,
                                  ),
                              ],
                            )
                          else
                            Icon(items[i].icon),
                          if (!rail) ...[
                            const SizedBox(width: 10),
                            // The place's name is the row's label: its
                            // capitals on the row's middle, beside its glyph.
                            Expanded(
                              child: RetroDesktopCaps(Text(items[i].label)),
                            ),
                            if (items[i].badgeLabel != null) ...[
                              const SizedBox(width: 6),
                              Text(items[i].badgeLabel!),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sequence of page marks in the family's mark shape; arrows and semantic steps move the selection.
///
/// ```dart
/// RetroDesktopPageDots(count: 3, selectedIndex: 1, label: 'Introduction pages', onChanged: (_) {})
/// ```
class RetroDesktopPageDots extends StatefulWidget {
  /// Creates a [RetroDesktopPageDots].
  const RetroDesktopPageDots({
    super.key,
    required this.count,
    required this.selectedIndex,
    required this.label,
    this.onChanged,
    this.style,
  }) : assert(count > 0),
       assert(selectedIndex >= 0 && selectedIndex < count);

  /// The count displayed by this part.
  final int count;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// The visible or accessible name of this part.
  final String label;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<int>? onChanged;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  State<RetroDesktopPageDots> createState() => _PageDotsState();
}

class _PageDotsState extends State<RetroDesktopPageDots> {
  final List<FocusNode> _nodes = [];
  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    while (_nodes.length < widget.count) {
      _nodes.add(FocusNode());
    }
    final t = RetroDesktopTheme.of(context);
    final live = widget.onChanged != null;
    void choose(int index) {
      widget.onChanged?.call(index);
      _nodes[index].requestFocus();
    }

    return Semantics(
      container: true,
      label: widget.label,
      explicitChildNodes: true,
      child: Wrap(
        children: [
          for (var i = 0; i < widget.count; i++)
            Focus(
              canRequestFocus: false,
              skipTraversal: true,
              includeSemantics: false,
              onKeyEvent: (_, event) {
                if (!live ||
                    (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
                  return KeyEventResult.ignored;
                }
                final rtl = Directionality.of(context) == TextDirection.rtl;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.home) {
                  choose(0);
                } else if (key == LogicalKeyboardKey.end) {
                  choose(widget.count - 1);
                } else if (key == LogicalKeyboardKey.arrowLeft) {
                  choose((i + (rtl ? 1 : -1)) % widget.count);
                } else if (key == LogicalKeyboardKey.arrowRight) {
                  choose((i + (rtl ? -1 : 1)) % widget.count);
                } else {
                  return KeyEventResult.ignored;
                }
                return KeyEventResult.handled;
              },
              child: Builder(
                builder: (context) {
                  _nodes[i].skipTraversal = i != widget.selectedIndex;
                  return RetroDesktopPressable(
                    label:
                        '${widget.label} ${RetroDesktopLocalizations.of(context).formatInteger(i + 1)}',
                    value:
                        '${RetroDesktopLocalizations.of(context).formatInteger(i + 1)} / ${RetroDesktopLocalizations.of(context).formatInteger(widget.count)}',
                    selected: i == widget.selectedIndex,
                    focusNode: _nodes[i],
                    onPressed: live ? () => choose(i) : null,
                    builder: (context, states) => ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: retroDesktopFace(
                        states: states,
                        // A status dot: round wherever the family rounds.
                        scale: RetroDesktopFaceScale.mark,
                        component: t.badgeTheme,
                        style: widget.style,
                        padding: EdgeInsets.zero,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A labelled progress summary along a fixed number of steps.
///
/// ```dart
/// RetroDesktopStepProgress(count: 4, currentStep: 1, name: 'Installation')
/// ```
class RetroDesktopStepProgress extends StatelessWidget {
  /// Creates a [RetroDesktopStepProgress].
  const RetroDesktopStepProgress({
    super.key,
    required this.count,
    required this.currentStep,
    required this.name,
    this.phase,
  }) : assert(count > 0),
       assert(currentStep >= 0 && currentStep < count);

  /// The count displayed by this part.
  final int count;

  /// The index of the current step in the sequence.
  final int currentStep;

  /// The name identifying this item.
  final String name;

  /// The progress of the current step.
  final String? phase;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Semantics(
      label: name,
      value:
          '${RetroDesktopLocalizations.of(context).formatInteger(currentStep + 1)} / ${RetroDesktopLocalizations.of(context).formatInteger(count)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(name, style: t.type.body),
                Text(
                  '${RetroDesktopLocalizations.of(context).formatInteger(currentStep + 1)} / ${RetroDesktopLocalizations.of(context).formatInteger(count)}',
                  style: t.type.meta,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: i == count - 1 ? 0 : 3,
                      ),
                      child: SizedBox(
                        height: 7,
                        // Each step is a capsule in the theme's family.
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: t.shapes.full,
                            color: i <= currentStep
                                ? t.colors.highlight
                                : t.colors.platinumDark,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (phase != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(phase!, style: t.type.meta),
              ),
          ],
        ),
      ),
    );
  }
}
