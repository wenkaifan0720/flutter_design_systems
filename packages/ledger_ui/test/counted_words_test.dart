// Counted words take their plural form. A text area's count of what is left speaks Material's counted words, which
// material_ui gives in the app's language with its plural forms (Polish: one, few, many); the visit ruler's own
// English says "1 payment" and "2 payments".
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

Widget _app(Locale locale, Widget page) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  localizationsDelegates: const [RawWidgetsLocalizations.delegate],
  builder: (context, _) => LedgerHost(
    brightness: Brightness.light,
    child: Navigator(
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (_, _, _) =>
            Center(child: SizedBox(width: 340, child: page)),
      ),
    ),
  ),
);

/// Every label a screen reader can reach.
List<String> _spoken(WidgetTester t) {
  final words = <String>[];
  void walk(SemanticsNode node) {
    if (!node.isMergedIntoParent) {
      final label = node.getSemanticsData().label;
      if (label.isNotEmpty) words.add(label);
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  for (final view in t.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) walk(root);
  }
  return words;
}

Matcher _says(String words) => contains(contains(words));

/// A text area of [maxLength] holding [typed], under [locale].
Future<void> _area(
  WidgetTester t,
  Locale locale,
  int maxLength,
  String typed,
) async {
  await t.pumpWidget(
    _app(locale, LedgerTextArea(labelText: 'Memo', maxLength: maxLength)),
  );
  await t.pumpAndSettle();
  await t.enterText(find.byType(EditableText), typed);
  await t.pumpAndSettle();
}

void main() {
  for (final (left, words) in const [
    (1, '1 character remaining'),
    (2, '2 characters remaining'),
    (0, 'No characters remaining'),
  ]) {
    testWidgets('a text area with $left left says "$words" in English', (
      t,
    ) async {
      await _area(t, const Locale('en'), 5, 'a' * (5 - left));
      expect(_spoken(t), _says(words));
      expect(_spoken(t).join(' '), isNot(contains('characters left')));
    });
  }

  for (final (left, words) in const [
    (1, 'Jeszcze 1 znak'),
    (2, 'Pozostały 2 znaki'),
    (5, 'Pozostało 5 znaków'),
  ]) {
    testWidgets('a text area with $left left says "$words" in Polish', (
      t,
    ) async {
      await _area(t, const Locale('pl'), 8, 'a' * (8 - left));
      expect(_spoken(t), _says(words));
    });
  }

  for (final (count, words) in const [
    (1, '1 payment this month'),
    (2, '2 payments this month'),
  ]) {
    testWidgets('a visit ruler of $count says "$words"', (t) async {
      await t.pumpWidget(
        _app(
          const Locale('en'),
          LedgerVisitRuler(
            visits: [for (var i = 0; i < count; i++) (3 + i, 6.5)],
            days: 31,
            today: 28,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(_spoken(t), contains(words));
    });
  }
}
