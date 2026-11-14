// Quill, a household ledger built on Ledger: the look's Overview, then Home, the Register, a new entry and Settings,
// moved between by the look's own navigation (the tab bar on a phone, the rail on a tablet, the side bar from 1024).
// The Overview ends in the index of every part's page. A link opens it as the looks' galleries share:
// `/#/<page>?theme=dark&dir=rtl&text=200`, where the page is a part's page by its id (`inputs`, `choices`, `commit`...),
// as the index opens it, or a screen by its name (`overview`, `home`, `settings`; `/#/screen/register` for the
// Register, whose name a part's page shares); `theme=dark` at night, `dir=rtl` right to left, `text=200` the words at
// twice the size. The older `?page=`, `?part=<id>`, `?dark=1`, `?rtl=1` and
// `?text=2` still read. `?density=comfortable|compact` sets that density; Settings changes them afterwards.
// `?slow=8` runs every animation eight times slower, to see one mid-way;
// `?a11y=1` turns the semantics on from the start, as a screen reader would. `?keylines=1` draws
// ui_core's keyline sheet over it (each region outlined, its leading keylines blue, its trailing green, an edge off
// them red), measured as it is laid out.
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ui_core/alignment.dart';

import 'gallery_pages.dart';
import 'kit_gallery/quill/quill.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame: on the web the words never flash in a fallback face.
  await ledgerLoadFonts();
  // The shared link's page and settings ride in the hash (`/#/inputs?theme=dark`); the older ones in the query.
  final hash = Uri.base.fragment.startsWith('/')
      ? Uri.parse(Uri.base.fragment)
      : null;
  final query = {...Uri.base.queryParameters, ...?hash?.queryParameters};
  final (screen, part) = switch (hash?.pathSegments
          .where((s) => s.isNotEmpty)
          .toList() ??
      const <String>[]) {
    ['screen', final name, ...] => (name, null),
    ['part', final id, ...] => (null, id),
    [final id, ...] when galleryPages.any((p) => p.id == id) => (null, id),
    [final name, ...] => (name, null),
    _ => (query['page'], query['part']),
  };
  final text = double.tryParse(query['text'] ?? '');
  timeDilation = double.tryParse(query['slow'] ?? '') ?? 1;
  if (query['a11y'] == '1') WidgetsBinding.instance.ensureSemantics();
  final app = QuillApp(
    initialPage: QuillPage.values.firstWhere(
      (p) => p.name == screen,
      orElse: () => QuillPage.overview,
    ),
    initialAppearance: query['theme'] == 'dark' || query['dark'] == '1'
        ? QuillAppearance.dark
        : QuillAppearance.light,
    initialDensity: LedgerDensity.values
        .where((d) => d.name == query['density'])
        .firstOrNull,
    initialDirection: query['dir'] == 'rtl' || query['rtl'] == '1'
        ? TextDirection.rtl
        : TextDirection.ltr,
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
              check: const DesignKeylineCheck(look: 'Ledger'),
              child: app,
            ),
          )
        : app,
  );
}
