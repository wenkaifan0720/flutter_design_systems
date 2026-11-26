// Civic's gallery (flutter run -t lib/gallery.dart): Brindlemere parking
// permits, a public service of an invented city built on Civic: the look's Overview, then the service (its start page, one
// question per page, the details with the error summary, the answers
// checked, the confirmation, the reader's applications and settings),
// moved between by the look's own navigation (along the bottom on a phone,
// down the start from 600 wide; the application's own pages show none).
// The Overview ends in the index of every part's page. A link opens it as
// the looks' galleries share: `/#/<page>?theme=dark&dir=rtl&text=200`,
// where the page is a part's page by its id (`actions`, `entry`,
// `choices`...) or a screen by its name (`overview`, `start`, `vehicle`,
// `details`, `check`, `sent`, `applications`, `settings`); `theme=dark` by
// night, `dir=rtl` in Arabic right to left, `text=200` the words at twice
// the size, `state=errors` the details page sent with its problems.
// `?slow=8` runs every animation eight times slower; `?a11y=1` turns the
// semantics on from the start, as a screen reader would.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';

import 'gallery_pages.dart';
import 'kit_gallery/permits/permits.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The faces before the first frame: on the web the words never flash in
  // a fallback face.
  await civicLoadFonts();
  final hash = Uri.base.fragment.startsWith('/')
      ? Uri.parse(Uri.base.fragment)
      : null;
  final query = {...Uri.base.queryParameters, ...?hash?.queryParameters};
  final segments =
      hash?.pathSegments.where((s) => s.isNotEmpty).toList() ??
      const <String>[];
  final (screen, part) = switch (segments) {
    ['screen', final name, ...] => (name, null),
    [final id, ...] when galleryPages.any((p) => p.id == id) => (null, id),
    [final name, ...] => (name, null),
    _ => (query['page'], query['part']),
  };
  final text = double.tryParse(query['text'] ?? '');
  timeDilation = double.tryParse(query['slow'] ?? '') ?? 1;
  if (query['a11y'] == '1') WidgetsBinding.instance.ensureSemantics();
  runApp(
    PermitsApp(
      initialPage: PermitsPage.values.firstWhere(
        (p) => p.name == screen,
        orElse: () => PermitsPage.overview,
      ),
      initialAppearance: query['theme'] == 'dark'
          ? PermitsAppearance.dark
          : PermitsAppearance.light,
      initialDirection: query['dir'] == 'rtl'
          ? TextDirection.rtl
          : TextDirection.ltr,
      // `text=200` is a percentage, `text=2` a factor.
      textScale: text == null ? null : (text > 5 ? text / 100 : text),
      showErrors: query['state'] == 'errors',
      parts: [
        for (final page in galleryPages) (title: page.title, build: page.build),
      ],
      initialPart: switch (galleryPages.indexWhere((p) => p.id == part)) {
        -1 => null,
        final i => i,
      },
    ),
  );
}
