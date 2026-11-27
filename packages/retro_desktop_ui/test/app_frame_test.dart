// Retro Desktop's frame: RetroDesktopAppShell's places at a phone's width (the strip along the foot) and on a desk (the
// menu bar), each place a tab; a stack of pages per place, a pushed page keeping the menu bar on a desk while the
// phone's strip steps away; a page's own bar under the menu bar on a desk; a notice clear of the strip; the six
// presets as named palettes; and a host that is at once by default, an app opting into a cross-fade.
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

const _places = [
  RetroDesktopNavItem(
    label: 'Books',
    short: 'Books',
    icon: RetroDesktopGlyphs.folder,
  ),
  RetroDesktopNavItem(
    label: 'Add a book',
    short: 'Add',
    icon: RetroDesktopGlyphs.plus,
  ),
  RetroDesktopNavItem(
    label: 'Settings',
    short: 'Settings',
    icon: RetroDesktopGlyphs.settings,
  ),
];

void _view(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => RetroDesktopHost(child: child!),
  home: home,
);

class _Shelled extends StatefulWidget {
  const _Shelled();
  @override
  State<_Shelled> createState() => _ShelledState();
}

class _ShelledState extends State<_Shelled> {
  int place = 0;
  @override
  Widget build(BuildContext context) => RetroDesktopAppShell.branches(
    brand: 'Shelf',
    destinations: _places,
    selectedIndex: place,
    onDestinationSelected: (i) => setState(() => place = i),
    branches: [
      for (final item in _places)
        (context) => RetroDesktopScaffold(
          appBar: RetroDesktopAppBar(title: item.label),
          body: Builder(
            builder: (context) => RetroDesktopButton(
              'Open ${item.short}',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => RetroDesktopScaffold(
                    appBar: RetroDesktopAppBar(
                      title: 'Inside ${item.short}',
                      leading: RetroDesktopAppBar.autoLeading(context),
                    ),
                    body: const Text('A page'),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

bool _shows(WidgetTester tester, String words) =>
    find.text(words).hitTestable().evaluate().isNotEmpty;

void main() {
  setUpAll(retroDesktopLoadFonts);

  for (final (width, mode) in const [(390.0, 'strip'), (1440.0, 'menu bar')]) {
    testWidgets(
      'RetroDesktopAppShell.branches at $width: the $mode, each place a tab, a stack per place',
      (tester) async {
        _view(tester, width);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_app(const _Shelled()));
        await tester.pumpAndSettle();
        // The page's title says Books too: a place is the strip's (last) on a phone, the menu bar's (first) on a desk.
        Finder placed(String words) =>
            width < 1024 ? find.text(words).last : find.text(words).first;
        final place = placed('Settings');
        final at = tester.getRect(place);
        if (mode == 'strip') {
          expect(at.top, greaterThan(800), reason: 'the places along the foot');
        } else {
          expect(at.top, lessThan(40), reason: 'the places in the menu bar');
          expect(
            _shows(tester, 'Shelf'),
            isTrue,
            reason: 'the brand heads the bar',
          );
        }
        expect(
          tester.getSemantics(place),
          isSemantics(isSelected: false),
          reason: 'a place is a tab, with its selected state',
        );
        expect(
          tester.getSemantics(placed('Books')),
          isSemantics(isSelected: true),
        );
        await tester.tap(find.text('Open Books'));
        await tester.pumpAndSettle();
        expect(_shows(tester, 'Inside Books'), isTrue);
        // On a desk the menu bar stays over a pushed page; the phone's strip steps away.
        expect(_shows(tester, 'Settings'), width >= 1024);
        if (width >= 1024) {
          await tester.tap(find.text('Settings').first);
          await tester.pumpAndSettle();
          expect(_shows(tester, 'Open Settings'), isTrue);
          await tester.tap(find.text('Books').first);
          await tester.pumpAndSettle();
          expect(
            _shows(tester, 'Inside Books'),
            isTrue,
            reason: 'its stack kept',
          );
        }
        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.pumpAndSettle();
        expect(
          _shows(tester, 'Open Books'),
          isTrue,
          reason: 'back pops the place',
        );
        expect(
          _shows(tester, 'Settings'),
          isTrue,
          reason: 'the places are back',
        );
        expect(tester.takeException(), isNull);
        handle.dispose();
      },
    );
  }

  testWidgets(
    "on a desk a page's title stands in its own bar under the menu bar, one menu bar in all",
    (tester) async {
      _view(tester, 1440);
      await tester.pumpWidget(_app(const _Shelled()));
      await tester.pumpAndSettle();
      final brand = tester.getRect(find.text('Shelf'));
      final title = tester.getRect(find.text('Books').last);
      expect(
        title.top,
        greaterThan(brand.bottom),
        reason: 'under the menu bar',
      );
      expect(find.text('Shelf'), findsOneWidget, reason: 'no second menu bar');
    },
  );

  testWidgets('a notice stands clear of the phone strip', (tester) async {
    _view(tester, 390);
    await tester.pumpWidget(_app(const _Shelled()));
    await tester.pumpAndSettle();
    showRetroDesktopSnackBar(
      tester.element(find.text('Open Books')),
      'Saved the shelf',
    );
    await tester.pumpAndSettle();
    final notice = tester.getRect(find.text('Saved the shelf'));
    final strip = tester.getRect(find.text('Settings').first);
    expect(notice.bottom, lessThanOrEqualTo(strip.top));
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  test("the six presets are named palettes, their swatches the presets' own colours", () {
    expect([
      for (final p in RetroDesktopThemeData.palettes) p.id,
    ], RetroDesktopThemeData.presets);
    for (final p in RetroDesktopThemeData.palettes) {
      for (final b in Brightness.values) {
        final c = RetroDesktopThemeData.preset(p.id, b).colors;
        expect(p.swatchesFor(b), [
          c.desktop,
          c.highlight,
          c.platinum,
        ], reason: '${p.id} $b');
      }
    }
  });

  testWidgets(
    "RetroDesktopHost builds the palette given, changes at once by default and cross-fades when the app asks",
    (tester) async {
      Color desk(WidgetTester tester) =>
          RetroDesktopTheme.of(tester.element(find.text('Shelf')))
              .colors
              .desktop;
      Widget host(String id, Duration duration) => MaterialApp(
        builder: (context, child) => RetroDesktopHost(
          palette: RetroDesktopThemeData.palettes.firstWhere((p) => p.id == id),
          brightness: Brightness.light,
          duration: duration,
          child: child!,
        ),
        home: const Text('Shelf'),
      );
      final lagoon = RetroDesktopThemeData.preset('lagoon', Brightness.light);
      final berry = RetroDesktopThemeData.preset('berry', Brightness.light);
      await tester.pumpWidget(host('lagoon', Duration.zero));
      expect(desk(tester), lagoon.colors.desktop);
      await tester.pumpWidget(host('berry', Duration.zero));
      expect(desk(tester), berry.colors.desktop, reason: 'at once');
      const fade = Duration(milliseconds: 200);
      await tester.pumpWidget(host('berry', fade));
      await tester.pumpWidget(host('lagoon', fade));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = desk(tester);
      expect(mid, isNot(berry.colors.desktop));
      expect(mid, isNot(lagoon.colors.desktop));
      await tester.pumpAndSettle();
      expect(desk(tester), lagoon.colors.desktop);
    },
  );
}
