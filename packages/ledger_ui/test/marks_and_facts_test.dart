// Ledger's marks and facts as an adopter places them: a monogram takes a
// name's first and last initials; a monogram and an avatar grow with a larger
// text, to the marks' 130%, as a tag does; a record's facts keep their grid in
// a desktop column with room and stand one under another in a side column.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  double width = 390,
  double text = 1,
}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: LedgerHost(
          brightness: Brightness.light,
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

const _facts = [
  LedgerFact('Spent', r'$1,284', note: 'This month'),
  LedgerFact('Left', r'$716', note: '9 days to go'),
  LedgerFact('Pace', '84%', note: 'Day 21 of 30'),
];

void main() {
  test("a monogram's letters are the first and the last word's", () {
    expect(LedgerFormat.initials('Ursula K. Le Guin'), 'UG');
    expect(LedgerFormat.initials('Blue Fern Café'), 'BC');
    expect(LedgerFormat.initials('George Eliot'), 'GE');
    expect(LedgerFormat.initials('Cloudbox'), 'CL');
  });

  testWidgets('a monogram and an avatar grow with the text, to 130%', (
    tester,
  ) async {
    Size sizes(String key) => tester.getSize(find.byKey(Key(key)));
    const marks = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LedgerMonogram('George Eliot', key: Key('mono')),
        LedgerAvatar(key: Key('avatar'), initials: 'GE'),
      ],
    );
    await _pump(tester, marks);
    final mono = sizes('mono'), avatar = sizes('avatar');
    await _pump(tester, marks, text: 1.2);
    expect(sizes('mono').width, moreOrLessEquals(mono.width * 1.2));
    expect(sizes('avatar').width, moreOrLessEquals(avatar.width * 1.2));
    await _pump(tester, marks, text: 2);
    expect(sizes('mono').width, moreOrLessEquals(mono.width * 1.3));
    expect(sizes('avatar').width, moreOrLessEquals(avatar.width * 1.3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('facts keep their grid in a desktop column with room', (
    tester,
  ) async {
    Rect at(String label) => tester.getRect(find.text(label.toUpperCase()));
    await _pump(
      tester,
      const SizedBox(
        width: 900,
        child: LedgerFacts(facts: _facts, columns: LedgerFactColumns.three),
      ),
      width: 1440,
    );
    expect(at('Left').top, moreOrLessEquals(at('Spent').top));
    expect(at('Pace').left, greaterThan(at('Left').left));
    await _pump(
      tester,
      const SizedBox(
        width: 300,
        child: LedgerFacts(facts: _facts, columns: LedgerFactColumns.three),
      ),
      width: 1440,
    );
    expect(at('Left').top, greaterThan(at('Spent').bottom));
    expect(at('Left').left, moreOrLessEquals(at('Spent').left));
  });
}
