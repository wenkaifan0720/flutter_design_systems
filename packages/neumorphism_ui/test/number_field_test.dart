// The number field on ui_core's RawNumberField: one tab stop that takes typing and the arrows, two round keys that
// step on a press and repeat while held and go out of use at their bounds, and one node a screen reader steps.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

/// A number field that keeps the number it is given, and the numbers it reported.
class _Counted extends StatefulWidget {
  const _Counted({
    required this.log,
    this.start = 2,
    this.max = 12,
    this.enabled = true,
  });

  final List<double?> log;
  final double start;
  final double? max;
  final bool enabled;

  @override
  State<_Counted> createState() => _CountedState();
}

class _CountedState extends State<_Counted> {
  late double? _value = widget.start;

  @override
  Widget build(BuildContext context) => NeumorphicNumberField(
    value: _value,
    min: 1,
    max: widget.max,
    unit: 'people',
    onChanged: widget.enabled
        ? (value) {
            widget.log.add(value);
            setState(() => _value = value);
          }
        : null,
  );
}

Widget _app(Widget field, {TextDirection direction = TextDirection.ltr}) =>
    neumorphicApp(
      Directionality(
        textDirection: direction,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(padding: const EdgeInsets.all(24), child: field),
        ),
      ),
    );

Finder get _less => find.byIcon(NeumorphicGlyphs.minus);
Finder get _more => find.byIcon(NeumorphicGlyphs.plus);
Finder get _editable => find.byType(EditableText);

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets(
    'one tab stop: the arrows and Page keys step it, the next Tab leaves',
    (tester) async {
      final log = <double?>[];
      var after = 0;
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Counted(log: log, max: 40),
              NeumorphicButton('After', onPressed: () => after++),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester.widget<EditableText>(_editable).focusNode.hasFocus,
        isTrue,
        reason: 'the figure is the first stop: the keys are not stops',
      );
      for (final key in [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.pageUp,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }
      expect(log, [3, 2, 1, 11]);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(after, 1);
    },
  );

  testWidgets(
    'the figure stands in a groove as tall as the keys\' faces, a gap from each, and focus raises the groove',
    (tester) async {
      await tester.pumpWidget(_app(const _Counted(log: [])));
      final groove = find.ancestor(
        of: _editable,
        matching: find.byType(NeumorphicSurface),
      );
      NeumorphicSurface surface() => tester.widget(groove.first);
      expect(surface().cast, NeumorphicSurfaceLevel.groove);
      expect(surface().states, isEmpty, reason: 'at rest a quiet groove');
      final well = tester.getRect(groove.first);
      for (final key in [_less, _more]) {
        final face = tester.widget<NeumorphicRoundButton>(
          find.ancestor(of: key, matching: find.byType(NeumorphicRoundButton)),
        );
        expect(well.height, face.size, reason: 'one height with the keys');
        expect(
          well.center.dy,
          moreOrLessEquals(tester.getCenter(key).dy, epsilon: .5),
        );
        // The key's 40 target, its face centred in it.
        final target = tester.getRect(
          find.ancestor(of: key, matching: find.byType(NeumorphicRoundButton)),
        );
        expect(
          target.overlaps(well),
          isFalse,
          reason: 'key $target, groove $well',
        );
        final gap = target.left > well.right
            ? target.left - well.right
            : well.left - target.right;
        expect(gap, greaterThanOrEqualTo(6));
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(surface().states, {WidgetState.focused});
      expect(
        NeumorphicStatesScope.of(tester.element(_editable)),
        isNot(contains(WidgetState.pressed)),
        reason: 'never pressed in as a key',
      );
    },
  );

  testWidgets(
    'the figure and its unit are one target: a press on the unit focuses the field',
    (tester) async {
      await tester.pumpWidget(_app(const _Counted(log: [])));
      await tester.tap(find.text('people'));
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(_editable).focusNode.hasFocus, isTrue);
    },
  );

  testWidgets('a typed number is taken on Enter, kept within the bounds', (
    tester,
  ) async {
    final log = <double?>[];
    await tester.pumpWidget(_app(_Counted(log: log)));
    await tester.enterText(_editable, '7');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.enterText(_editable, '99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(log, [7, 12]);
    expect(tester.widget<EditableText>(_editable).controller.text, '12');
  });

  testWidgets(
    'a key steps on a press, repeats while held, and goes out of use at its bound',
    (tester) async {
      final log = <double?>[];
      await tester.pumpWidget(_app(_Counted(log: log, start: 1, max: 6)));
      await tester.tap(_less);
      await tester.pump();
      expect(log, isEmpty, reason: 'at the least number, less is out of use');
      await tester.tap(_more);
      await tester.pump();
      expect(log, [2]);
      final hold = await tester.startGesture(tester.getCenter(_more));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 80));
      await hold.up();
      await tester.pump();
      expect(log, [2, 3, 4, 5, 6], reason: 'the hold stops at the greatest');
    },
  );

  testWidgets('each key keeps a 40 target at the row\'s ends', (tester) async {
    await tester.pumpWidget(_app(const _Counted(log: [])));
    for (final key in [_less, _more]) {
      final target = tester.getRect(
        find.ancestor(of: key, matching: find.byType(SizedBox)).last,
      );
      expect(target.width, greaterThanOrEqualTo(40));
      expect(target.height, greaterThanOrEqualTo(40));
    }
    final figure = tester.getCenter(_editable).dx;
    expect(tester.getCenter(_less).dx, lessThan(figure));
    expect(tester.getCenter(_more).dx, greaterThan(figure));
  });

  testWidgets('right to left, less stands on the right', (tester) async {
    await tester.pumpWidget(
      _app(const _Counted(log: []), direction: TextDirection.rtl),
    );
    expect(tester.getCenter(_less).dx, greaterThan(tester.getCenter(_more).dx));
  });

  testWidgets('a screen reader hears one field and steps it', (tester) async {
    final semantics = tester.ensureSemantics();
    final log = <double?>[];
    await tester.pumpWidget(_app(_Counted(log: log)));
    expect(
      tester.getSemantics(_editable),
      isSemantics(
        label: 'people',
        value: '2',
        increasedValue: '3',
        decreasedValue: '1',
        isTextField: true,
        isFocusable: true,
        isEnabled: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    tester.semantics.increase(find.semantics.byLabel('people'));
    await tester.pump();
    expect(log, [3]);
    semantics.dispose();
  });

  testWidgets('out of use: no stop, no steps', (tester) async {
    final log = <double?>[];
    await tester.pumpWidget(_app(_Counted(log: log, enabled: false)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.widget<EditableText>(_editable).focusNode.hasFocus, isFalse);
    await tester.tap(_more, warnIfMissed: false);
    await tester.pump();
    expect(log, isEmpty);
  });

  testWidgets('in a stretching column its node is its row, not the column', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      neumorphicApp(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_Counted(log: [])],
        ),
      ),
    );
    final row = tester.getRect(find.byType(Row).first);
    final node = tester.getSemantics(_editable).rect;
    expect(node.width, lessThanOrEqualTo(row.width + 1));
    semantics.dispose();
  });
}
