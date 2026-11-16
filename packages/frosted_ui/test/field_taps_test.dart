// A tap anywhere from a field's well's top to its bottom focuses the field (ui_core's tap check on 0.1.1: "a text
// field 'Search activity': a tap reaches it over 298 × 14 ... a screen reader outlines 298 × 48"; only the line's own
// 14-20 pt answered, inside a 44-48 well). The field's line now spans the row its well holds, and its one node spans
// the same box: the box a screen reader outlines is the box a tap reaches. At 390 and 1440, left to right and right to
// left: a tap 1 pt inside the well's row at its top and at its bottom, over the line's middle, gives the field focus.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/hit_slop.dart';

Future<void> _pump(
  WidgetTester t,
  Widget field, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
}) async {
  t.view.physicalSize = Size(width, 600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => Directionality(
        textDirection: direction,
        child: FrostedHost(brightness: Brightness.dark, child: page!),
      ),
      home: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(alignment: Alignment.topCenter, child: field),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Rect _global(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

final _fields = <String, Widget Function()>{
  'text field': () =>
      FrostedTextField(label: 'Name', hint: 'Your name', onChanged: (_) {}),
  'search field': () =>
      FrostedSearchField(hint: 'Search activity', onChanged: (_) {}),
  'password field': () =>
      FrostedPasswordField(label: 'Password', onChanged: (_) {}),
};

bool _focused(WidgetTester t) =>
    t.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

void main() {
  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      for (final MapEntry(key: name, value: build) in _fields.entries) {
        final tag = '$name, ${width.toInt()}, ${direction.name}';
        testWidgets(
          'a tap at the top or foot of the well focuses the field ($tag)',
          (t) async {
            for (final atTop in [true, false]) {
              await _pump(t, build(), width: width, direction: direction);
              expect(_focused(t), isFalse);
              final room = _global(
                t.renderObject<RenderBox>(find.byType(FrostedFieldRoom)),
              );
              final line = _global(
                t.renderObject<RenderBox>(find.byType(FrostedFieldTarget)),
              );
              // The room stands at least a finger's floor tall, and the line
              // well inside it: the tap lands off the line itself.
              expect(room.height, greaterThanOrEqualTo(44));
              expect(line.height, lessThan(room.height - 8));
              final at = Offset(
                line.center.dx,
                atTop ? room.top + 1 : room.bottom - 1,
              );
              await t.tapAt(at);
              await t.pumpAndSettle();
              expect(_focused(t), isTrue, reason: atTop ? 'top' : 'foot');
              // Reset for the next tap.
              await t.pumpWidget(const SizedBox());
            }
          },
        );

        testWidgets(
          'the node a screen reader outlines is the room the tap reaches ($tag)',
          (t) async {
            final handle = t.ensureSemantics();
            await _pump(t, build(), width: width, direction: direction);
            final room = t.renderObject<RenderBox>(
              find.byType(FrostedFieldRoom),
            );
            final node = t.getSemantics(find.byType(FrostedFieldTarget));
            expect(node.rect.height, closeTo(room.size.height, 0.01));
            handle.dispose();
          },
        );
      }
    }
  }
}
