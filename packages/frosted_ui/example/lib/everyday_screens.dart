// Frosted's ten everyday screens, each the whole gallery app opened at that
// screen, by day or by night, either way round: Harbor's Activity (on a phone
// and, at 1440, with its sidebar and detail pane: one screen at two widths),
// a transaction, Harbor's Settings, and the gallery's forms, sign-in fields,
// sheets, dialogs, states and menus. ui_core's sweep reads this list, and
// `runApp(everydayScreens.first.app(Brightness.light, TextDirection.ltr))`
// opens one by hand.
import 'package:flutter/widgets.dart';

import 'gallery.dart';

/// One everyday screen: its id and the app opened at it.
typedef EverydayScreen = ({
  String id,
  Widget Function(Brightness brightness, TextDirection direction) app,
});

/// The ten screens, as the gallery's links open them.
final everydayScreens = <EverydayScreen>[
  (id: 'harbor-activity', app: (b, d) => _open('harbor', b, d)),
  (
    id: 'harbor-transaction',
    app: (b, d) => _open('harbor', b, d, screen: 'transaction'),
  ),
  (
    id: 'harbor-settings',
    app: (b, d) => _open('harbor', b, d, screen: 'settings'),
  ),
  for (final page in ['forms', 'entry', 'sheet', 'dialog', 'states', 'menu'])
    (id: page, app: (b, d) => _open(page, b, d)),
];

/// The gallery opened at [page], in [brightness] and [direction].
Widget _open(
  String page,
  Brightness brightness,
  TextDirection direction, {
  String? screen,
}) {
  final modes = {
    if (brightness == Brightness.dark) 'theme': 'dark',
    if (direction == TextDirection.rtl) 'dir': 'rtl',
    'screen': ?screen,
  };
  final link = Uri(
    path: '/$page',
    queryParameters: modes.isEmpty ? null : modes,
  );
  return GalleryApp(link: '$link');
}
