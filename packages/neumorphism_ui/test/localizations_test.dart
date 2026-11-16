import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class _French extends NeumorphicLocalizationsEn {
  const _French() : super(localeName: 'fr');
  @override
  String get close => 'Fermer';
}

class _Words extends DefaultWidgetsLocalizations {
  const _Words();
  @override
  String get copyButtonLabel => 'Copy from Widgets';
}

void main() {
  test('default English formats before any delegate initializes intl', () {
    const words = NeumorphicLocalizationsEn();
    final date = DateTime(2026, 11, 6, 9, 5);
    expect(words.formatDay(date), '6');
    expect(words.formatMonthYear(date), 'November 2026');
    expect(words.formatFullDate(date), contains('Friday'));
    expect(words.formatTime(date), '09:05');
    expect(words.firstDayOfWeek, DateTime.sunday);
  });
  test('English delegate formats dates and numbers through intl', () async {
    final words = await NeumorphicLocalizations.delegate.load(
      const Locale('en', 'GB'),
    );
    expect(words.formatNumber(1234.5), '1,234.5');
    expect(words.formatPercent(.75), '75%');
    expect(words.formatTime(DateTime(2026, 11, 6, 9)), '09:00');
    expect(words.formatDay(DateTime(2026, 11, 6)), '6');
    expect(words.formatFullDate(DateTime(2026, 11, 6)), contains('November'));
    expect(words.formatMonthYear(DateTime(2026, 11)), 'November 2026');
  });
  test(
    'a custom language supplies words and regional number/date formatting',
    () async {
      await initializeDateFormatting('fr');
      const words = _French();
      expect(words.close, 'Fermer');
      expect(words.formatNumber(12.5), '12,5');
      expect(words.formatMonthYear(DateTime(2026, 11)), 'novembre 2026');
    },
  );
  testWidgets('without a look delegate editing words fall back to Widgets', (
    tester,
  ) async {
    late NeumorphicLocalizations words;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: const [_WidgetsDelegate()],
        child: Builder(
          builder: (context) {
            words = NeumorphicLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(words.copy, 'Copy from Widgets');
    expect(words.close, 'Close');
  });
  testWidgets('the words every look shares come from DesignLocalizations', (
    tester,
  ) async {
    late NeumorphicLocalizations words;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fr'),
        delegates: const [_SharedDelegate(), _WidgetsDelegate()],
        child: Builder(
          builder: (context) {
            words = NeumorphicLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(words.close, 'Fermer');
    expect(words.pageOf(3, 10), '3 sur 10');
    expect(words.cancel, 'Cancel');
  });
  for (final (locale, direction) in const [
    (Locale('ar'), TextDirection.rtl),
    (Locale('de'), TextDirection.ltr),
  ]) {
    // The Material machinery under a field needs Material's words; Flutter's own delegate loads only in English,
    // so under an app in another language a field threw for want of them.
    testWidgets('a field builds under an app in ${locale.languageCode} with '
        'no Material words, and says ui_core\'s words in it', (tester) async {
      late NeumorphicLocalizations words;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          locale: locale,
          supportedLocales: DesignLocalizations.supportedLocales,
          localizationsDelegates: const [DesignLocalizations.delegate],
          builder: (context, _) => Directionality(
            textDirection: direction,
            // The app's overlay under the theme, as a Navigator under an app's builder: is.
            child: NeumorphicTheme(
              data: NeumorphicThemeData.porcelain(),
              child: Overlay.wrap(
                child: Builder(
                  builder: (context) {
                    words = NeumorphicLocalizations.of(context);
                    return const Center(
                      child: SizedBox(
                        width: 320,
                        child: NeumorphicTextField(
                          label: 'Name',
                          hint: 'As on your card',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(NeumorphicTextField), findsOneWidget);
      final shared = DesignLocalizations.forLocale(locale);
      expect(words.close, shared.closeButtonLabel);
      expect(words.close, isNot('Close'));
    });
    // On iOS the editable reads Cupertino's words as well as Material's (its menu, its magnifier): a test that only
    // builds a field or types in it never shows them.
    testWidgets('on iOS a selection in a field opens its menu under an app '
        'in ${locale.languageCode} with no Material or Cupertino words', (
      tester,
    ) async {
      final text = TextEditingController(text: 'Morgan');
      addTearDown(text.dispose);
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          locale: locale,
          supportedLocales: DesignLocalizations.supportedLocales,
          localizationsDelegates: const [DesignLocalizations.delegate],
          builder: (context, _) => Directionality(
            textDirection: direction,
            child: NeumorphicTheme(
              data: NeumorphicThemeData.porcelain(),
              child: Overlay.wrap(
                child: Center(
                  child: SizedBox(
                    width: 320,
                    child: NeumorphicTextField(label: 'Name', controller: text),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final editable = find.byType(EditableText);
      final word = direction == TextDirection.rtl
          ? tester.getTopRight(editable) + const Offset(-12, 8)
          : tester.getTopLeft(editable) + const Offset(12, 8);
      // A long press shows the magnifier; a double tap selects the word and opens the menu.
      final press = await tester.startGesture(word);
      await tester.pump(const Duration(milliseconds: 600));
      await press.moveBy(const Offset(4, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await press.up();
      await tester.pumpAndSettle();
      await tester.tapAt(word);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(word);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        text.selection.isCollapsed,
        isFalse,
        reason: 'the word is selected',
      );
      final state = tester.state<EditableTextState>(editable);
      expect(
        state.selectionOverlay?.toolbarIsVisible,
        isTrue,
        reason: 'its menu is open',
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }
}

class _SharedFrench extends DefaultDesignLocalizations {
  const _SharedFrench();
  @override
  String get closeButtonLabel => 'Fermer';
  @override
  String positionLabel(int position, int count) => '$position sur $count';
}

class _SharedDelegate extends LocalizationsDelegate<DesignLocalizations> {
  const _SharedDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<DesignLocalizations> load(Locale locale) async =>
      const _SharedFrench();
  @override
  bool shouldReload(_SharedDelegate old) => false;
}

class _WidgetsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _WidgetsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) async => const _Words();
  @override
  bool shouldReload(_WidgetsDelegate old) => false;
}
