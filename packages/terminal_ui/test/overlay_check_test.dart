// Every overlay Terminal opens stays whole and readable on a phone, as
// ui_core_test's DesignOverlayCheck reads it: a select's list, a date field's
// calendar, a combobox's and a tag input's suggestions, a menu, a menu bar's
// menu, a context menu and a popover, each opened from an anchor high, in
// the middle and low on a 390 x 844 screen; and each dialog and sheet.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'faces.dart';

Widget _app(Widget page) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => TermTheme(data: TermThemeData.dark(), child: app!),
  home: page,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _branches = ['main', 'feat/main-menu', 'fix/retry', 'release/2.4'];

// What each anchor is, and how a reader opens what it holds.
final _anchored = <String, (Widget, Future<void> Function(WidgetTester))>{
  'select': (
    TermSelect<String>(
      labelText: 'environment',
      value: 'production',
      items: const [
        TermSelectItem(value: 'staging', label: 'staging'),
        TermSelectItem(value: 'canary', label: 'canary'),
        TermSelectItem(value: 'production', label: 'production'),
      ],
      onChanged: (_) {},
    ),
    (tester) => tester.tap(find.byType(TermSelect<String>)),
  ),
  'date': (
    TermDatePicker(
      labelText: 'freeze from',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    (tester) => tester.tap(find.byType(TermDatePicker)),
  ),
  'date range': (
    TermDateRangePicker(
      labelText: 'window',
      value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    (tester) => tester.tap(find.byType(TermDateRangePicker)),
  ),
  'combobox': (
    TermCombobox<String>(
      labelText: 'branch',
      options: _branches,
      onSelected: (_) {},
    ),
    (tester) async {
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'e');
    },
  ),
  'tag input': (
    TermTagInput<String>(
      labelText: 'branches',
      values: const [],
      options: _branches,
      onChanged: (_) {},
    ),
    (tester) async {
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'e');
    },
  ),
  'menu': (
    TermMenu(
      anchorBuilder: (context, anchor) => TermIconButton(
        glyph: '⋯',
        semanticLabel: 'more',
        onPressed: anchor.toggle,
      ),
      items: [
        for (final label in ['rerun', 'copy link', 'download logs', 'cancel'])
          TermMenuItem(label: label, onPressed: () {}),
      ],
    ),
    (tester) => tester.tap(find.byType(TermIconButton)),
  ),
  'menu bar': (
    TermMenuBar(
      menus: [
        RawMenuEntry(
          label: 'run',
          children: [
            for (final label in ['rerun', 'cancel', 'copy link'])
              RawMenuEntry(label: label, onPressed: () {}),
          ],
        ),
      ],
    ),
    (tester) => tester.tap(find.text('run')),
  ),
  'context menu': (
    TermContextMenu(
      menuChildren: [
        for (final label in ['rerun', 'copy link', 'download logs'])
          RawMenuEntry(label: label, onPressed: () {}),
      ],
      child: const Text('run #1482'),
    ),
    (tester) => tester.longPress(find.text('run #1482')),
  ),
  'popover': (
    TermPopover(
      anchorBuilder: (context, anchor) =>
          TermButton(label: 'filters', onPressed: anchor.toggle),
      builder: (context) => const Text('only failed runs'),
    ),
    (tester) => tester.tap(find.byType(TermButton)),
  ),
};

// Each dialog and sheet, opened from a key.
final _modal = <String, void Function(BuildContext)>{
  'dialog': (context) => showTermDialog<void>(
    context: context,
    builder: (context) => TermDialog(
      title: 'unsaved changes',
      content: const Text('the form has edits that are not saved.'),
      actions: [
        TermButton(label: 'cancel', onPressed: () {}),
        TermButton(label: 'discard', onPressed: () {}),
        TermButton.filled(label: 'save changes', onPressed: () {}),
      ],
    ),
  ),
  'confirm': (context) => showTermConfirmDialog(
    context: context,
    title: 'delete logs',
    message: "run #1482's logs go for good",
    confirmLabel: 'delete',
    isDestructiveAction: true,
  ),
  'sheet': (context) => showTermSheet<void>(
    context: context,
    builder: (context) => TermSheet(
      title: 'share run #1482',
      actions: [TermButton.filled(label: 'copy link', onPressed: () {})],
      child: const Text('a link anyone on the team can open'),
    ),
  ),
  'side sheet': (context) => showTermSideSheet<void>(
    context: context,
    builder: (context) => const TermSideSheet(
      title: 'run #1482',
      child: Text('failed at test, 3 of 5 steps'),
    ),
  ),
  'action sheet': (context) => showTermActionSheet<String>(
    context: context,
    title: 'run #1482',
    actions: const [
      TermSheetAction(label: 'rerun', value: 'rerun'),
      TermSheetAction(
        label: 'delete logs',
        value: 'delete',
        isDestructiveAction: true,
      ),
    ],
  ),
};

void main() {
  setUpAll(loadFaces);

  for (final MapEntry(key: kind, value: (anchor, open)) in _anchored.entries) {
    for (final (where, y) in const [
      ('high', -0.9),
      ('middle', 0.0),
      ('low', 0.9),
    ]) {
      testWidgets('a $kind opened $where on a phone stays whole', (
        tester,
      ) async {
        _phone(tester);
        await tester.pumpWidget(
          _app(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment(0, y), child: anchor),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await open(tester);
        await tester.pumpAndSettle();
        expect(find.byType(TermPane), findsWidgets, reason: '$kind opened');
        final report = const DesignOverlayCheck(look: 'terminal')
            .check(tester.element(find.byType(Navigator)));
        expect(report.problems, isEmpty);
      });
    }
  }

  for (final MapEntry(key: kind, value: show) in _modal.entries) {
    testWidgets('a $kind on a phone stays whole', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          Center(
            child: Builder(
              builder: (context) =>
                  TermButton(label: 'open', onPressed: () => show(context)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final report = const DesignOverlayCheck(look: 'terminal')
          .check(tester.element(find.byType(Navigator)));
      expect(report.problems, isEmpty);
    });
  }
}
