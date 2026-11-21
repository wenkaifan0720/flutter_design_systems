// The words Frosted's parts share with every design system (Done, Try again, a day's and a month's names, a time) are
// the reader's: in German, with FrostedLocalizations.delegate installed, ui_core's RawWidgetsLocalizations words; in
// English, Frosted's own ("Monday, March 9, 2026"); an app's own Frosted words, when it gives them, in any language.
// They were English in every locale.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

class _Own extends FrostedLocalizationsEn {
  const _Own();

  @override
  String get tryAgain => 'Nochmal';
}

class _OwnDelegate extends LocalizationsDelegate<FrostedLocalizations> {
  const _OwnDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FrostedLocalizations> load(Locale locale) =>
      SynchronousFuture<FrostedLocalizations>(const _Own());

  @override
  bool shouldReload(_OwnDelegate old) => false;
}

final _day = DateTime(2026, 3, 9);

Future<void> _pump(
  WidgetTester tester,
  Locale locale,
  Widget child, {
  bool own = false,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      localizationsDelegates: [
        RawWidgetsLocalizations.delegate,
        if (own) const _OwnDelegate() else FrostedLocalizations.delegate,
      ],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, page) =>
          FrostedHost(brightness: Brightness.light, child: page!),
      home: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 358, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'no locale warning');
}

/// Whether a node in the tree is named [name] (alone or ahead of its value).
bool _named(WidgetTester tester, String name) => find.semantics
    .byPredicate((n) => n.label == name || n.label.startsWith('$name\n'))
    .evaluate()
    .isNotEmpty;

String? _told;

final _parts = Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    FrostedDatePicker(value: _day, currentDate: _day, onChanged: (_) {}),
    FrostedCalendar(
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      value: _day,
      currentDate: _day,
      onChanged: (_) {},
    ),
    FrostedErrorState(title: 'Offline', onRetry: () {}),
    const FrostedDoneMark(),
    Builder(
      builder: (context) {
        _told = const FrostedTime(hour: 21, minute: 5).format(context);
        return const SizedBox.shrink();
      },
    ),
  ],
);

void main() {
  testWidgets("in German the parts say RawWidgetsLocalizations' words", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const de = Locale('de');
    final words = RawWidgetsLocalizations.forLocale(de);
    await _pump(tester, de, _parts);
    final month = words.formatMonthYear(_day);
    expect(month, isNot('March 2026'));
    expect(find.text(month), findsWidgets, reason: 'the months head');
    expect(find.text('March 2026'), findsNothing);
    final day = words.formatFullDate(_day);
    expect(_named(tester, day), isTrue, reason: day);
    expect(_named(tester, 'Monday, March 9, 2026'), isFalse);
    expect(find.text(words.retryButtonLabel), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(_named(tester, words.doneButtonLabel), isTrue);
    expect(
      _told,
      words.formatTimeOfDay(const RawTimeOfDay(hour: 21, minute: 5)),
    );
    semantics.dispose();
  });

  testWidgets("in English the parts say Frosted's own words", (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const Locale('en'), _parts);
    expect(find.text('March 2026'), findsWidgets);
    expect(_named(tester, 'Monday, March 9, 2026'), isTrue);
    expect(find.text('Try again'), findsOneWidget);
    expect(_named(tester, 'Done'), isTrue);
    expect(_told, '9:05 PM');
    semantics.dispose();
  });

  testWidgets("an app's own Frosted words win in German", (tester) async {
    await _pump(tester, const Locale('de'), _parts, own: true);
    expect(find.text('Nochmal'), findsOneWidget);
  });
}
