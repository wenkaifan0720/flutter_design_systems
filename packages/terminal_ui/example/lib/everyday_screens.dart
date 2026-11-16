// slipway's everyday screens, each as an app in a brightness and a
// direction: what ui_core's sweep and the screens tests render.
import 'package:flutter/widgets.dart';

import 'kit_gallery/slipway.dart';

/// slipway's screens, by id.
final List<
  ({
    String id,
    Widget Function(Brightness brightness, TextDirection direction) app,
  })
>
everydayScreens = [
  for (final (id, place) in const [
    ('home', SlipwayPlace.home),
    ('runs', SlipwayPlace.runs),
    ('run', SlipwayPlace.run),
    ('palette', SlipwayPlace.palette),
    ('deploy', SlipwayPlace.deploy),
    ('settings', SlipwayPlace.settings),
    ('diff', SlipwayPlace.diff),
    ('search', SlipwayPlace.search),
    ('confirm', SlipwayPlace.confirm),
    ('desk', SlipwayPlace.desk),
  ])
    (
      id: id,
      app: (Brightness brightness, TextDirection direction) =>
          slipwayApp(brightness, direction: direction, place: place),
    ),
];
