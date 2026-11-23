// Every overlay Studio opens stays whole and readable on a phone, as
// ui_core_test's DesignOverlayCheck reads it: a select's list, a combobox's
// and a tag input's suggestions, a date picker's and a date range picker's
// calendar, a menu and a popover, each opened from an anchor high, in the
// middle and low on a 390 x 844 screen; and each dialog and sheet.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

// The gallery's app frame; a test reads it from the example.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart' show kitApp;

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _shows = ['Morning edition', 'Field notes', 'Late session'];

void _none() {}

Future<void> _type(WidgetTester tester) async {
  await tester.tap(find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), 'e');
}

// What each anchor is, how a reader opens it, and words only its overlay
// shows.
final _anchored =
    <String, (Widget, Future<void> Function(WidgetTester), String)>{
      'select': (
        StudioSelect<String>(
          labelText: 'Show',
          value: _shows.first,
          items: [for (final s in _shows) StudioSelectItem(value: s, label: s)],
          onChanged: (_) {},
        ),
        (tester) => tester.tap(find.byType(StudioSelect<String>)),
        'Field notes',
      ),
      'combobox': (
        StudioCombobox<String>(
          labelText: 'Show',
          options: _shows,
          labelOf: (s) => s,
          onSelected: (_) {},
        ),
        _type,
        'Field notes',
      ),
      'tag input': (
        StudioTagInput<String>(
          labelText: 'Shows',
          values: const [],
          options: _shows,
          labelOf: (s) => s,
          onChanged: (_) {},
        ),
        _type,
        'Field notes',
      ),
      'date picker': (
        StudioDatePicker(
          labelText: 'Release date',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
        (tester) => tester.tap(find.byType(StudioDatePicker)),
        '27',
      ),
      'date range picker': (
        StudioDateRangePicker(
          labelText: 'Recording days',
          value: null,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          currentDate: DateTime(2026, 11, 20),
          onChanged: (_) {},
        ),
        (tester) => tester.tap(find.byType(StudioDateRangePicker)),
        '27',
      ),
      'menu': (
        StudioMenu(
          items: const [
            StudioMenuItem(label: 'Rename', onPressed: _none),
            StudioMenuItem(label: 'Duplicate', onPressed: _none),
            StudioMenuItem(
              label: 'Delete',
              onPressed: _none,
              isDestructiveAction: true,
            ),
          ],
          builder: (context, toggle, open) =>
              StudioButton('More', onPressed: toggle),
        ),
        (tester) => tester.tap(find.text('More')),
        'Rename',
      ),
      'popover': (
        StudioPopover(
          builder: (context, toggle, open) =>
              StudioButton('Speed', onPressed: toggle),
          content: (context, close) => const Text('Playback at one and a half'),
        ),
        (tester) => tester.tap(find.text('Speed')),
        'Playback at one and a half',
      ),
    };

// Each dialog and sheet, opened from a key.
final _modal = <String, void Function(BuildContext)>{
  'dialog': (context) => showStudioDialog<void>(
    context: context,
    builder: (context) => const StudioDialog(
      title: 'Discard this take?',
      content: Text('The 4 minutes you recorded will be gone.'),
      actions: [
        StudioButton.text('Cancel', onPressed: _none),
        StudioButton('Keep', onPressed: _none),
        StudioButton.lit(
          'Discard',
          isDestructiveAction: true,
          onPressed: _none,
        ),
      ],
    ),
  ),
  'bottom sheet': (context) => showStudioBottomSheet<void>(
    context: context,
    title: 'Export',
    builder: (context) => const Text('MP3, 128 kbps'),
  ),
  'side sheet': (context) => showStudioSideSheet<void>(
    context: context,
    title: 'Filters',
    builder: (context) => const Text('Only finished takes'),
  ),
  'action sheet': (context) => showStudioActionSheet<String>(
    context: context,
    title: 'This take',
    actions: const [
      StudioSheetAction(label: 'Keep', value: 'keep'),
      StudioSheetAction(
        label: 'Discard',
        value: 'discard',
        isDestructiveAction: true,
      ),
    ],
  ),
};

void main() {
  setUpAll(studioLoadFonts);

  for (final MapEntry(key: kind, value: (anchor, open, shown))
      in _anchored.entries) {
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
          kitApp(
            brightness: Brightness.light,
            home: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment(0, y), child: anchor),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await open(tester);
        await tester.pumpAndSettle();
        expect(
          find.textContaining(shown),
          findsWidgets,
          reason: '$kind opened',
        );
        final report = const DesignOverlayCheck(look: 'studio')
            .check(tester.element(find.byType(Navigator).first));
        expect(report.problems, isEmpty);
      });
    }
  }

  for (final MapEntry(key: kind, value: show) in _modal.entries) {
    testWidgets('a $kind on a phone stays whole', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        kitApp(
          brightness: Brightness.light,
          home: Center(
            child: Builder(
              builder: (context) =>
                  StudioButton('Open', onPressed: () => show(context)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final report = const DesignOverlayCheck(look: 'studio')
          .check(tester.element(find.byType(Navigator).first));
      expect(report.problems, isEmpty);
    });
  }
}
