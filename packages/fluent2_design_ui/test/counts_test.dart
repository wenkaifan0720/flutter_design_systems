// Counts a part speaks: a rating's score and how many scores it is made of, an avatar group's names and how many it
// folds into its "+N". Each comes from Fluent2Localizations with the count, so English says "1 rating" and "2 ratings",
// and a language with more plural forms (Polish here: one, few, many) picks its own.
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

Widget _app(Widget page, {Fluent2Localizations? words}) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: words == null ? const Locale('en') : const Locale('pl'),
  supportedLocales: const [Locale('en'), Locale('pl')],
  localizationsDelegates: [
    if (words != null) _Words(words),
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => Fluent2Host(child: child!),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) =>
        Center(child: SizedBox(width: 320, child: page)),
  ),
);

String _label(WidgetTester t, Type part) {
  final semantics = t.ensureSemantics();
  final label = t.getSemantics(find.byType(part)).label;
  semantics.dispose();
  return label;
}

const _people = [
  Fluent2AvatarPerson('Ana Silva'),
  Fluent2AvatarPerson('Kai Tanaka'),
  Fluent2AvatarPerson('Mara Okafor'),
  Fluent2AvatarPerson('Tomás Ruiz'),
  Fluent2AvatarPerson('Lena Vogel'),
  Fluent2AvatarPerson('Omar Haddad'),
];

void main() {
  for (final (words, count, said) in [
    (null, 1, 'Rated 4 out of 5, 1 rating'),
    (null, 2, 'Rated 4 out of 5, 2 ratings'),
    (const _Polish(), 1, 'Ocena 4 na 5, 1 ocena'),
    (const _Polish(), 2, 'Ocena 4 na 5, 2 oceny'),
    (const _Polish(), 5, 'Ocena 4 na 5, 5 ocen'),
  ]) {
    testWidgets('a rating made of $count scores says "$said"', (t) async {
      await t.pumpWidget(
        _app(Fluent2RatingDisplay(value: 4, count: count), words: words),
      );
      expect(_label(t, Fluent2RatingDisplay), said);
    });
  }

  for (final (words, shown, said) in [
    (null, 3, 'Ana Silva, Kai Tanaka, Mara Okafor and 3 more'),
    (null, 4, 'Ana Silva, Kai Tanaka, Mara Okafor, Tomás Ruiz and 2 more'),
    (
      const _Polish(),
      4,
      'Ana Silva, Kai Tanaka, Mara Okafor, Tomás Ruiz i 2 inne osoby',
    ),
    (const _Polish(), 1, 'Ana Silva i 5 innych osób'),
  ]) {
    testWidgets('an avatar group of 6 showing $shown says "$said"', (t) async {
      await t.pumpWidget(
        _app(
          Fluent2AvatarGroup(people: _people, max: shown + 1),
          words: words,
        ),
      );
      expect(_label(t, Fluent2AvatarGroup), said);
    });
  }
}

/// Polish: one (1), few (2-4, 22-24, ..., not 12-14), many (the rest).
enum _Form { one, few, many }

_Form _polish(int n) {
  if (n == 1) return _Form.one;
  final (ten, hundred) = (n % 10, n % 100);
  return ten >= 2 && ten <= 4 && (hundred < 12 || hundred > 14)
      ? _Form.few
      : _Form.many;
}

/// A language an app adds: the counts in Polish.
class _Polish extends Fluent2LocalizationsEn {
  const _Polish();

  @override
  String ratedOutOf(String value, int max) => 'Ocena $value na $max';

  @override
  String ratingsCount(int count, String counted) => switch (_polish(count)) {
    _Form.one => '$counted ocena',
    _Form.few => '$counted oceny',
    _Form.many => '$counted ocen',
  };

  @override
  String namesAndMore(String names, int more) => switch (_polish(more)) {
    _Form.one => '$names i jeszcze jedna osoba',
    _Form.few => '$names i $more inne osoby',
    _Form.many => '$names i $more innych osób',
  };
}

/// [words] in any locale.
class _Words extends LocalizationsDelegate<Fluent2Localizations> {
  const _Words(this.words);

  final Fluent2Localizations words;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Fluent2Localizations> load(Locale locale) =>
      SynchronousFuture<Fluent2Localizations>(words);

  @override
  bool shouldReload(_Words old) => false;
}
