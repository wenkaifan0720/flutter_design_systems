// Ledger draws ink on paper, so a held control stays where it is printed and
// says it is pressed in its ink: its marks deepen a shade toward the ink and
// the bare paper of its face takes the same ink (LedgerImpression), and a
// held menu command's underline grows heavier. The
// primary act and the tab bar's Move disc are green printed on the page and
// cast no drop in any theme.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/src/ledger/internal/face.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          LedgerHost(brightness: brightness, child: page!),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: SizedBox(width: 600, child: child),
        ),
      ),
    );

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Brightness? brightness,
}) async {
  t.view.physicalSize = const Size(1440, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(child, brightness: brightness ?? Brightness.light));
  await t.pumpAndSettle();
}

/// The depth of the impression over [finder]'s nearest held face.
double _depth(WidgetTester t, Finder finder) => t
    .widget<LedgerImpression>(
      find.ancestor(of: finder, matching: find.byType(LedgerImpression)).first,
    )
    .depth;

void main() {
  group('the primary act', () {
    test('casts no drop in any Ledger theme', () {
      for (final id in LedgerThemeData.presets) {
        for (final b in Brightness.values) {
          expect(
            LedgerThemeData.preset(id, b).primaryShadow,
            isEmpty,
            reason: '$id $b',
          );
        }
      }
      expect(LedgerThemeData.light().primaryShadow, isEmpty);
      expect(LedgerThemeData.dark().primaryShadow, isEmpty);
    });

    test('the Move disc casts none either', () {
      for (final id in LedgerThemeData.presets) {
        for (final b in Brightness.values) {
          expect(
            LedgerThemeData.preset(id, b).discShadow,
            isEmpty,
            reason: '$id $b',
          );
        }
      }
      expect(LedgerThemeData.light().discShadow, isEmpty);
      expect(LedgerThemeData.dark().discShadow, isEmpty);
    });

    for (final b in Brightness.values) {
      testWidgets('stays on the page and deepens while held ($b)', (t) async {
        await _pump(
          t,
          LedgerButton.filled(
            'Continue',
            icon: LucideIcons.arrowRight,
            iconAfter: true,
            onPressed: () {},
          ),
          brightness: b,
        );
        final theme = t.element(find.text('Continue')).ledgerTheme;
        BoxDecoration face() => t
            .widgetList<Container>(
              find.ancestor(
                of: find.text('Continue'),
                matching: find.byType(Container),
              ),
            )
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .first;
        expect(face().boxShadow ?? const <BoxShadow>[], isEmpty);
        expect(face().color, theme.accent);
        final rest = t.getRect(find.text('Continue'));

        final finger = await t.startGesture(t.getCenter(find.text('Continue')));
        await t.pumpAndSettle();
        expect(t.getRect(find.text('Continue')), rest);
        expect(face().boxShadow ?? const <BoxShadow>[], isEmpty);
        // The fill sinks a quarter of the way into the ink, and the
        // impression over it deepens it with the words.
        expect(
          face().color,
          isSameColorAs(Color.lerp(theme.accent, theme.textPrimary, .25)!),
        );
        expect(_depth(t, find.text('Continue')), LedgerImpression.pressed);

        await finger.up();
        await t.pumpAndSettle();
        expect(_depth(t, find.text('Continue')), 0);
        expect(t.getRect(find.text('Continue')), rest);
      });
    }
  });

  group('a held control keeps its place', () {
    final parts = <String, Widget>{
      'Blue Fern Café': LedgerTransactionRow(
        title: 'Blue Fern Café',
        category: 'Dining out',
        when: '8:12 AM',
        account: 'Everyday Card',
        amount: -6.75,
        pending: true,
        onTap: () {},
      ),
      'Paid': LedgerChip('Paid', onTap: () {}),
      'Bills': LedgerToggleRow(
        icon: LucideIcons.receipt,
        title: 'Bills',
        subtitle: 'A reminder before each bill is due',
        value: false,
        onChanged: (_) {},
      ),
      'Order the cotton paper': LedgerCheckbox(
        value: false,
        label: 'Order the cotton paper',
        onChanged: (_) {},
      ),
      'As the system is': LedgerRadio<String>(
        value: 'system',
        groupValue: 'light',
        label: 'As the system is',
        onChanged: (_) {},
      ),
      'Notes': LedgerTabs(
        tabs: const ['Entries', 'Notes'],
        counts: const [12, 3],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      'Lisbon in May': LedgerGoalCard(
        icon: LucideIcons.plane,
        name: 'Lisbon in May',
        saved: 2840,
        target: 4000,
        by: 'by May 2027',
        status: 'Behind',
        behindSchedule: true,
        note: r'Add $110 to stay on track.',
        onTap: () {},
      ),
    };
    for (final MapEntry(key: words, value: part) in parts.entries) {
      testWidgets('$words: its marks deepen in place', (t) async {
        await _pump(t, part);
        final mark = find.textContaining(words, findRichText: true).first;
        final rest = t.getRect(mark);
        expect(_depth(t, mark), 0);

        final finger = await t.startGesture(t.getCenter(mark));
        // Halfway through the motion and at its end, nothing has moved.
        await t.pump(LedgerMotion.fast ~/ 2);
        expect(t.getRect(mark), rest);
        await t.pumpAndSettle();
        expect(t.getRect(mark), rest);
        expect(_depth(t, mark), LedgerImpression.pressed);

        await finger.up();
        await t.pumpAndSettle();
        expect(t.getRect(mark), rest);
        expect(_depth(t, mark), 0);
      });
    }
  });

  testWidgets('a held face paints its marks a shade deeper, not the paper', (
    t,
  ) async {
    await _pump(
      t,
      const ColoredBox(
        color: Color(0xFFFFFFFF),
        child: SizedBox(
          width: 40,
          height: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: LedgerImpression(
              ink: Color(0xFF000000),
              depth: .5,
              child: SizedBox(
                width: 20,
                height: 20,
                child: ColoredBox(color: Color(0xFFFFFFFF)),
              ),
            ),
          ),
        ),
      ),
    );
    final layers = t.layers.whereType<ColorFilterLayer>();
    expect(layers, hasLength(1));
    expect(
      layers.single.colorFilter,
      ColorFilter.mode(
        const Color(0xFF000000).withValues(alpha: .5),
        BlendMode.srcATop,
      ),
    );
  });

  testWidgets('at rest an impression adds no layer', (t) async {
    await _pump(
      t,
      const LedgerImpression(
        ink: Color(0xFF000000),
        depth: 0,
        child: SizedBox(width: 20, height: 20),
      ),
    );
    expect(t.layers.whereType<ColorFilterLayer>(), isEmpty);
  });

  testWidgets('a held menu command draws its underline heavier than hover', (
    t,
  ) async {
    await _pump(
      t,
      LedgerSplitButton(
        'Export',
        onPressed: () {},
        actions: [
          for (final a in ['As CSV', 'As PDF'])
            LedgerSplitAction(label: a, onPressed: () {}),
        ],
      ),
    );
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    final chevron = t.getCenter(find.byIcon(LucideIcons.chevronDown).first);
    await mouse.moveTo(chevron);
    await mouse.down(chevron);
    await mouse.up();
    await t.pumpAndSettle();

    TextStyle words() => t.widget<Text>(find.text('As CSV').last).style!;
    final command = t.getCenter(find.text('As CSV').last);
    await mouse.moveTo(command);
    await t.pumpAndSettle();
    expect(words().decoration, TextDecoration.underline);
    expect(words().decorationStyle, TextDecorationStyle.solid);
    expect(words().decorationThickness, 1);
    final rest = t.getRect(find.text('As CSV').last);

    await mouse.down(command);
    await t.pumpAndSettle();
    expect(words().decoration, TextDecoration.underline);
    expect(words().decorationStyle, TextDecorationStyle.solid);
    expect(words().decorationThickness, 2);
    expect(t.getRect(find.text('As CSV').last), rest);
    await mouse.up();
    await t.pumpAndSettle();
  });
}
