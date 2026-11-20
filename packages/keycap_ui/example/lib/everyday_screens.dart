// Jotter's everyday screens, each the whole app opened on it, by day or by
// night, left to right or right to left: what ui_core's sweep reads as
// everyday/<id>, at every width.
import 'package:flutter/widgets.dart';

import 'kit_gallery/jotter/jotter.dart';

/// Every everyday screen, by id.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      (id: 'overview', app: (b, d) => _jotter(JotterPlace.overview, b, d)),
      (id: 'home', app: (b, d) => _jotter(JotterPlace.home, b, d)),
      (id: 'notes', app: (b, d) => _jotter(JotterPlace.notes, b, d)),
      (
        id: 'editor',
        app: (b, d) =>
            _jotter(JotterPlace.notes, b, d, scene: JotterScene.editor),
      ),
      (id: 'folders', app: (b, d) => _jotter(JotterPlace.folders, b, d)),
      (id: 'settings', app: (b, d) => _jotter(JotterPlace.settings, b, d)),
      (
        id: 'delete',
        app: (b, d) =>
            _jotter(JotterPlace.notes, b, d, scene: JotterScene.delete),
      ),
      (
        id: 'move',
        app: (b, d) =>
            _jotter(JotterPlace.notes, b, d, scene: JotterScene.move),
      ),
      (
        id: 'share',
        app: (b, d) =>
            _jotter(JotterPlace.notes, b, d, scene: JotterScene.share),
      ),
      (
        id: 'search',
        app: (b, d) =>
            _jotter(JotterPlace.notes, b, d, scene: JotterScene.search),
      ),
      (
        id: 'search-none',
        app: (b, d) =>
            _jotter(JotterPlace.notes, b, d, scene: JotterScene.searchNone),
      ),
      (
        id: 'sync-error',
        app: (b, d) =>
            _jotter(JotterPlace.home, b, d, scene: JotterScene.syncError),
      ),
      (
        id: 'empty',
        app: (b, d) =>
            _jotter(JotterPlace.notes, b, d, scene: JotterScene.empty),
      ),
    ];

Widget _jotter(
  JotterPlace place,
  Brightness brightness,
  TextDirection direction, {
  JotterScene? scene,
}) => JotterApp(
  initialPlace: place,
  initialScene: scene,
  initialAppearance: brightness == Brightness.dark
      ? JotterAppearance.dark
      : JotterAppearance.light,
  initialDirection: direction,
);
