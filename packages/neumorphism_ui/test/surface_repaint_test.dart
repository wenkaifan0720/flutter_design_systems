import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

class _PaintProbe extends CustomPainter {
  _PaintProbe(this.color, this.onPaint);

  final Color color;
  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PaintProbe old) => old.color != color;
}

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final mode in Brightness.values) {
    for (final custom in [false, true]) {
      testWidgets(
        '${mode.name} ${custom ? 'custom' : 'natural'} card isolates ancestor paints and refreshes its content',
        (tester) async {
          tester.view.physicalSize = const Size(390, 500);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final contentColor = ValueNotifier(Colors.red);
          addTearDown(contentColor.dispose);
          final parent = GlobalKey(),
              stage = GlobalKey(),
              content = GlobalKey();
          var parentPaints = 0, contentPaints = 0;
          final theme = NeumorphicThemeData.porcelain(mode).copyWith(
            cardTheme: custom
                ? const NeumorphicStyle(
                    shape: WidgetStatePropertyAll(
                      NeumorphicRoundedBorder(radius: 20),
                    ),
                  )
                : const NeumorphicStyle(),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: NeumorphicTheme(
                data: theme,
                child: Center(
                  child: RepaintBoundary(
                    key: stage,
                    child: SizedBox(
                      width: 320,
                      child: CustomPaint(
                        key: parent,
                        painter: _PaintProbe(
                          Colors.white,
                          () => parentPaints++,
                        ),
                        child: NeumorphicCard(
                          title: 'A stable surface',
                          children: [
                            ValueListenableBuilder<Color>(
                              valueListenable: contentColor,
                              builder: (context, color, _) => SizedBox(
                                height: 24,
                                child: CustomPaint(
                                  key: content,
                                  painter: _PaintProbe(
                                    color,
                                    () => contentPaints++,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final initialParent = parentPaints, initialContent = contentPaints;
          expect(initialContent, greaterThan(0));
          final outside = tester.renderObject<RenderCustomPaint>(
            find.byKey(parent),
          );
          for (var i = 0; i < 3; i++) {
            outside.markNeedsPaint();
            await tester.pump();
          }
          expect(parentPaints, initialParent + 3);
          expect(
            contentPaints,
            initialContent,
            reason: 'redrawing the surrounding page must retain the card layer',
          );

          contentColor.value = Colors.blue;
          await tester.pump();
          expect(contentPaints, greaterThan(initialContent));
          expect(parentPaints, initialParent + 3);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(stage),
          );
          final box = tester.renderObject<RenderBox>(find.byKey(content));
          final point = box.localToGlobal(
            box.size.center(Offset.zero),
            ancestor: boundary,
          );
          final image = await tester.runAsync(() => boundary.toImage());
          final bytes = await tester.runAsync(
            () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
          );
          final at = (point.dy.floor() * image!.width + point.dx.floor()) * 4;
          expect(
            Color.fromARGB(
              bytes!.getUint8(at + 3),
              bytes.getUint8(at),
              bytes.getUint8(at + 1),
              bytes.getUint8(at + 2),
            ).toARGB32(),
            Colors.blue.toARGB32(),
            reason: 'the retained layer must display new child paint',
          );
          image.dispose();
          expect(tester.takeException(), isNull);
        },
        tags: ['goldens'],
      );
    }
  }
}
