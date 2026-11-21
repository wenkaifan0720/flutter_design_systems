// A count Minimal speaks with a noun goes through MinimalLocalizations with
// the counts as numbers, so English says "1 day" and "2 days", and a
// translation says them in its own plural forms (Arabic's six, below).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// The app, its Minimal words [words] when given (the platform's own stay
/// English: the count is Minimal's to say).
Widget _app(Widget child, {MinimalLocalizations? words}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: [
    if (words != null) MinimalLocalizations.delegateOf(words),
    RawWidgetsLocalizations.delegate,
  ],
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(body: Center(child: child)),
);

/// What a screen reader hears for the heatmap of [levels].
Future<String> _heard(
  WidgetTester tester,
  List<int> levels, {
  MinimalLocalizations? words,
}) async {
  await tester.pumpWidget(_app(MinimalHeatmap(levels: levels), words: words));
  return tester.getSemantics(find.byType(MinimalHeatmap)).label;
}

/// Arabic counts as CLDR has it: one, two, three to ten, eleven to
/// ninety-nine, and the rest; a translation the package does not ship, so
/// the test brings its own.
class _Arabic extends MinimalLocalizationsEn {
  _Arabic() : super(RawWidgetsLocalizations.forLocale(const Locale('ar')));

  @override
  String daysKeptOf(int kept, int total) => 'أُنجز $kept من ${_days(total)}';

  static String _days(int n) => switch (n % 100) {
    _ when n == 1 => 'يوم واحد',
    _ when n == 2 => 'يومين',
    >= 3 && <= 10 => '$n أيام',
    >= 11 && <= 99 => '$n يومًا',
    _ => '$n يوم',
  };
}

void main() {
  testWidgets('a heatmap says "day" for one and "days" for two', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    expect(await _heard(tester, [2]), '1 of 1 day kept');
    expect(await _heard(tester, [1, 0]), '1 of 2 days kept');
    expect(await _heard(tester, [0]), '0 of 1 day kept');
    semantics.dispose();
  });

  testWidgets('a heatmap speaks the app\'s language in its plural forms', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final ar = _Arabic();
    expect(await _heard(tester, [2], words: ar), 'أُنجز 1 من يوم واحد');
    expect(await _heard(tester, [2, 2], words: ar), 'أُنجز 2 من يومين');
    expect(await _heard(tester, [2, 0, 1], words: ar), 'أُنجز 2 من 3 أيام');
    expect(
      await _heard(tester, List.filled(11, 1), words: ar),
      'أُنجز 11 من 11 يومًا',
    );
    expect(
      await _heard(tester, List.filled(100, 0), words: ar),
      'أُنجز 0 من 100 يوم',
    );
    semantics.dispose();
  });

  testWidgets('an avatar group says how many more it holds in the app\'s '
      'words', (tester) async {
    final semantics = tester.ensureSemantics();
    Future<String> heard(List<String> names) async {
      await tester.pumpWidget(_app(MinimalAvatarGroup(names, max: 2)));
      return tester.getSemantics(find.byType(MinimalAvatarGroup)).label;
    }

    expect(await heard(['Ana Souza', 'Ben Okafor']), contains('Ben Okafor'));
    expect(
      await heard(['Ana Souza', 'Ben Okafor', 'Chen Wei']),
      contains('and 1 more'),
    );
    expect(
      await heard(['Ana Souza', 'Ben Okafor', 'Chen Wei', 'Dara Kelly']),
      contains('and 2 more'),
    );
    semantics.dispose();
  });

  test("English's words: the counts as numbers, the noun by them", () {
    const en = MinimalLocalizationsEn();
    expect(en.daysKeptOf(1, 1), '1 of 1 day kept');
    expect(en.daysKeptOf(2, 2), '2 of 2 days kept');
    expect(en.daysKept(4), '4 of 7 days kept');
    expect(en.namesAndMore(['Ana'], 0), 'Ana');
    expect(en.namesAndMore(['Ana', 'Ben'], 1), 'Ana, Ben and 1 more');
  });
}
