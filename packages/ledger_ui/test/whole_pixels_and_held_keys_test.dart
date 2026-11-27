// What Ledger raises and presses shows plainly: a sheet or a dialog centred
// on a desk stands on whole pixels (its hairlines print crisp, never as two
// rows of half ink), and a held key filled with the page's ink shows the
// press, past its hover, by day and by night, with or without a pointer.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

const Key _frame = ValueKey<String>('frame');

void _size(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          LedgerHost(brightness: brightness, child: page!),
      home: RepaintBoundary(
        key: _frame,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    );

bool _whole(double v) => v == v.roundToDouble();

/// The frame's pixel at [at].
Future<List<int>> _pixel(WidgetTester t, Offset at) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_frame));
  final width = boundary.size.width.round();
  final ByteData bytes = (await t.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!;
  }))!;
  final i = (at.dy.round() * width + at.dx.round()) * 4;
  return [bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2)];
}

int _apart(List<int> a, List<int> b) =>
    [for (var c = 0; c < 3; c++) (a[c] - b[c]).abs()]
        .reduce((p, q) => p > q ? p : q);

void main() {
  // An odd remainder of room either way: a plain centre lands on .5.
  const desk = Size(1441, 901);

  testWidgets('a sheet centred on a desk stands on whole pixels', (t) async {
    _size(t, desk);
    await t.pumpWidget(
      _host(
        Builder(
          builder: (context) => LedgerButton(
            'Filter',
            onPressed: () => LedgerSheet.show<void>(
              context,
              title: 'Filter tasks',
              builder: (context) => const [
                LedgerTextField(labelText: 'Project'),
                LedgerTextField(labelText: 'Assignee'),
              ],
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Filter'));
    await t.pumpAndSettle();
    final card = t.getRect(find.byType(LedgerSheetShell));
    expect(_whole(card.left) && _whole(card.top), isTrue, reason: '$card');
  });

  testWidgets('a dialog centred on a desk stands on whole pixels', (t) async {
    _size(t, desk);
    await t.pumpWidget(
      _host(
        Builder(
          builder: (context) => LedgerButton(
            'Delete',
            onPressed: () => LedgerDialog.show(
              context,
              title: 'Delete this entry?',
              body: 'It leaves your records for good.',
              type: LedgerDialogType.destructive,
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    final card = t.getRect(find.byType(LedgerDialog));
    expect(_whole(card.left) && _whole(card.top), isTrue, reason: '$card');
  });

  for (final (face, key) in [
    ('ink', (VoidCallback press) => LedgerButton.ink('Stop', onPressed: press)),
    (
      'filled',
      (VoidCallback press) =>
          LedgerButton.filled('Add entry', onPressed: press),
    ),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('a held $face key shows the press, past its hover '
          '(${brightness.name})', (t) async {
        _size(t, const Size(390, 844));
        await t.pumpWidget(
          _host(
            Padding(padding: const EdgeInsets.all(24), child: key(() {})),
            brightness: brightness,
          ),
        );
        final rect = t.getRect(find.byType(LedgerButton));
        // The fill beside the words.
        final fill = Offset(rect.left + rect.width * .08, rect.center.dy);
        final rest = await _pixel(t, fill);

        // A finger: no hover first.
        final finger = await t.startGesture(rect.center);
        await t.pumpAndSettle();
        final held = await _pixel(t, fill);
        await finger.up();
        await t.pumpAndSettle();
        expect(
          _apart(held, rest),
          greaterThanOrEqualTo(16),
          reason: 'rest $rest, held $held',
        );

        // A pointer: the hover, then the press past it.
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(rect.center);
        await t.pumpAndSettle();
        final hovered = await _pixel(t, fill);
        await mouse.down(rect.center);
        await t.pumpAndSettle();
        final pressed = await _pixel(t, fill);
        await mouse.up();
        await t.pumpAndSettle();
        expect(
          _apart(pressed, hovered),
          greaterThanOrEqualTo(12),
          reason: 'rest $rest, hover $hovered, held $pressed',
        );
      });
    }
  }
}
