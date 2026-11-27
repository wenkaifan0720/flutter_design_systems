// GlossAppShell: one shell on ui_core's RawAdaptiveShell at every width.
// On a phone its bar is the tab bar (the places as tabs, the chosen one
// selected) with the act a button of its own beside it; a page pushed in a
// place sends the bar away and keeps the sidebar on a desktop; back pops the
// place's own stack; the rail holds the act under the name; the sidebar
// keeps its own width and words the act; a toast stands clear of the bar.
import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _act = ValueKey<String>('act');

Widget _app() => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => GlossHost(child: child!),
  home: GlossAppShell(
    header: const GlossBrand('Shelf'),
    action: GlossActKey(
      key: _act,
      icon: LucideIcons.plus,
      label: 'Add book',
      onPressed: () {},
    ),
    destinations: const [
      RawNavigationDestination(label: 'Books', icon: LucideIcons.bookOpen),
      RawNavigationDestination(label: 'Reading', icon: LucideIcons.bookmark),
      RawNavigationDestination(label: 'Settings', icon: LucideIcons.settings),
    ],
    branches: [
      (context) => GlossScreen(
        topBar: const GlossTopBar(title: 'Books'),
        body: Column(
          children: [
            GlossButton(
              'Open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => GlossScreen(
                    topBar: GlossTopBar(
                      title: 'Dune',
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    body: const Text('Detail'),
                  ),
                ),
              ),
            ),
            Builder(
              builder: (context) => GlossButton(
                'Toast',
                onPressed: () => showGlossToast(context, 'Saved'),
              ),
            ),
          ],
        ),
      ),
      (context) => const GlossScreen(body: Text('Reading list')),
      (context) => const GlossScreen(body: Text('Settings page')),
    ],
  ),
);

Future<void> _at(WidgetTester t, double width) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_app());
  await t.pumpAndSettle();
}

void main() {
  testWidgets("a phone's bar is the tab bar; the act a button beside it", (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await _at(t, 390);
    final books = t.getSemantics(find.text('Books').last);
    expect(books.getSemanticsData().role, SemanticsRole.tab);
    expect(
      books.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    final reading = t.getSemantics(find.text('Reading'));
    expect(
      reading.getSemanticsData().flagsCollection.isSelected,
      isNot(Tristate.isTrue),
    );
    final act = t.getSemantics(find.byKey(_act));
    expect(act.getSemanticsData().role, isNot(SemanticsRole.tab));
    expect(act.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    // The act stands in the bar, at the foot.
    final actRect = t.getRect(find.byKey(_act));
    expect(actRect.bottom, greaterThan(900 - 80));
    await t.tap(find.text('Reading'));
    await t.pumpAndSettle();
    expect(find.text('Reading list'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a pushed page sends the bar away; back pops its place', (
    t,
  ) async {
    await _at(t, 390);
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);
    expect(find.byKey(_act).hitTestable(), findsNothing);
    final navigator = t.state<NavigatorState>(
      find
          .ancestor(of: find.text('Detail'), matching: find.byType(Navigator))
          .first,
    );
    await navigator.maybePop();
    await t.pumpAndSettle();
    expect(find.text('Detail'), findsNothing);
    expect(find.byKey(_act).hitTestable(), findsOneWidget);
  });

  testWidgets('a desktop keeps its sidebar beside a pushed page', (t) async {
    await _at(t, 1440);
    final side = t.getRect(find.byType(GlossSidebar));
    expect(side.width, GlossSidebar.width);
    expect(
      find.descendant(of: find.byKey(_act), matching: find.text('Add book')),
      findsOneWidget,
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);
    expect(find.byType(GlossSidebar), findsOneWidget);
    expect(t.getRect(find.text('Detail')).left, greaterThan(side.right));
  });

  testWidgets('a tablet: the act stands under the name on the rail', (t) async {
    await _at(t, 800);
    expect(
      find.descendant(
        of: find.byType(GlossNavigationRail),
        matching: find.byKey(_act),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a toast stands clear of the bar', (t) async {
    await _at(t, 390);
    await t.tap(find.text('Toast'));
    await t.pump(const Duration(milliseconds: 600));
    final toast = t.getRect(find.text('Saved'));
    final act = t.getRect(find.byKey(_act));
    expect(toast.bottom, lessThanOrEqualTo(act.top));
    await t.pumpAndSettle(const Duration(seconds: 10));
  });
  testWidgets("a sidebar's name, act and glyphs share one start line", (
    t,
  ) async {
    await _at(t, 1440);
    final name = t.getRect(find.text('Shelf')).left;
    final act = t.getRect(find.byKey(_act)).left;
    final glyph = t.getRect(find.byIcon(LucideIcons.bookOpen)).left;
    expect(name, moreOrLessEquals(glyph, epsilon: 1.5));
    expect(act, moreOrLessEquals(glyph, epsilon: 1.5));
  });

  testWidgets("a sidebar's name stands on the top bar's title line", (t) async {
    await _at(t, 1440);
    final title = find.descendant(
      of: find.byType(GlossTopBar),
      matching: find.text('Books'),
    );
    expect(
      t.getRect(find.text('Shelf')).center.dy,
      moreOrLessEquals(t.getRect(title).center.dy, epsilon: 1),
    );
  });
}
