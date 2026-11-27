// A toast or a snack bar raised under ComicHost stands in the app's one toaster, above the navigator: it outlives a
// switch of place, and wherever it was raised from (a place, the root, a page with a footer) it stands above the tab
// bar, the page's footer and the keyboard.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

final _root = GlobalKey<NavigatorState>();

const _places = [
  ComicNavItem(
    key: ValueKey('place Books'),
    label: 'Books',
    short: 'Books',
    icon: ComicGlyphs.house,
  ),
  ComicNavItem(
    key: ValueKey('place Me'),
    label: 'Me',
    short: 'Me',
    icon: ComicGlyphs.person,
  ),
];

class _Shelf extends StatefulWidget {
  const _Shelf();
  @override
  State<_Shelf> createState() => _ShelfState();
}

class _ShelfState extends State<_Shelf> {
  int place = 0;
  @override
  Widget build(BuildContext context) => ComicAppShell.branches(
    brand: 'Shelf',
    destinations: _places,
    selectedIndex: place,
    onDestinationSelected: (index) => setState(() => place = index),
    branches: [
      (context) => ComicScaffold(
        topBar: const ComicAppBar(title: 'Reading list'),
        body: Builder(
          builder: (context) => ComicColumn(
            children: [
              ComicButton(
                'Toast',
                key: const ValueKey('Toast'),
                onPressed: () => showComicToast(context, 'Saved'),
              ),
              ComicButton(
                'Snack',
                key: const ValueKey('Snack'),
                onPressed: () => showComicSnackBar(
                  context,
                  'Moved',
                  actionLabel: 'Undo',
                  onAction: () {},
                ),
              ),
              ComicButton(
                'Open',
                key: const ValueKey('Open'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ComicScaffold(
                      topBar: const ComicAppBar(title: 'Stoner'),
                      footer: ComicButton.filled(
                        'Save',
                        key: const ValueKey('save'),
                        onPressed: () {},
                      ),
                      body: Builder(
                        builder: (context) => ComicButton(
                          'Toast here',
                          key: const ValueKey('Toast here'),
                          onPressed: () => showComicToast(context, 'Kept'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      (context) => const ComicScaffold(
        topBar: ComicAppBar(title: 'Account'),
        body: Text('Account body'),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: _root,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ComicHost(child: child!),
      home: const _Shelf(),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

// The tab bar's top: the shell's navigation, which keeps the toaster's toasts clear.
double _barTop(WidgetTester tester) => tester
    .getRect(
      find
          .ancestor(
            of: find.byKey(const ValueKey('place Me')),
            matching: find.byType(RawToasterKeepClear),
          )
          .first,
    )
    .top;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  testWidgets(
    'a toast raised on one place outlives a switch of place, above the tab bar',
    (tester) async {
      await _pump(tester);
      await _tap(tester, 'Toast');
      expect(find.byType(ComicToast), findsOneWidget);
      await _tap(tester, 'place Me');
      expect(find.text('Account body'), findsOneWidget);
      expect(
        find.byType(ComicToast),
        findsOneWidget,
        reason: 'the toast stays in sight on the other place',
      );
      expect(
        tester.getRect(find.byType(ComicToast)).bottom,
        lessThanOrEqualTo(_barTop(tester)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(ComicToast), findsNothing);
    },
  );

  testWidgets(
    'a snack bar raised on one place outlives a switch of place, above the tab bar',
    (tester) async {
      await _pump(tester);
      await _tap(tester, 'Snack');
      await _tap(tester, 'place Me');
      expect(find.byType(ComicSnackBar), findsOneWidget);
      expect(find.byType(ComicSnackBar).hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.byType(ComicSnackBar)).bottom,
        lessThanOrEqualTo(_barTop(tester)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    },
  );

  testWidgets('a toast raised from the root stands above the tab bar', (
    tester,
  ) async {
    await _pump(tester);
    showComicToast(_root.currentContext!, 'From the root');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ComicToast), findsOneWidget);
    expect(
      tester.getRect(find.byType(ComicToast)).bottom,
      lessThanOrEqualTo(_barTop(tester)),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets(
    "a toast raised on a page with a footer stands above the footer",
    (tester) async {
      await _pump(tester);
      await _tap(tester, 'Open');
      await tester.pumpAndSettle();
      await _tap(tester, 'Toast here');
      expect(find.byType(ComicToast), findsOneWidget);
      expect(
        tester.getRect(find.byType(ComicToast)).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const ValueKey('save'))).top,
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));
    },
  );

  testWidgets('the keyboard lifts a toast above it', (tester) async {
    await _pump(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    await _tap(tester, 'Toast');
    expect(
      tester.getRect(find.byType(ComicToast)).bottom,
      lessThanOrEqualTo(844 - 300),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('a new toast takes the place of the one standing', (
    tester,
  ) async {
    await _pump(tester);
    await _tap(tester, 'Toast');
    showComicToast(_root.currentContext!, 'Again');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ComicToast), findsOneWidget);
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('a toast is heard once, in the toaster\'s region', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    await _tap(tester, 'Toast');
    expect(find.bySemanticsLabel('Saved'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    semantics.dispose();
  });
}
