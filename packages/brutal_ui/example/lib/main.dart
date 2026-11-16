// Admit, a city's week of tickets set in Brutal: the look's Overview, then Home, Events, Tickets and Settings, moved
// between by the look's own navigation (the bottom bar on a phone, the rail from 600, the side list from 1024). The
// Overview ends in the index of every part's page. A link opens it as the looks' galleries share:
// `/#/<page>?theme=dark&dir=rtl&text=200`, where the page is a part's page by its id (`buttons`, `fields`,
// `choices`...) or a screen by its name (`overview`, `home`, `events`, `tickets`, `settings`), or a scene of one
// (`/#/scene/checkout`, `event`, `filter`, `ticket`, `cancel`, `search`, `searchNone`, `paymentFailed`);
// `theme=dark` at night, `dir=rtl` right to left, `text=200` the words at twice the size,
// `density=comfortable|compact` that density. `?slow=8` runs every animation eight times slower; `?a11y=1` turns the
// semantics on from the start; `?keylines=1` draws ui_core's keyline sheet over it.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';
import 'package:ui_core/alignment.dart';

import 'gallery_pages.dart';
import 'kit_gallery/admit/admit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The face before the first frame: on the web the words never flash in a fallback face.
  await brutalLoadFonts();
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
      AdmitScene.values.where((s) => s.name == name).firstOrNull,
      null,
    ),
    [final id, ...] when galleryPages.any((p) => p.id == id) => (
      null,
      null,
      id,
    ),
    [final name, ...] => (
      AdmitPlace.values.where((p) => p.name == name).firstOrNull,
      null,
      null,
    ),
    _ => (null, null, null),
  };
  final text = double.tryParse(query['text'] ?? '');
  timeDilation = double.tryParse(query['slow'] ?? '') ?? 1;
  if (query['a11y'] == '1') WidgetsBinding.instance.ensureSemantics();
  final app = AdmitApp(
    initialPlace:
        place ??
        switch (scene) {
          AdmitScene.ticket || AdmitScene.cancel => AdmitPlace.tickets,
          null => AdmitPlace.overview,
          _ => AdmitPlace.events,
        },
    initialScene: scene,
    initialAppearance: query['theme'] == 'dark'
        ? AdmitAppearance.dark
        : AdmitAppearance.light,
    initialDirection: query['dir'] == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr,
    initialDensity: switch (query['density']) {
      'comfortable' => BrutalDensity.comfortable,
      'compact' => BrutalDensity.compact,
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
  runApp(
    query['keylines'] == '1'
        ? Directionality(
            textDirection: TextDirection.ltr,
            child: DesignKeylineSheet(
              check: const DesignKeylineCheck(look: 'Brutal'),
              child: app,
            ),
          )
        : app,
  );
}
