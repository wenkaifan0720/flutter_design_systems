// The example service's counts in the reader's language, each in the form
// its number takes there: English's one and other, and Arabic's six (CLDR's
// zero, one, two, few, many and other), where "1 of every form" would read
// "5 streets" with the noun of 23.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/permits/words.dart';

String _streets(int n, {bool arabic = false}) =>
    permitsCount(n, one: '1 street', other: '# streets', arabic: arabic);

String _applications(int n, {bool arabic = false}) => permitsCount(
  n,
  one: 'Showing 1 application',
  other: 'Showing # applications',
  arabic: arabic,
);

void main() {
  test('in English, 1 has the singular and 2 (and 0) the plural', () {
    expect(_streets(1), '1 street');
    expect(_streets(2), '2 streets');
    expect(_streets(0), '0 streets');
    expect(_applications(1), 'Showing 1 application');
    expect(_applications(2), 'Showing 2 applications');
  });

  test('in Arabic, each count takes its own form', () {
    expect(_streets(0, arabic: true), 'لا توجد شوارع');
    expect(_streets(1, arabic: true), 'شارع واحد');
    expect(_streets(2, arabic: true), 'شارعان');
    expect(_streets(5, arabic: true), '5 شوارع');
    expect(_streets(23, arabic: true), '23 شارعًا');
    expect(_streets(100, arabic: true), '100 شارع');
    expect(_applications(1, arabic: true), 'عرض طلب واحد');
    expect(_applications(2, arabic: true), 'عرض طلبين');
    expect(_applications(3, arabic: true), 'عرض 3 طلبات');
    expect(_applications(11, arabic: true), 'عرض 11 طلبًا');
  });

  test("Arabic's plural categories are CLDR's", () {
    const categories = {
      0: 'zero',
      1: 'one',
      2: 'two',
      3: 'few',
      10: 'few',
      11: 'many',
      99: 'many',
      100: 'other',
      101: 'other',
      102: 'other',
      103: 'few',
      111: 'many',
    };
    for (final MapEntry(key: n, value: category) in categories.entries) {
      expect(permitsArabicPlural(n), category, reason: '$n');
    }
  });

  test('every Arabic count has a form for each category', () {
    for (final MapEntry(key: english, value: forms)
        in permitsArabicCounts.entries) {
      expect(forms.keys.toSet(), {
        'zero',
        'one',
        'two',
        'few',
        'many',
        'other',
      }, reason: english);
    }
  });

  testWidgets('a page right to left counts in Arabic, left to right in '
      'English', (tester) async {
    late String rtl, ltr;
    Widget counting(TextDirection direction, void Function(String) said) =>
        Directionality(
          textDirection: direction,
          child: Builder(
            builder: (context) {
              said(context.sayCount(2, one: '1 street', other: '# streets'));
              return const SizedBox();
            },
          ),
        );
    await tester.pumpWidget(counting(TextDirection.rtl, (s) => rtl = s));
    await tester.pumpWidget(counting(TextDirection.ltr, (s) => ltr = s));
    expect(rtl, 'شارعان');
    expect(ltr, '2 streets');
  });
}
