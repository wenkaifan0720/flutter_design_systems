// ui_core_test 0.3.0's checks on Brutal: each picker, select, combobox, menu,
// dialog and sheet opened on a phone with its anchor high, in the middle and
// low; every gallery page at text scale 2; a dialog's actions at 320 and 390
// wide, at 1x and 2x; and each text field's help, then its error, read on
// the field itself.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/admit/admit.dart';

void _view(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, {double scale = 1}) => MaterialApp(
  home: BrutalTheme(
    data: BrutalThemeData.light(),
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: home,
      ),
    ),
  ),
);

String _said(DesignAlignmentReport report) =>
    report.problems.map((p) => '\n  - $p').join();

final _day = DateTime(2026, 11, 20);

void main() {
  group('DesignOverlayCheck on a phone', () {
    // Each anchor, and how it opens: a tap on its foot (a field's box under
    // its label), or typing for the combobox.
    final anchors = <String, (Widget, Future<void> Function(WidgetTester))>{
      'date picker': (
        BrutalDatePicker(
          labelText: 'Due',
          value: _day,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
        (tester) => tester.tapAt(
          tester.getRect(find.byType(BrutalDatePicker)).bottomCenter -
              const Offset(0, 16),
        ),
      ),
      'date range picker': (
        BrutalDateRangePicker(
          labelText: 'Stay',
          value: BrutalDateRange(
            start: _day,
            end: _day.add(const Duration(days: 4)),
          ),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
        (tester) => tester.tapAt(
          tester.getRect(find.byType(BrutalDateRangePicker)).bottomCenter -
              const Offset(0, 16),
        ),
      ),
      'select': (
        BrutalSelect<int>(
          labelText: 'Row',
          value: 3,
          items: [
            for (var i = 1; i <= 12; i++)
              BrutalSelectItem(value: i, label: 'Row $i'),
          ],
          onChanged: (_) {},
        ),
        (tester) => tester.tapAt(
          tester.getRect(find.byType(BrutalSelect<int>)).bottomCenter -
              const Offset(0, 16),
        ),
      ),
      'combobox': (
        BrutalCombobox<String>(
          labelText: 'Venue',
          options: [for (var i = 1; i <= 12; i++) 'Hall $i'],
          displayStringForOption: (v) => v,
        ),
        (tester) async {
          await tester.showKeyboard(find.byType(EditableText));
          await tester.enterText(find.byType(EditableText), 'Hall');
        },
      ),
      'menu': (
        BrutalMenu(
          items: [
            for (final words in ['Edit', 'Share', 'Move', 'Delete'])
              BrutalMenuItem(label: words, onPressed: () {}),
          ],
          builder: (context, toggle, open) =>
              BrutalButton('More', onPressed: toggle),
        ),
        (tester) => tester.tap(find.text('More')),
      ),
    };
    for (final MapEntry(key: kind, value: (anchor, open)) in anchors.entries) {
      for (final (where, top) in const [
        ('high', 24.0),
        ('in the middle', 380.0),
        ('low', 700.0),
      ]) {
        testWidgets('a $kind $where', (tester) async {
          _view(tester);
          await tester.pumpWidget(
            _app(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: top),
                    anchor,
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await open(tester);
          await tester.pumpAndSettle();
          final report = const DesignOverlayCheck(look: 'brutal')
              .check(tester.element(find.byWidget(anchor)));
          expect(report.problems, isEmpty, reason: _said(report));
        });
      }
    }

    for (final (kind, show) in <(String, Future<void> Function(BuildContext))>[
      (
        'dialog',
        (context) => showBrutalDialog<void>(
          context: context,
          builder: (context) => BrutalDialog(
            title: 'Unsaved changes',
            content: const Text('Keep the edits to this task?'),
            actions: [
              BrutalDialogAction(label: 'Cancel', onPressed: () {}),
              BrutalDialogAction(
                label: 'Save changes',
                isDefaultAction: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      (
        'bottom sheet',
        (context) => showBrutalBottomSheet<void>(
          context: context,
          builder: (context) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Tickets for Friday'),
          ),
        ),
      ),
    ]) {
      testWidgets('a $kind', (tester) async {
        _view(tester);
        late BuildContext page;
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        );
        unawaited(show(page));
        await tester.pumpAndSettle();
        final report = const DesignOverlayCheck(look: 'brutal').check(page);
        expect(report.problems, isEmpty, reason: _said(report));
      });
    }
  });

  testWidgets('DesignOverflowCheck: every gallery page on a phone at text '
      'scale 2', (tester) async {
    // Tall enough that every section is laid out.
    _view(tester, height: 12000);
    final problems = <String>[];
    for (final (i, page) in galleryPages.indexed) {
      await tester.pumpWidget(
        AdmitApp(
          key: ValueKey(page.id),
          textScale: 2,
          parts: [
            for (final p in galleryPages) (title: p.title, build: p.build),
          ],
          initialPart: i,
        ),
      );
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      final report = const DesignOverflowCheck(look: 'brutal')
          .check(tester.element(find.byType(AdmitApp)));
      problems.addAll(report.problems.map((p) => '${page.id}: $p'));
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  group('DesignDialogActionsCheck', () {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('a dialog at ${width.round()}, ${scale}x', (tester) async {
          _view(tester, width: width);
          await tester.pumpWidget(
            _app(
              scale: scale,
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BrutalDialog(
                    title: 'Unsaved changes',
                    content: const Text('Keep the edits to this task?'),
                    actions: [
                      BrutalDialogAction(label: 'Cancel', onPressed: () {}),
                      BrutalDialogAction(
                        label: 'Discard changes',
                        isDestructiveAction: true,
                        onPressed: () {},
                      ),
                      BrutalDialogAction(
                        label: 'Save the changes',
                        isDefaultAction: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final report = const DesignDialogActionsCheck(
            look: 'brutal',
            actions: ['Cancel', 'Discard changes', 'Save the changes'],
          ).check(tester.element(find.byType(BrutalDialog)));
          expect(report.problems, isEmpty, reason: _said(report));
        });
      }
    }
  });

  // The text fields: a select's and a date picker's words are read on their
  // buttons, which the check (of a text field's words) does not take.
  group('DesignFieldWordsCheck', () {
    const help = 'We never share it', error = 'Enter a valid email';
    final fields = <String, Widget Function(String? help, String? error)>{
      'text field': (h, e) =>
          BrutalTextField(labelText: 'Email', helperText: h, errorText: e),
      'password field': (h, e) => BrutalPasswordField(
        labelText: 'Password',
        helperText: h,
        errorText: e,
      ),
      'input group': (h, e) =>
          BrutalInputGroup(labelText: 'Email', helperText: h, errorText: e),
      'code field': (h, e) =>
          BrutalCodeField(labelText: 'Code', helperText: h, errorText: e),
      'combobox': (h, e) => BrutalCombobox<String>(
        labelText: 'Venue',
        options: const ['Hall 1'],
        displayStringForOption: (v) => v,
        helperText: h,
        errorText: e,
      ),
      // Its tags present: the entry still carries the field's words.
      'tag input with tags': (h, e) => BrutalTagInput<String>(
        labelText: 'Kinds',
        values: const ['Gig'],
        options: const ['Gig', 'Talk'],
        displayStringForOption: (v) => v,
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
      'tag input': (h, e) => BrutalTagInput<String>(
        labelText: 'Kinds',
        values: const [],
        options: const ['Gig'],
        displayStringForOption: (v) => v,
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    };
    for (final MapEntry(key: kind, value: field) in fields.entries) {
      for (final (shows, h, e) in const [
        ('help', help, null),
        ('error', null, error),
      ]) {
        testWidgets('a $kind with its $shows', (tester) async {
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            _app(Center(child: SizedBox(width: 360, child: field(h, e)))),
          );
          await tester.pump(const Duration(seconds: 1));
          final report = DesignFieldWordsCheck(
            look: 'brutal',
            words: [?h, ?e],
          ).check(tester.element(find.byType(Center).first));
          expect(report.problems, isEmpty, reason: _said(report));
          semantics.dispose();
        });
      }
    }
  });
}
