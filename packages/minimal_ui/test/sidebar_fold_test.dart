// MinimalAppShell.extended: a wide shell folds its sidebar to the rail
// (Flutter's NavigationRail.extended), the page keeping its state; the key
// at the sidebar's head and at the folded rail's top asks for the other,
// heard as the navigation menu, expanded or collapsed; the card's width
// eases between the two; narrower widths keep their own rail and bar.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: MinimalButton(
      'Tapped $taps',
      onPressed: () => setState(() => taps++),
    ),
  );
}

class _App extends StatefulWidget {
  const _App({this.foldable = true, this.extended = true});

  final bool foldable;
  final bool extended;

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  late bool extended = widget.extended;
  final asked = <bool>[];

  @override
  Widget build(BuildContext context) => MinimalAppShell(
    destinations: const [
      MinimalNavItem(LucideIcons.bookOpen, 'Books'),
      MinimalNavItem(LucideIcons.settings, 'Settings'),
    ],
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    header: const Text('Shelf'),
    extended: extended,
    onExtendedChanged: widget.foldable
        ? (value) => setState(() {
            asked.add(value);
            extended = value;
          })
        : null,
    body: const _Counter(),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 1440,
  bool rtl = false,
  bool foldable = true,
  bool extended = true,
  bool still = false,
}) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900), disableAnimations: still),
      child: MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: MinimalHost(child: child!),
        ),
        home: _App(foldable: foldable, extended: extended),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The side's width: from the shell's start edge to the page's.
double _side(WidgetTester tester, {bool rtl = false}) {
  final page = tester.getRect(find.byType(_Counter));
  return rtl ? 1440 - page.right : page.left;
}

// Minimal draws Lucide on its own cut: the same code point, another face.
Finder _glyph(IconData icon) => find.byWidgetPredicate(
  (widget) => widget is Icon && widget.icon?.codePoint == icon.codePoint,
);

final _fold = _glyph(LucideIcons.panelLeftClose);
final _unfold = _glyph(LucideIcons.panelLeftOpen);

void main() {
  testWidgets('the key folds the sidebar to the rail and back; the page '
      'keeps its state', (tester) async {
    await _pump(tester);
    expect(_side(tester), MinimalAppShell.defaultSidebarWidth);
    expect(find.text('Books'), findsOneWidget);
    await tester.tap(find.text('Tapped 0'));
    await tester.pump();
    await tester.tap(_fold);
    await tester.pumpAndSettle();
    final state = tester.state<_AppState>(find.byType(_App));
    expect(state.asked, [false]);
    expect(_side(tester), lessThan(100));
    expect(_unfold, findsOneWidget);
    expect(find.text('Tapped 1'), findsOneWidget);
    await tester.tap(_unfold);
    await tester.pumpAndSettle();
    expect(state.asked, [false, true]);
    expect(_side(tester), MinimalAppShell.defaultSidebarWidth);
    expect(find.text('Tapped 1'), findsOneWidget);
  });

  testWidgets('the card eases between the widths', (tester) async {
    await _pump(tester);
    await tester.tap(_fold);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final mid = _side(tester);
    expect(mid, lessThan(MinimalAppShell.defaultSidebarWidth));
    expect(mid, greaterThan(100));
    await tester.pumpAndSettle();
    expect(_side(tester), lessThan(100));
  });

  testWidgets('Reduce Motion folds at once', (tester) async {
    await _pump(tester, still: true);
    await tester.tap(_fold);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_side(tester), lessThan(100));
  });

  testWidgets('heard as the navigation menu, expanded or collapsed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(find.bySemanticsLabel('Navigation menu, expanded'), findsOneWidget);
    await tester.tap(_fold);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Navigation menu, collapsed'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('folded without a key, and no key at rail widths', (
    tester,
  ) async {
    await _pump(tester, foldable: false, extended: false);
    expect(_side(tester), lessThan(100));
    expect(_unfold, findsNothing);
    expect(_fold, findsNothing);
    // A folded shell at rail widths: its rail has no key that would unfold
    // nothing.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, width: 800, extended: false);
    expect(_fold, findsNothing);
    expect(_unfold, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, width: 800);
    expect(_fold, findsNothing);
  });

  testWidgets('right to left the panel glyph mirrors with the side', (
    tester,
  ) async {
    await _pump(tester, rtl: true);
    expect(_side(tester, rtl: true), MinimalAppShell.defaultSidebarWidth);
    final key = _glyph(LucideIcons.panelRightClose);
    expect(key, findsOneWidget);
    expect(tester.getCenter(key).dx, lessThan(1440 - 124));
    await tester.tap(key);
    await tester.pumpAndSettle();
    expect(_side(tester, rtl: true), lessThan(100));
    expect(_glyph(LucideIcons.panelRightOpen), findsOneWidget);
  });
}
