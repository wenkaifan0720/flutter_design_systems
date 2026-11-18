// Simmer's everyday screens, each the whole app opened on it, by day or by
// night, left to right or right to left: what ui_core's sweep reads as
// everyday/<id>, at every width.
import 'package:flutter/widgets.dart';

import 'kit_gallery/simmer/simmer.dart';

/// The screens, by their ids in the look's decisions.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      (id: 'overview', app: (b, d) => _simmer(SimmerPlace.overview, b, d)),
      (id: 'home', app: (b, d) => _simmer(SimmerPlace.home, b, d)),
      (id: 'recipes', app: (b, d) => _simmer(SimmerPlace.recipes, b, d)),
      (
        id: 'recipe',
        app: (b, d) =>
            _simmer(SimmerScene.recipe.place, b, d, scene: SimmerScene.recipe),
      ),
      (
        id: 'filter',
        app: (b, d) =>
            _simmer(SimmerScene.filter.place, b, d, scene: SimmerScene.filter),
      ),
      (
        id: 'planner',
        app: (b, d) => _simmer(
          SimmerScene.planner.place,
          b,
          d,
          scene: SimmerScene.planner,
        ),
      ),
      (
        id: 'delete-plan',
        app: (b, d) => _simmer(
          SimmerScene.deletePlan.place,
          b,
          d,
          scene: SimmerScene.deletePlan,
        ),
      ),
      (id: 'shopping', app: (b, d) => _simmer(SimmerPlace.shopping, b, d)),
      (
        id: 'search',
        app: (b, d) =>
            _simmer(SimmerScene.search.place, b, d, scene: SimmerScene.search),
      ),
      (
        id: 'search-none',
        app: (b, d) => _simmer(
          SimmerScene.searchNone.place,
          b,
          d,
          scene: SimmerScene.searchNone,
        ),
      ),
      (id: 'settings', app: (b, d) => _simmer(SimmerPlace.settings, b, d)),
      (
        id: 'sync-failed',
        app: (b, d) => _simmer(
          SimmerScene.syncFailed.place,
          b,
          d,
          scene: SimmerScene.syncFailed,
        ),
      ),
      (
        id: 'empty',
        app: (b, d) => _simmer(
          SimmerScene.emptyList.place,
          b,
          d,
          scene: SimmerScene.emptyList,
        ),
      ),
    ];

/// Simmer opened on [place] (in [scene]) by [brightness], in [direction].
Widget _simmer(
  SimmerPlace place,
  Brightness brightness,
  TextDirection direction, {
  SimmerScene? scene,
}) => SimmerApp(
  initialPlace: place,
  initialScene: scene,
  initialAppearance: brightness == Brightness.dark
      ? SimmerAppearance.dark
      : SimmerAppearance.light,
  initialDirection: direction,
);
