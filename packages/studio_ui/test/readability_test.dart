import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double scale = 2,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, 1688);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: StudioHost(brightness: Brightness.light, child: app!),
        ),
      ),
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _words(WidgetTester tester, String text) {
  final p = tester.renderObject<RenderParagraph>(find.text(text));
  expect(p.didExceedMaxLines, isFalse, reason: text);
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  var r = boxes.first.toRect();
  for (final box in boxes.skip(1)) {
    r = r.expandToInclude(box.toRect());
  }
  return MatrixUtils.transformRect(p.getTransformTo(null), r);
}

class _AxisInk extends TestRecordingCanvas {
  final boxes = <Rect>[];
  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    boxes.add(offset & Size(paragraph.longestLine, paragraph.height));
  }
}

void main() {
  setUpAll(studioLoadFonts);
  testWidgets('date field gives separate hover and press feedback in RTL', (
    tester,
  ) async {
    final picker = StudioDatePicker(
      label: 'Release date',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      onChanged: (_) {},
    );
    await _show(
      tester,
      SizedBox(width: 366, child: picker),
      direction: TextDirection.rtl,
    );
    final face = find
        .descendant(
          of: find.byWidget(picker),
          matching: find.byType(AnimatedStudioSurface),
        )
        .first;
    Color? fill() => tester.widget<AnimatedStudioSurface>(face).face.fill;
    final resting = fill();
    final point = tester.getCenter(face);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(point);
    await tester.pumpAndSettle();
    final hover = fill();
    expect(hover, isNot(resting));
    await mouse.down(point);
    await tester.pump(const Duration(milliseconds: 305));
    await tester.pump();
    expect(fill(), isNot(hover));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.byType(StudioCalendar), findsOneWidget);
    await mouse.removePointer();
  });
  for (final direction in TextDirection.values) {
    testWidgets(
      'confirmation shows the destructive action in ${direction.name}',
      (tester) async {
        await _show(
          tester,
          SizedBox(
            width: 342,
            child: StudioDialog(
              title: 'Discard this take?',
              actions: [
                StudioButton('Keep', onPressed: () {}),
                StudioButton.lit(
                  'Discard',
                  isDestructiveAction: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          direction: direction,
        );
        final keep = _words(tester, 'Keep'),
            discard = _words(tester, 'Discard');
        expect(keep.overlaps(discard), isFalse);
      },
    );
    testWidgets(
      'filter legends scale equally and keep their full words in ${direction.name}',
      (tester) async {
        final bank = SizedBox(
          width: 366,
          child: StudioSegmentedButton<int>(
            segments: const [
              StudioSegment(value: 0, label: 'All'),
              StudioSegment(value: 1, label: 'Unplayed'),
              StudioSegment(value: 2, label: 'Downloaded'),
            ],
            value: 0,
            onChanged: (_) {},
          ),
        );
        await _show(tester, bank, scale: 1, direction: direction);
        final normal = _words(tester, 'Downloaded').height;
        await _show(tester, bank, direction: direction);
        final all = _words(tester, 'All'),
            downloaded = _words(tester, 'Downloaded');
        expect(downloaded.height, greaterThan(normal * 1.75));
        expect(downloaded.height, closeTo(all.height, 1));
        expect(downloaded.overlaps(_words(tester, 'Unplayed')), isFalse);
      },
    );
    testWidgets(
      'badges reserve space for adjacent counts in ${direction.name}',
      (tester) async {
        await _show(
          tester,
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudioBadge(count: 8, child: SizedBox.square(dimension: 24)),
              SizedBox(width: 12),
              StudioBadge(count: 128, child: SizedBox.square(dimension: 24)),
            ],
          ),
          direction: direction,
        );
        final a = _words(tester, '8'), b = _words(tester, '99+');
        final boxes = [
          for (final f in find.byType(StudioBadge).evaluate())
            tester.getRect(find.byWidget(f.widget)),
        ];
        expect(boxes[0].contains(a.center), isTrue);
        expect(boxes[1].contains(b.topLeft), isTrue);
        expect(boxes[1].contains(b.bottomRight - const Offset(.1, .1)), isTrue);
        expect(a.overlaps(b), isFalse);
      },
    );
    testWidgets('zoom and tree rows enclose their text in ${direction.name}', (
      tester,
    ) async {
      const name = 'Downloaded interview recordings';
      final folders = StudioTreeController<String>(
        roots: const ['Session'],
        childrenOf: (s) => s == 'Session' ? const [name] : const [],
        expanded: {'Session'},
      );
      addTearDown(folders.dispose);
      final keys = StudioKeyRow(
        items: [
          StudioKeyRowItem(label: 'In', onPressed: () {}),
          StudioKeyRowItem(label: 'Out', onPressed: () {}),
        ],
      );
      await _show(
        tester,
        SizedBox(
          width: 252,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              keys,
              StudioTree<String>(controller: folders, labelOf: (s) => s),
            ],
          ),
        ),
        direction: direction,
      );
      final keyBox = tester.getRect(find.byWidget(keys));
      expect(keyBox.inflate(.1).contains(_words(tester, 'In').topLeft), isTrue);
      expect(
        keyBox.inflate(.1).contains(_words(tester, 'Out').bottomRight),
        isTrue,
      );
      final bounds = _words(tester, name);
      final row = tester.getRect(
        find
            .ancestor(
              of: find.text(name),
              matching: find.byType(AnimatedStudioSurface),
            )
            .first,
      );
      expect(row.inflate(.1).contains(bounds.topLeft), isTrue);
      expect(row.inflate(.1).contains(bounds.bottomRight), isTrue);
      expect(bounds.height, greaterThan(_words(tester, 'Session').height));
    });
    testWidgets('a closed date keeps the selected year in ${direction.name}', (
      tester,
    ) async {
      await _show(
        tester,
        SizedBox(
          width: 328,
          child: StudioDatePicker(
            value: DateTime(2026, 11, 20),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            onChanged: (_) {},
          ),
        ),
        direction: direction,
      );
      final finder = find.textContaining('2026');
      final label = tester.widget<Text>(finder).data!;
      final bounds = _words(tester, label);
      final box = tester.getRect(find.byType(StudioDatePicker));
      expect(box.inflate(.1).contains(bounds.bottomRight), isTrue);
    });
  }
  testWidgets('disabled daylight button ink is legible on the key', (
    tester,
  ) async {
    await _show(
      tester,
      const StudioButton('Save draft', onPressed: null),
      scale: 1,
    );
    final ink = tester
        .renderObject<RenderParagraph>(find.text('Save draft'))
        .text
        .style!
        .color!;
    final face = tester
        .widget<AnimatedStudioSurface>(find.byType(AnimatedStudioSurface))
        .face;
    final a = ink.computeLuminance(), b = face.fill.computeLuminance();
    expect(
      (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05),
      greaterThanOrEqualTo(4.5),
    );
  });
  testWidgets('axis lettering grows and adjacent ticks stay apart', (
    tester,
  ) async {
    const labels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    const series = [
      StudioSeries('Plays', [10, 20, 30, 25, 15]),
    ];
    for (final chart in const <Widget>[
      StudioLineChart(semanticLabel: 'Plays', labels: labels, series: series),
      StudioBarChart(semanticLabel: 'Plays', labels: labels, series: series),
      StudioAreaChart(semanticLabel: 'Plays', labels: labels, series: series),
    ]) {
      List<Rect> paint() {
        final glass = find.descendant(
          of: find.byWidget(chart),
          matching: find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                w.painter != null &&
                w.painter is! StudioFacePainter,
          ),
        );
        final painter = tester.widget<CustomPaint>(glass.last).painter!;
        final ink = _AxisInk();
        final size = tester.getSize(glass.last);
        painter.paint(ink, size);
        for (final words in ink.boxes) {
          expect(words.left, greaterThanOrEqualTo(-0.1));
          expect(words.top, greaterThanOrEqualTo(-0.1));
          expect(words.right, lessThanOrEqualTo(size.width + 0.1));
          expect(words.bottom, lessThanOrEqualTo(size.height + 0.1));
        }
        return ink.boxes;
      }

      await _show(tester, SizedBox(width: 330, child: chart), scale: 1);
      final normal = paint().last.height;
      await _show(tester, SizedBox(width: 330, child: chart));
      final large = paint();
      expect(large.last.height, greaterThan(normal * 1.7));
      final ticks = large.where((r) => r.top == large.last.top).toList();
      expect(ticks.length, greaterThan(1));
      for (var i = 1; i < ticks.length; i++) {
        expect(ticks[i].left, greaterThanOrEqualTo(ticks[i - 1].right));
      }
    }
  });
}
