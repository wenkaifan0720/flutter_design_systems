// ui_core_test 0.3.0's checks on Comic: each select, combobox and menu opened
// on a phone with its anchor high, in the middle and low, and each dialog,
// sheet and date picker raised there; every gallery page at text scale 2; a
// dialog's actions at 320 and 390 wide, at 1x and 2x; and each text field's
// help, then its error, read on the field itself.
import 'dart:async';

import 'package:comic_ui/comic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart';
import 'support.dart';

void _view(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _scaled(Widget child, double scale) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child,
  ),
);

String _said(DesignAlignmentReport report) =>
    report.problems.map((p) => '\n  - $p').join();

final _day = DateTime(2026, 11, 20);

void main() {
  setUpAll(loadComicFonts);

  group('DesignOverlayCheck on a phone', () {
    // Each anchor, and how it opens: a tap on its face, or typing for the
    // combobox.
    final anchors = <String, (Widget, Future<void> Function(WidgetTester))>{
      'select': (
        ComicSelect<int>(
          labelText: 'Row',
          value: 3,
          options: [
            for (var i = 1; i <= 12; i++) ComicSelectOption(i, 'Row $i'),
          ],
          onChanged: (_) {},
        ),
        (tester) => tester.tap(find.text('Row 3')),
      ),
      'combobox': (
        ComicCombobox<String>(
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
        ComicMenuAnchor<String>(
          items: [
            for (final words in ['Edit', 'Share', 'Move', 'Delete'])
              ComicMenuItem(words, words),
          ],
          onSelected: (_) {},
          builder: (context, open) => ComicButton('More', onPressed: open),
        ),
        (tester) => tester.tap(find.byType(ComicButton)),
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
            comicApp(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
          final report = const DesignOverlayCheck(look: 'Comic')
              .check(tester.element(find.byWidget(anchor)));
          expect(report.problems, isEmpty, reason: _said(report));
        });
      }
    }

    for (final (kind, show) in <(String, Future<void> Function(BuildContext))>[
      (
        'dialog',
        (context) => showComicDialog<void>(
          context,
          builder: (context) => ComicDialog(
            title: 'Unsaved changes',
            message: 'Keep the edits to this task?',
            actions: [
              ComicButton('Cancel', onPressed: () {}),
              ComicButton.filled('Save changes', onPressed: () {}),
            ],
          ),
        ),
      ),
      (
        'bottom sheet',
        (context) => showComicBottomSheet<void>(
          context,
          builder: (context) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Tickets for Friday'),
          ),
        ),
      ),
      (
        'date picker',
        (context) => showComicDatePicker(
          context,
          value: _day,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
        ),
      ),
      (
        'date range picker',
        (context) => showComicDateRangePicker(
          context,
          value: RawDateRange(_day, _day.add(const Duration(days: 4))),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
        ),
      ),
    ]) {
      testWidgets('a $kind', (tester) async {
        _view(tester);
        late BuildContext page;
        await tester.pumpWidget(
          comicApp(
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
        final report = const DesignOverlayCheck(look: 'Comic').check(page);
        expect(report.problems, isEmpty, reason: _said(report));
      });
    }
  });

  group('DesignOverflowCheck at text scale 2 on a phone', () {
    for (final page in galleryPages) {
      testWidgets('the ${page.id} page', (tester) async {
        // Tall enough that every section is laid out.
        _view(tester, height: 12000);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final key = ValueKey(page.id);
        await tester.pumpWidget(
          KeyedSubtree(key: key, child: page.build(Brightness.light)),
        );
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        final report = const DesignOverflowCheck(look: 'Comic')
            .check(tester.element(find.byKey(key)));
        expect(report.problems, isEmpty, reason: _said(report));
      });
    }
  });

  group('DesignDialogActionsCheck', () {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('a dialog at ${width.round()}, ${scale}x', (tester) async {
          _view(tester, width: width);
          await tester.pumpWidget(
            comicApp(
              width: width,
              _scaled(
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ComicDialog(
                      title: 'Unsaved changes',
                      message: 'Keep the edits to this task?',
                      actions: [
                        ComicButton('Cancel', onPressed: () {}),
                        ComicButton('Discard changes', onPressed: () {}),
                        ComicButton.filled(
                          'Save the changes',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                scale,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final report = const DesignDialogActionsCheck(
            look: 'Comic',
            actions: ['Cancel', 'Discard changes', 'Save the changes'],
          ).check(tester.element(find.byType(ComicDialog)));
          expect(report.problems, isEmpty, reason: _said(report));
        });
      }
    }
  });

  // The text fields: a select's words are read on its button, which the check
  // (of a text field's words) does not take; a combobox shows help alone.
  group('DesignFieldWordsCheck', () {
    const help = 'We never share it', error = 'Enter a valid email';
    final fields =
        <String, (Widget Function(String? help, String? error), bool)>{
          'text field': (
            (h, e) =>
                ComicTextField(labelText: 'Email', helperText: h, errorText: e),
            true,
          ),
          'password field': (
            (h, e) => ComicPasswordField(
              labelText: 'Password',
              helperText: h,
              errorText: e,
            ),
            true,
          ),
          'input group': (
            (h, e) => ComicInputGroup(
              labelText: 'Email',
              helperText: h,
              errorText: e,
            ),
            true,
          ),
          'combobox': (
            (h, e) => ComicCombobox<String>(
              labelText: 'Venue',
              options: const ['Hall 1'],
              displayStringForOption: (v) => v,
              helperText: h,
            ),
            false,
          ),
          'form field': (
            (h, e) => ComicFormField(
              'Email',
              helperText: h,
              errorText: e,
              child: const ComicTextField(hintText: 'you@example.com'),
            ),
            true,
          ),
          // Its tags present: the entry still carries the field's words.
          'multi-select with tags': (
            (h, e) => ComicMultiSelect<String>(
              labelText: 'Kinds',
              values: const ['Gig'],
              options: const ['Gig', 'Talk'],
              displayStringForOption: (v) => v,
              onChanged: (_) {},
              helperText: h,
              errorText: e,
            ),
            true,
          ),
          'multi-select': (
            (h, e) => ComicMultiSelect<String>(
              labelText: 'Kinds',
              values: const [],
              options: const ['Gig'],
              displayStringForOption: (v) => v,
              onChanged: (_) {},
              helperText: h,
              errorText: e,
            ),
            true,
          ),
        };
    for (final MapEntry(key: kind, value: (field, errs)) in fields.entries) {
      for (final (shows, h, e) in [
        ('help', help, null),
        if (errs) ('error', null, error),
      ]) {
        testWidgets('a $kind with its $shows', (tester) async {
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            comicApp(Center(child: SizedBox(width: 360, child: field(h, e)))),
          );
          await tester.pump(const Duration(seconds: 1));
          final report = DesignFieldWordsCheck(
            look: 'Comic',
            words: [?h, ?e],
          ).check(tester.element(find.byType(Center).first));
          expect(report.problems, isEmpty, reason: _said(report));
          semantics.dispose();
        });
      }
    }
  });
}
