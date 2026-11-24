/// Material Expressive's push and pop as a map an app puts in its own
/// `ThemeData`: [expressivePageTransitions]. In the main library, beside the
/// theme an app installs, so the one import an app takes reaches it;
/// [ExpressivePage] and its builder stay in the host layer.
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:material_ui/material_ui.dart'
    show PageTransitionsBuilder, PredictiveBackPageTransitionsBuilder;

import 'page.dart' show ExpressivePage, ExpressivePageTransitionsBuilder;

/// Material Expressive's push and pop for every platform, as a map of
/// widgets-level [PageTransitionsBuilder]s that fits the `PageTransitionsTheme`
/// of both Materials, Flutter's and material_ui's:
///
/// - macOS, Windows, Linux and Fuchsia (and the web on any of them):
///   [ExpressivePageTransitionsBuilder], the fade-forwards an
///   [ExpressivePage] pushes with;
/// - Android: Flutter's predictive back builder, whose push is
///   fade-forwards and whose back gesture is the platform's predictive back;
/// - iOS: the Cupertino slide, which carries the edge swipe-back itself, so
///   the entry needs no ui_core `rawSwipeBack` round it (that is for a
///   look whose own push replaces the slide; round this one it would add a
///   second edge gesture).
///
/// The look's own Material theme (`ExpressiveHost`'s) names it, which an app
/// on material_ui's `MaterialApp` reads. An app on Flutter's own
/// `MaterialApp`, as most are, pushes Flutter's `MaterialPageRoute`, which
/// reads only Flutter's theme (on a Mac it would play the Cupertino slide
/// across the window), so the app names the map in its own `ThemeData`:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: expressivePageTransitions,
///     ),
///   ),
///   builder: (context, child) => ExpressiveTheme(
///     data: ExpressiveThemeData.grove(Brightness.light),
///     child: child!,
///   ),
/// )
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> expressivePageTransitions =
    <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: ExpressivePageTransitionsBuilder(),
      TargetPlatform.windows: ExpressivePageTransitionsBuilder(),
      TargetPlatform.linux: ExpressivePageTransitionsBuilder(),
      TargetPlatform.fuchsia: ExpressivePageTransitionsBuilder(),
    };
