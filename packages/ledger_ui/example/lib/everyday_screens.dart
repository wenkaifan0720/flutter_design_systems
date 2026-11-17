// Quill's ten everyday screens, each the whole app opened on it, by day or by
// night, left to right or right to left (in Hebrew): what ui_core's sweep
// reads as everyday/<id>, at every width.
import 'package:flutter/widgets.dart';

import 'kit_gallery/quill/quill.dart';

/// The ten screens, by their ids in the look's decisions.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      (id: 'home', app: (b, d) => _quill(QuillPage.home, b, d)),
      (id: 'register', app: (b, d) => _quill(QuillPage.register, b, d)),
      (
        id: 'register-searching',
        app: (b, d) =>
            _quill(QuillPage.register, b, d, scene: QuillScene.searching),
      ),
      (
        id: 'register-nothing-found',
        app: (b, d) =>
            _quill(QuillPage.register, b, d, scene: QuillScene.nothingFound),
      ),
      (
        id: 'register-cant-load',
        app: (b, d) => _quill(QuillPage.register, b, d, offline: true),
      ),
      (
        id: 'receipt',
        app: (b, d) =>
            _quill(QuillPage.register, b, d, scene: QuillScene.receipt),
      ),
      (
        id: 'new-entry',
        app: (b, d) => _quill(QuillPage.home, b, d, scene: QuillScene.newEntry),
      ),
      (id: 'settings', app: (b, d) => _quill(QuillPage.settings, b, d)),
      (
        id: 'sign-out',
        app: (b, d) =>
            _quill(QuillPage.settings, b, d, scene: QuillScene.signOut),
      ),
      (
        id: 'account',
        app: (b, d) => _quill(QuillPage.home, b, d, scene: QuillScene.account),
      ),
    ];

/// Quill opened on [page] (in [scene]) by [brightness], in [direction].
Widget _quill(
  QuillPage page,
  Brightness brightness,
  TextDirection direction, {
  QuillScene? scene,
  bool offline = false,
}) => QuillApp(
  initialPage: page,
  initialScene: scene,
  registerOffline: offline,
  initialAppearance: brightness == Brightness.dark
      ? QuillAppearance.dark
      : QuillAppearance.light,
  initialDirection: direction,
);
