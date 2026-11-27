// Every overlay Fluent 2 opens stays whole and readable on a phone, as
// ui_core_test's DesignOverlayCheck reads it: a select's list, a combobox's
// and a multi-select's suggestions, a date picker's calendar, a time picker's
// list, a menu and a popover, each opened from an anchor high, in the middle
// and low on a 390 x 844 screen; and each dialog and sheet.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart' show loadFluent2TestFonts;

Widget _app(
  Widget page, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => WidgetsApp(
  color: const Color(0xFF000000),
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: Fluent2Host(brightness: brightness, child: child!),
  ),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => page,
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _environments = [
  Fluent2Option('staging', 'Staging'),
  Fluent2Option('canary', 'Canary'),
  Fluent2Option('production', 'Production'),
];

Future<void> _type(WidgetTester tester) async {
  await tester.tap(find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), 'a');
}

// What each anchor is, how a reader opens it, and words only its overlay
// shows.
final _anchored =
    <String, (Widget, Future<void> Function(WidgetTester), String)>{
      'select': (
        Fluent2Select<String>(
          semanticLabel: 'Environment',
          options: _environments,
          value: 'production',
          onChanged: (_) {},
        ),
        (tester) => tester.tap(find.byType(Fluent2Select<String>)),
        'Canary',
      ),
      'combobox': (
        Fluent2Combobox<String>(
          semanticLabel: 'Environment',
          options: _environments,
          value: null,
          onChanged: (_) {},
        ),
        _type,
        'Canary',
      ),
      'multi-select': (
        Fluent2MultiSelect<String>(
          semanticLabel: 'Environments',
          options: _environments,
          selected: const [],
          onChanged: (_) {},
        ),
        _type,
        'Canary',
      ),
      'date picker': (
        Fluent2DatePicker(
          semanticLabel: 'Freeze from',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
        (tester) => tester.tap(find.byType(Fluent2DatePicker)),
        '27',
      ),
      'time picker': (
        Fluent2TimePicker(
          semanticLabel: 'Starts',
          value: const Fluent2Time(9, 0),
          onChanged: (_) {},
        ),
        (tester) => tester.tap(find.byType(Fluent2TimePicker)),
        '10:30',
      ),
      'menu': (
        Builder(
          builder: (context) => Fluent2Button(
            'More',
            onPressed: () => showFluent2Menu<String>(
              context,
              anchor: context,
              items: const [
                Fluent2MenuItem('rename', 'Rename'),
                Fluent2MenuItem('share', 'Share'),
                Fluent2MenuItem('delete', 'Delete', danger: true),
              ],
            ),
          ),
        ),
        (tester) => tester.tap(find.text('More')),
        'Rename',
      ),
      'popover': (
        Fluent2Popover(
          semanticLabel: 'Filters',
          trigger: (context, toggle) =>
              Fluent2Button('Filters', onPressed: toggle),
          content: const Text('Only failed runs'),
        ),
        (tester) => tester.tap(find.text('Filters')),
        'Only failed runs',
      ),
    };

// Each dialog and sheet, opened from a button.
final _modal = <String, void Function(BuildContext)>{
  'dialog': (context) => showFluent2Dialog<void>(
    context,
    builder: (context) => Fluent2Dialog(
      title: 'Save changes?',
      message: 'The form has edits that are not saved.',
      actions: [
        Fluent2Button('Cancel', onPressed: () {}),
        Fluent2Button("Don't save", onPressed: () {}),
        Fluent2Button(
          'Save',
          appearance: Fluent2ButtonAppearance.primary,
          onPressed: () {},
        ),
      ],
    ),
  ),
  'side sheet': (context) => showFluent2Sheet<void>(
    context,
    builder: (context, close) => const Text('Run 1482 failed at test'),
  ),
  'bottom sheet': (context) => showFluent2BottomSheet<void>(
    context,
    builder: (context) => const Fluent2BottomSheet(
      title: 'Share',
      child: Text('Anyone on the team can open the link'),
    ),
  ),
  'action sheet': (context) => showFluent2ActionSheet<String>(
    context,
    title: 'Run 1482',
    actions: const [
      Fluent2ActionSheetAction('rerun', 'Rerun'),
      Fluent2ActionSheetAction('delete', 'Delete logs', destructive: true),
    ],
  ),
  'date picker': (context) => showFluent2DatePicker(
    context,
    value: DateTime(2026, 11, 20),
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
  ),
  'time picker': (context) =>
      showFluent2TimePicker(context, value: const Fluent2Time(9, 0)),
};

void main() {
  setUpAll(loadFluent2TestFonts);

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
        expect(
          find.textContaining(shown),
          findsWidgets,
          reason: '$kind opened',
        );
        final report = const DesignOverlayCheck(look: 'fluent2')
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
                  Fluent2Button('Open', onPressed: () => show(context)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final report = const DesignOverlayCheck(look: 'fluent2')
          .check(tester.element(find.byType(Navigator)));
      expect(report.problems, isEmpty);
    });
  }
}
