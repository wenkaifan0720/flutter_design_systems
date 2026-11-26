// RawFocusShown, exported: a look's own pressable on a bare
// FocusableActionDetector shows its focus as RawButton does, not as
// Flutter's highlight mode does, which a mouse leaves traditional.
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// A look's row: its ring from RawFocusShown, or ([shown] false) from the
// detector's own highlight.
class _Row extends StatefulWidget {
  const _Row({required this.focusNode, required this.shown});

  final FocusNode focusNode;
  final bool shown;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _ring = false;

  late final RawFocusShown _focus = RawFocusShown(
    (shown) => setState(() => _ring = shown),
  );

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    focusNode: widget.focusNode,
    onShowFocusHighlight: widget.shown
        ? _focus.focused
        : (on) => setState(() => _ring = on),
    child: Semantics(
      key: const ValueKey('row'),
      button: true,
      label: 'Rename',
      onTap: () {},
      child: SizedBox(
        width: 200,
        height: 44,
        child: Text(_ring ? 'ring' : 'plain'),
      ),
    ),
  );
}

// A click on the web with semantics on: the browser focuses the row's node,
// then taps it, before any press reaches the app.
void _webClick(WidgetTester tester) {
  final node = tester.getSemantics(find.byKey(const ValueKey('row')));
  for (final type in [SemanticsAction.focus, SemanticsAction.tap]) {
    tester.binding.platformDispatcher.onSemanticsActionEvent!(
      SemanticsActionEvent(
        type: type,
        viewId: tester.view.viewId,
        nodeId: node.id,
      ),
    );
  }
}

final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  for (final shown in [true, false]) {
    final how = shown ? 'RawFocusShown' : "the detector's own highlight";
    testWidgets('a row a click focused on the web, by $how', (tester) async {
      final semantics = tester.ensureSemantics();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        harness(
          Align(
            alignment: Alignment.topLeft,
            child: _Row(focusNode: focusNode, shown: shown),
          ),
        ),
      );
      // A key before, as a menu the keys never touched.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      _webClick(tester);
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      // Flutter's highlight shows the ring a click left; RawFocusShown, as
      // ui_core's parts, does not.
      expect(find.text('ring'), shown ? findsNothing : findsOneWidget);
      semantics.dispose();
    }, variant: _desktop);
  }

  testWidgets('RawFocusShown: a key shows the ring, a press hides it', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topLeft,
          child: _Row(focusNode: focusNode, shown: true),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.down(tester.getCenter(find.byType(_Row)));
    await mouse.up();
    focusNode.requestFocus();
    await tester.pump();
    expect(find.text('plain'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(find.text('ring'), findsOneWidget);
    await mouse.down(tester.getCenter(find.byType(_Row)));
    await mouse.up();
    await tester.pump();
    expect(find.text('plain'), findsOneWidget);
    expect(focusNode.hasFocus, isTrue);
  }, variant: _desktop);
}
