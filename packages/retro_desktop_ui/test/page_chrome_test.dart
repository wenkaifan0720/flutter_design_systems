// What the adopters' study found on retro's pages: title-bar boxes that looked pressable and did nothing, a subtitle that
// never showed and a description list that dropped its glyphs. Where a desk's footer stands: app_page_test.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Future<void> _at(
  WidgetTester tester,
  double width,
  Widget home, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(retroDesktopApp(home, direction: direction));
  await tester.pumpAndSettle();
}

/// The title-bar boxes a window draws: Platinum's close, zoom and shade boxes, Chisel's caption buttons.
int _boxes(WidgetTester tester) {
  bool box(Object painter) => const {
    '_BoxPainter',
    '_CaptionPainter',
  }.contains('${painter.runtimeType}');
  var n = 0;
  for (final e in find.byType(RetroDesktopPixelPaint).evaluate()) {
    final paint = e.widget as RetroDesktopPixelPaint;
    if (!box(paint.painter)) continue;
    final hidden = e.findAncestorWidgetOfExactType<Visibility>();
    if (hidden == null || hidden.visible) n++;
  }
  return n;
}

Widget _desk(Widget window) => RetroDesktopDesktop(
  tiles: [
    RetroDesktopWindowColumn(span: 12, windows: [window]),
  ],
);

Widget _chisel(Widget child) => Builder(
  builder: (context) => RetroDesktopTheme(
    data: RetroDesktopTheme.of(context)
        .copyWith(appearance: RetroDesktopAppearance.chisel),
    child: child,
  ),
);

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final chisel in const [false, true]) {
    final look = chisel ? 'Chisel' : 'Platinum';
    testWidgets(
      '$look: a window that does not close draws no title-bar boxes',
      (tester) async {
        Widget wrap(Widget w) => chisel ? _chisel(w) : w;
        await _at(
          tester,
          1440,
          wrap(
            _desk(
              const RetroDesktopWindow(title: 'Notes', child: Text('A note')),
            ),
          ),
        );
        expect(
          _boxes(tester),
          0,
          reason: 'Boxes that do nothing read as controls',
        );
        var closed = 0;
        await _at(
          tester,
          1440,
          wrap(
            _desk(
              RetroDesktopWindow(
                title: 'Notes',
                onClose: () => closed++,
                child: const Text('A note'),
              ),
            ),
          ),
        );
        expect(
          _boxes(tester),
          1,
          reason: 'A window that closes draws its close box alone',
        );
        await tester.tap(find.bySemanticsLabel('Close'));
        await tester.pumpAndSettle();
        expect(closed, 1);
      },
    );
  }

  for (final width in const [390.0, 1440.0]) {
    testWidgets("at $width a page's subtitle shows", (tester) async {
      await _at(
        tester,
        width,
        const RetroDesktopScaffold(
          appBar: RetroDesktopAppBar(title: 'Inbox', subtitle: '3 unread'),
          body: Text('Mail'),
        ),
      );
      expect(find.text('3 unread'), findsOneWidget);
    });

    testWidgets(
      "at $width under the app shell a page's subtitle shows once, in its window's info strip",
      (tester) async {
        await _at(
          tester,
          width,
          RetroDesktopAppShell(
            brand: 'Mail',
            destinations: const [
              RetroDesktopNavItem(
                label: 'Inbox',
                short: 'Inbox',
                icon: RetroDesktopGlyphs.folder,
              ),
              RetroDesktopNavItem(
                label: 'Settings',
                short: 'Settings',
                icon: RetroDesktopGlyphs.settings,
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            body: const RetroDesktopScaffold(
              appBar: RetroDesktopAppBar(title: 'Inbox', subtitle: '3 unread'),
              body: Text('Mail'),
            ),
          ),
        );
        expect(
          find.text('3 unread'),
          findsOneWidget,
          reason: 'The window says it; a page bar saying it again repeats it',
        );
      },
    );
  }

  testWidgets("a description list draws its facts' glyphs", (tester) async {
    await _at(
      tester,
      390,
      const RetroDesktopDescriptionList([
        RetroDesktopFact('Wind', 'SW 24 km/h', icon: RetroDesktopGlyphs.wind),
      ]),
    );
    expect(find.byIcon(RetroDesktopGlyphs.wind), findsOneWidget);
  });
}
