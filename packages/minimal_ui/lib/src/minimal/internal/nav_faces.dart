/// The faces of a place in Minimal's navigation (a bar's tab, a rail's
/// cell, a sidebar's row), shared by the standalone bar, rail and sidebar
/// and by the app shell, which paints them for the states it hands over.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';
import 'cap_label.dart';
import 'face.dart';
import '../components/nav_item.dart';

/// The rail's cell side for [items] at the text size in force: the 56 px
/// cell, wider when a label's longest word outgrows it at a large text size
/// (up to half the window).
double minimalRailCellWidth(BuildContext context, List<MinimalNavItem> items) {
  const cell = 56.0;
  final t = context.minimalTheme;
  const fontSize = MinimalChromeMetrics.tabLabel;
  final scaler = MediaQuery.textScalerOf(context);
  var cellWidth = cell;
  if (scaler.scale(fontSize) > fontSize) {
    final caption = t.caption.copyWith(fontSize: fontSize).medium;
    for (final item in items) {
      for (final word
          in item.label?.split(RegExp(r'\s+')) ?? const <String>[]) {
        final wordWidth = TextPainter.computeWidth(
          text: TextSpan(text: word, style: caption),
          textScaler: scaler,
          textDirection: Directionality.of(context),
          maxLines: 1,
        ).ceilToDouble();
        if (wordWidth > cellWidth) cellWidth = wordWidth;
      }
    }
    cellWidth = cellWidth.clamp(
      cell,
      math.max(cell, MediaQuery.sizeOf(context).width / 2),
    );
  }
  return cellWidth;
}

/// A bar's tab: the 20 px glyph over its 10.5 px label, the ink when
/// [selected], the quiet ink otherwise, fading between them.
class MinimalTabFace extends StatelessWidget {
  /// The tab face of [item].
  const MinimalTabFace({super.key, required this.item, required this.selected});

  /// The place.
  final MinimalNavItem item;

  /// Whether it is the current place.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final inkTo = selected ? t.foreground : t.mutedForeground;
    final label = item.label;
    return MinimalFace(
      height: MinimalChromeMetrics.tabHeight,
      ink: inkTo,
      builder: (context, lerped) {
        final ink = lerped ?? inkTo;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MinimalIcon(
              item.icon,
              size: MinimalChromeMetrics.tabIcon,
              color: ink,
            ),
            if (label != null) ...[
              const SizedBox(height: MinimalChromeMetrics.tabLabelGap),
              // The control announces the label.
              ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.medium.copyWith(
                    fontSize: MinimalChromeMetrics.tabLabel,
                    height: MinimalChromeMetrics.tabLabelLeading,
                    color: ink,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A rail's cell: the glyph over its label in a cell [width] wide and at
/// least 56 px tall, the label at medium weight when [selected].
class MinimalRailFace extends StatelessWidget {
  /// The rail face of [item].
  const MinimalRailFace({
    super.key,
    required this.item,
    required this.selected,
    required this.width,
  });

  /// The place.
  final MinimalNavItem item;

  /// Whether it is the current place.
  final bool selected;

  /// The cell's width ([minimalRailCellWidth]).
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final inkTo = selected ? t.foreground : t.mutedForeground;
    final label = item.label;
    final caption = t.caption.copyWith(fontSize: MinimalChromeMetrics.tabLabel);
    return MinimalFace(
      width: width,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s8),
      ink: inkTo,
      builder: (context, lerped) {
        final ink = lerped ?? inkTo;
        return ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MinimalIcon(
                item.icon,
                size: MinimalChromeMetrics.tabIcon,
                color: ink,
              ),
              if (label != null) ...[
                const MinimalGap(MinimalChromeMetrics.tabLabelGap),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: (selected ? caption.medium : caption).c(ink),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A sidebar's row: a 16 px glyph and the label on one line, a control
/// tall, the label at medium weight when [selected].
class MinimalSidebarFace extends StatelessWidget {
  /// The sidebar face of [item].
  const MinimalSidebarFace({
    super.key,
    required this.item,
    required this.selected,
  });

  /// The place.
  final MinimalNavItem item;

  /// Whether it is the current place.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final inkTo = selected ? t.foreground : t.mutedForeground;
    final label = item.label ?? item.semanticLabel ?? '';
    return MinimalFace(
      height: t.density.height(MinimalChromeMetrics.control),
      padding: const EdgeInsets.symmetric(horizontal: MinimalSpacing.s8),
      ink: inkTo,
      builder: (context, lerped) {
        final ink = lerped ?? inkTo;
        return Row(
          children: [
            MinimalIcon(item.icon, size: MinimalIconSize.i16, color: ink),
            const MinimalGap(MinimalSpacing.s8),
            Expanded(
              child: minimalCapLabel(
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (selected ? t.body.medium : t.body).c(ink),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
