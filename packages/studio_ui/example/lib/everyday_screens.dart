// Roomtone's everyday screens, each the whole app opened on it, by day or by
// night, left to right or right to left: what ui_core's sweep reads as
// everyday/<id>, at every width.
import 'package:flutter/widgets.dart';

import 'kit_gallery/roomtone/roomtone.dart';

/// The screens, by their ids in the look's decisions.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      (id: 'overview', app: (b, d) => _roomtone(RoomtonePlace.overview, b, d)),
      (id: 'home', app: (b, d) => _roomtone(RoomtonePlace.home, b, d)),
      (id: 'library', app: (b, d) => _roomtone(RoomtonePlace.library, b, d)),
      (
        id: 'episode',
        app: (b, d) => _roomtone(
          RoomtonePlace.library,
          b,
          d,
          scene: RoomtoneScene.episode,
        ),
      ),
      (id: 'record', app: (b, d) => _roomtone(RoomtonePlace.record, b, d)),
      (id: 'settings', app: (b, d) => _roomtone(RoomtonePlace.settings, b, d)),
      (
        id: 'publish',
        app: (b, d) =>
            _roomtone(RoomtonePlace.record, b, d, scene: RoomtoneScene.publish),
      ),
      (
        id: 'search',
        app: (b, d) =>
            _roomtone(RoomtonePlace.library, b, d, scene: RoomtoneScene.search),
      ),
      (
        id: 'search-empty',
        app: (b, d) => _roomtone(
          RoomtonePlace.library,
          b,
          d,
          scene: RoomtoneScene.searchEmpty,
        ),
      ),
      (
        id: 'discard',
        app: (b, d) =>
            _roomtone(RoomtonePlace.record, b, d, scene: RoomtoneScene.discard),
      ),
      (
        id: 'export',
        app: (b, d) =>
            _roomtone(RoomtonePlace.record, b, d, scene: RoomtoneScene.export),
      ),
      (
        id: 'upload-failed',
        app: (b, d) => _roomtone(
          RoomtonePlace.record,
          b,
          d,
          scene: RoomtoneScene.uploadFailed,
        ),
      ),
      (
        id: 'downloads-empty',
        app: (b, d) => _roomtone(
          RoomtonePlace.library,
          b,
          d,
          scene: RoomtoneScene.downloadsEmpty,
        ),
      ),
    ];

/// Roomtone opened on [place] (in [scene]) by [brightness], in [direction].
Widget _roomtone(
  RoomtonePlace place,
  Brightness brightness,
  TextDirection direction, {
  RoomtoneScene? scene,
}) => RoomtoneApp(
  initialPlace: place,
  initialScene: scene,
  initialAppearance: brightness == Brightness.dark
      ? RoomtoneAppearance.dark
      : RoomtoneAppearance.light,
  initialDirection: direction,
);
