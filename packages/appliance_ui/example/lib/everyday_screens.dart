// Larder's everyday screens, each the whole app opened on it, by day or by
// night, left to right or right to left, at every width: the screens the
// screen tests and goldens open, by id.
import 'package:flutter/widgets.dart';

import 'kit_gallery/larder/larder.dart';

/// The screens, each by its id.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      (id: 'overview', app: (b, d) => _larder(LarderPlace.overview, b, d)),
      (id: 'home', app: (b, d) => _larder(LarderPlace.home, b, d)),
      (id: 'shop', app: (b, d) => _larder(LarderPlace.shop, b, d)),
      (
        id: 'product',
        app: (b, d) =>
            _larder(LarderPlace.shop, b, d, scene: LarderScene.product),
      ),
      (
        id: 'filter',
        app: (b, d) =>
            _larder(LarderPlace.shop, b, d, scene: LarderScene.filter),
      ),
      (id: 'basket', app: (b, d) => _larder(LarderPlace.basket, b, d)),
      (
        id: 'checkout',
        app: (b, d) =>
            _larder(LarderPlace.basket, b, d, scene: LarderScene.checkout),
      ),
      (
        id: 'remove',
        app: (b, d) =>
            _larder(LarderPlace.basket, b, d, scene: LarderScene.remove),
      ),
      (
        id: 'paymentFailed',
        app: (b, d) =>
            _larder(LarderPlace.basket, b, d, scene: LarderScene.paymentFailed),
      ),
      (
        id: 'emptyBasket',
        app: (b, d) =>
            _larder(LarderPlace.basket, b, d, scene: LarderScene.emptyBasket),
      ),
      (id: 'orders', app: (b, d) => _larder(LarderPlace.orders, b, d)),
      (
        id: 'order',
        app: (b, d) =>
            _larder(LarderPlace.orders, b, d, scene: LarderScene.order),
      ),
      (
        id: 'search',
        app: (b, d) =>
            _larder(LarderPlace.home, b, d, scene: LarderScene.search),
      ),
      (
        id: 'searchEmpty',
        app: (b, d) =>
            _larder(LarderPlace.home, b, d, scene: LarderScene.searchEmpty),
      ),
      (id: 'settings', app: (b, d) => _larder(LarderPlace.settings, b, d)),
    ];

/// Larder opened on [place] (in [scene]) by [brightness], in [direction].
Widget _larder(
  LarderPlace place,
  Brightness brightness,
  TextDirection direction, {
  LarderScene? scene,
}) => LarderApp(
  initialPlace: place,
  initialScene: scene,
  initialAppearance: brightness == Brightness.dark
      ? LarderAppearance.dark
      : LarderAppearance.light,
  initialDirection: direction,
);
