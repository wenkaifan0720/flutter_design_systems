// The shared checks (world_checks.dart), run on ui_core's own parts.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'world_checks.dart';

Widget _app(TextDirection direction, Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  debugShowCheckedModeBanner: false,
  builder: (context, _) => Directionality(
    textDirection: direction,
    child: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, top: 16),
            child: child,
          ),
        ),
      ),
    ),
  ),
);

Widget _group() => DesignToggleGroup<String>(
  options: const ['Day', 'Week', 'Month'],
  selected: const {'Day'},
  onSelectionChanged: (_) {},
  itemBuilder: (context, value, states) =>
      SizedBox(width: 72, child: Center(child: Text(value))),
);

void main() {
  testWidgets('a toggle group mirrors right to left', (tester) async {
    await expectMirrorsInRtl(
      tester,
      (direction) => _app(direction, _group()),
      parts: [find.text('Day'), find.text('Week'), find.text('Month')],
    );
  });

  testWidgets('a toggle group keeps to its box at text scale 2', (
    tester,
  ) async {
    await expectNoOverflowAtTextScale(
      tester,
      _app(TextDirection.ltr, _group()),
    );
  });

  testWidgets('a labelled 44 px press on white meets the guidelines', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TextDirection.ltr,
        DesignPressable(
          onPressed: () {},
          semanticLabel: 'Save',
          minimumSize: const Size(44, 44),
          builder: (context, states, child) => const Text('Save'),
        ),
      ),
    );
    await expectMeetsGuidelines(tester, android: false);
  });
}
