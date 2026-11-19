// A check row is a checkbox and its words as one target and one spoken
// control: a press on its words latches it, a screen reader hears one
// checkbox named by them, and keyboard focus lights the key's own edge.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

final _frame = GlobalKey();

Future<void> _show(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 800 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child: RepaintBoundary(
          key: _frame,
          child: Builder(
            builder: (context) => ColoredBox(
              color: StudioTheme.of(context).colors.panel,
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Row extends StatefulWidget {
  const _Row({this.enabled = true});

  final bool enabled;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  var done = false;

  @override
  Widget build(BuildContext context) => StudioCheckRow(
    label: 'Send the invoice',
    note: 'Due Friday',
    value: done,
    onChanged: widget.enabled ? (v) => setState(() => done = v) : null,
  );
}

Future<(Uint8List, int)> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (data!.buffer.asUint8List(), image.width);
    } finally {
      image.dispose();
    }
  }))!;
}

double _luminance(Uint8List p, int i) {
  double c(int v) {
    final x = v / 255;
    return x <= 0.04045 ? x / 12.92 : math.pow((x + 0.055) / 1.055, 2.4) * 1.0;
  }

  return 0.2126 * c(p[i]) + 0.7152 * c(p[i + 1]) + 0.0722 * c(p[i + 2]);
}

bool _checked(WidgetTester tester) =>
    tester.widget<StudioCheckRow>(find.byType(StudioCheckRow)).value;

void main() {
  setUpAll(studioLoadFonts);

  testWidgets('a press on its words or its key latches it', (tester) async {
    await _show(tester, const _Row());
    await tester.tap(find.text('Send the invoice'));
    await tester.pumpAndSettle();
    expect(_checked(tester), isTrue);
    await tester.tap(find.text('Due Friday'));
    await tester.pumpAndSettle();
    expect(_checked(tester), isFalse);
    final row = tester.getRect(find.byType(StudioCheckRow));
    await tester.tapAt(row.centerLeft + const Offset(12, 0));
    await tester.pumpAndSettle();
    expect(_checked(tester), isTrue);
    // A finger finds the whole row: at least the key's height.
    expect(row.height, greaterThanOrEqualTo(StudioMetrics.controlHeight));
  });

  testWidgets('a screen reader hears one checkbox named by its words', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(tester, const _Row());
    expect(
      find.bySemanticsLabel('Send the invoice, Due Friday'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byType(StudioCheckRow)),
      isSemantics(
        label: 'Send the invoice, Due Friday',
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('space latches the focused row and focus lights the key', (
    tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await _show(tester, const _Row());
    final (before, width) = await _pixels(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final (after, _) = await _pixels(tester);
    // The key's edge lights at 3:1 over a 2 px perimeter, and the words
    // stay as they were.
    final origin = tester.getTopLeft(find.byKey(_frame));
    final key = tester
        .getRect(
          find.descendant(
            of: find.byType(StudioCheckRow),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is SizedBox &&
                  w.width == StudioCheckbox.size &&
                  w.height == StudioCheckbox.size,
            ),
          ),
        )
        .shift(-origin);
    final words = tester.getRect(find.text('Send the invoice')).shift(-origin);
    final edge = key.inflate(StudioMetrics.focusWidth + 0.5);
    var lit = 0, inWords = 0;
    for (var i = 0; i + 3 < before.length; i += 4) {
      final at = Offset((i ~/ 4) % width / 2, (i ~/ 4) ~/ width / 2);
      final a = _luminance(before, i), b = _luminance(after, i);
      final ratio = (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
      if (ratio < 3) continue;
      if (edge.contains(at)) lit++;
      if (words.contains(at)) inWords++;
    }
    expect(lit, greaterThanOrEqualTo(2 * 4 * StudioCheckbox.size * 4 * 0.8));
    expect(inWords, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_checked(tester), isTrue);
  });

  testWidgets('without onChanged it stands disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(tester, const _Row(enabled: false));
    await tester.tap(find.text('Send the invoice'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(_checked(tester), isFalse);
    expect(
      tester.getSemantics(find.byType(StudioCheckRow)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    semantics.dispose();
  });
}
