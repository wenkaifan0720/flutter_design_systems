// Keycap's parts between states, read from the pixels each frame paints, not
// from the widget tree: every move eases toward where it ends and never past it
// (a calm spring, no bounce), shows at least a frame between its ends (a move,
// not a cut), and is at rest within half a second.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

const _frame = ValueKey('frame');

void _none() {}

Widget _host(Brightness brightness, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => KeycapHost(
    brightness: brightness,
    child: RepaintBoundary(key: _frame, child: navigator!),
  ),
  home: KeycapScreen(
    body: Align(
      alignment: Alignment.topCenter,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

/// How far [a] is from [b]: the mean difference per channel, over the
/// whole frame or down one [column] of it (a frame [width] wide). A column
/// of flat colour reads a slide truly: the whole frame does not, where
/// words pass over words.
double _distance(Uint8List a, Uint8List b, {int? column, int width = 390}) {
  var sum = 0;
  var n = 0;
  if (column == null) {
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]).abs();
    }
    n = a.length;
  } else {
    for (var i = column * 4; i < a.length; i += width * 4) {
      for (var k = 0; k < 4; k++) {
        sum += (a[i + k] - b[i + k]).abs();
      }
      n += 4;
    }
  }
  return sum / n;
}

/// Records the frames after [start] and checks the move they show.
///
/// With [part], the part's edge [edge] reads also, frame by frame: it too
/// eases to its rest and never past it.
Future<void> _calm(
  WidgetTester tester,
  String what,
  Future<void> Function() start, {
  int? column,
  Finder? part,
  double Function(Rect rect)? edge,
}) async {
  await start();
  final frames = <Uint8List>[];
  final edges = <double>[];
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    frames.add(await _pixels(tester));
    if (part != null && edge != null && part.evaluate().isNotEmpty) {
      edges.add(edge(tester.getRect(part)));
    }
  }
  await tester.pump(const Duration(seconds: 1));
  final rest = await _pixels(tester);
  if (part != null && edge != null) {
    final end = edge(tester.getRect(part));
    final e = [for (final v in edges) v - end];
    for (var i = 1; i < e.length; i++) {
      expect(
        e[i].abs(),
        lessThanOrEqualTo(e[i - 1].abs() + 0.5),
        reason: "$what's edge went back at frame $i: $e",
      );
      expect(
        e[i] * e.first.sign,
        greaterThan(-0.5),
        reason: "$what's edge passed its rest at frame $i: $e",
      );
    }
    expect(e.last.abs(), lessThan(0.5), reason: '$what still moving: $e');
  }
  final d = [for (final f in frames) _distance(f, rest, column: column)];
  final first = d.first;
  // Every frame nearer the end than the one before (a hair of noise
  // allowed): nothing overshoots and comes back.
  final noise = first * 0.03 + 0.02;
  for (var i = 1; i < d.length; i++) {
    expect(
      d[i],
      lessThanOrEqualTo(d[i - 1] + noise),
      reason: '$what went back at frame $i: $d',
    );
  }
  // Frames between the ends: it moved rather than cut.
  expect(first, greaterThan(0.01), reason: '$what never moved: $d');
  expect(
    d.where((x) => x > 0.01).length,
    greaterThan(1),
    reason: '$what cut straight to its end: $d',
  );
  // At rest within half a second.
  expect(
    d[29],
    lessThanOrEqualTo(first * 0.02 + 0.02),
    reason: '$what still moving at 480 ms: $d',
  );
}

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390, 640)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final brightness in Brightness.values) {
    final by = brightness.name;

    testWidgets('a key goes down and comes up calmly ($by)', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(
          brightness,
          const KeycapButton.accent(onPressed: _none, child: Text('Save')),
        ),
      );
      await tester.pumpAndSettle();
      final at = tester.getCenter(find.text('Save'));
      final finger = await tester.createGesture();
      await _calm(tester, 'the press', () => finger.down(at));
      await _calm(tester, 'the release', () => finger.up());
    });

    testWidgets('a switch slides calmly ($by)', (tester) async {
      _phone(tester);
      var on = false;
      await tester.pumpWidget(
        _host(
          brightness,
          StatefulBuilder(
            builder: (context, set) => KeycapSwitch(
              value: on,
              semanticLabel: 'Sync',
              onChanged: (v) => set(() => on = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _calm(
        tester,
        'the switch',
        () => tester.tap(find.byType(KeycapSwitch)),
      );
    });

    testWidgets('a checkbox latches calmly ($by)', (tester) async {
      _phone(tester);
      var on = false;
      await tester.pumpWidget(
        _host(
          brightness,
          StatefulBuilder(
            builder: (context, set) => KeycapCheckbox(
              value: on,
              semanticLabel: 'Sow the beans',
              onChanged: (v) => set(() => on = v ?? false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _calm(
        tester,
        'the latch',
        () => tester.tap(find.byType(KeycapCheckbox)),
      );
    });

    testWidgets('a segment latches calmly ($by)', (tester) async {
      _phone(tester);
      var shown = 'all';
      await tester.pumpWidget(
        _host(
          brightness,
          StatefulBuilder(
            builder: (context, set) => KeycapSegmentedButton<String>(
              segments: const [
                KeycapSegment(value: 'all', label: 'All'),
                KeycapSegment(value: 'pinned', label: 'Pinned'),
              ],
              selected: {shown},
              onSelectionChanged: (s) => set(() => shown = s.first),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _calm(tester, 'the segment', () => tester.tap(find.text('Pinned')));
    });

    testWidgets('the page dots stretch calmly ($by)', (tester) async {
      _phone(tester);
      var page = 0;
      late StateSetter turn;
      await tester.pumpWidget(
        _host(
          brightness,
          StatefulBuilder(
            builder: (context, set) {
              turn = set;
              return KeycapPageDots(count: 4, index: page);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _calm(tester, 'the dots', () async => turn(() => page = 2));
    });

    testWidgets('a sheet rises and a dialog opens calmly ($by)', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(
          brightness,
          Builder(
            builder: (context) => Column(
              children: [
                KeycapButton(
                  onPressed: () => showKeycapBottomSheet<void>(
                    context: context,
                    title: 'Sort',
                    builder: (_) => const Text('Last edited first'),
                  ),
                  child: const Text('Sheet'),
                ),
                KeycapButton(
                  onPressed: () => showKeycapDialog<void>(
                    context: context,
                    builder: (_) => const KeycapDialog(
                      title: 'Delete this note?',
                      content: Text('It moves to Recently deleted.'),
                    ),
                  ),
                  child: const Text('Dialog'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Down a column at the window's edge: the scrim, then the sheet's
      // flat panel rising through it.
      await _calm(
        tester,
        'the sheet',
        () => tester.tap(find.text('Sheet')),
        column: 4,
        part: find.byType(KeycapSheet),
        edge: (r) => r.top,
      );
      Navigator.of(tester.element(find.text('Last edited first'))).pop();
      await tester.pumpAndSettle();
      await _calm(
        tester,
        'the dialog',
        () => tester.tap(find.text('Dialog')),
        column: 4,
        part: find.byType(KeycapDialog),
        edge: (r) => r.width,
      );
      Navigator.of(tester.element(find.text('Delete this note?'))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('a select\'s menu opens calmly ($by)', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(
          brightness,
          SizedBox(
            width: 280,
            child: KeycapSelect<String>(
              label: 'Sort by',
              value: 'edited',
              onChanged: (_) {},
              items: const [
                KeycapSelectItem(value: 'edited', label: 'Last edited'),
                KeycapSelectItem(value: 'title', label: 'Title'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _calm(
        tester,
        'the menu',
        () => tester.tap(find.text('Last edited')),
      );
    });
  }
}
