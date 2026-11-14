import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';

/// One step of a [MinimalBreadcrumb]: its [label], whether it is an
/// identifier printed in mono (`HAB-4`, `#1047`), and where tapping it
/// goes.
///
/// ```dart
/// MinimalBreadcrumbItem('HAB-4', mono: true)
/// ```
@immutable
class MinimalBreadcrumbItem {
  /// A crumb saying [label].
  const MinimalBreadcrumbItem(this.label, {this.mono = false, this.onPressed});

  /// What it says.
  final String label;

  /// An identifier: printed in mono so ids read as data.
  final bool mono;

  /// Go to this step; null for a step that is only context. The last
  /// crumb is the current place and is never a control.
  final VoidCallback? onPressed;
}

/// Minimal's path line — `Habits / HAB-4`: where a record sits, the
/// ancestors in the quiet ink and tappable when they lead somewhere, a
/// faint slash between, the current step last in the ink. Identifiers
/// print in mono. It shortens with an ellipsis rather than wrapping. A
/// path with a tappable ancestor stands in a 44 px band, the least tap
/// target; a path of context alone is as tall as its text.
///
/// A pushed page's [MinimalAppBar] prints its own crumb from `parent:`;
/// this is the same line for anywhere else (a sheet's body, a list
/// header, a table's detail pane).
///
/// ```dart
/// MinimalBreadcrumb(crumbs: [MinimalBreadcrumbItem('Habits', onPressed: toHabits), MinimalBreadcrumbItem('HAB-4', mono: true)])
/// ```
class MinimalBreadcrumb extends StatelessWidget {
  /// The trail of [crumbs].
  const MinimalBreadcrumb({super.key, required this.crumbs});

  /// The path, outermost first; the last is the current place. An empty
  /// path prints nothing.
  final List<MinimalBreadcrumbItem> crumbs;

  @override
  Widget build(BuildContext context) {
    if (crumbs.isEmpty) return const SizedBox.shrink();
    final t = context.minimalTheme;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final type = t.bodySmall.copyWith(
      fontSize: MinimalControlMetrics.pillLabel,
    );
    TextStyle styleOf(MinimalBreadcrumbItem crumb, bool current) =>
        (crumb.mono
                ? t.mono.copyWith(fontSize: MinimalControlMetrics.pillLabel)
                : type)
            .c(current ? t.foreground : t.mutedForeground);
    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final slash = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinimalChromeMetrics.barCrumbGap,
      ),
      child: minimalCapLabel(Text('/', style: type.c(t.textTertiary))),
    );
    final slashWidth =
        widthOf('/', type) + 2 * MinimalChromeMetrics.barCrumbGap;
    final needs = [
      for (final (i, crumb) in crumbs.indexed)
        widthOf(crumb.label, styleOf(crumb, i == crumbs.length - 1)),
    ];
    final natural =
        needs.fold<double>(0, (sum, w) => sum + w) +
        (crumbs.length - 1) * slashWidth;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Only a path that does not fit shortens. The current step keeps
        // its whole label while it takes at most half the line; then the
        // LONGEST steps shorten first, all to one common width, so a short
        // ancestor (`Orders`) is never cut while a long one runs on.
        final max = constraints.maxWidth;
        final keepCurrent = needs.last <= max / 2;
        var cap = double.infinity;
        if (natural > max) {
          var room = max - (crumbs.length - 1) * slashWidth;
          if (keepCurrent) room -= needs.last;
          final sorted = [
            for (final (i, need) in needs.indexed)
              if (!(i == needs.length - 1 && keepCurrent)) need,
          ]..sort();
          var left = sorted.length;
          for (final need in sorted) {
            if (need * left <= room) {
              room -= need;
              left -= 1;
            } else {
              cap = room / left;
              break;
            }
          }
          // Sub-pixel text metrics: leave a hair so nothing overflows.
          cap = (cap - 1).clamp(0, double.infinity);
        }
        final children = <Widget>[];
        for (final (i, crumb) in crumbs.indexed) {
          final current = i == crumbs.length - 1;
          if (i > 0) children.add(ExcludeSemantics(child: slash));
          Widget label = Text(
            crumb.label,
            style: styleOf(crumb, current),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // A shortened step ends at its ellipsis, so the slash after it
            // keeps the same gap as every other.
            textWidthBasis: TextWidthBasis.longestLine,
          );
          // By its capitals, as every label in the bar beside it.
          label = minimalCapLabel(label);
          final onPressed = crumb.onPressed;
          if (!current && onPressed != null) {
            label = MinimalPressable(
              onPressed: onPressed,
              shape: t.shapes.mark,
              semanticLabel: crumb.label,
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: MinimalSpacing.s4,
                  ),
                  child: label,
                ),
              ),
            );
          } else if (current) {
            label = Semantics(
              label: crumb.label,
              selected: true,
              child: ExcludeSemantics(child: label),
            );
          }
          children.add(
            needs[i] > cap && !(current && keepCurrent)
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cap),
                    child: label,
                  )
                : label,
          );
        }
        Widget line = Row(mainAxisSize: MainAxisSize.min, children: children);
        // A path with a way back stands in a 44 px band, so a crumb's tap
        // area reaches the full minimum above and below its text.
        if (crumbs.any((crumb) => crumb.onPressed != null)) {
          line = ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MinimalLayout.minHitTarget,
            ),
            child: line,
          );
        }
        return Semantics(
          container: true,
          label: MinimalLocalizations.of(context).breadcrumb,
          explicitChildNodes: true,
          child: line,
        );
      },
    );
  }
}
