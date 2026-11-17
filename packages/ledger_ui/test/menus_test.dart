// Every open menu has one current row (the user's find on Expressive's menus, 11-15, checked in every look): the
// pointer's row and the keys' row never read as two (the pointer moves the lit row, the keys go on from it); the lit
// row's mark never touches the menu's paper (Ledger marks the words alone, inside the row's 16); a menu the pointer
// opened lights no row until the pointer or the keys move, one the keys opened its first. In the split button's menu
// and the menu slip. And a split button beside the desktop's side bar opens its menu clear of the bar, which stands
// over the page's own overlay.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _desk = Size(1440, 900);

final List<String> _pressed = [];

const _acts = ['As CSV', 'As PDF', 'As XLSX'];
const _wide = ['As a statement for the bank', 'As PDF'];
const _months = ['October 2026', 'September 2026', 'August 2026', 'July 2026'];

Widget _split() => LedgerSplitButton(
  'Export',
  onPressed: () {},
  actions: [
    for (final a in _acts)
      LedgerSplitAction(label: a, onPressed: () => _pressed.add(a)),
  ],
);

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: Align(
    alignment: Alignment.topLeft,
    child: Padding(padding: const EdgeInsets.all(40), child: child),
  ),
);

Future<void> _desktop(WidgetTester t, Widget app) async {
  t.view.physicalSize = _desk;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  _pressed.clear();
  await t.pumpWidget(app);
  await t.pumpAndSettle();
}

Future<TestGesture> _mouse(WidgetTester t) async {
  final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(1, 1));
  addTearDown(mouse.removePointer);
  return mouse;
}

/// A click of the split button's chevron, its half at the end.
Future<void> _clickChevron(WidgetTester t, TestGesture mouse) async {
  await mouse.moveTo(t.getCenter(find.byIcon(LucideIcons.chevronDown).first));
  await mouse.down(t.getCenter(find.byIcon(LucideIcons.chevronDown).first));
  await mouse.up();
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey key) async {
  await t.sendKeyEvent(key);
  await t.pumpAndSettle();
}

/// Each marked row's mark: `keys` (the double rule under its words) or `pointer` (the underline).
Map<String, String> _marks(WidgetTester t, List<String> rows) => {
  for (final r in rows) r: ?_mark(t, r),
};

String? _mark(WidgetTester t, String words) {
  final s = t.widget<Text>(find.text(words).last).style!;
  if (s.decoration != TextDecoration.underline) return null;
  return s.decorationStyle == TextDecorationStyle.double ? 'keys' : 'pointer';
}

void main() {
  group("the split button's menu", () {
    testWidgets(
      'opened by the pointer it lights no row; then the row the pointer or the keys moved to last, one at a time',
      (t) async {
        await _desktop(t, _host(_split()));
        final mouse = await _mouse(t);
        // A key first: a desktop keeps the keyboard's highlight on after it, whatever the mouse does.
        await _key(t, LogicalKeyboardKey.shiftLeft);
        await _clickChevron(t, mouse);
        expect(find.text('As CSV'), findsOneWidget);
        expect(_marks(t, _acts), isEmpty, reason: 'nothing moved yet');
        await mouse.moveTo(t.getCenter(find.text('As PDF')));
        await t.pumpAndSettle();
        expect(_marks(t, _acts), {'As PDF': 'pointer'});
        await _key(t, LogicalKeyboardKey.arrowDown);
        expect(
          _marks(t, _acts),
          {'As XLSX': 'keys'},
          reason: "the keys go on from the pointer's row, and the pointer's resting row is no longer current",
        );
        await mouse.moveTo(t.getCenter(find.text('As CSV')));
        await t.pumpAndSettle();
        expect(_marks(t, _acts), {'As CSV': 'pointer'});
        await _key(t, LogicalKeyboardKey.enter);
        expect(_pressed, ['As CSV'], reason: 'Enter presses the lit row');
      },
    );

    testWidgets(
      'opened by the pointer, Down or Enter lights the first row rather than pass it or press it unseen',
      (t) async {
        await _desktop(t, _host(_split()));
        final mouse = await _mouse(t);
        await _key(t, LogicalKeyboardKey.shiftLeft);
        await _clickChevron(t, mouse);
        await _key(t, LogicalKeyboardKey.enter);
        expect(_pressed, isEmpty);
        expect(_marks(t, _acts), {'As CSV': 'keys'});
        await _key(t, LogicalKeyboardKey.escape);
        await _clickChevron(t, mouse);
        expect(_marks(t, _acts), isEmpty);
        await _key(t, LogicalKeyboardKey.arrowDown);
        expect(_marks(t, _acts), {'As CSV': 'keys'});
        await _key(t, LogicalKeyboardKey.arrowDown);
        expect(_marks(t, _acts), {'As PDF': 'keys'});
      },
    );

    for (final (how, keys) in [
      (
        'Down on the main half',
        [LogicalKeyboardKey.tab, LogicalKeyboardKey.arrowDown],
      ),
      (
        'Enter on the chevron',
        [
          LogicalKeyboardKey.tab,
          LogicalKeyboardKey.tab,
          LogicalKeyboardKey.enter,
        ],
      ),
      (
        'Space on the chevron',
        [
          LogicalKeyboardKey.tab,
          LogicalKeyboardKey.tab,
          LogicalKeyboardKey.space,
        ],
      ),
    ]) {
      testWidgets('opened by the keys ($how) it lights its first row', (
        t,
      ) async {
        await _desktop(t, _host(_split()));
        for (final k in keys) {
          await _key(t, k);
        }
        expect(find.text('As CSV'), findsOneWidget);
        expect(_marks(t, _acts), {'As CSV': 'keys'});
      });
    }

    testWidgets(
      "the lit row's mark stands inside the row's 16, under its words",
      (t) async {
        await _desktop(t, _host(_split()));
        final mouse = await _mouse(t);
        await _key(t, LogicalKeyboardKey.tab);
        await _key(t, LogicalKeyboardKey.arrowDown);
        await mouse.moveTo(t.getCenter(find.text('As PDF')));
        await t.pumpAndSettle();
        final paper = t.getRect(
          find
              .ancestor(
                of: find.text('As PDF'),
                matching: find.byType(ClipRRect),
              )
              .first,
        );
        for (final words in _acts) {
          final at = t.getRect(find.text(words));
          expect(at.left - paper.left, greaterThanOrEqualTo(16), reason: words);
          expect(
            paper.right - at.right,
            greaterThanOrEqualTo(16),
            reason: words,
          );
        }
        expect(_marks(t, _acts), {'As PDF': 'pointer'});
      },
    );

    for (final direction in TextDirection.values) {
      testWidgets(
        'beside the side bar (${direction.name}) it opens clear of the bar, which stands over the page',
        (t) async {
          t.view.physicalSize = _desk;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          // A go_router shell's way: each destination a navigator of its own under the bar.
          await t.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, page) => Directionality(
                textDirection: direction,
                child: LedgerHost(brightness: Brightness.light, child: page!),
              ),
              home: LedgerNavigationFrame(
                destinations: const [
                  LedgerNavItem(LucideIcons.house, 'Home'),
                  LedgerNavItem(LucideIcons.chartPie, 'Spending'),
                ],
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                body: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (context) => Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: LedgerSideBar.width + 24,
                          top: 120,
                        ),
                        child: LedgerSplitButton(
                          'Export',
                          onPressed: () {},
                          // A menu much wider than the button, as a long act's words make it: aligned to the
                          // button's end, it reaches back past the button's start towards the bar.
                          actions: [
                            for (final a in _wide)
                              LedgerSplitAction(label: a, onPressed: () {}),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          final mouse = await _mouse(t);
          await _clickChevron(t, mouse);
          final bar = t.getRect(find.byType(LedgerSideBar));
          for (final words in _wide) {
            final at = t.getRect(find.text(words));
            if (direction == TextDirection.ltr) {
              expect(at.left, greaterThanOrEqualTo(bar.right), reason: words);
            } else {
              expect(at.right, lessThanOrEqualTo(bar.left), reason: words);
            }
          }
        },
      );
    }
  });

  group('the menu slip', () {
    Widget slip() => LedgerMenu(
      head: 'Spent by month',
      semanticLabel: 'Months',
      items: [
        for (final (i, m) in _months.indexed)
          LedgerMenuItem(
            m,
            amount: 2400.0 + i,
            selected: i == 0,
            onTap: () => _pressed.add(m),
          ),
      ],
    );

    testWidgets(
      "the keys' row and the pointer's never both lit: the pointer moves the lit row, the keys go on from it",
      (t) async {
        await _desktop(t, _host(slip()));
        final mouse = await _mouse(t);
        await _key(t, LogicalKeyboardKey.tab);
        await _key(t, LogicalKeyboardKey.tab);
        expect(_marks(t, _months), {'September 2026': 'keys'});
        await mouse.moveTo(t.getCenter(find.text('August 2026')));
        await t.pumpAndSettle();
        expect(_marks(t, _months), {'August 2026': 'pointer'});
        await _key(t, LogicalKeyboardKey.tab);
        expect(_marks(t, _months), {'July 2026': 'keys'});
      },
    );

    testWidgets(
      "a pointer over it while a field holds the keys lights a row and leaves the field's focus",
      (t) async {
        final field = FocusNode();
        addTearDown(field.dispose);
        await _desktop(
          t,
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 300,
                  child: LedgerTextField(label: 'Note', focusNode: field),
                ),
                const SizedBox(height: 24),
                slip(),
              ],
            ),
          ),
        );
        field.requestFocus();
        await t.pumpAndSettle();
        final mouse = await _mouse(t);
        await mouse.moveTo(t.getCenter(find.text('August 2026')));
        await t.pumpAndSettle();
        expect(_marks(t, _months), {'August 2026': 'pointer'});
        expect(field.hasPrimaryFocus, isTrue);
      },
    );
  });
}
