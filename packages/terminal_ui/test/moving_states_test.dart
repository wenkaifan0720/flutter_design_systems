// The moments between states, held still and kept as pictures: a press and
// a keyboard focus halfway in, a sheet and a dialog halfway up, a range's
// preview ending on its end's own shape, a disclosure and a tree halfway
// open. A terminal has no hover, so there is none here. Recorded with the
// other goldens (`flutter test --update-goldens --tags goldens`, on macOS).
import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';
import 'moving_states.dart';

final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Widget _host(Brightness b, Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => TermTheme(
    data: TermThemeData.of(b),
    child: TermToaster(child: child!),
  ),
  home: Builder(
    builder: (context) =>
        ColoredBox(color: TermTheme.of(context).background, child: home),
  ),
);

MovingStateLook _golden(String name) =>
    (moment) => expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        'goldens/moving/$name ${moment.replaceAll(' ', '-')}.png',
      ),
    );

/// Parts a press and a focus are held halfway into.
final Map<String, Widget> _parts = {
  'button': TermButton(label: 'cancel', onPressed: () {}),
  'filled-button': TermButton.filled(label: 'deploy', onPressed: () {}),
  'destructive-button': TermButton(
    label: 'delete',
    isDestructiveAction: true,
    onPressed: () {},
  ),
  'chip': TermChip(label: 'failed', selected: false, onSelected: (_) {}),
  'checkbox': TermCheckbox(
    value: false,
    onChanged: (_) {},
    label: 'run the tests first',
  ),
  'switch': TermSwitch(
    value: false,
    onChanged: (_) {},
    label: 'deploy on merge',
  ),
  'list-tile': SizedBox(
    width: 324,
    child: TermListTile(
      title: const Text('#1482 fix the cache key'),
      subtitle: const Text('main · 2m 14s'),
      onTap: () {},
    ),
  ),
  'text-field': const SizedBox(
    width: 288,
    child: TermTextField(labelText: 'branch', hintText: 'main'),
  ),
};

void main() {
  setUpAll(loadFaces);

  for (final b in Brightness.values) {
    for (final MapEntry(key: name, value: part) in _parts.entries) {
      testWidgets('$name, ${b.name}: a press and a focus halfway in', (
        tester,
      ) async {
        if (!_recorded) return;
        _size(tester, const Size(400, 120));
        await tester.pumpWidget(_host(b, Center(child: part)));
        await tester.pump();
        final target = find.byType(RawButton).evaluate().isNotEmpty
            ? find.byType(RawButton).first
            : find.byType(EditableText).first;
        if (name != 'text-field') {
          await atPressHalfway(tester, target, _golden('$name-${b.name}'));
        }
        await atFocus(tester, target, _golden('$name-${b.name}'));
        expect(tester.takeException(), isNull);
      }, tags: const ['goldens']);
    }
  }

  testWidgets('a side sheet, an action sheet and a dialog halfway up', (
    tester,
  ) async {
    if (!_recorded) return;
    late BuildContext page;
    Widget home() => Builder(
      builder: (context) {
        page = context;
        return const Padding(padding: EdgeInsets.all(18), child: Text('runs'));
      },
    );

    _size(tester, const Size(1440, 900));
    await tester.pumpWidget(_host(Brightness.dark, home()));
    await atSheetHalfway(
      tester,
      () => unawaited(
        showTermSideSheet<void>(
          context: page,
          builder: (_) => const TermSideSheet(
            title: 'run #1482',
            child: Text('fix the cache key'),
          ),
        ),
      ),
      _golden('side-sheet-1440'),
    );
    Navigator.of(page).pop();
    await tester.pumpAndSettle();

    _size(tester, const Size(390, 844));
    await tester.pump();
    await atSheetHalfway(
      tester,
      () => unawaited(
        showTermActionSheet<int>(
          context: page,
          title: 'run #1482',
          actions: const [
            TermSheetAction(label: 'rerun', value: 1),
            TermSheetAction(
              label: 'delete logs',
              value: 2,
              isDestructiveAction: true,
            ),
          ],
        ),
      ),
      _golden('action-sheet-390'),
    );
    Navigator.of(page).pop();
    await tester.pumpAndSettle();

    _size(tester, const Size(768, 1024));
    await tester.pump();
    await atSheetHalfway(
      tester,
      () => unawaited(
        showTermDialog<void>(
          context: page,
          builder: (_) => const TermDialog(
            title: 'delete project',
            content: Text('its runs and logs go with it'),
          ),
        ),
      ),
      _golden('dialog-768'),
    );
    Navigator.of(page).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, tags: const ['goldens']);

  testWidgets("a range's preview ends on its end's shape", (tester) async {
    if (!_recorded) return;
    _size(tester, const Size(400, 320));
    final calendar = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      mode: RawCalendarMode.range,
      currentDate: DateTime(2026, 11, 14),
      initialMonth: DateTime(2026, 11),
    );
    addTearDown(calendar.dispose);
    for (final b in Brightness.values) {
      await tester.pumpWidget(
        _host(b, Center(child: TermCalendar(controller: calendar))),
      );
      calendar
        ..clear()
        ..select(DateTime(2026, 11, 9));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('13').first));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _golden('range-preview-${b.name}')('waiting for its end');
      await mouse.removePointer();
      calendar.select(DateTime(2026, 11, 13));
      await tester.pump(const Duration(milliseconds: 300));
      await _golden('range-preview-${b.name}')('chosen');
    }
    expect(tester.takeException(), isNull);
  }, tags: const ['goldens']);

  for (final row in const ['Disclosure', 'TreeView']) {
    testWidgets('a ${row.toLowerCase()} halfway open', (tester) async {
      if (!_recorded) return;
      _size(tester, const Size(390, 520));
      await tester.pumpWidget(
        _host(
          Brightness.dark,
          SingleChildScrollView(
            padding: const EdgeInsets.all(9),
            child: Builder(builder: termInventory.entryFor(row)!.builder!),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Close what is open and hold it halfway shut, then open it again
      // and hold it halfway open.
      for (final moment in const ['halfway shut', 'halfway open']) {
        await tester.tap(find.byType(RawButton).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        await _golden(row.toLowerCase())(moment);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(tester.takeException(), isNull);
    }, tags: const ['goldens']);
  }
}
