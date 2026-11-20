// The system back on Android: it closes what is raised over a page first, then pops
// the page under Frosted's own page motion. A sheet, a dialog, a menu and a
// select's list are routes, which the navigator pops; a popover and a
// combobox's list are ui_core's, which closes them itself (fec8131445): the
// popover giving the focus back to its control, the list keeping it in the
// field. Frosted holds no back of its own. (The iOS edge back-swipe under
// that motion: page_motion_test.)
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _home = Key('home');

Widget _app() => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => FrostedHost(child: child!),
  home: Builder(
    builder: (context) => ColoredBox(
      key: _home,
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const _Detail())),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

class _Detail extends StatefulWidget {
  const _Detail();

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  String? _room = 's';
  final _filter = FocusNode(debugLabel: 'Filter');

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFEEEEEE),
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Detail'),
            SizedBox(
              width: 320,
              child: FrostedSelect<String>(
                label: 'Room',
                value: _room,
                onChanged: (v) => setState(() => _room = v),
                options: const [
                  FrostedSelectOption('k', 'Kitchen'),
                  FrostedSelectOption('s', 'Study'),
                ],
              ),
            ),
            const SizedBox(
              width: 320,
              child: FrostedCombobox<String>(
                label: 'City',
                options: ['Lisbon', 'Madrid'],
              ),
            ),
            FrostedPopover(
              builder: (context, controller, _) => FrostedButton.glass(
                'Filter',
                focusNode: _filter,
                onPressed: controller.open,
              ),
              content: const Text('Only unread'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the system back closes a sheet, a dialog, a menu and a select\'s list '
    'before the page, then pops the page',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final page = tester.element(find.text('Detail'));

      unawaited(
        FrostedSheet.show<void>(
          page,
          title: 'Filters',
          builder: (_) => [const Text('Sheet body')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsOneWidget);
      await _back(tester);
      expect(find.text('Sheet body'), findsNothing, reason: 'the sheet first');
      expect(find.text('Detail'), findsOneWidget);

      unawaited(FrostedDialog.show(page, title: 'Delete this note?'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this note?'), findsOneWidget);
      await _back(tester);
      expect(find.text('Delete this note?'), findsNothing);
      expect(find.text('Detail'), findsOneWidget);

      unawaited(
        FrostedMenu.show<String>(
          page,
          anchor: tester.element(find.text('Detail')),
          items: const [
            FrostedMenuItem('a', 'Archive'),
            FrostedMenuItem('d', 'Delete'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
      await _back(tester);
      expect(find.text('Archive'), findsNothing);
      expect(find.text('Detail'), findsOneWidget);

      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();
      expect(find.text('Kitchen'), findsOneWidget, reason: 'the list is open');
      await _back(tester);
      expect(find.text('Kitchen'), findsNothing, reason: 'the list first');
      expect(find.text('Study'), findsOneWidget, reason: 'nothing chosen');
      expect(find.text('Detail'), findsOneWidget);

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(
        find.text('Madrid'),
        findsOneWidget,
        reason: "the combobox's list",
      );
      await _back(tester);
      expect(find.text('Madrid'), findsNothing, reason: 'the list first');
      expect(find.text('Detail'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
        reason: 'the focus stays in the field',
      );

      // Opened from its control by a key, so the focus has a control to go
      // back to (a tap leaves it where it was).
      final detail = tester.state<_DetailState>(find.byType(_Detail));
      detail._filter.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Only unread'), findsOneWidget, reason: 'the popover');
      await _back(tester);
      expect(
        find.text('Only unread'),
        findsNothing,
        reason: 'the popover first',
      );
      expect(find.text('Detail'), findsOneWidget);
      expect(detail._filter.hasFocus, isTrue, reason: 'back to its control');

      await _back(tester);
      expect(find.text('Detail'), findsNothing, reason: 'then the page');
      expect(find.byKey(_home), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
