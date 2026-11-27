// A groove is a cut whose lower lip catches the light, by day and by night,
// read from the pixels in each of Clay's six palettes. By night a dark line
// alone sinks into the dark ground: there the lit lip reads at least as well
// as the day's groove does.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = ValueKey('frame');

double _ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

// How far a groove on the ground stands from it: its strongest mark either
// way, and its lightest mark (the lip) above the ground.
Future<({double mark, double lip})> _groove(
  WidgetTester tester,
  ClayThemeData theme,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ClayHost(
        brightness: theme.colors.brightness,
        theme: theme,
        darkTheme: theme,
        child: Center(
          child: RepaintBoundary(
            key: _frame,
            child: ColoredBox(
              color: theme.colors.ground,
              child: const SizedBox(
                width: 40,
                height: 9,
                child: Center(child: ClayGroove()),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  final bytes = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    return image.toByteData(format: ui.ImageByteFormat.rawRgba);
  }))!;
  Color at(int y) {
    final i = (y * 40 + 20) * 4;
    return Color.fromARGB(
      255,
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }

  final ground = at(0);
  final marks = [for (var y = 1; y < 9; y++) at(y)];
  return (
    mark: marks.map((m) => _ratio(m, ground)).reduce(math.max),
    lip: marks
        .where((m) => m.computeLuminance() > ground.computeLuminance())
        .map((m) => _ratio(m, ground))
        .fold(1.0, math.max),
  );
}

void main() {
  for (final palette in ClayThemeData.palettes) {
    testWidgets('a groove reads on the ground by night (${palette.id})', (
      tester,
    ) async {
      final day = await _groove(
        tester,
        ClayThemeData.preset(palette.id, Brightness.light),
      );
      final night = await _groove(
        tester,
        ClayThemeData.preset(palette.id, Brightness.dark),
      );
      expect(day.mark, greaterThan(1.05));
      expect(night.mark, greaterThanOrEqualTo(day.mark));
    });

    testWidgets('a groove has a lit lip by day and by night (${palette.id})', (
      tester,
    ) async {
      for (final b in Brightness.values) {
        final groove = await _groove(
          tester,
          ClayThemeData.preset(palette.id, b),
        );
        expect(groove.lip, greaterThan(1.1), reason: b.name);
      }
    });
  }
}
