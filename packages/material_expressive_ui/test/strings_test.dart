// ExpressiveLocalizations (strings.dart): the words components say on their
// own come from two places. The shared ones from the app's
// DesignLocalizations (ui_core's, one set for every look): a secure field's
// reveal toggle, a dialog's Cancel. The look's own from its
// ExpressiveLocalizations (a delegate's, or a host's
// ExpressiveLocalizationsScope): a chat bubble's sender and status, a
// combobox's menu toggle.
library;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

class _FrenchWords extends DefaultDesignLocalizations {
  const _FrenchWords();

  @override
  String get showPasswordLabel => 'Afficher le mot de passe';

  @override
  String get hidePasswordLabel => 'Masquer le mot de passe';

  @override
  String get cancelButtonLabel => 'Annuler';
}

class _French<T> extends LocalizationsDelegate<T> {
  const _French(this.words);

  final T words;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => SynchronousFuture<T>(words);

  @override
  bool shouldReload(_French<T> old) => false;
}

const ExpressiveLocalizations _frenchOwn = ExpressiveLocalizations(
  messageFromYou: 'Vous',
  messageFailed: 'Non envoyé',
  showSuggestions: 'Afficher les suggestions',
  hideSuggestions: 'Masquer les suggestions',
  selectDate: 'Choisir une date',
);

/// [child] under an app whose delegates give the shared words in French,
/// and the look's own through its delegate ([own] null: English) or a
/// scope ([scoped]).
Widget _app(
  Widget child, {
  ExpressiveLocalizations? own,
  ExpressiveLocalizations? scoped,
}) => MaterialApp(
  localizationsDelegates: <LocalizationsDelegate<dynamic>>[
    const _French<DesignLocalizations>(_FrenchWords()),
    if (own != null) _French<ExpressiveLocalizations>(own),
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  home: ExpressiveHost(
    light: _theme,
    brightness: Brightness.light,
    child: Center(
      child: SizedBox(
        width: 360,
        child: scoped == null
            ? child
            : ExpressiveLocalizationsScope(strings: scoped, child: child),
      ),
    ),
  ),
);

Future<ExpressiveLocalizations> _read(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  return ExpressiveLocalizations.of(tester.element(find.byType(SizedBox).last));
}

void main() {
  testWidgets("a secure field names its reveal toggle from the app's shared "
      'words', (tester) async {
    await tester.pumpWidget(
      _app(const ExpressiveTextField(label: 'Mot de passe', obscureText: true)),
    );
    await tester.tap(find.bySemanticsLabel('Afficher le mot de passe'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Masquer le mot de passe'), findsOneWidget);
  });

  testWidgets('the shared words read the app, the look\'s own its delegate', (
    tester,
  ) async {
    final english = await _read(tester, _app(const SizedBox()));
    expect(english.cancel, 'Annuler');
    expect(english.back, 'Back');
    expect(english.selectDate, 'Select date');
    final french = await _read(tester, _app(const SizedBox(), own: _frenchOwn));
    expect(french.cancel, 'Annuler');
    expect(french.selectDate, 'Choisir une date');
    expect(french.toastDismiss, 'Dismiss');
  });

  testWidgets('a chat bubble says its sender and status from the scope', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const ExpressiveMessageBubble(
          text: 'On arrive',
          side: ExpressiveMessageSide.outgoing,
          timestamp: '6:04',
          status: ExpressiveMessageStatus.failed,
        ),
        scoped: _frenchOwn,
      ),
    );
    expect(find.text('Non envoyé'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Vous, On arrive, 6:04, Non envoyé'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a combobox names its menu toggle from the delegate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ExpressiveCombobox<String>(
          label: 'Ville',
          options: <ExpressiveSelectOption<String>>[
            ExpressiveSelectOption('paris', 'Paris'),
            ExpressiveSelectOption('lyon', 'Lyon'),
          ],
        ),
        own: _frenchOwn,
      ),
    );
    expect(find.bySemanticsLabel('Afficher les suggestions'), findsOneWidget);
  });
}
