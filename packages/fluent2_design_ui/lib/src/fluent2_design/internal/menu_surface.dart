import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../styled.dart';
import '../theme.dart';

/// Fluent's menu panel round the rows a kit menu hands it (the menu bar's,
/// the split button's): the first layer's fill at the medium corner, a
/// stroke in dark, shadow16, 4 round the rows, between the menu's least and
/// most widths and no taller than the overlay allows (it scrolls past
/// that), fading in on the overlay's presence. Plumbing of the components;
/// pages never place one.
class Fluent2MenuSurface extends StatelessWidget {
  /// A menu panel round [items].
  const Fluent2MenuSurface({
    required this.info,
    required this.items,
    super.key,
  });

  /// Where the overlay stands and how much room it has.
  final DesignOverlayInfo info;

  /// The menu's rows, in order.
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final look = Fluent2StyleOf([t.menuTheme], const {});
    return FadeTransition(
      // The overlay's spring can pass 1: held to 0..1 for the fade.
      opacity: info.animation.drive(
        Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: Fluent2ChromeMetrics.menuMinWidth,
          maxWidth: math.min(
            Fluent2ChromeMetrics.menuMaxWidth,
            info.maxSize.width,
          ),
          maxHeight: info.maxSize.height,
        ),
        child: IntrinsicWidth(
          child: Fluent2Plate(
            fill: look.fill ?? t.colors.neutralBackground1,
            side: fluent2Rim(
              t,
              look,
              t.isDark ? t.colors.neutralStroke2 : t.colors.transparentStroke,
            ),
            radius: BorderRadius.circular(Fluent2Radius.medium),
            shape: look.shape,
            shadows: t.shadows.shadow16,
            padding:
                look.padding(Directionality.of(context)) ??
                const EdgeInsets.all(Fluent2ChromeMetrics.menuPadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
