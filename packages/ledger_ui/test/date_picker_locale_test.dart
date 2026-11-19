// Ledger's date picker in another language: its pills, its calendar and its
// wheels print and speak the reader's words, order and digits (ui_core's
// DesignLocalizations), at the reader's size and at twice it, every word
// whole.
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

final DateTime _due = DateTime(2026, 11, 20, 21, 5);

/// Loads every family the test asset bundle declares, so words lay out in
/// their real faces and a cut one is a cut one.
Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _pump(
  WidgetTester t,
  Locale locale,
  double scale,
  Widget picker,
) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: DesignLocalizations.supportedLocales,
      localizationsDelegates: const [DesignLocalizations.delegate],
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: LedgerHost(
            brightness: Brightness.light,
            child: Navigator(
              onGenerateRoute: (_) => PageRouteBuilder<void>(
                pageBuilder: (_, _, _) => Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: picker,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// The words on screen, each line as laid out.
Iterable<RenderParagraph> _lines(WidgetTester t) => t.allRenderObjects
    .whereType<RenderParagraph>()
    .where((p) => p.attached && p.hasSize);

/// The words on screen that are cut short: an ellipsis, or lines lost.
List<String> _cut(WidgetTester t) => [
  for (final p in _lines(t))
    if (p.didExceedMaxLines) p.text.toPlainText(),
];

/// The words on screen with a Latin letter or a Western digit in them.
List<String> _latin(WidgetTester t) => [
  for (final p in _lines(t))
    if (RegExp('[A-Za-z0-9]').hasMatch(p.text.toPlainText()))
      p.text.toPlainText(),
];

void main() {
  setUpAll(_loadFonts);
  for (final scale in const [1.0, 2.0]) {
    final at = '${(scale * 100).round()}%';

    group('in Arabic at $at', () {
      const ar = Locale('ar');
      final words = DesignLocalizations.forLocale(ar);

      testWidgets('the compact line prints and names the day and the clock '
          'in Arabic, its label whole', (t) async {
        final semantics = t.ensureSemantics();
        await _pump(
          t,
          ar,
          scale,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LedgerDatePicker(
                label: 'تاريخ الاستحقاق',
                value: _due,
                onChanged: (_) {},
              ),
              LedgerDatePicker(
                label: 'وقت التذكير',
                mode: LedgerDatePickerMode.time,
                use24hFormat: true,
                value: DateTime(2026, 11, 20, 9, 30),
                onChanged: (_) {},
              ),
              LedgerDatePicker(
                label: 'الموعد',
                mode: LedgerDatePickerMode.dateAndTime,
                value: _due,
                onChanged: (_) {},
              ),
            ],
          ),
        );
        expect(t.takeException(), isNull);
        expect(find.text('٢٠ نوفمبر ٢٠٢٦'), findsNWidgets(2));
        expect(find.text('٠٩:٣٠'), findsOneWidget);
        expect(find.text('٩:٠٥ م'), findsOneWidget);
        expect(_latin(t), isEmpty);
        expect(_cut(t), isEmpty);
        // Each pill is named by its picker's label and read as its value.
        expect(
          t.getSemantics(find.text('٠٩:٣٠')),
          isSemantics(label: 'وقت التذكير', value: '٠٩:٣٠', isButton: true),
        );
        expect(
          t.getSemantics(find.text('٩:٠٥ م')),
          isSemantics(label: 'الموعد', value: '٩:٠٥ م', isButton: true),
        );
        expect(find.bySemanticsLabel(RegExp('date|time')), findsNothing);
        semantics.dispose();
      });

      testWidgets('the day sheet is the month in Arabic', (t) async {
        final semantics = t.ensureSemantics();
        await _pump(
          t,
          ar,
          scale,
          LedgerDatePicker(
            label: 'تاريخ الاستحقاق',
            value: _due,
            today: DateTime(2026, 11, 18),
            onChanged: (_) {},
          ),
        );
        await t.tap(find.text('٢٠ نوفمبر ٢٠٢٦'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.text(words.formatMonthYear(_due)), findsOneWidget);
        expect(find.text('نوفمبر ٢٠٢٦'), findsOneWidget);
        // Monday first, in the calendar's own letters.
        for (var d = DateTime.monday; d <= DateTime.sunday; d++) {
          expect(find.text(words.formatShortWeekday(d)), findsOneWidget);
        }
        expect(find.text('٢٠'), findsOneWidget);
        expect(
          find.bySemanticsLabel(words.formatFullDate(DateTime(2026, 11, 20))),
          findsOneWidget,
        );
        expect(find.text(words.doneButtonLabel), findsOneWidget);
        expect(_latin(t), isEmpty);
        expect(_cut(t), isEmpty);
        semantics.dispose();
      });

      testWidgets('the time sheet turns Arabic wheels', (t) async {
        final semantics = t.ensureSemantics();
        await _pump(
          t,
          ar,
          scale,
          LedgerDatePicker(
            label: 'الموعد',
            mode: LedgerDatePickerMode.time,
            value: _due,
            onChanged: (_) {},
          ),
        );
        await t.tap(find.text('٩:٠٥ م'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(
          t.getSemantics(find.bySemanticsLabel(words.timePickerHourLabel)),
          isSemantics(value: '٩'),
        );
        expect(
          t.getSemantics(find.bySemanticsLabel(words.timePickerMinuteLabel)),
          isSemantics(value: '٠٥'),
        );
        expect(
          t.getSemantics(find.bySemanticsLabel(words.timeFieldDayPeriodLabel)),
          isSemantics(value: words.postMeridiemAbbreviation),
        );
        expect(_latin(t), isEmpty);
        expect(_cut(t), isEmpty);
        semantics.dispose();
      });
    });

    group('in German at $at', () {
      const de = Locale('de');
      final words = DesignLocalizations.forLocale(de);

      testWidgets('the compact line prints the day and the clock in German', (
        t,
      ) async {
        await _pump(
          t,
          de,
          scale,
          LedgerDatePicker(
            label: 'Fällig am',
            mode: LedgerDatePickerMode.dateAndTime,
            value: _due,
            onChanged: (_) {},
          ),
        );
        expect(t.takeException(), isNull);
        expect(find.text('20. Nov. 2026'), findsOneWidget);
        expect(find.text('21:05'), findsOneWidget);
        expect(_cut(t), isEmpty);
      });

      testWidgets('the day sheet is the month in German', (t) async {
        final semantics = t.ensureSemantics();
        await _pump(
          t,
          de,
          scale,
          LedgerDatePicker(label: 'Fällig am', value: _due, onChanged: (_) {}),
        );
        await t.tap(find.text('20. Nov. 2026'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.text('November 2026'), findsOneWidget);
        for (final head in const ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO']) {
          expect(find.text(head), findsOneWidget);
        }
        expect(
          find.bySemanticsLabel(words.formatFullDate(DateTime(2026, 11, 20))),
          findsOneWidget,
        );
        expect(find.text(words.doneButtonLabel), findsOneWidget);
        expect(_cut(t), isEmpty);
        semantics.dispose();
      });

      testWidgets('the time sheet turns German wheels', (t) async {
        final semantics = t.ensureSemantics();
        await _pump(
          t,
          de,
          scale,
          LedgerDatePicker(
            label: 'Beginn',
            mode: LedgerDatePickerMode.dateAndTime,
            presentation: LedgerDatePickerPresentation.wheel,
            value: _due,
            onChanged: (_) {},
          ),
        );
        expect(t.takeException(), isNull);
        expect(
          t.getSemantics(find.bySemanticsLabel(words.dateFieldDayLabel)),
          isSemantics(value: 'Fr, 20. Nov.'),
        );
        // German's clock is a twenty-four-hour one, as its pill prints it.
        expect(
          t.getSemantics(find.bySemanticsLabel(words.timePickerHourLabel)),
          isSemantics(value: '21'),
        );
        expect(
          find.bySemanticsLabel(words.timeFieldDayPeriodLabel),
          findsNothing,
        );
        expect(_cut(t), isEmpty);
        semantics.dispose();
      });
    });
  }

  testWidgets('in English the picker writes as it always has', (t) async {
    await _pump(
      t,
      const Locale('en'),
      1,
      LedgerDatePicker(
        label: 'Starts',
        mode: LedgerDatePickerMode.dateAndTime,
        value: _due,
        onChanged: (_) {},
      ),
    );
    expect(find.text('Nov 20, 2026'), findsOneWidget);
    expect(find.text('9:05 PM'), findsOneWidget);
    await t.tap(find.text('Nov 20, 2026'));
    await t.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    for (final head in const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU']) {
      expect(find.text(head), findsOneWidget);
    }
  });
}
