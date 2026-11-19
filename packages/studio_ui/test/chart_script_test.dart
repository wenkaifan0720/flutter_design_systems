// The scope paints its labels directly, so a text-widget or semantics check
// alone cannot detect a row of missing-glyph boxes on the glass.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _days = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const _hours = [2.5, 3.0, 3.5, 4.0, 5.0, 0.0, 0.0];

// Keep the ink before the chart disposes each paragraph. Ignore its position
// and colour when comparing glyphs with a sample from the bundled Arabic face.
class _Labels extends TestRecordingCanvas {
  final boxes = <Rect>[];
  final pictures = <ui.Picture>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    boxes.add(offset & Size(paragraph.longestLine, paragraph.height));
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(2)
      ..drawParagraph(paragraph, const Offset(4, 4));
    pictures.add(recorder.endRecording());
  }
}

Future<List<int>> _ink(ui.Picture picture) async {
  const width = 180;
  const height = 64;
  final image = await picture.toImage(width, height);
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  picture.dispose();
  final points = <(int, int)>[];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (rgba.getUint8((y * width + x) * 4 + 3) > 96) points.add((x, y));
    }
  }
  expect(points, isNotEmpty);
  final left = points.map((p) => p.$1).reduce((a, b) => a < b ? a : b);
  final top = points.first.$2;
  return [for (final (x, y) in points) (y - top) * width + x - left];
}

void main() {
  setUpAll(studioLoadFonts);

  testWidgets('Arabic axis digits and every weekday are whole, shaped glyphs', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(780, 1200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ar'),
        delegates: const [
          DesignLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: StudioHost(
            brightness: Brightness.light,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 358,
                child: StudioBarChart(
                  semanticLabel: 'الساعات المسجلة',
                  height: 150,
                  labels: _days,
                  series: [StudioSeries('ساعات', _hours)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scope = find.byType(StudioBarChart);
    final node = tester.getSemantics(find.bySemanticsLabel('الساعات المسجلة'));
    const values = ['٢٫٥', '٣', '٣٫٥', '٤', '٥', '٠', '٠'];
    for (final (i, day) in _days.indexed) {
      expect(node.value, contains('$day ${values[i]}'));
    }

    final plot = tester
        .renderObjectList<RenderCustomPaint>(
          find.descendant(of: scope, matching: find.byType(CustomPaint)),
        )
        .singleWhere((p) => p.painter.runtimeType.toString() == '_BarPainter');
    final painter = plot.painter!;
    final actual = _Labels();
    painter.paint(actual, plot.size);
    const labels = ['٠', '١', '٢', '٣', '٤', '٥', ..._days];
    expect(actual.boxes, hasLength(labels.length));
    final bounds = Offset.zero & plot.size;
    for (final box in actual.boxes) {
      expect(bounds.intersect(box), box);
    }
    final caption = StudioTheme.of(tester.element(scope)).textTheme.caption;
    final reference = _Labels();
    for (final label in labels) {
      final p = TextPainter(
        text: TextSpan(
          text: label,
          style: caption.copyWith(
            fontFamily: 'NotoSansArabic',
            package: 'studio_ui',
            fontSize: 11,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
        maxLines: 1,
      )..layout();
      p.paint(reference, Offset.zero);
      p.dispose();
    }
    await tester.runAsync(() async {
      for (final (i, label) in labels.indexed) {
        final actualInk = await _ink(actual.pictures[i]);
        final expectedInk = await _ink(reference.pictures[i]);
        expect(listEquals(actualInk, expectedInk), isTrue, reason: label);
      }
    });

    var notifications = 0;
    void fontsChanged() => notifications++;
    painter.addListener(fontsChanged);
    addTearDown(() => painter.removeListener(fontsChanged));
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.system.name,
      SystemChannels.system.codec.encodeMessage({'type': 'fontsChange'}),
      null,
    );
    expect(notifications, 1);
  });
}
