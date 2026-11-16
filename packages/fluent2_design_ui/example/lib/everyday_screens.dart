import 'package:flutter/widgets.dart';

import 'gallery_pages.dart';
import 'kit_gallery/kit.dart';

/// The ten everyday screens of the sample app, each the whole app opened at
/// that screen: Northwind's Home, Files, a new request and Settings, a pushed
/// page's top bar, a dialog, a sheet, the empty, error and loading states, a
/// conversation's composer and a menu.
///
/// A design review (and ui_core's checks) opens each one by day and by
/// night, left to right and right to left, at a phone's, a tablet's and a
/// desktop's width.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      for (final (id, page) in const [
        ('home', 'app-overview'),
        ('files', 'app-files'),
        ('request', 'app-request'),
        ('settings', 'app-settings'),
        ('top-bar', 'top-bar'),
        ('dialog', 'dialog'),
        ('sheet', 'sheet'),
        ('states', 'states'),
        ('composer', 'composer'),
        ('menu', 'menu'),
      ])
        (
          id: id,
          app: (brightness, direction) => _opened(page, brightness, direction),
        ),
    ];

/// The gallery's page [id] as its own app, in [brightness] and [direction]:
/// right to left, its words are Arabic.
Widget _opened(String id, Brightness brightness, TextDirection direction) {
  kitShownDirection = direction;
  final page = galleryPages.firstWhere((p) => p.id == id);
  return KeyedSubtree(
    key: ValueKey((id, brightness, direction)),
    child: page.build(brightness),
  );
}
