// A nav root may own the bottom edge's slots: a form
// that is itself a place keeps its Save in the footer, docked above a
// phone's tab bar and at the page's foot beside the sidebar, in both shell
// forms; a floating control floats above the bar.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _places = [
  MinimalNavItem(LucideIcons.libraryBig, 'Books'),
  MinimalNavItem(LucideIcons.plus, 'Add'),
];

Widget _form(VoidCallback save) => MinimalScaffold(
  topBar: const MinimalAppBar(title: 'Add'),
  body: const Text('Form body'),
  footer: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [MinimalButton('Save', onPressed: save)],
  ),
);

Widget _app(Widget home) => MaterialApp(
  builder: (context, app) =>
      MinimalHost(brightness: Brightness.light, child: app!),
  home: home,
);

Widget _shell(bool branches, Widget root) => branches
    ? MinimalAppShell.branches(
        destinations: _places,
        selectedIndex: 1,
        onDestinationSelected: (_) {},
        branches: [(context) => const SizedBox(), (context) => root],
      )
    : MinimalAppShell(
        destinations: _places,
        selectedIndex: 1,
        onDestinationSelected: (_) {},
        body: root,
      );

void main() {
  for (final branches in [false, true]) {
    final form = branches ? 'branches' : 'one body';
    for (final size in [const Size(390, 844), const Size(1440, 900)]) {
      testWidgets('$form at ${size.width.toInt()}: the footer stands clear '
          'of the bar and takes its taps', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var saved = 0;
        await tester.pumpWidget(_app(_shell(branches, _form(() => saved++))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final save = tester.getRect(find.text('Save'));
        if (size.width < MinimalLayout.compact) {
          // Above the tab bar, never under it.
          final tab = tester.getRect(find.text('Books').last);
          expect(save.bottom, lessThan(tab.top - 8));
        } else {
          // The page's foot, beside the sidebar.
          expect(save.bottom, greaterThan(size.height - 48));
        }
        await tester.tap(find.text('Save'));
        expect(saved, 1);
      });
    }

    testWidgets('$form at 390: a floating control floats above the bar', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var added = 0;
      await tester.pumpWidget(
        _app(
          _shell(
            branches,
            MinimalScaffold(
              topBar: const MinimalAppBar(title: 'Add'),
              body: const Text('Form body'),
              floating: MinimalIconButton(
                LucideIcons.plus,
                semanticLabel: 'New',
                onPressed: () => added++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final plus = tester.getRect(find.byType(MinimalIconButton));
      final tab = tester.getRect(find.text('Books').last);
      expect(plus.bottom, lessThan(tab.top - 8));
      await tester.tap(find.byType(MinimalIconButton));
      expect(added, 1);
    });
  }
}
