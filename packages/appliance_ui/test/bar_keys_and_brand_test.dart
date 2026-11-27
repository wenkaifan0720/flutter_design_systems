// The top bar's keys stand one size: an icon key an app puts at the bar's
// end is as big as the way back at its start, unless the app's theme sizes
// its icon keys itself. On a desk the side panel's brand stands on the top
// bar's title line, the app's act under it.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void _size(WidgetTester tester, double width) {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, {ApplianceThemeData? light}) => MaterialApp(
  builder: (context, app) =>
      ApplianceHost(brightness: Brightness.light, light: light, child: app!),
  home: home,
);

Widget _bar() => ApplianceScreen(
  topBar: ApplianceAppBar(
    title: 'Middlemarch',
    onBack: () {},
    actions: [
      ApplianceIconButton(
        icon: const Icon(LucideIcons.pencil),
        semanticLabel: 'Edit',
        onPressed: () {},
      ),
    ],
  ),
  body: const SizedBox(),
);

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('at $width the way back and a key at the end stand one size', (
      tester,
    ) async {
      _size(tester, width);
      await tester.pumpWidget(_app(_bar()));
      await tester.pumpAndSettle();
      final keys = find.byType(ApplianceIconButton);
      expect(keys, findsNWidgets(2));
      final back = tester.getRect(keys.first);
      final edit = tester.getRect(keys.last);
      expect(edit.size, back.size);
      expect(edit.center.dy, back.center.dy);
    });
  }

  testWidgets("an app's own icon key size still wins in the bar", (
    tester,
  ) async {
    _size(tester, 390);
    final theme = ApplianceThemeData.preset(
      ApplianceThemeData.palettes.first.id,
      Brightness.light,
    );
    await tester.pumpWidget(
      _app(
        _bar(),
        light: theme.copyWith(
          iconButtonStyle: const RawStyle(
            minimumSize: WidgetStatePropertyAll(Size.square(44)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(ApplianceIconButton).last),
      const Size.square(44),
    );
  });

  for (final act in [false, true]) {
    testWidgets("at 1440 the side panel's brand stands on the bar's title line"
        "${act ? ', the act under it' : ''}", (tester) async {
      _size(tester, 1440);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => ApplianceScaffold(
              destinations: const [
                ApplianceDestination(icon: LucideIcons.library, label: 'Books'),
                ApplianceDestination(
                  icon: LucideIcons.bookOpen,
                  label: 'Reading',
                ),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
              header: Text(
                'Shelf',
                style: ApplianceTheme.of(context).textTheme.heading,
              ),
              action: act
                  ? ApplianceShellAction(
                      icon: LucideIcons.plus,
                      label: 'Add a book',
                      onPressed: (_) {},
                    )
                  : null,
              body: const ApplianceScreen(
                topBar: ApplianceAppBar(title: 'Middlemarch'),
                body: SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final brand = tester.getRect(find.text('Shelf'));
      final title = tester.getRect(find.text('Middlemarch'));
      expect(brand.center.dy, closeTo(title.center.dy, 0.5));
      final first = tester.getRect(find.text('Books'));
      expect(first.top, greaterThan(brand.bottom));
      if (act) {
        final add = tester.getRect(find.text('Add a book'));
        expect(add.top, greaterThan(brand.bottom));
        expect(first.top, greaterThan(add.bottom));
      }
    });
  }
}
