// The ten everyday screens of Hearth, the gallery's app: each one is the whole app, opened at that screen, by day or
// by night and in either reading direction. A design review walks them, and ui_core's sweep checks every one at each
// width.
import 'package:flutter/widgets.dart';

import 'kit_gallery/hearth.dart';
import 'main.dart';

/// Hearth opened on [page] (one of [hearthScreens]), past it to [start].
Widget _hearth(
  String page,
  Brightness brightness,
  TextDirection direction, [
  HearthStart start = const HearthStart(),
]) => GalleryApp(
  initialPage: page,
  initialBrightness: brightness,
  initialCustom: GalleryCustom(rightToLeft: direction == TextDirection.rtl),
  initialStart: start,
);

/// The screens, by the ids the look's design decisions name them.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      // The room you are in, its lights, the house.
      (id: 'home', app: (b, dir) => _hearth('home', b, dir)),
      // Devices, searched for lamps.
      (
        id: 'devices-search',
        app: (b, dir) =>
            _hearth('list', b, dir, const HearthStart(search: 'lamp')),
      ),
      // A device's own page on a phone; beside the list from a tablet up.
      (
        id: 'device',
        app: (b, dir) =>
            _hearth('list', b, dir, const HearthStart(device: 'floor-lamp')),
      ),
      // A search that finds nothing.
      (
        id: 'no-match',
        app: (b, dir) =>
            _hearth('list', b, dir, const HearthStart(search: 'garage')),
      ),
      // Add a device, the dialog.
      (
        id: 'add-device',
        app: (b, dir) =>
            _hearth('list', b, dir, const HearthStart(adding: true)),
      ),
      // The shop's checkout.
      (id: 'checkout', app: (b, dir) => _hearth('checkout', b, dir)),
      // Account, saved with an email that can't be used.
      (
        id: 'account-email-error',
        app: (b, dir) => _hearth(
          'form',
          b,
          dir,
          const HearthStart(email: 'alex.morgan@hearth'),
        ),
      ),
      (id: 'settings', app: (b, dir) => _hearth('settings', b, dir)),
      // The look and feel: day and night and Customize, in a sheet on a phone or a tablet, at the pilaster's foot on
      // a desk.
      (
        id: 'look-and-feel',
        app: (b, dir) => _hearth('home', b, dir, const HearthStart(ways: true)),
      ),
      // Devices as it opens: at 1440 the pilaster, the list and the open device beside it.
      (id: 'devices', app: (b, dir) => _hearth('list', b, dir)),
    ];
