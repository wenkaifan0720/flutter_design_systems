// A listbox option that is both chosen and the keyboard's active one draws
// its ring as its outermost line, over the chosen pill at its leading edge
// (as a menu's row does), so the pill never cuts the ring.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2OptionFace;

void main() {
  testWidgets("a chosen option's keyboard ring is drawn over its pill", (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) => Fluent2Host(child: page!),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: Fluent2OptionFace(
                label: 'Kai Chen',
                selected: true,
                highlighted: true,
                states: <WidgetState>{},
              ),
            ),
          ),
        ),
      ),
    );
    final ring = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.position == DecorationPosition.foreground &&
          (w.decoration as BoxDecoration).border != null,
    );
    expect(ring, findsOneWidget);
    // Fluent's 2 px focus stroke.
    final border =
        (t.widget<DecoratedBox>(ring).decoration as BoxDecoration).border!;
    expect(border.top.width, Fluent2Stroke.thick);
    // The pill's stack is inside the ring's box, so the ring paints after it.
    expect(
      find.descendant(of: ring, matching: find.byType(Stack)),
      findsWidgets,
    );
    expect(
      find.descendant(of: ring, matching: find.text('Kai Chen')),
      findsOneWidget,
    );
  });
}
