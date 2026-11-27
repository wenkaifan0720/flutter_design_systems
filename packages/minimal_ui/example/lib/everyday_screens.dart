// The example's ten everyday screens: each is the whole app, opened at that screen, by day or by night and either way
// round (right to left, the gallery speaks Arabic).
import 'package:flutter/widgets.dart';

import 'gallery.dart';

/// Every everyday screen: its id (`?app=…&screen=<id>` opens it) and the app opened at it.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      // Ritual, the habit tracker.
      _at('habits', 'today'),
      _at('habits', 'habit'),
      _at('habits', 'new-habit'),
      _at('habits', 'archive'),
      _at('habits', 'habits'),
      _at('habits', 'settings'),
      // Tracker, the issue tracker.
      _at('issues', 'my-issues'),
      _at('issues', 'issue'),
      // Lund Bakery, the bakery's back office.
      _at('orders', 'orders'),
      _at('orders', 'products'),
    ];

/// [app] opened at [screen], as the link `?app=<app>&screen=<screen>` opens it.
({
  String id,
  Widget Function(Brightness brightness, TextDirection direction) app,
})
_at(String app, String screen) => (
  id: screen,
  app: (brightness, direction) => GalleryApp.at(
    Uri(
      queryParameters: {
        'app': app,
        'screen': screen,
        if (brightness == Brightness.dark) 'appearance': 'dark',
        if (direction == TextDirection.rtl) 'dir': 'rtl',
      },
    ),
  ),
);
