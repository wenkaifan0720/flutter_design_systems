// TermHost, the one mount: the theme for the brightness in force (the
// platform's, or pinned), a palette by day and by night, the toasts, and a
// change of palette or brightness blended over 200 ms (cut under Reduce
// Motion).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

RawNamedPalette _palette(String id) =>
    TermThemeData.palettes.firstWhere((p) => p.id == id);

Widget _app({
  Brightness? brightness,
  RawNamedPalette? palette,
  bool still = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: still),
    child: TermHost(brightness: brightness, palette: palette, child: child!),
  ),
  home: Builder(
    builder: (context) => TermButton(
      label: 'save',
      onPressed: () => TermToaster.show(context, message: 'saved'),
    ),
  ),
);

TermThemeData _theme(WidgetTester tester) =>
    TermTheme.of(tester.element(find.text('save')));

void main() {
  setUpAll(loadFaces);

  testWidgets('follows the platform, or the brightness it is given', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(_app());
    expect(_theme(tester).background, TermThemeData.light().background);
    await tester.pumpWidget(_app(brightness: Brightness.dark));
    await tester.pumpAndSettle();
    expect(_theme(tester).background, TermThemeData.dark().background);
  });

  testWidgets('a palette by day and by night', (tester) async {
    for (final b in Brightness.values) {
      await tester.pumpWidget(_app(brightness: b, palette: _palette('amber')));
      await tester.pumpAndSettle();
      expect(
        _theme(tester).background,
        TermThemeData.preset('amber', b).background,
      );
    }
  });

  testWidgets('a change of palette blends; Reduce Motion cuts', (tester) async {
    final from = TermThemeData.preset('standard', Brightness.dark).accent;
    final to = TermThemeData.preset('dusk', Brightness.dark).accent;
    await tester.pumpWidget(
      _app(brightness: Brightness.dark, palette: _palette('standard')),
    );
    await tester.pumpWidget(
      _app(brightness: Brightness.dark, palette: _palette('dusk')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _theme(tester).accent;
    expect(mid, isNot(from));
    expect(mid, isNot(to));
    await tester.pumpAndSettle();
    expect(_theme(tester).accent, to);
    await tester.pumpWidget(
      _app(
        brightness: Brightness.dark,
        palette: _palette('harbor'),
        still: true,
      ),
    );
    await tester.pump();
    expect(
      _theme(tester).accent,
      TermThemeData.preset('harbor', Brightness.dark).accent,
    );
  });

  testWidgets('its toasts show with no toaster of the app own', (tester) async {
    await tester.pumpWidget(_app(brightness: Brightness.dark));
    await tester.tap(find.text('save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('saved'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });
}
