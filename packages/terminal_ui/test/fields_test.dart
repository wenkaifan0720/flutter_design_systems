// A field is its whole frame: the input covers the three lines (over a
// finger's 44), so a tap on the label line reaches it, and the select on one
// line opens from its label too.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: child),
    ),
  ),
);

void main() {
  testWidgets('a text field takes a tap anywhere in its frame', (tester) async {
    await tester.pumpWidget(_host(const TermTextField(labelText: 'branch')));
    final frame = tester.getRect(find.byType(TermTextField));
    expect(tester.getSize(find.byType(TextField)).height, frame.height);
    expect(frame.height, greaterThanOrEqualTo(44));
    // Its words on the frame's middle line.
    expect(
      tester.getCenter(find.byType(EditableText)).dy,
      closeTo(frame.center.dy, 1),
    );

    // On the label's line, not the input's.
    await tester.tapAt(frame.topLeft + const Offset(40, 6));
    await tester.pump();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('a one-line field is as tall as a finger needs', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => DesignTapTargetScope(
            targets: DesignTapTargets.of(context)
                .copyWith(input: DesignInput.touch),
            child: const TermTextField.inline(labelText: 'name', labelCols: 8),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getCenter(find.byType(EditableText)).dy,
      closeTo(tester.getCenter(find.byType(TextField)).dy, 1),
    );
  });

  testWidgets('under Reduce Motion the caret holds still', (tester) async {
    Future<EditableText> field({required bool still}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: still),
            child: TermTheme(
              data: TermThemeData.dark(),
              child: const Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 360,
                  child: TermTextField(labelText: 'branch'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TermTextField));
      await tester.pump();
      return tester.widget<EditableText>(find.byType(EditableText));
    }

    // Flutter's own caret blinks; it shows only where motion is wanted.
    expect((await field(still: false)).showCursor, isTrue);
    expect((await field(still: true)).showCursor, isFalse);
    final painters = [
      for (final p in tester.widgetList<CustomPaint>(find.byType(CustomPaint)))
        p.painter.runtimeType.toString(),
    ];
    expect(painters, contains('_SteadyCaret'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a one-time code is one line, however much room it has', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const TermOtpField()));
    // Its target may reach a finger's two lines; never the screen's height.
    expect(tester.getSize(find.byType(TermOtpField)).height, lessThan(60));
  });
}
