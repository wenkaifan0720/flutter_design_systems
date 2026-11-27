// Android's system back, as Minimal's overlays take it: whatever is open
// over a page (a menu, a select's list, a bottom sheet, a side sheet, a
// dialog, an action sheet) closes first, and the page stays; the next back
// pops the page. The platform sends back as a pop-route message, which a
// MaterialApp hands its navigator: a menu, a sheet or a dialog is a route on
// it, so it is the one popped. A combobox's or a multi-select's list, a split
// button's menu and a popover are no routes (they stand in the page's
// overlay, on their field or button): ui_core's surface holds the page's pop
// while it shows, and closes instead.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// A page one push deep, with a control for each overlay.
Widget _app() => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: MinimalButton(
          'Page one',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const _PageTwo())),
        ),
      ),
    ),
  ),
);

class _PageTwo extends StatelessWidget {
  const _PageTwo();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const Text('Page two'),
          MinimalMenu.button(
            Icons.more_horiz,
            semanticLabel: 'Actions',
            items: [
              MinimalMenuItem('Rename', onPressed: () {}),
              MinimalMenuItem('Archive', onPressed: () {}),
            ],
          ),
          SizedBox(
            width: 280,
            child: MinimalSelect<String>(
              labelText: 'Repeats',
              value: 'Every day',
              options: const [
                MinimalSelectOption('Every day', 'Every day'),
                MinimalSelectOption('Weekdays', 'Weekdays'),
              ],
              onChanged: (_) {},
            ),
          ),
          Builder(
            builder: (context) => MinimalButton(
              'Bottom sheet',
              onPressed: () => showMinimalBottomSheet<void>(
                context,
                title: 'New habit',
                builder: (_) => const Text('In the bottom sheet'),
              ),
            ),
          ),
          Builder(
            builder: (context) => MinimalButton(
              'Side sheet',
              onPressed: () => showMinimalSheet<void>(
                context,
                title: 'Order',
                builder: (_) => const Text('In the side sheet'),
              ),
            ),
          ),
          Builder(
            builder: (context) => MinimalButton(
              'Dialog',
              onPressed: () => showMinimalDialog<bool>(
                context,
                builder: (_) => const MinimalDialog(
                  title: 'Archive habit?',
                  confirmLabel: 'Archive',
                  cancelLabel: 'Keep',
                ),
              ),
            ),
          ),
          Builder(
            builder: (context) => MinimalButton(
              'Action sheet',
              onPressed: () => showMinimalActionSheet(
                context,
                title: 'Habit',
                actions: [
                  MinimalActionSheetAction('Duplicate', onPressed: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The platform's back button.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'system back closes what is open over a page first, then pops the page',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Page one'));
      await tester.pumpAndSettle();
      expect(find.text('Page two'), findsOneWidget);

      // Each overlay: the control that opens it, and what shows only while
      // it is open.
      final overlays = <(String, Finder, Finder)>[
        (
          'menu',
          find.bySemanticsLabel(RegExp('^Actions')),
          find.text('Rename'),
        ),
        ('select', find.text('Repeats').first, find.text('Weekdays')),
        (
          'bottom sheet',
          find.text('Bottom sheet'),
          find.text('In the bottom sheet'),
        ),
        ('side sheet', find.text('Side sheet'), find.text('In the side sheet')),
        ('dialog', find.text('Dialog'), find.text('Archive habit?')),
        ('action sheet', find.text('Action sheet'), find.text('Duplicate')),
      ];
      for (final (name, open, shown) in overlays) {
        await tester.tap(open.first);
        await tester.pumpAndSettle();
        expect(shown, findsOneWidget, reason: 'the $name opens');
        await _back(tester);
        expect(shown, findsNothing, reason: 'back closes the $name');
        expect(
          find.text('Page two'),
          findsOneWidget,
          reason: 'and leaves the page under the $name',
        );
      }

      await _back(tester);
      expect(find.text('Page two'), findsNothing, reason: 'back pops the page');
      expect(find.text('Page one'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  // A combobox's or a multi-select's list, a split button's menu and a
  // popover: each its own test, from a fresh page, so a back held after
  // its surface closed shows as that surface's.
  final overlays = <(String, Finder Function(), Finder Function())>[
    (
      'combobox',
      () => find.byType(EditableText).first,
      () => find.text('Lyon'),
    ),
    (
      'multi-select',
      () => find.byType(EditableText).last,
      () => find.text('Green'),
    ),
    (
      'split button',
      () => find.bySemanticsLabel('Save options'),
      () => find.text('Save a copy'),
    ),
    ('popover', () => find.text('Filters'), () => find.text('In the popover')),
  ];
  for (final (name, open, shown) in overlays) {
    testWidgets(
      'system back closes the $name first: it is no route of its own (the '
      "page's overlay); the next back pops the page",
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, navigator) => MinimalHost(
              light: MinimalThemeData.preset('standard', Brightness.light),
              dark: MinimalThemeData.preset('standard', Brightness.dark),
              brightness: Brightness.light,
              child: navigator!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: MinimalButton(
                  'Page one',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              const Text('Page two'),
                              SizedBox(
                                width: 280,
                                child: MinimalCombobox<String>(
                                  labelText: 'City',
                                  options: const ['Lyon', 'London'],
                                  onSelected: (_) {},
                                ),
                              ),
                              SizedBox(
                                width: 280,
                                child: MinimalMultiSelect<String>(
                                  labelText: 'Colours',
                                  values: const [],
                                  options: const ['Red', 'Green'],
                                  onChanged: (_) {},
                                ),
                              ),
                              MinimalSplitButton(
                                'Save',
                                menuLabel: 'Save options',
                                onPressed: () {},
                                actions: [
                                  MinimalMenuItem(
                                    'Save a copy',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              MinimalPopover(
                                anchor: (context, toggle, open) =>
                                    MinimalButton('Filters', onPressed: toggle),
                                content: (context, close) =>
                                    const Text('In the popover'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Page one'));
        await tester.pumpAndSettle();
        await tester.tap(open().first);
        await tester.pumpAndSettle();
        expect(shown(), findsOneWidget, reason: 'the $name opens');
        await _back(tester);
        expect(shown(), findsNothing, reason: 'back closes the $name');
        expect(find.text('Page two'), findsOneWidget, reason: 'not the page');
        await _back(tester);
        expect(
          find.text('Page two'),
          findsNothing,
          reason: 'the next back pops the page',
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}
