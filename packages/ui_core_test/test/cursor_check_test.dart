import 'dart:async' show unawaited;

import 'package:material_ui/material_ui.dart' show InkWell, Material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
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

  // 0.3.0 tooling: the rest of what the check reads, each case once.

  testWidgets("a Material ink response's arrow is the web's click cursor, "
      'and the arrow off the web', (tester) async {
    // Material resolves the adaptive click cursor to the arrow off the
    // web; on the web it is the click cursor.
    Widget ink() => Material(
      child: Semantics(
        button: true,
        label: 'Save',
        child: InkWell(
          onTap: () {},
          mouseCursor: WidgetStateMouseCursor.adaptiveClickable,
          child: const SizedBox(width: 120, height: 44),
        ),
      ),
    );
    expect((await _check(tester, ink())).problems, isEmpty);
    expect((await _check(tester, ink(), web: false)).problems, [
      allOf(contains('a button "Save"'), contains('shows the arrow cursor')),
    ]);
  });

  testWidgets('the adaptive click cursor off the web is the arrow', (
    tester,
  ) async {
    final report = await _check(
      tester,
      Semantics(
        button: true,
        label: 'Save',
        child: GestureDetector(
          onTap: () {},
          child: const MouseRegion(
            cursor: WidgetStateMouseCursor.adaptiveClickable,
            child: SizedBox(width: 120, height: 44),
          ),
        ),
      ),
      web: false,
    );
    expect(report.problems, hasLength(1));
  });

  testWidgets('a cursor is named as it shows, a state cursor as it resolves', (
    tester,
  ) async {
    Widget live(MouseCursor cursor) => Semantics(
      button: true,
      label: 'Save',
      child: GestureDetector(
        onTap: () {},
        child: MouseRegion(
          cursor: cursor,
          child: const SizedBox(width: 120, height: 44),
        ),
      ),
    );
    Widget off(MouseCursor cursor) => Semantics(
      button: true,
      enabled: false,
      label: 'Save',
      child: MouseRegion(
        cursor: cursor,
        child: const SizedBox(width: 120, height: 44),
      ),
    );
    for (final (control, name) in [
      (off(SystemMouseCursors.text), 'shows the text cursor'),
      (off(SystemMouseCursors.grab), 'shows the grab cursor'),
      (live(SystemMouseCursors.forbidden), 'shows the forbidden cursor'),
      (live(MouseCursor.uncontrolled), 'uncontrolled'),
    ]) {
      final report = await _check(tester, control);
      expect(report.problems, [contains(name)], reason: name);
    }
    expect(
      (await _check(tester, live(WidgetStateMouseCursor.clickable))).problems,
      isEmpty,
    );
  });

  testWidgets('where a control shows the arrow is said: the spots across it', (
    tester,
  ) async {
    // The click cursor over its left half only.
    final report = await _check(
      tester,
      Semantics(
        button: true,
        label: 'Save',
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(width: 60, height: 44),
              ),
              SizedBox(width: 60, height: 44),
            ],
          ),
        ),
      ),
    );
    expect(report.problems, [
      contains(
        'shows the arrow cursor in its middle, three quarters across and '
        'near its right end',
      ),
    ]);
  });

  testWidgets('a part with no name of its own is named by the control round '
      'it, and a field by the text cursor it should show', (tester) async {
    // A slider's track under the slider's semantics takes the tap, and
    // shows the arrow.
    final part = await _check(
      tester,
      Semantics(
        slider: true,
        label: 'Volume',
        value: '50',
        child: SizedBox(
          width: 240,
          height: 32,
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(width: 120, height: 32),
            ),
          ),
        ),
      ),
    );
    expect(part.problems, [contains('a part of a slider "Volume" shows')]);
    final field = await _check(
      tester,
      Semantics(
        textField: true,
        label: 'Name',
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(width: 200, height: 40),
        ),
      ),
    );
    expect(field.problems, [
      allOf(
        contains('a text field "Name" shows the arrow cursor'),
        contains('a live field shows the text cursor'),
      ),
    ]);
  });

  testWidgets("a press heard round the whole page is not a control's own", (
    tester,
  ) async {
    // A listener round the page (a tap that closes the keyboard) takes the
    // press over a button that has none of its own: not the button's.
    final report = await _check(
      tester,
      Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {},
        child: SizedBox(
          width: 400,
          height: 300,
          child: Center(
            child: Semantics(
              button: true,
              label: 'Info',
              child: const SizedBox(width: 120, height: 44),
            ),
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('every check runs from a navigator, past the pages its overlay '
      'keeps offstage, laid out once or never', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Route<void> page(Widget child) => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Center(child: child),
      ),
    );
    // A button that keeps the arrow, which the web's click cursor should
    // be: the check names it where it reads it.
    Widget button(String label) => Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {},
        child: const MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: SizedBox(width: 120, height: 44),
        ),
      ),
    );
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigator,
          // The first page is built under the second, offstage: never laid
          // out (a transform placed in its own size, by its alignment).
          onGenerateInitialRoutes: (_, _) => [
            page(Transform.scale(scale: 1, child: button('Under'))),
            page(button('Middle')),
          ],
        ),
      ),
    );
    // The second, laid out, goes offstage under a third.
    unawaited(navigator.currentState!.push(page(button('Top'))));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Navigator));
    final reports = <DesignAlignmentReport>[
      const DesignCursorCheck(look: 'Test').check(context),
      await const DesignKeylineCheck(look: 'Test')
          .check(context, runAsync: tester.runAsync),
      await const DesignLabelCheck(look: 'Test')
          .check(context, runAsync: tester.runAsync),
      await const DesignRowCheck(look: 'Test')
          .check(context, runAsync: tester.runAsync),
      await const DesignWidthCheck(look: 'Test')
          .check(context, runAsync: tester.runAsync),
      await const DesignSpacingCheck(look: 'Test')
          .check(context, runAsync: tester.runAsync),
      await const DesignShadowClipCheck(look: 'Test')
          .check(context, runAsync: tester.runAsync),
      const DesignWordBreakCheck(look: 'Test').check(context),
      const DesignClipCheck(look: 'Test').check(context),
      const DesignTapTargetCheck(look: 'Test').check(context),
    ];
    expect(tester.takeException(), isNull);
    final cursor = reports.first.problems;
    expect(cursor, hasLength(1));
    expect(cursor.single, contains('Top'));
    for (final report in reports) {
      for (final problem in report.problems) {
        expect(problem, isNot(contains('Under')));
        expect(problem, isNot(contains('Middle')));
      }
    }
    semantics.dispose();
  });
}
