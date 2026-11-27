import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'face.dart';

/// Marks the band a screen or a sheet stands its footer in, so a bar that
/// also asks for a band of its own there is caught: the two would draw two
/// hairlines and inset the bar twice. Plumbing of the components; pages never
/// place one.
class FrostedFooterBand extends InheritedWidget {
  /// Creates a [FrostedFooterBand].
  const FrostedFooterBand({required super.child, super.key});

  /// Whether [context] stands in a screen's or a sheet's footer band.
  static bool around(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FrostedFooterBand>() != null;

  @override
  bool updateShouldNotify(FrostedFooterBand oldWidget) => false;
}

/// Marks what a screen or a sheet stands over its bottom edge (the footer's
/// band, a floating bar), so the toasts stand above it rather than over its
/// buttons: ui_core's [RawToasterKeepClear] round it, which follows the band
/// as it moves and lets go as it leaves. Plumbing of the components; pages
/// never place one.
class FrostedBottomStand extends StatelessWidget {
  /// Creates a [FrostedBottomStand].
  const FrostedBottomStand({required this.child, super.key});

  /// What stands at the foot.
  final Widget child;

  @override
  Widget build(BuildContext context) => RawToasterKeepClear(child: child);
}

/// The glass a footer stands on (a screen's, a docked action bar's): the
/// bar's glass, edged on top by the lit hairline as a phone's bar is at its
/// foot, the hairline inside [padding]'s top. The page passes under it,
/// blurred; nothing fades it out and no band of the canvas hides it.
/// Plumbing of the components; pages never place one.
class FrostedFootGlass extends StatelessWidget {
  /// Creates a [FrostedFootGlass].
  const FrostedFootGlass({
    required this.padding,
    required this.child,
    super.key,
  });

  /// The room round [child], the hairline counted in its top.
  final EdgeInsets padding;

  /// What stands on the glass.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return FrostedFace(
      material: FrostedMaterial.bar,
      radius: BorderRadius.zero,
      edge: frostedLitEdge(t, t.colorScheme.border),
      edges: const EdgeInsets.only(top: FrostedStrokes.regular),
      ring: const Color(0x00000000),
      sheen: const Color(0x00000000),
      padding: padding.copyWith(
        top: (padding.top - FrostedStrokes.regular).clamp(0.0, double.infinity),
      ),
      child: child,
    );
  }
}
