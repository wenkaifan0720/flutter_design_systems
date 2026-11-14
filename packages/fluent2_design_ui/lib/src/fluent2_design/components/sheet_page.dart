// The go_router page a sheet route is: host vocabulary (the package exports
// it from its host library, beside ui_core's host).
import 'package:material_ui/material_ui.dart' show MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../theme.dart';
import 'sheet.dart';

/// The go_router [Page] whose route is Fluent 2's page sheet, created on the
/// root navigator so it rises over the shell's bar. [drawer] stands it as
/// tall as its content on a phone and as the end drawer on the desktop;
/// [fullScreen] raises a full-screen cover on the ground instead, drawn as
/// a pushed page whose exit is the dismiss. Either publishes
/// `RoutePresentation.sheet` around its child, so the screen inside derives
/// its dismiss, or with [back] the way back.
///
/// ```dart
/// Fluent2SheetPage<void>(drawer: true, child: const SharePage())
/// ```
class Fluent2SheetPage<T> extends Page<T> {
  /// A sheet route's page showing [child].
  const Fluent2SheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    this.back = false,
    super.key,
    super.name,
  });

  /// What the sheet shows.
  final Widget child;

  /// As tall as its content on a phone; the end drawer on the desktop.
  final bool drawer;

  /// A full-screen cover: no overlay, no card.
  final bool fullScreen;

  /// Closes by the way back rather than the dismiss.
  final bool back;

  /// Whether the sheet page [context] stands in closes by the way back.
  static bool closesBack(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BackExit>() != null;

  @override
  Route<T> createRoute(BuildContext context) {
    Widget current(BuildContext sheetContext) {
      final page = ModalRoute.of(sheetContext)?.settings;
      final shown = page is Fluent2SheetPage ? page.child : child;
      return back ? _BackExit(child: shown) : shown;
    }

    if (fullScreen) {
      return MaterialPageRoute<T>(
        settings: this,
        fullscreenDialog: true,
        builder: (sheetContext) => RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: ColoredBox(
            color: sheetContext.fluent2Theme.background,
            child: current(sheetContext),
          ),
        ),
      );
    }
    return Fluent2Sheet.pageRoute<T>(
      context: context,
      settings: this,
      drawer: drawer,
      builder: current,
    );
  }
}

class _BackExit extends InheritedWidget {
  const _BackExit({required super.child});

  @override
  bool updateShouldNotify(_BackExit oldWidget) => false;
}
