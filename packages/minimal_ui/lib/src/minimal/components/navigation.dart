/// Navigation for wide windows: a rail of glyphs, and a sidebar of rows.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/controls.dart';
import '../internal/nav_faces.dart';
import '../theme.dart';
import 'nav_bar.dart';
import 'pressable.dart';
import 'nav_item.dart';

/// The arrow keys walk a column of destinations.
Widget _walk(Widget child) => Shortcuts(
  shortcuts: const <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
  },
  child: FocusTraversalGroup(child: child),
);

/// The app's top-level places as a narrow rail at a window's start edge —
/// a tablet, a desktop window too narrow for a sidebar: each destination
/// a glyph over its label in a 56 px cell, a hairline down its end. The
/// current one is said in type alone: its glyph and label in the full ink,
/// the label at medium weight, the rest in the muted ink; nothing behind it.
/// The same [MinimalNavItem]s the phone's [MinimalNavigationBar] takes, so
/// a shell swaps one for the other as the window widens.
///
/// [leading] stands above the destinations (the create action, the app's
/// mark), [trailing] at the foot (the account). The arrow keys walk the
/// destinations; each takes its whole cell as its target, and its press
/// wash and focus ring are the cell's shape.
///
/// ```dart
/// MinimalNavigationRail(destinations: const [MinimalNavItem(LucideIcons.inbox, 'Inbox'), MinimalNavItem(LucideIcons.folder, 'Projects')], selectedIndex: tab, onDestinationSelected: setTab)
/// ```
class MinimalNavigationRail extends StatelessWidget {
  /// A rail of [destinations].
  const MinimalNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.leading,
    this.trailing,
  });

  /// The destinations, top to bottom.
  final List<MinimalNavItem> destinations;

  /// The current destination.
  final int selectedIndex;

  /// Reports the destination pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// Above the destinations: the create action, the app's mark.
  final Widget? leading;

  /// At the rail's foot: the account, settings.
  final Widget? trailing;

  /// The rail's width at the default text size.
  static const double width = 72;

  /// The minimum size of a destination cell.
  static const double cell = 56;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final cellWidth = minimalRailCellWidth(context, destinations);
    final shape = t.shapes.small;
    final select = onDestinationSelected;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final lead = leading;
    final trail = trailing;
    return Container(
      width: cellWidth + width - cell,
      decoration: BoxDecoration(
        color: t.card,
        border: rtl ? Border(left: t.rule) : Border(right: t.rule),
      ),
      padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s12),
      child: Column(
        children: [
          if (lead != null) ...[lead, const MinimalGap(MinimalSpacing.s12)],
          // The places stand at the top and the foot at the bottom; when
          // large text makes them taller than the rail, they scroll.
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              // Cut a scrolled run past the rail's room, but not a place's
              // focus ring, drawn outside its cell.
              child: ClipRect(
                clipper: const MinimalRingRoom(),
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  child: _walk(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: MinimalSpacing.s4,
                            ),
                            child: _RailCell(
                              width: cellWidth, // A tab's walkthrough key finds it in the rail too.
                              key: destinations[i].key,
                              item: destinations[i],
                              selected: i == selectedIndex,
                              shape: shape,
                              onPressed: select == null
                                  ? null
                                  : () => select(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ?trail,
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MinimalNavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      );
  }
}

class _RailCell extends StatelessWidget {
  const _RailCell({
    super.key,
    required this.item,
    required this.width,
    required this.selected,
    required this.shape,
    required this.onPressed,
  });

  final MinimalNavItem item;
  final double width;
  final bool selected;
  final OutlinedBorder shape;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => MinimalPressable(
    onPressed: onPressed,
    selected: selected,
    shape: shape,
    semanticLabel: item.label ?? item.semanticLabel,
    // The current place's ink fades in, the last one's out.
    child: MinimalRailFace(item: item, selected: selected, width: width),
  );
}

/// A titled run of a [MinimalNavigationDrawer]'s destinations ("Workspace",
/// "Your teams"); a null [title] prints none.
@immutable
class MinimalNavigationSection {
  /// A titled group of [destinations] in a drawer.
  const MinimalNavigationSection({this.title, required this.destinations});

  /// What the group is; null for an untitled group.
  final String? title;

  /// Its destinations, top to bottom.
  final List<MinimalNavItem> destinations;
}

/// The app's places as a sidebar for a wide window, the way a desk tool
/// lays them out: [header] on top (the workspace, a search), then
/// [sections] of 32 px rows — a 16 px glyph and the label — inset from the
/// sidebar's edges; [footer] at the foot. A hairline runs down its end. The
/// current row is said in type alone: its glyph and label in the full ink,
/// the label at medium weight, the rest in the muted ink; nothing behind it.
///
/// [selectedIndex] counts the destinations of every section in order. The
/// arrow keys walk the rows; each row's press wash and focus ring take the
/// row's own shape.
///
/// ```dart
/// MinimalNavigationDrawer(sections: const [MinimalNavigationSection(destinations: [MinimalNavItem(LucideIcons.inbox, 'Inbox'), MinimalNavItem(LucideIcons.listTodo, 'My issues')])], selectedIndex: page, onDestinationSelected: setPage)
/// ```
class MinimalNavigationDrawer extends StatelessWidget {
  /// A drawer of [sections].
  const MinimalNavigationDrawer({
    super.key,
    required this.sections,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.width = 248,
  });

  /// The groups, top to bottom.
  final List<MinimalNavigationSection> sections;

  /// The current destination, counted across every section.
  final int selectedIndex;

  /// Reports the destination pressed, counted across every section.
  final ValueChanged<int>? onDestinationSelected;

  /// What stands over the sections: a workspace, a wordmark.
  final Widget? header;

  /// What stands under them: an account, settings.
  final Widget? footer;

  /// Its width.
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final select = onDestinationSelected;
    final head = header;
    final foot = footer;
    var index = 0;
    final rows = <Widget>[];
    for (final section in sections) {
      final title = section.title;
      if (title != null) {
        rows.add(
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              MinimalSpacing.s8,
              MinimalSpacing.s16,
              MinimalSpacing.s8,
              MinimalSpacing.s4,
            ),
            child: Semantics(
              container: true,
              header: true,
              child: Text(title, style: t.caption.medium.c(t.textTertiary)),
            ),
          ),
        );
      }
      for (final item in section.destinations) {
        final i = index++;
        rows.add(
          _DrawerRow(
            item: item,
            selected: i == selectedIndex,
            onPressed: select == null ? null : () => select(i),
          ),
        );
      }
    }
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: t.card,
        border: rtl ? Border(left: t.rule) : Border(right: t.rule),
      ),
      padding: EdgeInsets.fromLTRB(
        MinimalSpacing.s8,
        head == null ? MinimalSpacing.s8 : 0,
        MinimalSpacing.s8,
        MinimalSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The head stands in a band a page's bar tall, centred in it, so
          // it lines up with the bars of the panes beside the drawer.
          if (head != null)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: MinimalChromeMetrics.barHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [head],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: _walk(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows,
                ),
              ),
            ),
          ),
          ?foot,
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MinimalNavigationSection>('sections', sections))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(DoubleProperty('width', width, defaultValue: 248));
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final MinimalNavItem item;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MinimalSpacing.s2),
    child: MinimalPressable(
      onPressed: onPressed,
      selected: selected,
      shape: context.minimalTheme.shapes.small,
      focusInside: true,
      child: MinimalSidebarFace(item: item, selected: selected),
    ),
  );
}
