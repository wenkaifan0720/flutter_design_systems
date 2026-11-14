import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The host stands above the Navigator, as an app mounts it, so overlays (a
// menu, a calendar, a sheet) read the same tokens as the page.
Widget _host(Widget child) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: child,
    ),
  ),
);

const _options = [
  MinimalSelectOption('daily', 'Every day'),
  MinimalSelectOption('evening', 'Every evening', subtitle: 'After 18:00'),
  MinimalSelectOption('custom', 'Custom…', enabled: false),
];

void main() {
  group('MinimalTextField', () {
    testWidgets('its label names the text field, and typing reports', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final typed = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalTextField(label: 'Name', hint: 'Habit', onChanged: typed.add),
        ),
      );
      // The hint follows the label while the field is empty.
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Name'))),
        matchesSemantics(
          label: 'Name\nHabit',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.enterText(find.byType(TextField), 'Stretch');
      expect(typed, ['Stretch']);
      handle.dispose();
    });

    testWidgets('the clear glyph empties the field and says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Morning run');
      final typed = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalTextField(
            label: 'Name',
            controller: controller,
            clearable: true,
            onChanged: typed.add,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Clear Name'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Clear Name'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(typed, ['']);
      expect(find.bySemanticsLabel('Clear Name'), findsNothing);
      handle.dispose();
    });

    testWidgets('focus turns the rule to the accent; the keyboard adds '
        'the solid ring', (tester) async {
      final focus = <bool>[];
      await tester.pumpWidget(
        _host(MinimalTextField(label: 'Name', onFocusChanged: focus.add)),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focus, [true]);
      await tester.pump(const Duration(milliseconds: 200));
      Container box() => tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Container),
            )
            .first,
      );
      Color ring() =>
          ((box().foregroundDecoration! as BoxDecoration).border! as Border)
              .top
              .color;
      final t = MinimalThemeData.preset('standard', Brightness.light);
      expect(
        (box().decoration! as BoxDecoration).border,
        Border.all(color: t.ring, width: t.hairline),
      );
      // A pointer brought the focus: the rule says it, no ring.
      expect(ring().a, 0);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(ring(), t.ring);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('the box is the md control height, muted boxes sink', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              MinimalTextField(label: 'Name'),
              MinimalTextField(label: 'Identifier', readOnly: true),
            ],
          ),
        ),
      );
      final boxes = find.ancestor(
        of: find.byType(TextField),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      expect(tester.getSize(boxes.first).height, MinimalChromeMetrics.control);
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final colors = [
        for (final e in boxes.evaluate())
          ((e.widget as Container).decoration! as BoxDecoration).color,
      ];
      expect(colors, containsAll([t.card, t.sunken]));
    });

    testWidgets('an error prints under the field as a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const MinimalTextField(
            label: 'Reminder',
            helper: 'Hidden by the error',
            error: 'Pick a time after 06:00.',
          ),
        ),
      );
      expect(find.text('Hidden by the error'), findsNothing);
      expect(
        tester
            .getSemantics(find.text('Pick a time after 06:00.'))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('a disabled field says so and takes no text', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const MinimalTextField(label: 'Team', enabled: false)),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Team'));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isTextField, isTrue);
      handle.dispose();
    });

    testWidgets('mono prints its unit, bare draws no box', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              MinimalTextField(label: 'Goal', mono: true, suffix: 'pages'),
              MinimalTextField(bare: true, hint: 'Add a note…'),
            ],
          ),
        ),
      );
      expect(find.text('pages'), findsOneWidget);
      final bare = find.byType(MinimalTextField).last;
      expect(
        find.descendant(of: bare, matching: find.byType(Container)),
        findsNothing,
      );
    });

    testWidgets('the value is one screen-reader node on the 44 px band, and a '
        'tap anywhere on the box focuses it', (tester) async {
      final handle = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _host(MinimalTextField(label: 'Name', focusNode: focus)),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Name'));
      expect(node.flagsCollection.isTextField, isTrue);
      expect(node.rect.height, MinimalLayout.minHitTarget);
      // The box's top edge, above the one line of text it paints.
      final box = tester.getRect(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.decoration is BoxDecoration,
              ),
            )
            .first,
      );
      await tester.tapAt(box.topLeft + const Offset(40, 2));
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      handle.dispose();
    });

    testWidgets('formats what is typed and hands the editing action over', (
      tester,
    ) async {
      final typed = <String>[];
      var completed = 0;
      await tester.pumpWidget(
        _host(
          MinimalTextField(
            label: 'Code',
            mono: true,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: typed.add,
            onEditingComplete: () => completed += 1,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12a34567');
      expect(typed.last, '123456');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      expect(completed, 1);
    });

    testWidgets('a trailing control is its own node, reached after the value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var shown = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MinimalTextField(
              label: 'Password',
              focusNode: focus,
              obscureText: !shown,
              trailing: MinimalIconButton(
                LucideIcons.eye,
                label: 'Show',
                size: MinimalButtonSize.small,
                onPressed: () => setState(() => shown = !shown),
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Show'))
            .flagsCollection
            .isButton,
        isTrue,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Password')).label,
        'Password',
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('suggestions follow obscure unless the caller says', (
      tester,
    ) async {
      bool suggests() =>
          tester.widget<TextField>(find.byType(TextField)).enableSuggestions;
      await tester.pumpWidget(_host(const MinimalTextField()));
      expect(suggests(), isTrue);
      await tester.pumpWidget(_host(const MinimalTextField(obscureText: true)));
      expect(suggests(), isFalse);
      // A revealed password: shown, still kept from the keyboard.
      await tester.pumpWidget(
        _host(const MinimalTextField(enableSuggestions: false)),
      );
      expect(suggests(), isFalse);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
    });

    testWidgets('invalid paints the danger rule and prints nothing', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MinimalTextField(invalid: true)));
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final box = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.decoration is BoxDecoration,
              ),
            )
            .first,
      );
      expect(
        (box.decoration! as BoxDecoration).border,
        Border.all(color: t.destructive, width: t.hairline),
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('a form field in error turns the field it holds danger', (
      tester,
    ) async {
      final t = MinimalThemeData.preset('standard', Brightness.light);
      Border rule() =>
          (tester
                          .widget<Container>(
                            find
                                .ancestor(
                                  of: find.byType(TextField),
                                  matching: find.byWidgetPredicate(
                                    (w) =>
                                        w is Container &&
                                        w.decoration is BoxDecoration,
                                  ),
                                )
                                .first,
                          )
                          .decoration!
                      as BoxDecoration)
                  .border!
              as Border;
      await tester.pumpWidget(
        _host(
          const MinimalFormField(
            label: 'Issue ID',
            error: 'An issue ID ends in its number.',
            child: MinimalTextField(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(rule(), Border.all(color: t.destructive, width: t.hairline));
      await tester.pumpWidget(
        _host(
          const MinimalFormField(
            label: 'Issue ID',
            help: 'Shown to your team.',
            child: MinimalTextField(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(rule(), Border.all(color: t.border, width: t.hairline));
    });

    testWidgets('what a caller says of the field lands on its own node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalTextField(
            fieldBuilder: (field) => Semantics(
              label: 'Email',
              hint: 'Enter your email.',
              child: field,
            ),
            trailing: MinimalIconButton(
              LucideIcons.x,
              label: 'Clear',
              size: MinimalButtonSize.small,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Email')),
        isSemantics(isTextField: true, hint: 'Enter your email.'),
      );
      handle.dispose();
    });
  });

  group('form rows', () {
    testWidgets('a section prints its title upper-cased, as a header', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const MinimalFormSection(
            title: 'Schedule',
            footer: 'Reminders follow the device time zone.',
            children: [MinimalFormRow(label: 'Remind me')],
          ),
        ),
      );
      expect(find.text('SCHEDULE'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('SCHEDULE')).flagsCollection.isHeader,
        isTrue,
      );
      expect(find.text('Reminders follow the device time zone.'), findsOne);
      handle.dispose();
    });

    testWidgets('a tappable form row is one button', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalFormRow(label: 'Archive habit', onPressed: () => taps += 1),
        ),
      );
      await tester.tap(find.text('Archive habit'));
      expect(taps, 1);
      final node = tester.getSemantics(find.bySemanticsLabel('Archive habit'));
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('an input row names its field and shows its error', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final typed = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalInputRow(
            label: 'Goal',
            mono: true,
            error: 'Between 1 and 240 minutes.',
            onChanged: typed.add,
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Goal'));
      expect(node.flagsCollection.isTextField, isTrue);
      await tester.enterText(find.byType(TextField), '30');
      expect(typed, ['30']);
      expect(find.text('Between 1 and 240 minutes.'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MinimalSelect', () {
    testWidgets('the menu shows the choice checked and picks another', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? chosen;
      await tester.pumpWidget(
        _host(
          MinimalSelect(
            label: 'Repeats',
            value: 'evening',
            options: _options,
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await tester.tap(find.text('Every evening'));
      await tester.pumpAndSettle();
      // The row's value and the menu's item.
      expect(find.text('Every evening'), findsNWidgets(2));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Every day')),
        matchesSemantics(
          label: 'Every day',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      // A disabled option does nothing and keeps the menu open.
      await tester.tap(find.text('Custom…'));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      await tester.tap(find.text('Every day'));
      await tester.pumpAndSettle();
      expect(chosen, 'daily');
      expect(find.text('Every day'), findsNothing);
      handle.dispose();
    });

    testWidgets('the sheet presentation returns the chosen value', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        _host(
          MinimalSelect(
            label: 'Repeats',
            value: 'daily',
            options: _options,
            presentation: MinimalSelectPresentation.sheet,
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await tester.tap(find.text('Every day'));
      await tester.pumpAndSettle();
      expect(find.text('After 18:00'), findsOneWidget);
      await tester.tap(find.text('Every evening'));
      await tester.pumpAndSettle();
      expect(chosen, 'evening');
      expect(find.text('After 18:00'), findsNothing);
    });

    testWidgets('with no onChanged it is disabled and opens nothing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const MinimalSelect(
            label: 'Owner',
            value: 'daily',
            options: _options,
          ),
        ),
      );
      await tester.tap(find.text('Every day'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Every evening'), findsNothing);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Owner')));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      // Its value drops to the quiet ink, so dimmed it never reads
      // stronger than an enabled row's.
      final t = MinimalThemeData.preset('standard', Brightness.light);
      expect(
        tester.widget<Text>(find.text('Every day')).style?.color,
        t.mutedForeground,
      );
      handle.dispose();
    });

    testWidgets('a placeholder stands in for no value', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalSelect(
            label: 'Area',
            value: null,
            options: _options,
            prompt: 'None',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('None'), findsOneWidget);
    });
  });

  group('MinimalSelectionList', () {
    testWidgets('it checks the value and skips a disabled option', (
      tester,
    ) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalSelectionList(
            value: 'daily',
            options: _options,
            onChanged: chosen.add,
          ),
        ),
      );
      await tester.tap(find.text('Custom…'));
      await tester.tap(find.text('Every evening'));
      expect(chosen, ['evening']);
    });
  });

  group('MinimalMenu', () {
    List<MinimalMenuItem> items(List<String> log) => [
      MinimalMenuItem('Edit', shortcut: 'E', onPressed: () => log.add('edit')),
      MinimalMenuItem('Duplicate', onPressed: () => log.add('duplicate')),
      const MinimalMenuItem('Move to…'),
      MinimalMenuItem(
        'Delete',
        destructive: true,
        startsGroup: true,
        onPressed: () => log.add('delete'),
      ),
    ];

    testWidgets('a tap opens it; an item runs once the menu has closed', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalMenu(
            label: 'Habit actions',
            items: items(log),
            child: const Text('More'),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('E'), findsOneWidget);
      await tester.tap(find.text('Move to…'));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(log, ['delete']);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('a tap outside and Escape close it with nothing run', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalMenu(
            label: 'Habit actions',
            items: items(log),
            child: const Text('More'),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('the arrow keys walk the items and Enter runs one', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalMenu(
            label: 'Habit actions',
            items: items(log),
            child: const Text('More'),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(log, ['duplicate']);
    });

    testWidgets('long press opens the context menu; a tap does not', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalMenu(
            label: 'Row actions',
            trigger: MinimalMenuTrigger.longPress,
            items: items([]),
            child: GestureDetector(
              onTap: () => taps += 1,
              child: const Text('Morning run'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Morning run'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(find.text('Edit'), findsNothing);
      await tester.longPress(find.text('Morning run'));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('a menu with no items is a disabled control', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const MinimalMenu(
            label: 'No actions',
            items: [],
            child: Text('More'),
          ),
        ),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('No actions')),
      );
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });

  testWidgets('two months stacked in a narrow column still step forward', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 340,
          child: MinimalCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            value: DateTime(2026, 8, 12),
            onChanged: (_) {},
            months: 2,
          ),
        ),
      ),
    );
    // Stacked, both chevrons stand on the first month's header.
    final next = find.byWidgetPredicate(
      (w) => w is MinimalIconButton && w.icon == LucideIcons.chevronRightDir,
    );
    expect(next, findsOneWidget);
    expect(tester.widget<MinimalIconButton>(next).onPressed, isNotNull);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.textContaining('August'), findsNothing);
  });

  group('MinimalDatePicker', () {
    final today = DateTime(2026, 8, 28);

    testWidgets('a date pill opens the calendar; a day picks and closes', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Starts',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            today: today,
            onChanged: chosen.add,
          ),
        ),
      );
      expect(find.text('21 Aug 2026'), findsOneWidget);
      await tester.tap(find.text('21 Aug 2026'));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(chosen, [DateTime(2026, 8, 15)]);
      expect(find.text('August 2026'), findsNothing);
    });

    testWidgets('the calendar names days, marks today and the choice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Started',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.inline,
            today: today,
            first: DateTime(2026, 8, 3),
            onChanged: (_) {},
          ),
        ),
      );
      final chosen = tester.getSemantics(
        find.bySemanticsLabel('Friday, 21 August 2026'),
      );
      expect(chosen.flagsCollection.isSelected, Tristate.isTrue);
      expect(
        find.bySemanticsLabel('Friday, 28 August 2026, Today'),
        findsOneWidget,
      );
      final early = tester.getSemantics(
        find.bySemanticsLabel('Sunday, 2 August 2026'),
      );
      expect(early.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('September 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pump();
      expect(find.text('July 2026'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the time columns set the hour and the minute', (tester) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Reminder',
            value: DateTime(2026, 8, 28, 21, 30),
            mode: MinimalDatePickerMode.time,
            presentation: MinimalDatePickerPresentation.wheel,
            onChanged: chosen.add,
          ),
        ),
      );
      await tester.tap(find.text('35'));
      await tester.tap(find.text('22'));
      expect(chosen, [
        DateTime(2026, 8, 28, 21, 35),
        DateTime(2026, 8, 28, 22, 30),
      ]);
    });

    testWidgets('the time columns loop as a clock face does: on the hour, '
        '55 and 50 stand over 00', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalTimePicker(
            label: 'Reminder',
            value: DateTime(2026, 8, 28, 7),
            wheel: true,
            onChanged: (_) {},
          ),
        ),
      );
      final hour = tester.getCenter(find.text('07')).dy;
      final minute = tester.getCenter(find.text('00')).dy;
      expect(minute, moreOrLessEquals(hour, epsilon: 0.5));
      // Two rows over the pick in both columns: 05 and 06, 50 and 55.
      expect(tester.getCenter(find.text('55')).dy, minute - 32);
      expect(tester.getCenter(find.text('50')).dy, minute - 64);
      expect(tester.getCenter(find.text('06')).dy, hour - 32);
    });

    testWidgets('a confirming sheet commits only on Done', (tester) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Ends',
            value: DateTime(2026, 12, 31, 23),
            mode: MinimalDatePickerMode.date,
            confirmSelection: true,
            onChanged: chosen.add,
          ),
        ),
      );
      await tester.tap(find.text('31 Dec 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24'));
      await tester.pump();
      expect(chosen, isEmpty);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(chosen, [DateTime(2026, 12, 24, 23)]);
    });

    testWidgets('with no onChanged its pills are disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Created',
            value: DateTime(2026, 6, 2, 7, 12),
          ),
        ),
      );
      final pill = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Created, date')),
      );
      expect(pill.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(find.text('2 Jun 2026'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsNothing);
      expect(find.text('07:12'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MinimalSearchField', () {
    testWidgets('typing reports; the clear cap and Escape empty it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final typed = <String>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _host(
          MinimalSearchField(
            hint: 'Search habits',
            clearable: true,
            focusNode: focus,
            onChanged: typed.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'run');
      await tester.pump();
      expect(find.text('run'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pump();
      expect(typed, ['run', '']);
      await tester.enterText(find.byType(TextField), 'read');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(typed.last, '');
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      handle.dispose();
    });

    testWidgets('Cancel shows while focused, and clears and leaves', (
      tester,
    ) async {
      var cancelled = 0;
      await tester.pumpWidget(
        _host(
          MinimalSearchField(showCancel: true, onCancel: () => cancelled += 1),
        ),
      );
      expect(find.text('Cancel'), findsNothing);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'water');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(cancelled, 1);
      expect(find.text('water'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('scopes announce the current one and switch', (tester) async {
      final handle = tester.ensureSemantics();
      final scopes = <int>[];
      await tester.pumpWidget(
        _host(
          MinimalSearchField(
            scopes: const ['All', 'Open', 'Done'],
            scopeIndex: 1,
            onScopeChanged: scopes.add,
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Open'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      await tester.tap(find.text('Done'));
      expect(scopes, [2]);
      handle.dispose();
    });

    testWidgets('a tap on the box beside the text, its glyph too, focuses it', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(_host(MinimalSearchField(focusNode: focus)));
      final box = tester.getRect(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.decoration is BoxDecoration,
              ),
            )
            .first,
      );
      final line = tester.getRect(find.byType(EditableText));
      // The glyph's column, left of the editable line.
      final glyph = box.centerLeft + const Offset(12, 0);
      expect(line.contains(glyph), isFalse);
      await tester.tapAt(glyph);
      await tester.pump();
      expect(focus.hasFocus, isTrue);
    });

    testWidgets('a disabled field takes no text', (tester) async {
      await tester.pumpWidget(_host(const MinimalSearchField(enabled: false)));
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
    });
  });

  group('MinimalSearchEntry', () {
    testWidgets('the entry and its filter square are two controls', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      var filtered = 0;
      await tester.pumpWidget(
        _host(
          MinimalSearchEntry(
            label: 'Search habits',
            detail: 'In Habits',
            onPressed: () => opened += 1,
            onFilter: () => filtered += 1,
            filtersActive: true,
          ),
        ),
      );
      await tester.tap(find.text('Search habits'));
      await tester.tap(find.bySemanticsLabel('Filters, active'));
      expect(opened, 1);
      expect(filtered, 1);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('Search habits')))
            .flagsCollection
            .isButton,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('beside a two-line entry the filter square stands as tall '
        'as the entry', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalSearchEntry(
            label: 'Search issues',
            detail: 'In Habits · 6 open',
            onPressed: () {},
            onFilter: () {},
          ),
        ),
      );
      final entry = tester.getRect(
        find
            .ancestor(
              of: find.text('Search issues'),
              matching: find.byType(Container),
            )
            .first,
      );
      final square = tester.getRect(
        find
            .ancestor(
              of: find.byType(MinimalIcon).last,
              matching: find.byType(Container),
            )
            .first,
      );
      expect(entry.height, greaterThan(MinimalChromeMetrics.control));
      expect(square.top, moreOrLessEquals(entry.top, epsilon: 0.5));
      expect(square.height, moreOrLessEquals(entry.height, epsilon: 0.5));
    });

    testWidgets('with no onPressed it is disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const MinimalSearchEntry(label: 'Search archive')),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Search archive'));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });

  group('MinimalChoiceRow', () {
    testWidgets('it is a checked radio of a mutually exclusive set', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalSelectionGroup(
            children: [
              MinimalChoiceRow(
                title: 'Every day',
                selected: true,
                onPressed: () => taps += 1,
              ),
              const MinimalChoiceRow(title: 'Weekly', selected: false),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Every day')),
        matchesSemantics(
          label: 'Every day',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final weekly = tester.getSemantics(find.bySemanticsLabel('Weekly'));
      expect(weekly.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(find.text('Every day'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('rich content keeps the title as what is announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalChoiceRow(
            title: 'Morning run, HAB-4',
            selected: false,
            onPressed: () {},
            content: const Text('HAB-4'),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('^Morning run, HAB-4')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the arrow keys walk a group', (tester) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalSelectionGroup(
            children: [
              for (final label in const ['Morning', 'Afternoon', 'Evening'])
                MinimalChoiceRow(
                  title: label,
                  selected: label == 'Morning',
                  onPressed: () => chosen.add(label),
                ),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, ['Evening']);
    });
  });

  group('hit targets', () {
    // A tap just outside what a small control paints, still inside its
    // 44 px target.
    Future<void> tapBelow(WidgetTester tester, Finder painted, double dy) =>
        tester.tapAt(tester.getRect(painted).bottomCenter + Offset(0, dy));

    Finder pill(String text) => find
        .ancestor(of: find.text(text), matching: find.byType(Container))
        .first;

    testWidgets('a date pill opens from 7 px below its face', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Starts',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            onChanged: (_) {},
          ),
        ),
      );
      expect(tester.getSize(pill('21 Aug 2026')).height, 28);
      await tapBelow(tester, pill('21 Aug 2026'), 7);
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('the month buttons and the days take taps beside them', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Started',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.inline,
            onChanged: chosen.add,
          ),
        ),
      );
      await tapBelow(tester, find.bySemanticsLabel('Next month'), 6);
      await tester.pump();
      expect(find.text('September 2026'), findsOneWidget);
      await tester.tapAt(
        tester.getRect(find.bySemanticsLabel('Previous month')).topCenter -
            const Offset(0, 6),
      );
      await tester.pump();
      expect(find.text('August 2026'), findsOneWidget);
      await tapBelow(tester, pill('15'), 5);
      expect(chosen, [DateTime(2026, 8, 15)]);
    });

    testWidgets('the clear glyphs and the scopes take taps beside them', (
      tester,
    ) async {
      final input = TextEditingController(text: 'Morning run');
      final search = TextEditingController(text: 'run');
      final scopes = <int>[];
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MinimalTextField(
                label: 'Name',
                helper: 'Shown on Today.',
                controller: input,
                clearable: true,
              ),
              MinimalSearchField(
                controller: search,
                clearable: true,
                scopes: const ['All', 'Open', 'Done'],
                onScopeChanged: scopes.add,
              ),
            ],
          ),
        ),
      );
      await tapBelow(tester, find.bySemanticsLabel('Clear Name'), 5);
      await tester.pump();
      expect(input.text, isEmpty);
      await tapBelow(tester, find.bySemanticsLabel('Clear'), 6);
      await tester.pump();
      expect(search.text, isEmpty);
      await tapBelow(tester, find.bySemanticsLabel('Done'), 7);
      expect(scopes, [2]);
    });

    testWidgets('the search entry and its filter square take taps below', (
      tester,
    ) async {
      var opened = 0;
      var filtered = 0;
      await tester.pumpWidget(
        _host(
          MinimalSearchEntry(
            label: 'Search habits',
            onPressed: () => opened += 1,
            onFilter: () => filtered += 1,
          ),
        ),
      );
      await tapBelow(tester, find.bySemanticsLabel('Filters'), 5);
      await tapBelow(tester, find.text('Search habits'), 10);
      expect(filtered, 1);
      expect(opened, 1);
    });
  });

  group('MinimalDatePicker range, format and keys', () {
    testWidgets('days past the maximum are out; times clamp into range', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MinimalDatePicker(
                label: 'Started',
                value: DateTime(2026, 8, 18),
                mode: MinimalDatePickerMode.date,
                presentation: MinimalDatePickerPresentation.inline,
                last: DateTime(2026, 8, 20),
                onChanged: chosen.add,
              ),
              MinimalDatePicker(
                label: 'Reminder',
                value: DateTime(2026, 8, 28, 10),
                mode: MinimalDatePickerMode.time,
                presentation: MinimalDatePickerPresentation.wheel,
                first: DateTime(2026, 8, 28, 9),
                onChanged: chosen.add,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('25'), warnIfMissed: false);
      expect(chosen, isEmpty);
      await tester.tap(find.text('08'));
      expect(chosen, [DateTime(2026, 8, 28, 9)]);
    });

    testWidgets('the 12-hour clock prints in the pill and the columns', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MinimalDatePicker(
                label: 'Reminder',
                value: DateTime(2026, 8, 28, 21, 30),
                mode: MinimalDatePickerMode.time,
                use24HourFormat: false,
                onChanged: (_) {},
              ),
              MinimalDatePicker(
                label: 'Reminder',
                value: DateTime(2026, 8, 28, 21, 30),
                mode: MinimalDatePickerMode.time,
                presentation: MinimalDatePickerPresentation.wheel,
                use24HourFormat: false,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('9:30 PM'), findsOneWidget);
      expect(find.text('9 PM'), findsOneWidget);
    });

    testWidgets('the chosen time prints in the ink, centred under its head', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Reminder',
            value: DateTime(2026, 8, 28, 21, 30),
            mode: MinimalDatePickerMode.time,
            presentation: MinimalDatePickerPresentation.wheel,
            onChanged: (_) {},
          ),
        ),
      );
      final t = MinimalThemeData.preset('standard', Brightness.light);
      expect(tester.widget<Text>(find.text('21')).style!.color, t.foreground);
      expect(
        tester.getCenter(find.text('HOUR')).dx,
        moreOrLessEquals(tester.getCenter(find.text('21')).dx, epsilon: 1),
      );
    });

    testWidgets('the arrow keys walk the days across months; Enter picks', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        _host(
          MinimalDatePicker(
            label: 'Started',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.inline,
            onChanged: chosen.add,
          ),
        ),
      );
      final grid = find.byWidgetPredicate(
        (w) => w is Focus && w.focusNode?.debugLabel == 'Calendar days',
      );
      tester.widget<Focus>(grid).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(chosen, [DateTime(2026, 8, 22)]);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      }
      await tester.pump();
      expect(find.text('July 2026'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(chosen.last, DateTime(2026, 7, 25));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(find.text('August 2026'), findsOneWidget);
    });
  });

  group('menu placement and triggers', () {
    Widget bottomHost(Widget child) => MaterialApp(
      builder: (context, navigator) => MinimalHost(
        light: MinimalThemeData.preset('standard', Brightness.light),
        dark: MinimalThemeData.preset('standard', Brightness.dark),
        brightness: Brightness.light,
        child: navigator!,
      ),
      home: Scaffold(
        body: Align(alignment: Alignment.bottomLeft, child: child),
      ),
    );

    testWidgets('near the bottom the card opens above its control', (
      tester,
    ) async {
      await tester.pumpWidget(
        bottomHost(
          MinimalMenu.button(
            LucideIcons.ellipsis,
            label: 'Habit actions',
            items: [
              for (final label in const ['Edit', 'Duplicate', 'Archive'])
                MinimalMenuItem(label, onPressed: () {}),
            ],
          ),
        ),
      );
      final anchor = tester.getRect(find.bySemanticsLabel('Habit actions'));
      await tester.tap(find.bySemanticsLabel('Habit actions'));
      await tester.pumpAndSettle();
      final card = tester.getRect(
        find
            .ancestor(of: find.text('Edit'), matching: find.byType(ClipRRect))
            .first,
      );
      expect(card.bottom, lessThanOrEqualTo(anchor.top));
    });

    testWidgets('the pill trigger prints its choice and opens the menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalMenu.button(
            LucideIcons.arrowDownUp,
            text: 'Sort: Streak',
            label: 'Sort habits',
            items: [MinimalMenuItem('Name', onPressed: () {})],
          ),
        ),
      );
      await tester.tap(find.text('Sort: Streak'));
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('Shift+F10 opens a long-press menu from the keyboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalMenu(
            label: 'Row actions',
            trigger: MinimalMenuTrigger.longPress,
            items: [MinimalMenuItem('Edit', onPressed: () {})],
            child: const Text('Morning run'),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets(
      'the card reads the theme of its caller under a bare navigator',
      (tester) async {
        final t = MinimalThemeData.preset('ember', Brightness.dark);
        await tester.pumpWidget(
          MaterialApp(
            home: MinimalHost(
              light: MinimalThemeData.preset('ember', Brightness.light),
              dark: t,
              brightness: Brightness.dark,
              child: Center(
                child: MinimalMenu(
                  label: 'Habit actions',
                  items: [MinimalMenuItem('Edit', onPressed: () {})],
                  child: const Text('More'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('More'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final card = tester.widget<Container>(
          find
              .ancestor(of: find.text('Edit'), matching: find.byType(Container))
              .last,
        );
        expect((card.decoration! as BoxDecoration).color, t.card);
      },
    );
  });

  group('MinimalInputRow layout', () {
    testWidgets('narrow rows stack; wide rows start the error under the '
        'field', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              SizedBox(
                width: 240,
                child: MinimalInputRow(label: 'Name', hint: 'Stretch'),
              ),
              MinimalInputRow(
                label: 'Goal',
                hint: '10',
                error: 'Between 1 and 240 minutes.',
              ),
            ],
          ),
        ),
      );
      final name = tester.getRect(find.text('Name'));
      final stretch = tester.getRect(find.text('Stretch'));
      expect(stretch.top, greaterThan(name.bottom));
      final goalField = tester.getRect(find.text('10'));
      final error = tester.getRect(find.text('Between 1 and 240 minutes.'));
      expect(error.left, moreOrLessEquals(goalField.left, epsilon: 0.5));
    });
  });
}
