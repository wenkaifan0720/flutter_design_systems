// A time picker speaks the app's language: its hour and minute wheels are
// named, and its AM and PM marks written, in ui_core's words for the locale
// (Arabic's ساعة, دقيقة, ص and م; German's Stunde and Minute), with or
// without Fluent 2's delegate installed. English is as it was, and an app's
// own words win.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _pick = ValueKey('pick');

/// An app in [locale] with [delegates], a button on its one page that opens
/// a time picker.
Widget _app(
  Locale locale, {
  List<LocalizationsDelegate<Object>> delegates = const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
}) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: [locale],
  localizationsDelegates: delegates,
  builder: (context, child) => Fluent2Host(child: child!),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => Center(
      child: Builder(
        builder: (context) => Fluent2Button(
          'Pick',
          key: _pick,
          onPressed: () =>
              showFluent2TimePicker(context, value: const Fluent2Time(9, 30)),
        ),
      ),
    ),
  ),
);

/// Every label and value a screen reader hears.
List<String> _heard(WidgetTester tester) {
  final said = <String>[];
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) said.add(data.label);
    if (data.value.isNotEmpty) said.add(data.value);
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return said;
}

Fluent2Localizations _words(WidgetTester tester) =>
    Fluent2Localizations.of(tester.element(find.byKey(_pick)));

/// Each language's hour, minute, AM and PM.
const _time = {
  'en': ('Hour', 'Minute', 'AM', 'PM'),
  'ar': ('ساعة', 'دقيقة', 'ص', 'م'),
  'de': ('Stunde', 'Minute', 'AM', 'PM'),
};

class _OwnWords extends Fluent2LocalizationsEn {
  const _OwnWords();

  @override
  String get hour => 'Std.';
}

class _OwnDelegate extends LocalizationsDelegate<Fluent2Localizations> {
  const _OwnDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Fluent2Localizations> load(Locale locale) =>
      SynchronousFuture<Fluent2Localizations>(const _OwnWords());

  @override
  bool shouldReload(_OwnDelegate old) => false;
}

void main() {
  for (final MapEntry(key: language, value: (hour, minute, am, pm))
      in _time.entries) {
    testWidgets('$language: a time picker names its wheels "$hour" and '
        '"$minute", and writes "$am" and "$pm"', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(Locale(language)));
      await tester.pumpAndSettle();
      final words = _words(tester);
      expect(
        (words.hour, words.minute, words.am, words.pm),
        (hour, minute, am, pm),
      );

      await tester.tap(find.byKey(_pick));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final heard = _heard(tester);
      expect(heard.where((s) => s.contains(hour)), isNotEmpty);
      expect(heard.where((s) => s.contains(minute)), isNotEmpty);
      if (language != 'en') {
        expect(heard.where((s) => s.contains('Hour')), isEmpty);
      }
      semantics.dispose();
    });
  }

  testWidgets("without Fluent 2's delegate, the time words still follow "
      "ui_core's", (tester) async {
    await tester.pumpWidget(
      _app(
        const Locale('ar'),
        delegates: const [RawWidgetsLocalizations.delegate],
      ),
    );
    await tester.pumpAndSettle();
    final words = _words(tester);
    expect((words.hour, words.minute, words.am, words.pm), _time['ar']);
  });

  testWidgets("an app's own words win", (tester) async {
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        delegates: const [RawWidgetsLocalizations.delegate, _OwnDelegate()],
      ),
    );
    await tester.pumpAndSettle();
    expect(_words(tester).hour, 'Std.');
  });
}
