// A switch's exposed mark (the O when off, the I when on) stands midway in
// the room the cap leaves bare, clear of the cap; the cap still covers the
// mark it rests on.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _slot = find.byWidgetPredicate(
  (w) => w is CustomPaint && '${w.painter.runtimeType}' == '_SwitchPainter',
);

Future<void> _pump(WidgetTester tester, TextDirection direction) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: ApplianceSwitch(
            value: false,
            onChanged: (_) {},
            semanticLabel: 'Favourite',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets(
      'each mark stands midway in the bare room (${direction.name})',
      (tester) async {
        await _pump(tester, direction);
        final size = tester.getSize(_slot);
        const cap = ApplianceSwitch.capSize;
        // At rest at one end the cap spans [capInset, capInset + cap]; the
        // room it leaves bare runs from its edge to the slot's far wall.
        final bare = (ApplianceMetrics.capInset + cap.width + size.width) / 2;
        final rtl = direction == TextDirection.rtl;
        final offX = rtl ? size.width - bare : bare;
        final onX = size.width - offX;
        final cy = size.height / 2;
        expect(
          tester.renderObject(_slot),
          paints
            ..line(p1: Offset(onX, cy - 6.5), p2: Offset(onX, cy + 6.5))
            ..circle(x: offX, y: cy, radius: 5.5),
        );
      },
    );
  }
}
