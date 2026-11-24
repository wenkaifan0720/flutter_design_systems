// A legend key's legend takes a second line where one can't hold it, the key growing by it, rather than being cut
// ("Hours this week" in Arabic on a phone); a legend that fits keeps the key at its height.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _shot = Key('shot');

Future<void> _show(
  WidgetTester tester,
  String legend, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          KeycapHost(brightness: brightness, child: app!),
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _shot,
          child: SizedBox(
            width: 175,
            child: KeycapLegendKey(
              icon: const Icon(LucideIcons.clock3),
              legend: legend,
              subLegend: '15 h 45 m',
              onPressed: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(keycapLoadFonts);

  testWidgets('a long legend takes a second line, whole', (tester) async {
    await _show(tester, 'Hours this week');
    final words = tester.renderObject<RenderParagraph>(
      find.text('Hours this week'),
    );
    expect(words.didExceedMaxLines, isFalse);
    expect(words.size.height, greaterThan(1.5 * words.preferredLineHeight));
    final legend = tester.getRect(find.text('Hours this week'));
    final figure = tester.getRect(find.text('15 h 45 m'));
    // The value stands clear of the legend's second line.
    expect(
      figure.top,
      greaterThanOrEqualTo(legend.bottom + KeycapSpacing.small),
    );
    final key = tester.getRect(find.byType(KeycapLegendKey));
    expect(figure.bottom, lessThanOrEqualTo(key.bottom));
    expect(key.height, lessThan(KeycapLegendKey.height + 2 * legend.height));
  });

  testWidgets('a legend that fits keeps the key at its height', (tester) async {
    await _show(tester, 'Open tasks');
    final key = tester.getSize(find.byType(KeycapLegendKey));
    await _show(tester, 'Done');
    expect(tester.getSize(find.byType(KeycapLegendKey)), key);
    expect(
      tester.getRect(find.byType(KeycapLegendKey)).height,
      greaterThanOrEqualTo(KeycapLegendKey.height),
    );
  });

  testWidgets('in a stretched row the keys stand as tall as the tallest', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            KeycapHost(brightness: Brightness.light, child: app!),
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 358,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final legend in const ['Hours this week', 'Open tasks'])
                    Expanded(
                      child: KeycapLegendKey(
                        legend: legend,
                        subLegend: '12',
                        onPressed: () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final keys = tester
        .widgetList<KeycapLegendKey>(find.byType(KeycapLegendKey))
        .map((key) => tester.getRect(find.byWidget(key)))
        .toList();
    expect(keys[0].height, keys[1].height);
    // Each value stands at its key's foot.
    final figures = tester.getRect(find.text('12').first).bottom;
    expect(tester.getRect(find.text('12').last).bottom, figures);
  });

  testWidgets('the icon stands on the legend\'s first line', (tester) async {
    await _show(tester, 'Hours this week');
    final legend = tester.getRect(find.text('Hours this week'));
    final icon = tester.getRect(find.byType(Icon));
    final line = tester
        .renderObject<RenderParagraph>(find.text('Hours this week'))
        .preferredLineHeight;
    expect(legend.height, greaterThan(1.5 * line));
    expect(icon.center.dy, moreOrLessEquals(legend.top + line / 2, epsilon: 1));
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'the value reads at 4.5:1 on its key as drawn (${brightness.name})',
      (tester) async {
        await _show(tester, 'Open tasks', brightness: brightness);
        final ink = tester.widget<Text>(find.text('15 h 45 m')).style!.color!;
        // The value's words, not its line (the line runs the key's width).
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('15 h 45 m'),
        );
        final glyphs = paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 9),
            )
            .map((box) => box.toRect())
            .reduce((a, b) => a.expandToInclude(b))
            .shift(paragraph.localToGlobal(Offset.zero));
        final key = tester.getRect(find.byType(KeycapLegendKey));
        // The key's face as painted (its light falls across it), on the value's
        // line before the value starts: the lightest of it is the worst case.
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_shot),
        );
        final bytes = (await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData();
          image.dispose();
          return data;
        }))!;
        final width = boundary.size.width.round();
        var worst = double.infinity;
        final y = glyphs.center.dy.round();
        final from = key.left.round() + 20, to = glyphs.left.round() - 4;
        expect(to - from, greaterThan(20));
        for (var x = from; x < to; x++) {
          final i = 4 * (y * width + x);
          final face = Color.fromARGB(
            255,
            bytes.getUint8(i),
            bytes.getUint8(i + 1),
            bytes.getUint8(i + 2),
          );
          final a = ink.computeLuminance(), b = face.computeLuminance();
          worst = math.min(
            worst,
            (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05),
          );
        }
        expect(worst, greaterThanOrEqualTo(4.5));
      },
    );
  }
}
