// The Clay gallery (`flutter run -t lib/gallery.dart`); the example app, lib/main.dart, is Shelf. Steady, a habits
// and wellbeing app set in Clay: the look's Overview, then Today, Habits and Settings, moved between by the look's own
// navigation (the dock on a phone, the rail from 600, the sidebar from 1024). The Overview ends in the index of every
// part's page. A link opens it as the looks' galleries share: `/#/<page>?theme=dark&dir=rtl`, where the page is a
// part's page by its id (`buttons`, `fields`, `choices`...) or a screen by its name (`overview`, `today`,
// `habits`, `settings`), or a scene of one (`/#/scene/habit`, `newHabit`, `editHabit`, `deleteHabit`,
// `reminder`, `checkIn`, `search`, `searchEmpty`, `syncFailed`, `empty`); `theme=dark` at night, `dir=rtl`
// right to left, `text=200` the words at twice the size, `density=comfortable|compact` that density. `?slow=8` runs
// every animation eight times slower; `?a11y=1` turns the semantics on from the start.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';

import 'gallery_pages.dart';
import 'kit_gallery/steady/steady.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The face before the first frame: on the web the words never flash in a fallback face.
  await clayLoadFonts();
  final hash = Uri.base.fragment.startsWith('/')
      ? Uri.parse(Uri.base.fragment)
      : null;
  final query = {...Uri.base.queryParameters, ...?hash?.queryParameters};
  final segments =
      hash?.pathSegments.where((s) => s.isNotEmpty).toList() ??
      const <String>[];
  final (place, scene, part) = switch (segments) {
    ['scene', final name, ...] => (
      null,
      SteadyScene.values.where((s) => s.name == name).firstOrNull,
      null,
    ),
    [final id, ...] when galleryPages.any((p) => p.id == id) => (
      null,
      null,
      id,
    ),
    [final name, ...] => (
      SteadyPlace.values.where((p) => p.name == name).firstOrNull,
      null,
      null,
    ),
    _ => (null, null, null),
  };
  final text = double.tryParse(query['text'] ?? '');
  timeDilation = double.tryParse(query['slow'] ?? '') ?? 1;
  if (query['a11y'] == '1') WidgetsBinding.instance.ensureSemantics();
  final app = SteadyApp(
    initialPlace:
        place ??
        switch (scene) {
          null => SteadyPlace.overview,
          final scene => scene.place,
        },
    initialScene: scene,
    initialAppearance: query['theme'] == 'dark'
        ? SteadyAppearance.dark
        : SteadyAppearance.light,
    initialDirection: query['dir'] == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr,
    initialDensity: switch (query['density']) {
      'comfortable' => ClayDensity.comfortable,
      'compact' => ClayDensity.compact,
      _ => null,
    },
    // `text=200` is a percentage, `text=2` a factor.
    textScale: text == null ? null : (text > 5 ? text / 100 : text),
    parts: [
      for (final page in galleryPages) (title: page.title, build: page.build),
    ],
    initialPart: switch (galleryPages.indexWhere((p) => p.id == part)) {
      -1 => null,
      final i => i,
    },
  );
  runApp(app);
}
