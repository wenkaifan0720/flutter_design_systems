// The rating on ui_core's RawRating: one control and one tab stop, set by a tap, a drag, the keys or a screen reader,
// a hover showing the score a tap would give; the look's stars keep their targets edge to edge, their faces, a sinking
// star under a finger, and the focus on the star at the score.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

/// A rating that keeps the score it is given, and the scores it reported.
class _Rated extends StatefulWidget {
  const _Rated({required this.log, this.start = 2, this.enabled = true});

  final List<int> log;
  final int start;
  final bool enabled;

  @override
  State<_Rated> createState() => _RatedState();
}

class _RatedState extends State<_Rated> {
  late int _score = widget.start;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: NeumorphicRating(
      label: 'Sleep',
      value: _score.toDouble(),
      enabled: widget.enabled,
      onChanged: (score) {
        widget.log.add(score);
        setState(() => _score = score);
      },
    ),
  );
}

Finder get _stars => find.descendant(
  of: find.byType(NeumorphicRating),
  matching: find.byType(KeyedSubtree),
);

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets(
    'one tab stop: the arrows step it, Home clears it, End and a digit set it',
    (tester) async {
      final log = <int>[];
      var after = 0;
      await tester.pumpWidget(
        neumorphicApp(
          Column(
            children: [
              _Rated(log: log),
              NeumorphicButton('After', onPressed: () => after++),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      // A pump after each key: the rating steps from the score its parent gives it back.
      for (final key in [
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.end,
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.digit4,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }
      expect(log, [3, 2, 1, 5, 0, 4]);
      // The next Tab leaves the rating for the key after it: the stars are not stops of their own.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(after, 1);
      expect(log, [3, 2, 1, 5, 0, 4]);
    },
  );

  testWidgets('right to left, Right steps it down', (tester) async {
    final log = <int>[];
    await tester.pumpWidget(
      neumorphicApp(
        Directionality(
          textDirection: TextDirection.rtl,
          child: _Rated(log: log),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(log, [1]);
  });

  testWidgets('a tap sets its star; a drag sweeps across', (tester) async {
    final log = <int>[];
    await tester.pumpWidget(neumorphicApp(_Rated(log: log)));
    await tester.tap(_stars.at(3));
    await tester.pump();
    expect(log, [4]);
    await tester.dragFrom(
      tester.getCenter(_stars.at(0)),
      tester.getCenter(_stars.at(4)) - tester.getCenter(_stars.at(0)),
    );
    await tester.pump();
    expect(log.last, 5);
    expect(log.skip(1), containsAllInOrder([1, 5]));
  });

  testWidgets('each star keeps a 48 target, edge to edge', (tester) async {
    await tester.pumpWidget(neumorphicApp(const _Rated(log: [])));
    for (var i = 0; i < 5; i++) {
      final box = tester.getRect(_stars.at(i));
      expect(box.width, greaterThanOrEqualTo(48));
      expect(box.height, greaterThanOrEqualTo(48));
      if (i > 0) expect(box.left, tester.getRect(_stars.at(i - 1)).right);
    }
  });

  testWidgets(
    'a hovering pointer shows the score a tap would give, and leaves it as it goes',
    (tester) async {
      await tester.pumpWidget(neumorphicApp(const _Rated(log: [], start: 1)));
      Future<List<int>> rgba() async {
        final image = await tester.runAsync(
          () => captureImage(tester.element(find.byType(NeumorphicRating))),
        );
        final bytes = await tester.runAsync(() => image!.toByteData());
        image!.dispose();
        return bytes!.buffer.asUint8List().toList();
      }

      final idle = await rgba();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_stars.at(3)));
      await tester.pump();
      expect(await rgba(), isNot(idle), reason: 'four stars show lit');
      await mouse.moveTo(const Offset(600, 500));
      await tester.pump();
      expect(await rgba(), idle);
    },
  );

  testWidgets('a screen reader hears one slider and steps it', (tester) async {
    final semantics = tester.ensureSemantics();
    final log = <int>[];
    await tester.pumpWidget(neumorphicApp(_Rated(log: log)));
    final node = tester.getSemantics(find.byType(RawRating));
    expect(
      node,
      isSemantics(
        label: 'Sleep',
        value: '2 of 5',
        increasedValue: '3 of 5',
        decreasedValue: '1 of 5',
        isSlider: true,
        isFocusable: true,
        isEnabled: true,
        isButton: false,
        isSelected: false,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    tester.semantics.increase(find.semantics.byLabel('Sleep'));
    await tester.pump();
    expect(log, [3]);
    semantics.dispose();
  });

  testWidgets('a rating that only shows is a value, not a control', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      neumorphicApp(
        const Align(
          alignment: Alignment.topLeft,
          child: NeumorphicRating(label: 'Average', value: 3.5),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(RawRating)),
      matchesSemantics(label: 'Average', value: '3.5 of 5'),
    );
    semantics.dispose();
  });

  testWidgets('out of use, it takes no focus and no press', (tester) async {
    final log = <int>[];
    await tester.pumpWidget(neumorphicApp(_Rated(log: log, enabled: false)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.tap(_stars.at(4), warnIfMissed: false);
    await tester.pump();
    expect(log, isEmpty);
  });

  testWidgets(
    'in a stretching column it is as wide as its stars: the space past them takes no tap',
    (tester) async {
      final log = <int>[];
      await tester.pumpWidget(
        neumorphicApp(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeumorphicRating(label: 'Sleep', value: 2, onChanged: log.add),
            ],
          ),
        ),
      );
      final stars = tester.getRect(find.byType(RawRating));
      expect(stars.width, lessThan(400), reason: 'the stars, not the column');
      await tester.tapAt(Offset(stars.right + 120, stars.center.dy));
      await tester.pump();
      expect(log, isEmpty);
    },
  );
}
