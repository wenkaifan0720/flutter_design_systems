// Steady's everyday screens, each the whole app opened on it, by day or by
// night, left to right or right to left: what ui_core's sweep reads as
// everyday/<id>, at every width.
import 'package:flutter/widgets.dart';

import 'kit_gallery/steady/steady.dart';

/// The screens, by their ids in the look's decisions.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      (id: 'overview', app: (b, d) => _steady(SteadyPlace.overview, b, d)),
      (id: 'today', app: (b, d) => _steady(SteadyPlace.today, b, d)),
      (id: 'habits', app: (b, d) => _steady(SteadyPlace.habits, b, d)),
      (
        id: 'habit',
        app: (b, d) =>
            _steady(SteadyScene.habit.place, b, d, scene: SteadyScene.habit),
      ),
      (
        id: 'edit-habit',
        app: (b, d) => _steady(
          SteadyScene.editHabit.place,
          b,
          d,
          scene: SteadyScene.editHabit,
        ),
      ),
      (
        id: 'delete-habit',
        app: (b, d) => _steady(
          SteadyScene.deleteHabit.place,
          b,
          d,
          scene: SteadyScene.deleteHabit,
        ),
      ),
      (
        id: 'reminder',
        app: (b, d) => _steady(
          SteadyScene.reminder.place,
          b,
          d,
          scene: SteadyScene.reminder,
        ),
      ),
      (id: 'settings', app: (b, d) => _steady(SteadyPlace.settings, b, d)),
      for (final (id, scene) in const [
        ('check-in', SteadyScene.checkIn),
        ('search', SteadyScene.search),
        ('search-empty', SteadyScene.searchEmpty),
        ('sync-failed', SteadyScene.syncFailed),
        ('empty', SteadyScene.empty),
      ])
        (id: id, app: (b, d) => _steady(scene.place, b, d, scene: scene)),
    ];

/// Steady opened on [place] (in [scene]) by [brightness], in [direction].
Widget _steady(
  SteadyPlace place,
  Brightness brightness,
  TextDirection direction, {
  SteadyScene? scene,
}) => SteadyApp(
  initialPlace: place,
  initialScene: scene,
  initialAppearance: brightness == Brightness.dark
      ? SteadyAppearance.dark
      : SteadyAppearance.light,
  initialDirection: direction,
);
