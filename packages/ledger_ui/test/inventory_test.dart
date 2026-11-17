// Ledger in ui_core's shared inventory (DesignInventory): every row it
// answers is answered once, each absence gives a ledger's reason (not a
// to-do), and every live specimen builds and lays out on a phone and a desk,
// by day and by night, right to left, and at 200% text on a phone, without an
// error. The rows still to build are named here, and the list only shrinks:
// once it is empty the test holds the whole inventory with verify().
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

/// The rows still to build: none, every row is built in Ledger's hand.
const Set<String> _toBuild = {};

const Set<String> _absent = {
  'FloatingActionButton',
  'Rating',
  'ColorPicker',
  'MenuBar',
  'Resizable',
  'TreeView',
  'HoverCard',
};

/// [child] on a page's column; a filling specimen in a band of its own.
Widget _host(
  String id,
  WidgetBuilder builder, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: LedgerHost(brightness: brightness, child: page!),
    ),
  ),
  home: Builder(
    builder: (context) => ColoredBox(
      color: context.ledgerTheme.background,
      child: ledgerInventoryFills.contains(id)
          ? SizedBox(
              height: LedgerInventoryGallery.fillHeight,
              child: Builder(builder: builder),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: LedgerLayout.gutter(context),
                vertical: 24,
              ),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Builder(builder: builder),
              ),
            ),
    ),
  ),
);

void _size(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> _everySpecimen(
  WidgetTester t, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) async {
  for (final entry in ledgerInventory.entries) {
    final builder = entry.builder;
    if (builder == null) continue;
    await t.pumpWidget(
      _host(
        entry.row,
        builder,
        brightness: brightness,
        direction: direction,
        textScale: textScale,
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    final error = t.takeException();
    expect(error, isNull, reason: '${entry.row}: $error');
  }
  // A toast's or a carousel's timers run out before the end.
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 10));
}

void main() {
  test('every row answered once, or named as one still to build', () {
    final missing = <String>{};
    final other = <String>[];
    for (final problem in ledgerInventory.problems) {
      final id = problem.split(':').first;
      if (problem.contains(': missing (')) {
        missing.add(id);
      } else {
        other.add(problem);
      }
    }
    expect(other, isEmpty);
    expect(missing, _toBuild);
    if (_toBuild.isEmpty) ledgerInventory.verify();
  });

  test("each row a ledger leaves out says why, in a ledger's terms", () {
    final absent = [
      for (final e in ledgerInventory.entries)
        if (e.builder == null) e,
    ];
    expect({for (final e in absent) e.row}, _absent);
    for (final e in absent) {
      expect(e.absentReason!.length, greaterThan(40), reason: e.row);
    }
    expect(ledgerInventory.absentCount, _absent.length);
    expect(
      ledgerInventory.presentCount,
      DesignInventoryRow.all.length - _absent.length - _toBuild.length,
    );
  });

  test('each live row names its Ledger part', () {
    for (final e in ledgerInventory.entries) {
      if (e.builder == null) continue;
      expect(ledgerInventoryParts[e.row], isNotNull, reason: e.row);
    }
  });

  for (final brightness in Brightness.values) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      testWidgets('every live specimen lays out: ${brightness.name}, '
          '${size.width.round()} wide', (t) async {
        _size(t, size);
        await _everySpecimen(t, brightness: brightness);
      });
    }
  }

  testWidgets('every live specimen lays out right to left on a phone', (
    t,
  ) async {
    _size(t, const Size(390, 844));
    await _everySpecimen(t, direction: TextDirection.rtl);
  });

  testWidgets('every live specimen lays out at 200% text on a phone', (
    t,
  ) async {
    _size(t, const Size(390, 844));
    await _everySpecimen(t, textScale: 2);
  });

  testWidgets('the inventory page lists every row under its group', (t) async {
    _size(t, const Size(1440, 900));
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) => LedgerHost(child: page!),
        home: const LedgerInventoryGallery(),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    expect(t.takeException(), isNull);
    expect(
      find.text('LedgerButton · ${DesignInventoryRow.button.name}'),
      findsOneWidget,
    );
    // The last group's last row is reached by scrolling, and an absent
    // row reads its reason.
    await t.scrollUntilVisible(
      find.textContaining('Deliberately absent: Nothing floats'),
      200,
    );
    expect(t.takeException(), isNull);
  });
}
