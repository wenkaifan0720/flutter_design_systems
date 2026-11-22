// A chart's figures, a meter's percentage and a calendar's days are written
// and said in the reader's digits: Arabic-Indic in Arabic, as the dates and
// the number fields already are.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;

import '../example/lib/kit_gallery/kit.dart';

final _latin = RegExp('[0-9]');
final _arabic = RegExp('[٠-٩]');

Future<void> _show(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 1400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          KeycapTheme(data: kitTheme(Brightness.light), child: app!),
      home: Localizations(
        locale: const Locale('ar'),
        delegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every line of words on screen.
List<String> _printed(WidgetTester tester) => [
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>())
    p.text.toPlainText(),
];

/// Every label and value a screen reader is given.
List<String> _said(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    out
      ..add(data.label)
      ..add(data.value);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(
    RendererBinding
        .instance
        .renderViews
        .first
        .owner!
        .semanticsOwner!
        .rootSemanticsNode!,
  );
  return out.where((s) => s.isNotEmpty).toList();
}

void main() {
  testWidgets('a bar chart in Arabic says its values in Arabic-Indic digits', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      const KeycapBarChart(
        semanticLabel: 'الملاحظات',
        labels: ['أ', 'ب', 'ج'],
        series: [
          KeycapChartSeries('الملاحظات', [14, 9, 21]),
        ],
      ),
    );
    final said = _said(tester).where((s) => s.contains(_arabic)).toList();
    expect(said, isNotEmpty);
    expect(_said(tester).where((s) => s.contains(_latin)), isEmpty);
    semantics.dispose();
  });

  testWidgets('a donut in Arabic writes its total, values and shares in '
      'Arabic-Indic digits', (tester) async {
    await _show(
      tester,
      const KeycapDonutChart(
        semanticLabel: 'الملاحظات',
        slices: [('العمل', 14), ('المنزل', 9), ('الأفكار', 21)],
      ),
    );
    final printed = _printed(tester);
    expect(printed.where((s) => s.contains(_arabic)), isNotEmpty);
    expect(printed.where((s) => s.contains(_latin)), isEmpty);
  });

  testWidgets('a meter in Arabic writes its percentage in Arabic-Indic '
      'digits', (tester) async {
    await _show(tester, const KeycapMeter(label: 'التخزين', value: 0.72));
    final printed = _printed(tester);
    expect(printed, contains(contains('٧٢')));
    expect(printed.where((s) => s.contains(_latin)), isEmpty);
  });

  testWidgets('a calendar in Arabic numbers its days in Arabic-Indic digits', (
    tester,
  ) async {
    final controller = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
    );
    addTearDown(controller.dispose);
    await _show(tester, KeycapCalendar(controller: controller));
    final printed = _printed(tester);
    expect(printed, contains('٢١'));
    expect(printed.where((s) => s.contains(_latin)), isEmpty);
  });
}
