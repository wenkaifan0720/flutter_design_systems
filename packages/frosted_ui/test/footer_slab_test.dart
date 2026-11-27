// A page's footer floats on a slab of the tab bar's glass where the page
// doesn't own the window's foot: 8 over the app shell's tab bar on a root
// page, the column's width at desktop width. A phone's pushed page keeps its
// band along the foot.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/frosted_parts.dart'
    show FrostedFootGlass, FrostedFootSlab, FrostedFace;
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void _none() {}

Widget _detail() => FrostedScaffold(
  maxWidth: 760,
  topBar: const FrostedAppBar(title: 'Dune', backLabel: 'Books'),
  footer: const FrostedButton('Edit', onPressed: _none),
  body: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (var i = 0; i < 30; i++) Text('Row $i')],
  ),
);

class _Books extends StatelessWidget {
  const _Books();

  @override
  Widget build(BuildContext context) => FrostedScaffold(
    topBar: const FrostedAppBar(title: 'Books'),
    body: Center(
      child: FrostedButton(
        'Open',
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder<void>(pageBuilder: (context, _, _) => _detail()),
        ),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          FrostedHost(brightness: Brightness.light, child: app!),
      home: FrostedAppShell(
        destinations: const [
          RawNavigationDestination(label: 'Books', icon: FrostedGlyphs.house),
          RawNavigationDestination(label: 'Add', icon: FrostedGlyphs.add),
        ],
        branches: [
          (context) => const _Books(),
          (context) => FrostedScaffold(
            topBar: const FrostedAppBar(title: 'Add a book'),
            footer: const FrostedButton('Save', onPressed: _none),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (var i = 0; i < 30; i++) Text('Field $i')],
            ),
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _slab(WidgetTester tester) => tester.getRect(find.byType(FrostedFootSlab));

void main() {
  testWidgets("a root page's footer floats 8 over the tab bar on a phone", (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.byType(FrostedFootGlass), findsNothing);
    final slab = _slab(tester);
    expect(slab.left, FrostedChromeMetrics.tabBarSide);
    expect(slab.right, 390 - FrostedChromeMetrics.tabBarSide);
    expect(slab.height, FrostedChromeMetrics.slabHeight);
    // The tab bar's slab: the bar's other face 64 tall, under the footer's.
    final bar = find
        .byType(FrostedFace)
        .evaluate()
        .map((e) => tester.getRect(find.byElementPredicate((x) => x == e)))
        .where((r) => r.height == FrostedChromeMetrics.slabHeight)
        .where((r) => r.top > slab.bottom)
        .single;
    expect(bar.top - slab.bottom, FrostedSpacing.s8);
    expect(bar.left, slab.left);
    expect(bar.right, slab.right);
    // The page's end rests over it.
    await tester.drag(find.text('Field 5'), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Field 29')).bottom, lessThan(slab.top));
  });

  testWidgets("a phone's pushed page keeps its band along the foot", (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(FrostedFootSlab), findsNothing);
    final band = tester.getRect(find.byType(FrostedFootGlass));
    expect(band.left, 0);
    expect(band.right, 390);
    expect(band.bottom, 844);
  });

  for (final rtl in [false, true]) {
    testWidgets('at desktop width it floats in the column '
        '(${rtl ? 'right to left' : 'left to right'})', (tester) async {
      await _pump(tester, const Size(1440, 900));
      if (rtl) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: tester.widget<MaterialApp>(find.byType(MaterialApp)),
          ),
        );
      }
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(FrostedFootGlass), findsNothing);
      final slab = _slab(tester);
      final title = tester.getRect(find.text('Dune'));
      final row = tester.getRect(find.text('Row 0'));
      // Its edges on the column's: the title's start, the rows' end.
      if (rtl) {
        expect(slab.right, row.right);
      } else {
        expect(slab.left, title.left);
        expect(slab.left, row.left);
      }
      expect(slab.width, lessThan(760));
      expect(slab.bottom, 900 - FrostedChromeMetrics.tabBarBottom);
      expect(slab.height, FrostedChromeMetrics.slabHeight);
    });
  }
}
