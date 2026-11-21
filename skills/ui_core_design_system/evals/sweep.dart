// The scoring sweep: every part a look's inventory carries, alone on a
// screen, under every condition a reader brings, through ui_core_test's
// checks. A scorer copies this file into the candidate's example/test/
// folder and calls [sweepInventory] from a test (see README.md).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core/inventory.dart';
import 'package:ui_core/ui_core.dart' show DesignInput, RawWidgetsLocalizations;
import 'package:ui_core_test/ui_core_test.dart';

/// Puts [child] under the look's theme for [brightness]: what the
/// candidate's app puts in `MaterialApp.builder`.
typedef LookHost = Widget Function(
  BuildContext context,
  Widget child,
  Brightness brightness,
);

/// One reader's conditions.
class SweepCondition {
  /// A condition at [width], in [brightness], [direction] and [textScale].
  const SweepCondition(
    this.width,
    this.brightness,
    this.direction,
    this.textScale,
  );

  /// The screen's width in logical pixels (the height is 900).
  final double width;

  /// Day or night.
  final Brightness brightness;

  /// Reading direction.
  final TextDirection direction;

  /// Text scale.
  final double textScale;

  /// Whether a finger reaches the screen (a phone's width).
  bool get touch => width < 600;

  @override
  String toString() =>
      '${width.round()} ${brightness.name} ${direction.name} ${textScale}x';
}

/// Every combination of 390 and 1440 wide, day and night, left to right and
/// right to left, and 1x and 2x text.
final List<SweepCondition> sweepConditions = [
  for (final width in [390.0, 1440.0])
    for (final brightness in Brightness.values)
      for (final direction in TextDirection.values)
        for (final textScale in [1.0, 2.0])
          SweepCondition(width, brightness, direction, textScale),
];

/// Pumps each present entry of [inventory] alone under each of [conditions],
/// under [host], and returns one line per problem found: a layout exception
/// (an overflow), or a ui_core_test check's finding. Empty when every part
/// holds everywhere.
Future<List<String>> sweepInventory(
  WidgetTester tester, {
  required DesignInventory inventory,
  required LookHost host,
  List<SweepCondition>? conditions,
}) async {
  final look = inventory.look;
  final found = <String>[];
  addTearDown(tester.view.reset);
  for (final condition in conditions ?? sweepConditions) {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(condition.width, 900) * 2;
    for (final entry in inventory.entries.where((e) => e.isPresent)) {
      final at = '${entry.row} at $condition';
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(at),
          localizationsDelegates: const [RawWidgetsLocalizations.delegate],
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: condition.textScale,
            maxScaleFactor: condition.textScale,
            child: Directionality(
              textDirection: condition.direction,
              child: host(context, child!, condition.brightness),
            ),
          ),
          home: Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              key: key,
              padding: const EdgeInsets.all(24),
              child: Builder(builder: entry.builder!),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final thrown = tester.takeException();
      if (thrown != null) {
        found.add('$at: threw ${'$thrown'.split('\n').first}');
        continue;
      }
      final screen = key.currentContext!;
      final reports = [
        DesignCheckableCheck(look: look).check(screen),
        DesignTextFieldNameCheck(look: look).check(screen),
        DesignFieldSemanticsCheck(look: look).check(screen),
        DesignTapTargetCheck(
          look: look,
          input: condition.touch ? DesignInput.touch : DesignInput.pointer,
        ).check(screen),
        if (!condition.touch) DesignCursorCheck(look: look).check(screen),
        DesignClipCheck(look: look).check(screen),
        DesignWordBreakCheck(look: look).check(screen),
      ];
      for (final report in reports) {
        found.addAll(report.problems.map((p) => '$at: $p'));
      }
    }
  }
  return found;
}
