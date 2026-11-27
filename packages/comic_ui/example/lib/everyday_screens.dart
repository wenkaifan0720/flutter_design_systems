/// Comic's ten everyday screens: what an app printed in Comic shows most, each the whole example app opened at that
/// screen in a given brightness and direction. The design checks sweep them as `everyday/<id>`.
library;

import 'package:flutter/widgets.dart';

import 'gallery.dart';

/// Opens the example app at [page], by day or night, in [direction].
Widget _at(String page, Brightness brightness, TextDirection direction) =>
    GalleryApp(page: page, brightness: brightness, direction: direction);

/// The ten screens, by their gallery page ids.
final everydayScreens =
    <
      ({
        String id,
        Widget Function(Brightness brightness, TextDirection direction) app,
      })
    >[
      // Home: the issue's cover and a splash.
      (id: 'cover', app: (b, dir) => _at('cover', b, dir)),
      // A list: the library, a tier of covers with tabs.
      (id: 'list', app: (b, dir) => _at('list', b, dir)),
      // A form: the account, captioned, beside its facts.
      (id: 'form', app: (b, dir) => _at('form', b, dir)),
      // Settings: switch rows in two panels.
      (id: 'settings', app: (b, dir) => _at('settings', b, dir)),
      // A detail with choices: the order beside delivery and payment.
      (id: 'checkout', app: (b, dir) => _at('checkout', b, dir)),
      // Sheets and dialogs, opened for real.
      (id: 'dialogs', app: (b, dir) => _at('dialogs', b, dir)),
      // Empty, error, toast, snack bar and progress.
      (id: 'feedback', app: (b, dir) => _at('feedback', b, dir)),
      // Search, field states, a password and errors.
      (id: 'text-fields', app: (b, dir) => _at('text-fields', b, dir)),
      // Lists and a data table, at a desk's width too.
      (id: 'lists', app: (b, dir) => _at('lists', b, dir)),
      // Every press state of the act and the other buttons.
      (id: 'buttons', app: (b, dir) => _at('buttons', b, dir)),
    ];
