import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../../localizations.dart';
import '../../internal/cap.dart';
import '../../internal/chosen_plate.dart';
import '../../internal/dim.dart';
import '../../internal/bleed.dart';

// metric: how far past a scrolling strip's line its viewport stands: the
// chosen plate's lift (4 down, 12 blur, -4 spread) fades out about 15 under
// the plate, a tab's focus ring stands 4 out.
const double _stripReach = 16;

/// In-page tabs: peer section labels as a row of pills 40 tall, the current
/// one on the sidebar's lit pill (white at 80% under the rim and the
/// hairline edge, its word in the 600 ink), the rest bare in the quieter
/// ink. A row too long for its width scrolls sideways; with [expand] the
/// tabs share the width instead (a few short ones). A null [onChanged]
/// shows the choice inert. Read aloud as a group named [label], each tab a
/// button saying whether it is chosen. DERIVED: the source has no tab row;
/// the sidebar's current row (`.nav.on`) lends the chosen tab its face.
///
/// ```dart
/// FrostedTabBar(tabs: const ['Spending', 'Income', 'Transfers'], selectedIndex: tab, expand: true, onChanged: setTab)
/// ```
class FrostedTabBar extends StatelessWidget {
  /// Creates a [FrostedTabBar].
  const FrostedTabBar({
    required this.tabs,
    this.selectedIndex = 0,
    this.onChanged,
    this.label,
    this.expand = false,
    this.style,
    super.key,
  });

  /// The labels, in order.
  final List<String> tabs;

  /// The current tab.
  final int selectedIndex;

  /// What choosing a tab does with its index; null makes the row inert.
  final ValueChanged<int>? onChanged;

  /// What a screen reader calls the group.
  final String? label;

  /// Whether the tabs share the row's width rather than keeping their own.
  final bool expand;

  /// This bar's own style, over `FrostedThemeData.components.tabBar`: each
  /// tab's fill (selected for the chosen one), words, edge or side, overlay,
  /// shape, padding and least size, each per state.
  ///
  /// ```dart
  /// FrostedTabBar(
  ///   tabs: const ['Overview', 'Activity'],
  ///   selectedIndex: tab,
  ///   onChanged: setTab,
  ///   style: FrostedStyle(
  ///     fill: WidgetStateProperty.resolveWith(
  ///       (states) => states.contains(WidgetState.selected)
  ///           ? const Color(0xFFE8E6FF)
  ///           : null,
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final label = this.label ?? FrostedLocalizations.of(context).sections;
    final t = context.frostedTheme;
    final layers = FrostedStyleLayers(style, t.components.tabBar);
    final cut = layers.cut(FrostedCorners.full);
    const height = FrostedChromeMetrics.tabHeight;
    final corner = FrostedStyleLayers.radiusOf(cut, height, height / 2);
    Widget tab(int i) {
      final on = i == selectedIndex;
      Widget draw(Set<WidgetState> states) {
        final s = layers.at(states);
        final (edge, edges) = s.edgeOf(
          on ? t.glass.edge : null,
          FrostedStrokes.regular,
        );
        return s.least(
          SizedBox(
            height: height,
            child: FrostedFace(
              material: FrostedMaterial.paint,
              radius: BorderRadius.circular(corner),
              shape: cut,
              // The chosen tab stands on the look's chosen plate: thicker,
              // brighter glass raised off the row.
              color: s.fill ?? (on ? FrostedChosenPlate.fillOf(t) : null),
              wash: s.overlay,
              edge: edge,
              edges: edges,
              sheen: on ? FrostedChosenPlate.lightOf(t) : null,
              shadows: on && s.side == null
                  ? FrostedChosenPlate.shadowsOf(t)
                  : const <BoxShadow>[],
              padding:
                  s.padding?.resolve(Directionality.of(context)) ??
                  const EdgeInsets.symmetric(
                    horizontal: FrostedChromeMetrics.tabInset,
                  ),
              child: Center(
                child: FrostedEase<TextStyle>(
                  value: s.words(
                    on
                        ? t.textTheme.labelLarge.c(t.colorScheme.textPrimary)
                        : t.textTheme.link,
                  ),
                  lerp: FrostedEase.words,
                  builder: (context, words) => frostedCapCentred(
                    Text(
                      tabs[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: words,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return FrostedPressable(
        onPressed: onChanged == null ? null : () => onChanged!(i),
        label: tabs[i],
        role: FrostedPressRole.tab,
        selected: on,
        radius: corner,
        shape: cut,
        builder: (context, states, _) => draw(states),
      );
    }

    final row = expand
        ? Row(
            children: [
              for (var i = 0; i < tabs.length; i++) Expanded(child: tab(i)),
            ],
          )
        // The strip scrolls within its line, but the chosen plate's lift
        // and rim and a tab's focus ring reach past the line: its viewport
        // stands that far out on every side, so it clips only what scrolls
        // away, never the plate (cut flat at the strip's start and foot).
        : FrostedBleed(
            reach: _stripReach,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(_stripReach),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (var i = 0; i < tabs.length; i++) tab(i)],
              ),
            ),
          );
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: row,
    );
  }
}
