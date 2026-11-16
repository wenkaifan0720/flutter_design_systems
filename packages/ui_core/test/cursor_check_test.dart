import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

// A slider drawn the way Frosted's and Ledger's 0.1.0 drew theirs: the
// whole bar takes a drag, but only the thumb shows the click cursor.
Widget _slider({required bool wholeBar, bool enabled = true}) {
  Widget thumb = const SizedBox(
    width: 20,
    height: 20,
    child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF333333))),
  );
  if (!wholeBar) {
    thumb = MouseRegion(cursor: SystemMouseCursors.click, child: thumb);
  }
  Widget bar = GestureDetector(
    onHorizontalDragUpdate: enabled ? (_) {} : null,
    behavior: HitTestBehavior.opaque,
    child: const SizedBox(width: 240, height: 32),
  );
  bar = Stack(
    alignment: Alignment.center,
    children: [
      bar,
      Positioned(left: 110, child: thumb),
    ],
  );
  if (wholeBar) {
    bar = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: bar,
    );
  }
  return Semantics(
    slider: true,
    label: 'Volume',
    value: '50',
    enabled: enabled,
    child: bar,
  );
}

Future<DesignAlignmentReport> _check(
  WidgetTester tester,
  Widget child, {
  bool web = true,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(key: const Key('page'), child: child),
    ),
  );
  return DesignCursorCheck(
    look: 'Test',
    web: web,
  ).check(tester.element(find.byKey(const Key('page'))));
}

void main() {
  testWidgets('a slider whose track shows the arrow is named', (tester) async {
    final report = await _check(tester, _slider(wholeBar: false));
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(
        contains('a slider "Volume"'),
        contains('shows the arrow cursor'),
        contains('a live control shows the click cursor'),
      ),
    );
    expect(report.verify, throwsA(isA<DesignAlignmentError>()));
  });

  testWidgets('a slider that shows the click cursor over all of it passes', (
    tester,
  ) async {
    final report = await _check(tester, _slider(wholeBar: true));
    expect(report.problems, isEmpty);
  });

  testWidgets('an off control showing the click cursor is named', (
    tester,
  ) async {
    final report = await _check(
      tester,
      Semantics(
        button: true,
        enabled: false,
        label: 'Save',
        child: const MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(width: 120, height: 44),
        ),
      ),
    );
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(contains('"Save"'), contains('click cursor')),
    );
  });

  testWidgets('a pressable, live and off, passes', (tester) async {
    for (final enabled in [true, false]) {
      final report = await _check(
        tester,
        DesignPressable(
          onPressed: enabled ? () {} : null,
          semanticLabel: 'Save',
          builder: (context, states, _) =>
              const SizedBox(width: 120, height: 44),
        ),
      );
      expect(report.problems, isEmpty, reason: 'enabled: $enabled');
    }
  });

  testWidgets('a text field shows the text cursor and passes', (tester) async {
    final controller = TextEditingController(text: 'Hello');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    final report = await _check(
      tester,
      SizedBox(
        width: 200,
        child: EditableText(
          controller: controller,
          focusNode: focus,
          style: const TextStyle(fontSize: 14),
          cursorColor: const Color(0xFF000000),
          backgroundCursorColor: const Color(0xFF888888),
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets("the adaptive click cursor is the web's click cursor", (
    tester,
  ) async {
    Widget button() => Semantics(
      button: true,
      label: 'Save',
      child: GestureDetector(
        onTap: () {},
        child: const MouseRegion(
          cursor: WidgetStateMouseCursor.adaptiveClickable,
          child: SizedBox(width: 120, height: 44),
        ),
      ),
    );
    expect((await _check(tester, button())).problems, isEmpty);
  });

  testWidgets('a modal barrier keeps the arrow', (tester) async {
    final report = await _check(
      tester,
      ModalBarrier(
        color: const Color(0x66000000),
        onDismiss: () {},
        semanticsLabel: 'Dismiss',
      ),
    );
    expect(report.problems, isEmpty);
  });
}
