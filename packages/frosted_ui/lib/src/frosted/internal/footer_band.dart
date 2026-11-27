import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
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

/// Marks the app shell's places, so a page's footer knows a tab bar stands
/// under it. Plumbing of the components; pages never place one.
class FrostedShellFoot extends InheritedWidget {
  /// Creates a [FrostedShellFoot].
  const FrostedShellFoot({
    required this.hideBarOnPush,
    required super.child,
    super.key,
  });

  /// Whether the shell's tab bar steps away while a page is pushed.
  final bool hideBarOnPush;

  /// Whether the shell's tab bar stands under the page at [context]: at a
  /// phone's or a tablet's width, on its place's [root] page, or on any page
  /// while the bar stays through a push.
  static bool barUnder(BuildContext context, {required bool root}) {
    final shell = context
        .dependOnInheritedWidgetOfExactType<FrostedShellFoot>();
    return shell != null &&
        !FrostedBreakpoints.isWide(context) &&
        (root || !shell.hideBarOnPush);
  }

  @override
  bool updateShouldNotify(FrostedShellFoot oldWidget) =>
      hideBarOnPush != oldWidget.hideBarOnPush;
}

/// The slab a footer floats on where its page doesn't own the window's foot:
/// over the app shell's tab bar on a phone, in the page's column at desktop
/// width. The tab bar's slab, as glass and as corners (the bar's glass lit
/// all round, its shadow, [FrostedChromeMetrics.slabRadius] at the extra
/// large corner), its acts [FrostedChromeMetrics.footSlabInset] in, so a row
/// of buttons stands it as tall as the tab bar. Plumbing of the components;
/// pages never place one.
class FrostedFootSlab extends StatelessWidget {
  /// Creates a [FrostedFootSlab].
  const FrostedFootSlab({required this.child, super.key});

  /// What stands on the slab.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return FrostedFace(
      material: FrostedMaterial.bar,
      radius: BorderRadius.circular(
        t.corner(RawCorner.extraLarge, FrostedChromeMetrics.slabRadius),
      ),
      edge: t.glass.edge,
      edges: const EdgeInsets.all(FrostedStrokes.regular),
      sheen: t.glass.rim,
      shadows: t.shadows.bar,
      // The edge counted in the room.
      padding: const EdgeInsets.all(
        FrostedChromeMetrics.footSlabInset - FrostedStrokes.regular,
      ),
      child: child,
    );
  }
}
