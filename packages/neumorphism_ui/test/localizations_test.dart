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
