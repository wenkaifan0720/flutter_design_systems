// The segmented control, the latches and the tab bar are banks of cells (polish round 3, §3; DECISIONS.md, "Cells"):
// one raised bank split by carved seams, every cell the same width, the bank as tall as a field beside it. The chosen
// cell is its whole cell, pressed in edge to edge: its outer corners are the bank's (concentric_test measures them),
// the corners it shares with a neighbour are square, and its label does not move when it is chosen. First, middle and
// last chosen, in every corner family and at every stroke setting.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

/// The outlines a painter fills or clips to, in its own coordinates.
class _Paths implements Canvas {
  final paths = <Path>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final a = invocation.positionalArguments;
    if ({#drawPath, #clipPath}.contains(invocation.memberName)) {
      paths.add(Path.from(a.first as Path));
    } else if (invocation.memberName == #getSaveCount) {
      return 1;
    }
    return null;
  }
}

const _families = <String>['look'];

/// The relief alone, and the fine outline high contrast prints.
const _strokes = <String, bool>{'relief': false, 'high contrast': true};

const _labels = ['Day', 'Week', 'Month'];

/// The three banks, each at [chosen], reporting a choice to [choose].
final _banks = <String, Widget Function(int chosen, ValueChanged<int> choose)>{
  'segmented control': (chosen, choose) => NeumorphicSegmentedButton<int>(
    label: 'Period',
    value: chosen,
    segments: [
      for (final (i, label) in _labels.indexed)
        NeumorphicButtonSegment(i, label),
    ],
    onChanged: choose,
  ),
  'latches': (chosen, choose) => NeumorphicLatchGroup(
    options: [for (final label in _labels) NeumorphicLatch(label)],
    value: _labels[chosen],
    onChanged: (v) => choose(_labels.indexOf(v)),
  ),
  'tab bar': (chosen, choose) =>
      NeumorphicTabBar(tabs: _labels, selectedIndex: chosen, onChanged: choose),
};

/// Whether [path]'s corner at [corner] is square: the point just inside it, on the diagonal, is already inside.
bool _square(Path path, Offset corner, Offset centre) {
  final dir = (centre - corner) / (centre - corner).distance;
  return path.contains(corner + dir * .75);
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final MapEntry(key: bank, value: build) in _banks.entries) {
    for (final family in _families) {
      testWidgets(
        '$bank, $family: whole cells, round where they meet, labels still',
        (tester) async {
          tester.view.physicalSize = const Size(520, 400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final faults = <String>[];
          for (final MapEntry(key: stroke, value: strokes)
              in _strokes.entries) {
            final theme = NeumorphicThemeData.porcelain().copyWith(
              highContrast: strokes,
            );
            var chosen = 0;
            await tester.pumpWidget(
              MaterialApp(
                key: ValueKey(stroke),
                home: NeumorphicTheme(
                  data: theme,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      size: Size(520, 400),
                      disableAnimations: true,
                    ),
                    child: ColoredBox(
                      color: theme.colors.ground,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StatefulBuilder(
                              builder: (context, setState) => build(
                                chosen,
                                (i) => setState(() => chosen = i),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const NeumorphicTextField(
                              hint: 'A field beside it',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final where = stroke;

            // Every cell the same width.
            final cells = [
              for (final e in find.byType(NeumorphicTap).evaluate())
                if (e.findAncestorWidgetOfExactType<NeumorphicTextField>() ==
                    null)
                  () {
                    final box = e.renderObject! as RenderBox;
                    return box.localToGlobal(Offset.zero) & box.size;
                  }(),
            ];
            if (cells.length != 3) {
              faults.add('$where: ${cells.length} cells, not 3');
              continue;
            }
            final widths = cells.map((c) => c.width).toList();
            if (widths.reduce(math.max) - widths.reduce(math.min) > .5) {
              faults.add('$where: cells of $widths');
            }

            // The bank as tall as the field beside it.
            final banks = find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_BankFace',
            );
            final field = tester.getSize(find.byType(NeumorphicFieldBox));
            if (banks.evaluate().isEmpty) {
              faults.add('$where: no bank painted');
            } else {
              final height = tester.getSize(banks.first).height;
              if ((height - field.height).abs() > .5) {
                faults.add(
                  '$where: a bank $height tall beside a field ${field.height}',
                );
              }
            }

            for (final i in [0, 1, 2]) {
              final label = find.text(_labels[i]);
              final before = tester.getRect(label);
              await tester.tap(label);
              await tester.pumpAndSettle();
              if ((tester.getRect(label).topLeft - before.topLeft).distance >
                  .01) {
                faults.add('$where: "${_labels[i]}" moves when it is chosen');
              }
              // The chosen cell's pressed-in face is its whole cell, square where it meets a neighbour.
              final chosenFaces = find.byWidgetPredicate(
                (w) =>
                    w is CustomPaint &&
                    (w.painter ?? w.foregroundPainter).runtimeType.toString() ==
                        '_ChosenCell',
              );
              Path? face;
              Rect? at;
              for (final e in chosenFaces.evaluate()) {
                final w = e.widget as CustomPaint;
                final painter = w.painter ?? w.foregroundPainter!;
                final box = e.renderObject! as RenderBox;
                final canvas = _Paths();
                painter.paint(canvas, box.size);
                if (canvas.paths.isEmpty) continue;
                final origin = box.localToGlobal(Offset.zero);
                if (!(origin & box.size).overlaps(cells[i])) continue;
                face = canvas.paths.first.shift(origin);
                at = cells[i];
              }
              if (face == null || at == null) {
                faults.add(
                  '$where: no pressed-in face under the chosen cell $i',
                );
                continue;
              }
              final b = face.getBounds();
              // Edge to edge between the seams: as wide as the cell, less the bank's rim at an end.
              if ((b.width - at.width).abs() > 2.5) {
                faults.add(
                  '$where: cell $i pressed in ${b.width} of ${at.width}',
                );
              }
              final centre = b.center;
              final inner = <Offset>[
                if (i > 0) ...[b.topLeft, b.bottomLeft],
                if (i < 2) ...[b.topRight, b.bottomRight],
              ];
              for (final corner in inner) {
                // Law 8: no corner is sharp, so a pressed cell rounds by the least corner where it meets the next.
                if (_square(face, corner, centre)) {
                  faults.add(
                    '$where: cell $i is square where it meets a neighbour',
                  );
                }
              }
            }
          }
          expect(faults, isEmpty, reason: faults.join('\n'));
        },
      );
    }
  }

  // A focused field keeps its own fill: focus is the caret and a deeper well at the edges, never a tint behind the
  // words.
  for (final preset in NeumorphicThemeData.presets) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'a focused field keeps its fill in $preset ${brightness.name}',
        (tester) async {
          tester.view.physicalSize = const Size(420, 200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final theme = NeumorphicThemeData.preset(preset, brightness);
          final shot = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: NeumorphicTheme(
                data: theme,
                child: ColoredBox(
                  color: theme.colors.ground,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: RepaintBoundary(
                      key: shot,
                      child: const NeumorphicTextField(hint: 'Name'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          Future<Color> fillAt() async {
            final box = tester.getSize(find.byType(NeumorphicFieldBox));
            final origin =
                tester.getTopLeft(find.byType(NeumorphicFieldBox)) -
                tester.getTopLeft(find.byKey(shot));
            final at = origin + Offset(box.width - 24, box.height / 2);
            final boundary =
                shot.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final bytes = (await tester.runAsync(() async {
              final image = await boundary.toImage();
              final data = await image.toByteData();
              final width = image.width;
              image.dispose();
              return (data!.buffer.asUint8List(), width);
            }))!;
            final (Uint8List px, int width) = bytes;
            final i = (at.dy.round() * width + at.dx.round()) * 4;
            return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
          }

          final idle = await fillAt();
          await tester.tap(find.byType(EditableText));
          await tester.pumpAndSettle();
          expect(await fillAt(), idle);
        },
        tags: ['goldens'],
      );
    }
  }
}
