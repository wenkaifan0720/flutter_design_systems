// A field's message grows open as it fades in and closes as it fades out,
// so what stands under the field moves with it and never jumps; under
// Reduce Motion it cuts.
import 'dart:math' as math;

import 'package:appliance_ui/appliance_ui.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _below = Key('below');

Future<ValueNotifier<String?>> _show(
  WidgetTester tester, {
  bool still = false,
}) async {
  final error = ValueNotifier<String?>(null);
  addTearDown(error.dispose);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: ApplianceHost(brightness: Brightness.light, child: app!),
      ),
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 360,
          child: ValueListenableBuilder<String?>(
            valueListenable: error,
            builder: (context, e, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ApplianceTextField(labelText: 'Title', errorText: e),
                const SizedBox(key: _below, height: 10),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return error;
}

double _top(WidgetTester tester) => tester.getTopLeft(find.byKey(_below)).dy;

// Where what stands under the field is, frame by frame, until it settles.
Future<List<double>> _frames(WidgetTester tester) async {
  final tops = <double>[];
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    tops.add(_top(tester));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pumpAndSettle();
  return tops;
}

// It passes between [from] and [to], never more than half the way in a
// frame.
void _moves(List<double> tops, double from, double to) {
  final between = tops.where(
    (y) => y > math.min(from, to) && y < math.max(from, to),
  );
  expect(between, isNotEmpty);
  var last = from;
  for (final y in tops) {
    expect((y - last).abs(), lessThan((to - from).abs() / 2));
    last = y;
  }
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets("a text field's error grows in and closes, never jumps", (
    tester,
  ) async {
    final error = await _show(tester);
    final rest = _top(tester);
    error.value = 'Give it a title';
    final opening = await _frames(tester);
    final open = _top(tester);
    expect(open, greaterThan(rest));
    _moves(opening, rest, open);
    error.value = null;
    final closing = await _frames(tester);
    expect(_top(tester), rest);
    _moves(closing, open, rest);
  });

  testWidgets("under Reduce Motion a text field's error cuts", (tester) async {
    final error = await _show(tester, still: true);
    final rest = _top(tester);
    error.value = 'Give it a title';
    await tester.pump();
    final open = _top(tester);
    expect(open, greaterThan(rest));
    await tester.pumpAndSettle();
    expect(_top(tester), open);
  });
}
