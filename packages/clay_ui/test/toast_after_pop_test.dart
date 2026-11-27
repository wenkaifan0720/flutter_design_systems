// A page pushed over the scaffold and popped leaves toasts above the phone's
// dock, as they stood before it: shown as the page pops or long after. A
// desk's toast centres on the page beside the sidebar, and a phone's
// calendar low on the page opens above its field rather than over the dock.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute, PageTransitionsTheme, ThemeData;

const _places = [
  ClayDestination(icon: IconData(0xe000), label: 'Books'),
  ClayDestination(icon: IconData(0xe001), label: 'Add'),
  ClayDestination(icon: IconData(0xe002), label: 'Settings'),
];

Widget _detail(BuildContext listContext) => Builder(
  builder: (context) => ClayScreen(
    topBar: ClayTopBar(
      title: 'Middlemarch',
      onBack: () => Navigator.of(context).pop(),
    ),
    body: ClayButton(
      'Save',
      onPressed: () {
        Navigator.of(context).pop();
        showClayToast(listContext, 'Saved');
      },
    ),
  ),
);

Widget _app({Widget? body}) => MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: clayPageTransitions,
    ),
  ),
  builder: (context, app) => ClayTheme(
    data: ClayThemeData.clay(Brightness.light),
    child: ClayToaster(child: app!),
  ),
  home: ClayScaffold(
    destinations: _places,
    onDestinationSelected: (_) {},
    body:
        body ??
        Builder(
          builder: (context) => ClayScreen(
            topBar: const ClayTopBar(title: 'Books'),
            body: Column(
              children: [
                ClayButton(
                  'Open',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => _detail(context)),
                  ),
                ),
                ClayButton(
                  'Delete',
                  onPressed: () => showClayToast(context, 'Deleted'),
                ),
              ],
            ),
          ),
        ),
  ),
);

Rect _toast(WidgetTester tester, String words) => tester.getRect(
  find.ancestor(of: find.text(words), matching: find.byType(ClaySurface)).first,
);

Future<void> _clear(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 8));
  await tester.pumpAndSettle();
}

void main() {
  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  ]) {
    testWidgets('a toast stands above the dock after a pushed page pops '
        '(${platform.name})', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      final bar = tester.getRect(find.byType(ClayNavigationBar));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        _toast(tester, 'Saved').bottom,
        lessThanOrEqualTo(bar.top + 0.5),
        reason: 'toast shown as the page pops',
      );
      await _clear(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Save'))).pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
        _toast(tester, 'Deleted').bottom,
        lessThanOrEqualTo(bar.top + 0.5),
        reason: 'toast shown long after the back key popped the page',
      );
      await _clear(tester);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('a desk\'s toast centres on the page beside the sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    final side = tester.getRect(find.byType(ClaySidebar));
    final centre = (side.right + 1440) / 2;
    final t = _toast(tester, 'Deleted');
    expect((t.center.dx - centre).abs(), lessThan(2));
    await _clear(tester);
  });

  testWidgets('a phone\'s calendar low on the page opens above its field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picker = ClayDatePicker(
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      labelText: 'Date started',
      onChanged: (_) {},
    );
    await tester.pumpWidget(
      _app(
        body: ClayScreen(
          topBar: const ClayTopBar(title: 'Add'),
          body: Column(children: [const SizedBox(height: 340), picker]),
        ),
      ),
    );
    final field = tester.getRect(find.byWidget(picker));
    final bar = tester.getRect(find.byType(ClayNavigationBar));
    await tester.tapAt(field.bottomCenter - const Offset(0, 16));
    await tester.pumpAndSettle();
    final month = tester.getRect(find.text('November 2026').first);
    expect(month.top, lessThan(field.top), reason: 'the month opened below');
    expect(month.bottom, lessThan(bar.top));
  });
}
