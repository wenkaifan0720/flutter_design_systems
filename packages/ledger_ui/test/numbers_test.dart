// Ledger's numbers: a part that does not know its number is money prints the
// plain number in the reader's digits unless its caller formats it, a pie
// chart's whole, parts and centre word are the reader's, and a table's
// amounts read whole at every text size, in the look's own faces.
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

/// Loads every family the test asset bundle declares, so figures lay out in
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

/// [child] [width] wide on a 390 phone, in [locale], at [scale].
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Locale locale = const Locale('en'),
  double scale = 1,
  double width = 342,
}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: LedgerHost(
            brightness: Brightness.light,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(width: width, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// A budget's whole dollars, as an app passes them.
String _dollars(num v) => LedgerFormat.money(v, showCents: false);

void main() {
  setUpAll(_loadFonts);

  for (final locale in const [Locale('en'), Locale('ar'), Locale('de')]) {
    final words = RawWidgetsLocalizations.forLocale(locale);
    final lang = locale.languageCode;

    testWidgets('a stepper shows a count, not money, in $lang', (t) async {
      final semantics = t.ensureSemantics();
      await _pump(
        t,
        locale: locale,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerStepper(
              value: 2,
              label: 'Copies',
              step: 1,
              min: 1,
              onChanged: (_) {},
            ),
            LedgerStepper(
              size: LedgerStepperSize.field,
              label: 'Estimate (minutes)',
              value: 45,
              min: 5,
              max: 480,
              onChanged: (_) {},
            ),
          ],
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text(words.formatDecimal(2)), findsOneWidget);
      expect(find.textContaining(r'$'), findsNothing);
      expect(
        t.getSemantics(find.bySemanticsLabel('Copies')),
        isSemantics(
          label: 'Copies',
          value: words.formatDecimal(2),
          increasedValue: words.formatDecimal(3),
          decreasedValue: words.formatDecimal(1),
        ),
      );
      semantics.dispose();
    });

    testWidgets('a pie chart prints its shares plainly in $lang', (t) async {
      final semantics = t.ensureSemantics();
      await _pump(
        t,
        locale: locale,
        const LedgerPieChart(
          label: 'Hours by project',
          shares: [LedgerShare('Atlas', 1150), LedgerShare('Harbour', 486)],
        ),
      );
      expect(t.takeException(), isNull);
      for (final n in const [1636, 1150, 486]) {
        expect(find.text(words.formatDecimal(n)), findsOneWidget, reason: '$n');
      }
      // Each share's part of the whole, in the reader's digits and sign.
      for (final v in const [1150, 486]) {
        expect(
          find.text(words.formatPercent(v / 1636)),
          findsOneWidget,
          reason: '$v',
        );
      }
      expect(find.textContaining(r'$'), findsNothing);
      // The centre word is English's own; another language's whole stands
      // alone until the app names it.
      expect(find.text('TOTAL'), lang == 'en' ? findsOneWidget : findsNothing);
      expect(
        t.getSemantics(find.byType(LedgerPieChart)),
        isSemantics(
          label: [
            'Hours by project, ${words.formatDecimal(1636)}',
            'Atlas ${words.formatDecimal(1150)}, '
                '${words.formatPercent(1150 / 1636)}',
            'Harbour ${words.formatDecimal(486)}, '
                '${words.formatPercent(486 / 1636)}',
          ].join('; '),
        ),
      );
      semantics.dispose();
    });
  }

  for (final (locale, total, shares) in const [
    (Locale('ar'), 'الإجمالي', [('الإيجار', 1150.0), ('البقالة', 486.0)]),
    (Locale('de'), 'Gesamt', [('Miete', 1150.0), ('Lebensmittel', 486.0)]),
  ]) {
    testWidgets('a pie chart in ${locale.languageCode} says the app\'s word '
        'for its whole', (t) async {
      final words = RawWidgetsLocalizations.forLocale(locale);
      await _pump(
        t,
        locale: locale,
        LedgerPieChart(
          label: shares.map((s) => s.$1).join(' · '),
          totalLabel: total,
          shares: [for (final (name, v) in shares) LedgerShare(name, v)],
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text(total.toUpperCase()), findsOneWidget);
      expect(find.text(words.formatDecimal(1636)), findsOneWidget);
      expect(find.text('TOTAL'), findsNothing);
      // Nothing on the ring but the app's words and the reader's digits.
      for (final p in t.allRenderObjects.whereType<RenderParagraph>()) {
        final text = p.text.toPlainText();
        if (locale.languageCode == 'ar') {
          expect(RegExp('[A-Za-z0-9]').hasMatch(text), isFalse, reason: text);
        }
        expect(p.didExceedMaxLines, isFalse, reason: text);
      }
    });
  }

  testWidgets('money is the caller\'s to ask for', (t) async {
    await _pump(
      t,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LedgerStepper(
            value: 250,
            label: 'Monthly budget',
            format: _dollars,
            onChanged: (_) {},
          ),
          const LedgerPieChart(
            label: 'October by category',
            format: LedgerFormat.money,
            shares: [LedgerShare('Rent', 1150), LedgerShare('Groceries', 486)],
          ),
        ],
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.text(r'$250'), findsOneWidget);
    expect(find.text(r'$1,636.00'), findsOneWidget);
    expect(find.text(r'$1,150.00'), findsOneWidget);
  });

  for (final scale in const [1.0, 2.0, 3.0]) {
    final at = '${(scale * 100).round()}%';
    testWidgets('a selectable table\'s amounts read whole at $at on a phone', (
      t,
    ) async {
      final table = RawDataTableController<(String, double)>(
        rows: const [
          ('Corner Market', 64.18),
          ('Rent', 1150),
          ('Payroll', 3200),
        ],
        columns: [
          RawDataColumn(id: 'entry', label: 'Entry', sortKey: (r) => r.$1),
          RawDataColumn(
            id: 'amount',
            label: 'Amount',
            numeric: true,
            sortKey: (r) => r.$2,
          ),
        ],
      );
      addTearDown(table.dispose);
      await _pump(
        t,
        scale: scale,
        LedgerDataTable<(String, double)>(
          controller: table,
          cellText: (r, column) =>
              column.id == 'entry' ? r.$1 : r.$2.toStringAsFixed(2),
        ),
      );
      expect(t.takeException(), isNull);
      final bounds = t.getRect(find.byType(LedgerDataTable<(String, double)>));
      for (final (payee, amount) in const [
        ('Corner Market', '64.18'),
        ('Rent', '1150.00'),
        ('Payroll', '3200.00'),
      ]) {
        final figure = t.renderObject<RenderParagraph>(find.text(amount));
        // One line, every digit laid out: never cut, never broken.
        expect(figure.didExceedMaxLines, isFalse, reason: amount);
        expect(
          figure.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: amount.length),
          ),
          hasLength(1),
          reason: amount,
        );
        expect(
          figure.size.width,
          greaterThanOrEqualTo(
            figure.getMaxIntrinsicWidth(double.infinity) - 0.5,
          ),
          reason: amount,
        );
        final rect = t.getRect(find.text(amount));
        expect(rect.left, greaterThanOrEqualTo(bounds.left), reason: amount);
        expect(
          rect.right,
          lessThanOrEqualTo(bounds.right + 0.5),
          reason: amount,
        );
        // The payee gives way (it wraps) and never runs under the amount.
        final name = t.getRect(find.text(payee));
        expect(name.overlaps(rect), isFalse, reason: '$payee, $amount');
        expect(
          t.renderObject<RenderParagraph>(find.text(payee)).didExceedMaxLines,
          isFalse,
          reason: payee,
        );
      }
    });
  }
}
