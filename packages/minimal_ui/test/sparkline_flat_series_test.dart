// A sparkline of zeros lies along its foot: nothing happened, so the line
// sits where nothing is. Any other flat series runs through the middle,
// steady at whatever it holds.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

const double _height = 40;

Widget _host(List<double> data) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Center(
    child: SizedBox(width: 120, child: MinimalSparkline(data, height: _height)),
  ),
);

/// Where the end dot stands, from the top of the sparkline's box.
double _dotFromTop(WidgetTester tester) {
  final box = tester.getRect(find.byType(MinimalSparkline));
  final paint = find.descendant(
    of: find.byType(MinimalSparkline),
    matching: find.byType(CustomPaint),
  );
  double? y;
  expect(
    paint.first,
    paints..something((method, args) {
      if (method != #drawCircle) return false;
      y = (args[0] as Offset).dy;
      return true;
    }),
  );
  final paintTop = tester.getTopLeft(paint.first).dy;
  return y! + paintTop - box.top;
}

void main() {
  testWidgets('a series of zeros lies along the foot', (tester) async {
    await tester.pumpWidget(_host(const [0, 0, 0, 0, 0]));
    final foot = _height - MinimalSparkline.stroke / 2 - 2.2;
    expect(_dotFromTop(tester), closeTo(foot, 0.01));
  });

  testWidgets('another flat series runs through the middle', (tester) async {
    await tester.pumpWidget(_host(const [4, 4, 4, 4]));
    expect(_dotFromTop(tester), closeTo(_height / 2, 0.01));
  });

  testWidgets('a rising series ends at the top', (tester) async {
    await tester.pumpWidget(_host(const [0, 1, 2, 3]));
    final top = MinimalSparkline.stroke / 2 + 2.2;
    expect(_dotFromTop(tester), closeTo(top, 0.01));
  });
}
