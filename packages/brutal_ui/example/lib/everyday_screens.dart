// Admit's everyday screens, each the whole app opened on it, by day or by
// night, left to right or right to left: what ui_core's sweep reads as
// everyday/<id>, at every width.
import 'package:flutter/widgets.dart';

import 'kit_gallery/admit/admit.dart';

/// The screens, by their ids in the look's decisions.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      (id: 'overview', app: (b, d) => _admit(AdmitPlace.overview, b, d)),
      (id: 'home', app: (b, d) => _admit(AdmitPlace.home, b, d)),
      (id: 'events', app: (b, d) => _admit(AdmitPlace.events, b, d)),
      (
        id: 'event',
        app: (b, d) => _admit(AdmitPlace.events, b, d, scene: AdmitScene.event),
      ),
      (
        id: 'filter',
        app: (b, d) =>
            _admit(AdmitPlace.events, b, d, scene: AdmitScene.filter),
      ),
      (
        id: 'checkout',
        app: (b, d) =>
            _admit(AdmitPlace.events, b, d, scene: AdmitScene.checkout),
      ),
      (id: 'tickets', app: (b, d) => _admit(AdmitPlace.tickets, b, d)),
      (
        id: 'ticket',
        app: (b, d) =>
            _admit(AdmitPlace.tickets, b, d, scene: AdmitScene.ticket),
      ),
      (
        id: 'cancel',
        app: (b, d) =>
            _admit(AdmitPlace.tickets, b, d, scene: AdmitScene.cancel),
      ),
      (id: 'settings', app: (b, d) => _admit(AdmitPlace.settings, b, d)),
      (
        id: 'search',
        app: (b, d) =>
            _admit(AdmitPlace.events, b, d, scene: AdmitScene.search),
      ),
      (
        id: 'search-none',
        app: (b, d) =>
            _admit(AdmitPlace.events, b, d, scene: AdmitScene.searchNone),
      ),
      (
        id: 'payment-failed',
        app: (b, d) =>
            _admit(AdmitPlace.events, b, d, scene: AdmitScene.paymentFailed),
      ),
    ];

/// Admit opened on [place] (in [scene]) by [brightness], in [direction].
Widget _admit(
  AdmitPlace place,
  Brightness brightness,
  TextDirection direction, {
  AdmitScene? scene,
}) => AdmitApp(
  initialPlace: place,
  initialScene: scene,
  initialAppearance: brightness == Brightness.dark
      ? AdmitAppearance.dark
      : AdmitAppearance.light,
  initialDirection: direction,
);
