// Each ui_core overlay runs its look's exit motion before it unmounts: asked
// to close, its surface stays drawn while its animation runs down, and
// leaves the tree only once the motion has ended, never at once.
// DesignTooltip is deprecated in the package, which keeps its tests for its
// one last release.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _surface = ValueKey('surface');

late Animation<double> _animation;
late VoidCallback _close;

// The surface, at its animation's opacity, as a look draws one.
Widget _drawn(Animation<double> animation, VoidCallback close) {
  _animation = animation;
  _close = close;
  return FadeTransition(
    opacity: animation.drive(Tween(begin: 0, end: 1)),
    child: const SizedBox(key: _surface, width: 120, height: 80),
  );
}

// A button that opens [open] from the page.
Widget _opener(void Function(BuildContext context) open) => harness(
  Builder(
    builder: (context) => Align(
      alignment: Alignment.topLeft,
      child: RawButton(
        semanticLabel: 'Open',
        onPressed: () => open(context),
        builder: (context, states, _) => plainFace('Open'),
      ),
    ),
  ),
);

// Closes the shown surface, then checks it is still drawn part way out, a
// frame at a time, and gone once the motion has run.
Future<void> _leavesWithItsMotion(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.byKey(_surface), findsOneWidget);
  expect(_animation.value, closeTo(1, 0.01));
  _close();
  var frames = 0;
  while (_animation.value > 0.9 && frames++ < 60) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(_animation.value, inExclusiveRange(0.01, 0.9));
  expect(find.byKey(_surface), findsOneWidget, reason: 'drawn as it leaves');
  await tester.pumpAndSettle();
  expect(find.byKey(_surface), findsNothing);
}

void main() {
  testWidgets('a popover or a menu (RawPopover)', (tester) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: RawPopover(
            semanticLabel: 'Options',
            anchorBuilder: (context, anchor) => RawButton(
              onPressed: anchor.toggle,
              builder: (context, states, _) => plainFace('Open'),
            ),
            overlayBuilder: (context, info) =>
                _drawn(info.animation, info.close),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await _leavesWithItsMotion(tester);
  });

  testWidgets('a tooltip', (tester) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignTooltip(
            message: 'Save the report',
            tooltipBuilder: (context, info) =>
                _drawn(info.animation, info.close),
            child: plainFace('Save'),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Save'));
    await _leavesWithItsMotion(tester);
  });

  testWidgets('a dialog', (tester) async {
    await tester.pumpWidget(
      _opener(
        (context) => Navigator.of(context).push(
          DesignDialogRoute<void>(
            semanticLabel: 'Rename',
            builder: (context, d) => _drawn(d.animation, d.close),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await _leavesWithItsMotion(tester);
  });

  testWidgets('a bottom sheet', (tester) async {
    await tester.pumpWidget(
      _opener(
        (context) => Navigator.of(context).push(
          RawBottomSheetRoute<void>(
            builder: (context, d) => _drawn(d.animation, d.close),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await _leavesWithItsMotion(tester);
  });

  testWidgets('a side sheet', (tester) async {
    await tester.pumpWidget(
      _opener(
        (context) => Navigator.of(context).push(
          RawSideSheetRoute<void>(
            semanticLabel: 'Filters',
            builder: (context, sheet) => _drawn(sheet.animation, sheet.close),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await _leavesWithItsMotion(tester);
  });
}
