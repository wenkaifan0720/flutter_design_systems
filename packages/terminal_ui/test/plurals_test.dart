// A count Terminal says comes through its localizations whole, so English
// says one person and two people, and a language with more plural forms
// words each of them: Polish here, through an app's subclass and its
// delegate (1 osoba, 2 osoby, 5 osób, 12 osób, 22 osoby).
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

/// An app's Polish words, as an app adds them: a subclass of the English
/// ones and a delegate for it.
class _PolishTerm extends DefaultTermLocalizations {
  const _PolishTerm();

  static const delegate = _PolishTermDelegate();

  @override
  String avatarGroupLabel(List<String> names) {
    final n = names.length;
    final ones = n % 10, tens = n % 100;
    final who = switch (n) {
      1 => 'osoba',
      _ when ones >= 2 && ones <= 4 && (tens < 12 || tens > 14) => 'osoby',
      _ => 'osób',
    };
    return '$n $who: ${names.join(', ')}';
  }
}

class _PolishTermDelegate extends LocalizationsDelegate<TermLocalizations> {
  const _PolishTermDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'pl';

  @override
  Future<TermLocalizations> load(Locale locale) =>
      SynchronousFuture<TermLocalizations>(const _PolishTerm());

  @override
  bool shouldReload(_PolishTermDelegate old) => false;
}

List<String> _people(int n) => [for (var i = 1; i <= n; i++) 'p$i'];

/// What a screen reader hears for a [TermAvatarGroup] of [n] people, in
/// [locale] with [delegates].
Future<String> _heard(
  WidgetTester tester,
  int n, {
  Locale locale = const Locale('en'),
  List<LocalizationsDelegate<Object>> delegates = const [],
}) async {
  final semantics = tester.ensureSemantics();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Localizations(
        locale: locale,
        delegates: [...delegates, DefaultWidgetsLocalizations.delegate],
        child: TermTheme(
          data: TermThemeData.dark(),
          child: Align(child: TermAvatarGroup(names: _people(n), max: 2)),
        ),
      ),
    ),
  );
  final label = tester
      .getSemantics(find.byType(TermAvatarGroup))
      .getSemanticsData()
      .label;
  semantics.dispose();
  return label;
}

void main() {
  test('English: one person, two people, and who', () {
    const en = DefaultTermLocalizations();
    expect(
      en.avatarGroupLabel(const ['Ada Lovelace']),
      '1 person: Ada Lovelace',
    );
    expect(
      en.avatarGroupLabel(const ['Ada Lovelace', 'Alan Turing']),
      '2 people: Ada Lovelace, Alan Turing',
    );
  });

  testWidgets('an avatar group says 1 person and 2 people', (tester) async {
    expect(await _heard(tester, 1), '1 person: p1');
    expect(await _heard(tester, 2), '2 people: p1, p2');
    expect(await _heard(tester, 5), '5 people: p1, p2, p3, p4, p5');
  });

  testWidgets("an app's Polish words every plural form", (tester) async {
    Future<String> pl(int n) => _heard(
      tester,
      n,
      locale: const Locale('pl'),
      delegates: const [_PolishTerm.delegate],
    );
    expect(await pl(1), '1 osoba: p1');
    expect(await pl(2), '2 osoby: p1, p2');
    expect(await pl(5), startsWith('5 osób: '));
    expect(await pl(12), startsWith('12 osób: '));
    expect(await pl(22), startsWith('22 osoby: '));
  });

  testWidgets('a locale with no words of its own gets English', (tester) async {
    expect(
      await _heard(tester, 2, locale: const Locale('pl')),
      '2 people: p1, p2',
    );
  });
}
