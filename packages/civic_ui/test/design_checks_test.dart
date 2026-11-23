// ui_core_test 0.3.0's checks on Civic: each picker, select, combobox, menu,
// dialog and sheet opened on a phone with its anchor high, in the middle and
// low; every gallery page on a phone at text scale 2; a dialog's actions at
// 320 and 390 wide (and on a desk), at 1x and 2x; and each text field's
// help, then its error, read on the field itself.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';

const _root = ValueKey('checked');

Widget _app(Widget home) => kitApp(
  brightness: Brightness.light,
  home: KeyedSubtree(key: _root, child: home),
);

String _said(DesignAlignmentReport report) =>
    report.problems.map((p) => '\n  - $p').join();

BuildContext _page(WidgetTester tester) => tester.element(find.byKey(_root));

final _day = DateTime(2026, 11, 20);

void main() {
  group('DesignOverlayCheck on a phone', () {
    // Each anchor, and how it opens: a press on its control, or typing for
    // the combobox.
    final anchors = <String, (Widget, Future<void> Function(WidgetTester))>{
      'date picker': (
        CivicDatePicker(
          labelText: 'Start date',
          value: _day,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
        (tester) => tester.tap(
          find
              .descendant(
                of: find.byType(CivicDatePicker),
                matching: find.byType(CivicButton),
              )
              .first,
        ),
      ),
      'select': (
        CivicSelect<int>(
          labelText: 'Zone',
          value: 3,
          items: [
            for (var i = 1; i <= 12; i++)
              CivicSelectItem(value: i, label: 'Zone $i'),
          ],
          onChanged: (_) {},
        ),
        (tester) => tester.tapAt(
          tester.getRect(find.byType(CivicSelect<int>)).bottomCenter -
              const Offset(0, 16),
        ),
      ),
      'combobox': (
        CivicCombobox<String>(
          labelText: 'Street',
          options: [for (var i = 1; i <= 12; i++) 'Mill Lane $i'],
        ),
        (tester) async {
          await tester.showKeyboard(find.byType(EditableText));
          await tester.enterText(find.byType(EditableText), 'Mill');
        },
      ),
      'menu': (
        CivicMenu<String>(
          items: const [
            CivicMenuItem(value: 'print', label: 'Print this page'),
            CivicMenuItem(value: 'copy', label: 'Copy the link'),
            CivicMenuItem(value: 'save', label: 'Save for later'),
            CivicMenuItem(value: 'withdraw', label: 'Withdraw application'),
          ],
          onSelected: (_) {},
          builder: (context, anchor) => CivicButton.secondary(
            onPressed: anchor.toggle,
            child: const Text('Actions'),
          ),
        ),
        (tester) => tester.tap(find.text('Actions')),
      ),
    };
    for (final MapEntry(key: kind, value: (anchor, open)) in anchors.entries) {
      for (final (where, top) in const [
        ('high', 24.0),
        ('in the middle', 380.0),
        ('low', 700.0),
      ]) {
        testWidgets('a $kind $where', (tester) async {
          await showScreen(
            tester,
            _app(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: top),
                    anchor,
                  ],
                ),
              ),
            ),
            width: 390,
            height: 844,
          );
          await open(tester);
          await tester.pumpAndSettle();
          final report = const DesignOverlayCheck(look: 'civic')
              .check(_page(tester));
          expect(report.problems, isEmpty, reason: _said(report));
        });
      }
    }

    for (final (kind, show) in <(String, Future<void> Function(BuildContext))>[
      (
        'dialog',
        (context) => showCivicDialog<void>(
          context: context,
          builder: (context) => CivicDialog(
            title: 'Cancel your application?',
            content: const Text('Your answers so far will be deleted.'),
            actions: [
              CivicButton(onPressed: () {}, child: const Text('Cancel it')),
              CivicButton.secondary(
                onPressed: () {},
                child: const Text('Keep it'),
              ),
            ],
          ),
        ),
      ),
      (
        'bottom sheet',
        (context) => showCivicBottomSheet<void>(
          context: context,
          builder: (context) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Permits for Mill Lane'),
          ),
        ),
      ),
    ]) {
      testWidgets('a $kind', (tester) async {
        await showScreen(
          tester,
          _app(const SizedBox.expand()),
          width: 390,
          height: 844,
        );
        unawaited(show(_page(tester)));
        await tester.pumpAndSettle();
        final report = const DesignOverlayCheck(look: 'civic')
            .check(_page(tester));
        expect(report.problems, isEmpty, reason: _said(report));
      });
    }
  });

  for (final page in galleryPages) {
    testWidgets('DesignOverflowCheck: ${page.id} on a phone at text scale 2', (
      tester,
    ) async {
      // Tall enough that every section is laid out.
      await showScreen(
        tester,
        KeyedSubtree(key: _root, child: page.build(Brightness.light)),
        width: 390,
        height: 12000,
        text: 2,
      );
      final report = const DesignOverflowCheck(look: 'civic')
          .check(_page(tester));
      expect(report.problems, isEmpty, reason: _said(report));
    });
  }

  group('DesignDialogActionsCheck', () {
    for (final width in [320.0, 390.0, 1440.0]) {
      for (final text in [1.0, 2.0]) {
        testWidgets('a dialog at ${width.round()}, ${text}x', (tester) async {
          await showScreen(
            tester,
            _app(
              CivicDialog(
                title: 'Unsaved changes',
                content: const Text('Keep the changes to this permit?'),
                // Civic's order: the one that does what the title asks
                // first.
                actions: [
                  CivicButton(
                    onPressed: () {},
                    child: const Text('Save the changes'),
                  ),
                  CivicButton(
                    isDestructiveAction: true,
                    onPressed: () {},
                    child: const Text('Discard changes'),
                  ),
                  CivicButton.secondary(
                    onPressed: () {},
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            width: width,
            height: 900,
            text: text,
          );
          final report = const DesignDialogActionsCheck(
            look: 'civic',
            actions: ['Cancel', 'Discard changes', 'Save the changes'],
          ).check(_page(tester));
          expect(report.problems, isEmpty, reason: _said(report));
        });
      }
    }
  });

  // The text fields: a select's and a date picker's words are read on their
  // buttons, which the check (of a text field's words) does not take; a
  // number field's on its stepper's node (ui_core's RawNumberField), over
  // its entry's own.
  group('DesignFieldWordsCheck', () {
    const help = 'For example, AB12 CDE', error = 'Enter your registration';
    final fields = <String, Widget Function(String? help, String? error)>{
      'text field': (h, e) => CivicTextField(
        labelText: 'Registration',
        helperText: h,
        errorText: e,
      ),
      'password field': (h, e) => CivicPasswordField(
        labelText: 'Password',
        helperText: h,
        errorText: e,
      ),
      'code field': (h, e) =>
          CivicCodeField(labelText: 'Code', helperText: h, errorText: e),
      'combobox': (h, e) => CivicCombobox<String>(
        labelText: 'Street',
        options: const ['Mill Lane'],
        helperText: h,
        errorText: e,
      ),
      // Its choices present: the entry still carries the field's words.
      'multi-select with choices': (h, e) => CivicMultiSelect<String>(
        labelText: 'Zones',
        values: const ['Zone 1'],
        options: const ['Zone 1', 'Zone 2'],
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
      'multi-select': (h, e) => CivicMultiSelect<String>(
        labelText: 'Zones',
        values: const [],
        options: const ['Zone 1'],
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
          await showScreen(
            tester,
            _app(Center(child: SizedBox(width: 360, child: field(h, e)))),
            width: 390,
            height: 844,
          );
          final report = DesignFieldWordsCheck(
            look: 'civic',
            words: [?h, ?e],
          ).check(_page(tester));
          expect(report.problems, isEmpty, reason: _said(report));
          semantics.dispose();
        });
      }
    }
  });
}
