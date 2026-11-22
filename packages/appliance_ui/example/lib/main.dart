// Larder, a small kitchen and home goods shop set in Appliance: the look's Overview, then Home, Shop, Basket,
// Orders and Settings, moved between by the look's own navigation (the key strip on a phone, the rail from 600, the moulded
// side panel from 1024). The Overview ends in the index of every part's page. A link opens it as the looks'
// galleries share: `/#/<page>?theme=dark&dir=rtl&text=200`, where the page is a part's page by its id (`buttons`,
// `fields`, `choices`...) or a screen by its name (`overview`, `home`, `shop`, `basket`, `orders`, `settings`), or a
// scene of one (`/#/scene/product`, `filter`, `checkout`, `remove`, `order`, `search`, `searchEmpty`, `paymentFailed`,
// `emptyBasket`); `theme=dark` at night, `dir=rtl` right to left,
// `text=200` the words at twice the size, `density=comfortable|compact` that density. `?slow=8` runs every
// animation eight times slower; `?a11y=1` turns the semantics on from the start.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';

import 'gallery_pages.dart';
import 'kit_gallery/larder/larder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The face before the first frame: on the web the words never flash in a fallback face.
  await applianceLoadFonts();
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
      LarderScene.values.where((s) => s.name == name).firstOrNull,
      null,
    ),
    [final id, ...] when galleryPages.any((p) => p.id == id) => (
      null,
      null,
      id,
    ),
    [final name, ...] => (
      LarderPlace.values.where((p) => p.name == name).firstOrNull,
      null,
      null,
    ),
    _ => (null, null, null),
  };
  final text = double.tryParse(query['text'] ?? '');
  timeDilation = double.tryParse(query['slow'] ?? '') ?? 1;
  if (query['a11y'] == '1') WidgetsBinding.instance.ensureSemantics();
  final app = LarderApp(
    initialPlace:
        place ??
        switch (scene) {
          LarderScene.product || LarderScene.filter => LarderPlace.shop,
          LarderScene.checkout ||
          LarderScene.remove ||
          LarderScene.paymentFailed ||
          LarderScene.emptyBasket => LarderPlace.basket,
          LarderScene.order => LarderPlace.orders,
          LarderScene.search || LarderScene.searchEmpty => LarderPlace.home,
          null => LarderPlace.overview,
        },
    initialScene: scene,
    initialAppearance: query['theme'] == 'dark'
        ? LarderAppearance.dark
        : LarderAppearance.light,
    initialDirection: query['dir'] == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr,
    initialDensity: switch (query['density']) {
      'comfortable' => ApplianceDensity.comfortable,
      'compact' => ApplianceDensity.compact,
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
