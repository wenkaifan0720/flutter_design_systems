// The haptics table: the platform's own by default, swapped or silenced by
// a scope, and the moments ui_core plays it at (a slider's tick while
// dragged; the wheel and the rating have their own tests).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

/// The platform messages HapticFeedback sends, for the rest of the test.
List<String> _platformHaptics(WidgetTester tester) {
  final sent = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method.startsWith('HapticFeedback')) {
        sent.add('${call.method}(${call.arguments ?? ''})');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return sent;
}

/// A table that records each moment it is asked to play.
RawHaptics _recording(List<String> log) => RawHaptics(
  selectionChanged: () => log.add('selection'),
  longPress: () => log.add('long press'),
  thresholdCrossed: () => log.add('threshold'),
);

/// A value handle with ten divisions, dragged by its parent to [value].
Widget _handle(double value, {bool dragging = true, int? divisions = 10}) =>
    Center(
      child: RawValueHandle(
        value: value,
        divisions: divisions,
        dragging: dragging,
        onChanged: (_) {},
        builder: (context, states) => const SizedBox(width: 20, height: 20),
      ),
    );

void main() {
  test('the default table is the platform\'s, and silent is none', () {
    const table = RawHaptics();
    expect(table.selectionChanged, HapticFeedback.selectionClick);
    expect(table.thresholdCrossed, HapticFeedback.lightImpact);
    expect(table.longPress, isNotNull);
    const silent = RawHaptics.silent();
    expect(silent.selectionChanged, isNull);
    expect(silent.longPress, isNull);
    expect(silent.thresholdCrossed, isNull);
    expect(silent, const RawHaptics.silent());
    expect(silent.hashCode, const RawHaptics.silent().hashCode);
    expect(silent == table, isFalse);
  });

  testWidgets('each default plays the platform\'s haptic', (tester) async {
    final sent = _platformHaptics(tester);
    const table = RawHaptics();
    table.selectionChanged!();
    table.thresholdCrossed!();
    await tester.pump();
    expect(sent, [
      'HapticFeedback.vibrate(HapticFeedbackType.selectionClick)',
      'HapticFeedback.vibrate(HapticFeedbackType.lightImpact)',
    ]);
  });

  testWidgets('a long press plays the platform\'s own', (tester) async {
    final sent = _platformHaptics(tester);
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      const RawHaptics().longPress!();
    }
    debugDefaultTargetPlatformOverride = null;
    await tester.pump();
    expect(sent, [
      'HapticFeedback.vibrate()', // Android
      'HapticFeedback.vibrate()', // Fuchsia
      'HapticFeedback.vibrate(HapticFeedbackType.mediumImpact)', // iOS
    ], reason: 'Linux, macOS and Windows play nothing');
  });

  testWidgets('a scope swaps the table, and tells who read it', (tester) async {
    final log = <String>[];
    var builds = 0;
    late RawHaptics read;
    Widget app(RawHaptics haptics) => RawHapticsScope(
      haptics: haptics,
      child: Builder(
        builder: (context) {
          builds++;
          read = RawHaptics.of(context);
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          read = RawHaptics.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(read, const RawHaptics(), reason: 'no scope: the platform\'s');

    final recording = _recording(log);
    await tester.pumpWidget(app(recording));
    expect(read, same(recording));
    read.longPress!();
    expect(log, ['long press']);

    final before = builds;
    await tester.pumpWidget(app(recording));
    expect(builds, before + 1, reason: 'its parent built it');
    await tester.pumpWidget(app(const RawHaptics.silent()));
    expect(read.selectionChanged, isNull);

    final scope = tester.widget<RawHapticsScope>(find.byType(RawHapticsScope));
    expect(scope.toString(), contains('RawHapticsScope'));
    expect(
      scope.toDiagnosticsNode().getProperties().map((p) => p.name),
      contains('haptics'),
    );
  });

  group('a slider\'s tick', () {
    testWidgets('plays once per division a dragged thumb crosses', (
      tester,
    ) async {
      final log = <String>[];
      Widget at(double v, {bool dragging = true, int? divisions = 10}) =>
          RawHapticsScope(
            haptics: _recording(log),
            child: _handle(v, dragging: dragging, divisions: divisions),
          );
      await tester.pumpWidget(harness(at(0.5)));
      await tester.pumpWidget(harness(at(0.52)));
      expect(log, isEmpty, reason: 'still on the 0.5 division');
      await tester.pumpWidget(harness(at(0.61)));
      expect(log, ['selection']);
      await tester.pumpWidget(harness(at(0.8)));
      expect(log, ['selection', 'selection']);
      await tester.pumpWidget(harness(at(0.3, dragging: false)));
      expect(log, hasLength(2), reason: 'a key or the parent set it');
      await tester.pumpWidget(harness(at(0.9, divisions: null)));
      expect(log, hasLength(2), reason: 'no divisions, no ticks');
    });

    testWidgets('a range slider\'s thumbs tick as they are dragged', (
      tester,
    ) async {
      final log = <String>[];
      var values = const RawRangeValues(20, 80);
      await tester.pumpWidget(
        harness(
          RawHapticsScope(
            haptics: _recording(log),
            child: StatefulBuilder(
              builder: (context, setState) => Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 444,
                  child: RawRangeSlider(
                    values: values,
                    max: 100,
                    divisions: 10,
                    onChanged: (next) => setState(() => values = next),
                    trackBuilder: (context, track) => const SizedBox(height: 4),
                    thumbBuilder: (context, index, states) => SizedBox(
                      key: ValueKey('thumb $index'),
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('thumb 0'))),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(values.start, greaterThan(20));
      expect(log, isNotEmpty);
      expect(log.every((m) => m == 'selection'), isTrue);
      expect(
        log.length,
        ((values.start - 20) / 10).round(),
        reason: 'one tick per division crossed',
      );
    });
  });
}
