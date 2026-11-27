// The Studio gallery: Roomtone, a podcast player and recorder set in Studio, with the look's Overview, then Home,
// Library, Record and Settings. Run it with `flutter run -t lib/gallery.dart`; lib/main.dart is the example app.
// The screens are moved between by the look's own navigation (the key bank on a phone, the rail from 600, the side panel from 1024).
// The Overview ends in the index of every part's page. A link opens it as the looks' galleries share:
// `/#/<page>?theme=dark&dir=rtl&text=200`, where the page is a part's page by its id (`buttons`, `fields`,
// `choices`...) or a screen by its name (`overview`, `home`, `library`, `record`, `settings`), or a scene of one
// (`/#/scene/episode`, which `id=sr-7` points at one episode, as a shared link does; also `search`, `searchEmpty`,
// `downloadsEmpty`, `publish`, `uploadFailed`, `discard`, `export`); `theme=dark` at night, `dir=rtl` right to left, `text=200` the words at twice the size,
// `density=comfortable|compact` that density. `?slow=8` runs every animation eight times slower; `?a11y=1` turns the
// semantics on from the start.
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

import 'gallery_pages.dart';
import 'kit_gallery/roomtone/roomtone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The face before the first frame: on the web the words never flash in a fallback face.
  await studioLoadFonts();
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
      RoomtoneScene.values.where((s) => s.name == name).firstOrNull,
      null,
    ),
    [final id, ...] when galleryPages.any((p) => p.id == id) => (
      null,
      null,
      id,
    ),
    [final name, ...] => (
      RoomtonePlace.values.where((p) => p.name == name).firstOrNull,
      null,
      null,
    ),
    _ => (null, null, null),
  };
  final text = double.tryParse(query['text'] ?? '');
  timeDilation = double.tryParse(query['slow'] ?? '') ?? 1;
  if (query['a11y'] == '1') WidgetsBinding.instance.ensureSemantics();
  final app = RoomtoneApp(
    initialPlace:
        place ??
        switch (scene) {
          RoomtoneScene.episode ||
          RoomtoneScene.search ||
          RoomtoneScene.searchEmpty ||
          RoomtoneScene.downloadsEmpty => RoomtonePlace.library,
          RoomtoneScene.publish ||
          RoomtoneScene.uploadFailed ||
          RoomtoneScene.discard ||
          RoomtoneScene.export => RoomtonePlace.record,
          null => RoomtonePlace.overview,
        },
    initialScene: scene,
    initialEpisodeId: query['id'],
    initialAppearance: query['theme'] == 'dark'
        ? RoomtoneAppearance.dark
        : RoomtoneAppearance.light,
    initialDirection: query['dir'] == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr,
    initialDensity: switch (query['density']) {
      'comfortable' => StudioDensity.comfortable,
      'compact' => StudioDensity.compact,
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
