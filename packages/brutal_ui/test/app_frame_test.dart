// Brutal's frame: the app shell's places at every width and its stacks of pages; the six presets as ui_core's named
// palettes, and a host that moves between them; a page's title and its footer's action on the page's column on a wide
// desk; a large app bar in one band, its rule on the rule under a side list's head.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _tabs = [
  BrutalTab(IconData(0xe318), 'Home'),
  BrutalTab(IconData(0xe158), 'Tickets'),
  BrutalTab(IconData(0xe57f), 'Settings'),
];

void _view(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => BrutalHost(child: child!),
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
  Widget build(BuildContext context) => BrutalAppShell.branches(
    tabs: _tabs,
    brand: 'Admit',
    selectedIndex: place,
    onDestinationSelected: (i) => setState(() => place = i),
    action: BrutalShellAction(
      icon: const IconData(0xe047),
      tooltip: 'New event',
      onPressed: (_) {},
    ),
    branches: [
      for (final tab in _tabs)
        (context) => BrutalScreen(
          topBar: BrutalAppBar(title: tab.label, large: true),
          body: Builder(
            builder: (context) => BrutalButton.filled(
              'Open ${tab.label}',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => BrutalScreen(
                    topBar: BrutalAppBar(
                      title: 'Inside ${tab.label}',
                      leading: BrutalAppBar.autoLeading(context),
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

// Words as drawn, whatever their case (the bar and the rail set their names in capitals).
Finder _words(String text) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText().trim().toLowerCase() == text.toLowerCase(),
);

bool _shows(WidgetTester tester, String words) =>
    _words(words).hitTestable().evaluate().isNotEmpty;

void main() {
  setUpAll(brutalLoadFonts);

  testWidgets("a phone bar's long name keeps clear of its cell's sides", (
    tester,
  ) async {
    _view(tester, 390);
    await tester.pumpWidget(
      _app(
        BrutalAppShell(
          tabs: const [
            BrutalTab(IconData(0xe318), 'الرئيسية'),
            BrutalTab(IconData(0xe158), 'التذاكر'),
            BrutalTab(IconData(0xe57f), 'الإعدادات والخصوصية'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final name = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('الإعدادات'),
    );
    final cell = tester.getRect(
      find.ancestor(of: name, matching: find.byType(Column)).first,
    );
    // The name as drawn: its box scaled down to the room it has.
    final box = tester.renderObject<RenderBox>(name);
    final drawn = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    expect(drawn.left - cell.left, greaterThanOrEqualTo(4 - 0.01));
    expect(cell.right - drawn.right, greaterThanOrEqualTo(4 - 0.01));
  });

  for (final (width, mode) in const [
    (390.0, 'bar'),
    (800.0, 'rail'),
    (1440.0, 'side list'),
  ]) {
    testWidgets(
      'BrutalAppShell.branches at $width: the $mode, a stack per place, the act on a root page',
      (tester) async {
        _view(tester, width);
        await tester.pumpWidget(_app(const _Shelled()));
        await tester.pumpAndSettle();
        final bar = tester.getRect(_words('Tickets').first);
        switch (mode) {
          case 'bar':
            expect(
              bar.top,
              greaterThan(800),
              reason: 'the places along the foot',
            );
          case 'rail':
            expect(
              bar.left,
              lessThan(120),
              reason: 'the places down the start',
            );
            expect(bar.width, lessThan(100));
          default:
            expect(bar.left, lessThan(240), reason: 'the side list');
            expect(
              _shows(tester, 'Admit'),
              isTrue,
              reason: 'the brand heads the list',
            );
        }
        expect(
          find.bySemanticsLabel('New event'),
          findsOneWidget,
          reason: 'the act over the root',
        );
        await tester.tap(find.text('Open Home'));
        await tester.pumpAndSettle();
        expect(_shows(tester, 'Inside Home'), isTrue);
        expect(
          find.bySemanticsLabel('New event').hitTestable(),
          findsNothing,
          reason: 'a pushed page covers the act',
        );
        // The rail and the side list stay beside a pushed page; the phone's bar steps away.
        expect(_shows(tester, 'Tickets'), width >= 600);
        // Another place keeps its own stack; coming back finds the page still pushed.
        if (width >= 600) {
          await tester.tap(_words('Tickets').first);
          await tester.pumpAndSettle();
          expect(_shows(tester, 'Open Tickets'), isTrue);
          await tester.tap(_words('Home').first);
          await tester.pumpAndSettle();
          expect(_shows(tester, 'Inside Home'), isTrue);
        }
        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.pumpAndSettle();
        expect(
          _shows(tester, 'Open Home'),
          isTrue,
          reason: 'back pops the place\'s stack',
        );
        expect(
          _shows(tester, 'Tickets'),
          isTrue,
          reason: 'the places are back',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('the six presets are named palettes, their swatches the presets\' own colours', () {
    expect([
      for (final p in BrutalThemeData.palettes) p.id,
    ], BrutalThemeData.presets);
    for (final p in BrutalThemeData.palettes) {
      for (final b in Brightness.values) {
        final c = BrutalThemeData.preset(p.id, b).colors;
        expect(p.swatchesFor(b), [
          c.signal,
          c.lime,
          c.paper,
        ], reason: '${p.id} $b');
      }
    }
  });

  testWidgets(
    'BrutalHost builds the palette given and moves to a new brightness',
    (tester) async {
      late BuildContext inside;
      Widget host(Brightness b) => Directionality(
        textDirection: TextDirection.ltr,
        child: BrutalHost(
          palette: BrutalThemeData.palettes[3],
          brightness: b,
          child: Builder(
            builder: (context) {
              inside = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpWidget(host(Brightness.light));
      final day = BrutalThemeData.preset('riso', Brightness.light).colors;
      final night = BrutalThemeData.preset('riso', Brightness.dark).colors;
      expect(BrutalTheme.of(inside).colors.signal, day.signal);
      await tester.pumpWidget(host(Brightness.dark));
      await tester.pump(const Duration(milliseconds: 60));
      final mid = BrutalTheme.of(inside).colors.paper;
      expect(mid, isNot(day.paper), reason: 'it has left the day');
      expect(
        mid,
        isNot(night.paper),
        reason: 'it has not snapped to the night',
      );
      await tester.pumpAndSettle();
      expect(BrutalTheme.of(inside).colors.paper, night.paper);
    },
  );

  testWidgets(
    "on a wide desk a page's title and its footer's action stand on the page's column",
    (tester) async {
      _view(tester, 1920);
      await tester.pumpWidget(
        _app(
          BrutalScreen(
            topBar: const BrutalAppBar(title: 'Checkout'),
            footer: BrutalButton.filled('Pay', onPressed: () {}),
            body: const SizedBox(
              height: 40,
              width: double.infinity,
              key: ValueKey('body'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final body = tester.getRect(find.byKey(const ValueKey('body')));
      expect(
        tester.getRect(find.text('Checkout')).left,
        moreOrLessEquals(body.left, epsilon: 1),
      );
      expect(
        tester.getRect(find.byType(BrutalButton)).right,
        moreOrLessEquals(body.right, epsilon: 1),
      );
    },
  );

  testWidgets(
    "a large app bar is one band: its rule meets the rule under the side list's head",
    (tester) async {
      _view(tester, 1440);
      await tester.pumpWidget(
        _app(
          BrutalScaffold(
            brand: const Text('ADMIT'),
            destinations: [
              for (final t in _tabs)
                BrutalDestination(icon: t.icon, label: t.label),
            ],
            onDestinationSelected: (_) {},
            appBar: const BrutalAppBar(title: 'Home', large: true),
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(BrutalAppBar));
      final head = tester.getRect(find.text('ADMIT'));
      // The side list's head is the app bar's height, its rule under it.
      expect(
        bar.height,
        BrutalAppBar.height +
            BrutalTheme.of(tester.element(find.byType(BrutalAppBar)))
                .borderWidth,
      );
      expect(
        tester.getRect(find.text('Home').last).center.dy,
        moreOrLessEquals(head.center.dy, epsilon: 6),
      );
    },
  );
}
