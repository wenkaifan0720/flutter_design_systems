// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

import '../example/lib/kit_gallery/admit/admit.dart';
import '../example/lib/kit_gallery/demos/choices.dart';

class _Labels extends TestRecordingCanvas {
  final labels = <Rect>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    labels.add(offset & Size(paragraph.longestLine, paragraph.height));
  }
}

void _phone(WidgetTester t, {double height = 844}) {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(390, height);
  addTearDown(t.view.reset);
}

Widget _host(Widget child, {double scale = 2}) => MaterialApp(
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: BrutalTheme(data: BrutalThemeData.light(), child: app!),
  ),
  home: child,
);

List<TextBox> _boxes(WidgetTester t, Finder f, int start, int end) => t
    .renderObject<RenderParagraph>(f)
    .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end));

void main() {
  setUpAll(brutalLoadFonts);

  testWidgets('Admit keeps the price and event day readable at 200%', (
    t,
  ) async {
    _phone(t);
    await t.pumpWidget(
      const AdmitApp(
        initialPlace: AdmitPlace.events,
        initialAppearance: AdmitAppearance.dark,
        initialDirection: TextDirection.rtl,
        textScale: 2,
      ),
    );
    await t.pumpAndSettle();
    expect(_boxes(t, find.text('17').first, 0, 2), hasLength(1));
    final count = find.textContaining('7 events,');
    final paragraph = t.renderObject<RenderParagraph>(count);
    expect(paragraph.textDirection, TextDirection.ltr);
    expect(
      _boxes(t, count, 0, 1).single.left,
      lessThan(_boxes(t, count, 2, 3).single.left),
    );
    await t.pumpWidget(
      const AdmitApp(
        key: ValueKey('detail'),
        initialPlace: AdmitPlace.events,
        initialScene: AdmitScene.event,
        textScale: 2,
      ),
    );
    await t.pumpAndSettle();
    final price = find.text('From €32.00').last;
    final amount = _boxes(t, price, 5, 11);
    expect(amount, hasLength(1));
    expect(
      t.getRect(find.text('Buy tickets').last).top,
      greaterThan(t.getRect(price).bottom),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('the consent label toggles the same checkbox as its box', (
    t,
  ) async {
    _phone(t);
    await t.pumpWidget(_host(kitChoicesDemo(Brightness.light)));
    await t.pumpAndSettle();
    final consent = find.byType(BrutalCheckbox).first;
    expect(t.widget<BrutalCheckbox>(consent).value, isTrue);
    await t.tap(find.text('I agree to the terms'));
    await t.pumpAndSettle();
    expect(t.widget<BrutalCheckbox>(consent).value, isFalse);
    await t.tap(consent);
    await t.pumpAndSettle();
    expect(t.widget<BrutalCheckbox>(consent).value, isTrue);
  });

  testWidgets('large app bar shows the entire title in its preferred height', (
    t,
  ) async {
    _phone(t);
    const bar = BrutalAppBar(title: 'Tickets', large: true);
    await t.pumpWidget(
      _host(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(height: bar.preferredSize.height, child: bar),
        ),
      ),
    );
    await t.pumpAndSettle();
    final title = find.text('Tickets');
    final text = t.renderObject<RenderParagraph>(title);
    final glyphBottom =
        t.getTopLeft(title).dy + _boxes(t, title, 0, 7).single.bottom;
    expect(
      glyphBottom,
      lessThan(t.getRect(find.byType(BrutalAppBar)).bottom - 2),
    );
    expect(text.didExceedMaxLines, isFalse);
    expect(text.size.height, greaterThan(48));
    expect(
      t.getRect(title).bottom,
      lessThan(t.getRect(find.byType(BrutalAppBar)).bottom),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('step progress keeps all names at 200%', (t) async {
    _phone(t);
    await t.pumpWidget(
      _host(
        const Center(
          child: SizedBox(
            width: 340,
            child: BrutalStepProgress(
              steps: ['Cart', 'Address', 'Delivery', 'Review'],
              current: 1,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    for (final title in ['Cart', 'Address', 'Delivery', 'Review']) {
      final text = t.renderObject<RenderParagraph>(find.text(title));
      expect(text.didExceedMaxLines, isFalse);
    }
    expect(
      t.getRect(find.text('Address')).bottom,
      lessThan(t.getRect(find.text('Delivery')).top),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'equal-width tabs and segments keep their complete names at 200%',
    (t) async {
      _phone(t);
      await t.pumpWidget(
        _host(
          Center(
            child: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrutalTabBar(
                    tabs: const ['Upcoming', 'Past'],
                    selectedIndex: 0,
                    expand: true,
                    onSelected: (_) {},
                  ),
                  BrutalSegmentedButton<String>(
                    value: 'music',
                    segments: const [
                      BrutalSegment(value: 'all', label: 'All'),
                      BrutalSegment(value: 'music', label: 'Music'),
                      BrutalSegment(value: 'talks', label: 'Talks'),
                      BrutalSegment(value: 'film', label: 'Film'),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      for (final label in ['Upcoming', 'Music', 'Talks']) {
        expect(
          t.renderObject<RenderParagraph>(find.text(label)).didExceedMaxLines,
          isFalse,
        );
      }
      expect(t.takeException(), isNull);
    },
  );

  for (final range in [false, true]) {
    testWidgets(
      'the last day in a short ${range ? "range" : "date"} popup can be reached',
      (t) async {
        _phone(t, height: 620);
        final start = DateTime(2026, 11);
        final end = DateTime(2026, 12, 31);
        DateTime? selected;
        final picker = range
            ? BrutalDateRangePicker(
                value: null,
                firstDate: start,
                lastDate: end,
                currentDate: start,
                onChanged: (r) => selected = r.end,
              )
            : BrutalDatePicker(
                value: null,
                firstDate: start,
                lastDate: end,
                currentDate: start,
                onChanged: (date) => selected = date,
              );
        await t.pumpWidget(
          _host(Center(child: SizedBox(width: 330, child: picker))),
        );
        await t.pumpAndSettle();
        await t.tap(find.text(range ? 'Choose dates' : 'Choose a date'));
        await t.pumpAndSettle();
        if (range) {
          await t.ensureVisible(find.text('3').first);
          await t.tap(find.text('3').first);
          await t.pumpAndSettle();
        }
        final scroll = find
            .ancestor(
              of: find.text('30').first,
              matching: find.byType(Scrollable),
            )
            .first;
        final position = t.state<ScrollableState>(scroll).position;
        expect(position.maxScrollExtent, greaterThan(0));
        await t.drag(scroll, const Offset(0, -250));
        await t.pumpAndSettle();
        final last = find.text('30').hitTestable();
        expect(last, findsOneWidget);
        expect(t.getRect(last).bottom, lessThan(620));
        await t.tap(last);
        await t.pumpAndSettle();
        expect(selected, DateTime(2026, 11, 30));
        expect(t.takeException(), isNull);
      },
    );
  }

  for (final kind in ['line', 'area', 'bar']) {
    testWidgets('$kind chart scales its axes inside the plot frame', (t) async {
      _phone(t);
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const series = [
        BrutalSeries('Bookings', [80, 165, 130, 120, 90, 170, 200]),
      ];
      final widget = switch (kind) {
        'line' => const BrutalLineChart(
          labels: labels,
          series: series,
          semanticLabel: 'Bookings',
        ),
        'area' => const BrutalAreaChart(
          labels: labels,
          series: series,
          semanticLabel: 'Bookings',
        ),
        _ => const BrutalBarChart(
          labels: labels,
          series: series,
          semanticLabel: 'Bookings',
        ),
      };
      final heights = <double>[];
      for (final scale in [1.0, 2.0]) {
        await t.pumpWidget(
          _host(
            Center(child: SizedBox(width: 330, child: widget)),
            scale: scale,
          ),
        );
        await t.pumpAndSettle();
        final paint = find
            .descendant(
              of: find.byWidget(widget),
              matching: find.byType(CustomPaint),
            )
            .last;
        final size = t.getSize(paint);
        final canvas = _Labels();
        t.widget<CustomPaint>(paint).painter!.paint(canvas, size);
        expect(canvas.labels.length, greaterThan(4));
        for (final label in canvas.labels) {
          expect(label.left, greaterThanOrEqualTo(-0.5));
          expect(label.right, lessThanOrEqualTo(size.width + .5));
          expect(label.bottom, lessThanOrEqualTo(size.height + .5));
        }
        heights.add(canvas.labels.first.height);
      }
      expect(heights.last, greaterThan(heights.first * 1.8));
    });
  }
}
