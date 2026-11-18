// An underlined link draws one line under its words, left to right and right
// to left, at rest and under the keyboard's focus (where the ink bar is the
// one line). Right to left the line is drawn below the words, clear of
// Arabic's tails, so the words' own underline must draw nothing there.
import 'dart:typed_data';

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _shot = ValueKey('shot');
const _words = 'Change your name';

/// The runs of ink down the column through the first space between the
/// words: each a stretch of rows that differ from the space's own top row.
Future<int> _linesUnderTheSpace(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final paragraph = tester.renderObject<RenderParagraph>(find.text(_words));
  final space = _words.indexOf(' ');
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: space, extentOffset: space + 1),
      )
      .single;
  final origin = paragraph.localToGlobal(Offset.zero, ancestor: boundary);
  final x = (origin.dx + (box.left + box.right) / 2).round();
  final top = (origin.dy + box.top).round();
  final image = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    final out = (bytes!.buffer.asUint8List(), image.width, image.height);
    image.dispose();
    return out;
  }))!;
  final (Uint8List rgba, int width, int height) = image;
  int at(int y) {
    final i = (y * width + x) * 4;
    return rgba[i] + rgba[i + 1] + rgba[i + 2];
  }

  final ground = at(top);
  var runs = 0;
  var inside = false;
  for (var y = top; y < height; y++) {
    final ink = (at(y) - ground).abs() > 60;
    if (ink && !inside) runs++;
    inside = ink;
  }
  return runs;
}

void main() {
  for (final direction in TextDirection.values) {
    for (final focused in [false, true]) {
      testWidgets(
        '${direction.name}, ${focused ? 'focused' : 'at rest'}: one line under the words',
        (tester) async {
          final states = WidgetStatesController({
            if (focused) WidgetState.focused,
          });
          addTearDown(states.dispose);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => CivicHost(child: child!),
              home: Directionality(
                textDirection: direction,
                child: Center(
                  child: RepaintBoundary(
                    key: _shot,
                    child: CivicLink(
                      onPressed: () {},
                      statesController: states,
                      child: const Text(_words),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(await _linesUnderTheSpace(tester), 1);
        },
      );
    }
  }
}
