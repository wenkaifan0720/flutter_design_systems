// Clay's controls and routes as an app meets them: a dialog and a sheet open
// and close, the switch, the slider and the segments answer a finger and the
// keys, the step bar's grooves join its balls, large text keeps words whole,
// a disabled key lies level, and a ball stands 3:1 on its groove by day and
// by night.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_ui/clay_ui.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double text = 1,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (text != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await tester.pumpWidget(
    ClayPreview(
      brightness: brightness,
      child: ClayScreen(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// A key that opens what [open] shows.
Widget _opener(void Function(BuildContext context) open) => Builder(
  builder: (context) => ClayButton('Open', onPressed: () => open(context)),
);

double _contrast(Color a, Color b) {
  final (x, y) = (a.computeLuminance(), b.computeLuminance());
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('$brightness: a dialog rises; Escape or its action closes it', (
      tester,
    ) async {
      String? answer;
      await _show(
        tester,
        brightness: brightness,
        _opener(
          (context) => showClayDialog<void>(
            context: context,
            builder: (context) => ClayDialog(
              title: 'Delete the habit?',
              actions: [
                ClayDialogAction(
                  label: 'Keep',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ClayDialogAction(
                  label: 'Delete',
                  destructive: true,
                  primary: true,
                  onPressed: () {
                    answer = 'deleted';
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete the habit?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Delete the habit?'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(answer, 'deleted');
      expect(find.text('Delete the habit?'), findsNothing);
    });
  }

  testWidgets('a sheet stays on a press inside it and closes on one beside '
      'it', (tester) async {
    await _show(
      tester,
      _opener(
        (context) => showClayBottomSheet<void>(
          context: context,
          builder: (context) => const Text('Eight glasses'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eight glasses'));
    await tester.pumpAndSettle();
    expect(find.text('Eight glasses'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Eight glasses'), findsNothing);
  });

  testWidgets('the switch, the slider and the segments answer', (tester) async {
    var on = false;
    var level = 0.5;
    var range = 'week';
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            ClaySwitch(
              value: on,
              onChanged: (v) => setState(() => on = v),
              semanticLabel: 'Remind me',
            ),
            ClaySlider(
              value: level,
              divisions: 10,
              focusNode: focus,
              onChanged: (v) => setState(() => level = v),
              semanticLabel: 'Energy',
            ),
            ClaySegmentedButton<String>(
              segments: const [
                ClaySegment(value: 'week', label: 'Week'),
                ClaySegment(value: 'month', label: 'Month'),
              ],
              selected: range,
              onChanged: (v) => setState(() => range = v),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(ClaySwitch));
    await tester.pumpAndSettle();
    expect(on, isTrue);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(level, closeTo(0.6, 1e-9));
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(range, 'month');
  });

  testWidgets('the step bar\'s grooves run between its balls', (tester) async {
    await _show(
      tester,
      const ClayStepProgress(
        steps: ['Habit', 'Schedule', 'Reminder'],
        current: 1,
      ),
    );
    // The balls are animated surfaces, the grooves plain ones.
    List<Rect> rects(Type type, bool Function(Size size) which) =>
        find
            .descendant(
              of: find.byType(ClayStepProgress),
              matching: find.byType(type),
            )
            .evaluate()
            .map((e) => (e.renderObject! as RenderBox))
            .map((box) => box.localToGlobal(Offset.zero) & box.size)
            .where((r) => which(r.size))
            .toList()
          ..sort((a, b) => a.left.compareTo(b.left));
    bool near(double a, double b) => (a - b).abs() < 0.5;
    final balls = rects(
      AnimatedClaySurface,
      (s) => near(s.width, 32) && near(s.height, 32),
    );
    final grooves = rects(ClaySurface, (s) => near(s.height, 6));
    expect(balls, hasLength(3));
    expect(grooves, hasLength(2));
    for (var i = 0; i < 2; i++) {
      expect(grooves[i].left, greaterThanOrEqualTo(balls[i].right - 0.5));
      expect(grooves[i].right, lessThanOrEqualTo(balls[i + 1].left + 0.5));
    }
  });

  testWidgets('at 200% the words stay whole: segments stack, a row keeps its '
      'title\'s start, a key grows', (tester) async {
    await _show(
      tester,
      text: 2,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClaySegmentedButton<int>(
            segments: const [
              ClaySegment(value: 0, label: 'Morning'),
              ClaySegment(value: 1, label: 'Afternoon'),
              ClaySegment(value: 2, label: 'Evening'),
            ],
            selected: 0,
            onChanged: (_) {},
          ),
          ClayGroup(
            children: [
              ClayListTile(
                title: 'Compact rows',
                subtitle: 'More on screen at once',
                trailing: ClaySwitch(value: false, onChanged: (_) {}),
              ),
              ClayListTile(
                title: 'Right to left',
                trailing: ClaySwitch(value: false, onChanged: (_) {}),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ClayButton('Save habit', onPressed: () {}),
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    final morning = tester.getTopLeft(find.text('Morning'));
    final afternoon = tester.getTopLeft(find.text('Afternoon'));
    expect(afternoon.dy, greaterThan(morning.dy));
    expect(
      tester.getTopLeft(find.text('Compact rows')).dx,
      tester.getTopLeft(find.text('Right to left')).dx,
    );
    expect(
      tester.getSize(find.byType(ClayButton)).height,
      greaterThanOrEqualTo(
        tester.getSize(find.text('Save habit')).height + 2 * ClaySpacing.small,
      ),
    );
  });

  testWidgets('a disabled key lies level: no shadow', (tester) async {
    await _show(tester, const ClayButton('Save', onPressed: null));
    final face = tester
        .widget<AnimatedClaySurface>(
          find.descendant(
            of: find.byType(ClayButton),
            matching: find.byType(AnimatedClaySurface),
          ),
        )
        .face;
    expect(face.shadowOpacity, 0);
  });

  testWidgets('a count stands under free text, never under a number', (
    tester,
  ) async {
    final note = TextEditingController(text: 'abc');
    final goal = TextEditingController(text: '1');
    addTearDown(note.dispose);
    addTearDown(goal.dispose);
    await _show(
      tester,
      Column(
        children: [
          ClayTextField(label: 'Note', controller: note, maxLength: 4),
          ClayTextField(
            label: 'Daily goal',
            controller: goal,
            maxLength: 2,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('1/2'), findsNothing);
  });

  test('a ball stands 3:1 on an off groove, by day and by night', () {
    for (final theme in [ClayThemeData.light(), ClayThemeData.dark()]) {
      final c = theme.colors;
      expect(_contrast(c.knob, c.track), greaterThanOrEqualTo(3));
    }
  });
}
