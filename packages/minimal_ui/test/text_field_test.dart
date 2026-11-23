import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/scrolling_host.dart';

void main() {
  group('MinimalTextField', () {
    testWidgets('its label names the text field, and typing reports', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final typed = <String>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalTextField(
            labelText: 'Name',
            hintText: 'Habit',
            onChanged: typed.add,
          ),
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
      addTearDown(controller.dispose);
      final typed = <String>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalTextField(
            labelText: 'Name',
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

    testWidgets('focus turns the outline to the accent, 1.5 px drawn inward, '
        'after a tap as after the keyboard', (tester) async {
      final focus = <bool>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalTextField(labelText: 'Name', onFocusChange: focus.add),
        ),
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
      BorderSide edge() =>
          ((box().foregroundDecoration! as BoxDecoration).border! as Border)
              .top;
      final t = MinimalThemeData.preset('standard', Brightness.light);
      expect(
        (box().decoration! as BoxDecoration).border,
        Border.all(color: t.ring, width: t.hairline),
      );
      // The field's own edge shows the focus, inside its outline: no ring
      // stands outside it, whether a pointer or the keyboard brought it.
      const shown = BorderSide(
        color: Color(0x00000000),
        width: 1.5,
        strokeAlign: BorderSide.strokeAlignInside,
      );
      expect(edge(), shown.copyWith(color: t.ring));
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(edge(), shown.copyWith(color: t.ring));
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('the box is the md control height, muted boxes sink', (
      tester,
    ) async {
      await tester.pumpWidget(
        scrollingHost(
          const Column(
            children: [
              MinimalTextField(labelText: 'Name'),
              MinimalTextField(labelText: 'Identifier', readOnly: true),
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

    testWidgets('an error prints under the field in place of the help and '
        "is read as the input's hint", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(
          const MinimalTextField(
            labelText: 'Reminder',
            helperText: 'Hidden by the error',
            errorText: 'Pick a time after 06:00.',
          ),
        ),
      );
      expect(find.text('Hidden by the error'), findsNothing);
      expect(find.text('Pick a time after 06:00.'), findsOneWidget);
      final input = tester.getSemantics(find.byType(EditableText));
      expect(input.getSemanticsData().label, 'Reminder');
      expect(
        input.getSemanticsData().hint,
        contains('Pick a time after 06:00.'),
      );
      handle.dispose();
    });

    testWidgets('a disabled field says so and takes no text', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(
          const MinimalTextField(labelText: 'Team', enabled: false),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Team'));
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
      handle.dispose();
    });

    testWidgets('mono prints its unit, bare draws no box', (tester) async {
      await tester.pumpWidget(
        scrollingHost(
          const Column(
            children: [
              MinimalTextField(labelText: 'Goal', mono: true, suffix: 'pages'),
              MinimalTextField(bare: true, hintText: 'Add a note…'),
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
        scrollingHost(MinimalTextField(labelText: 'Name', focusNode: focus)),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Name'));
      expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
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
        scrollingHost(
          MinimalTextField(
            labelText: 'Code',
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
        scrollingHost(
          StatefulBuilder(
            builder: (context, setState) => MinimalTextField(
              labelText: 'Password',
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
            .getSemanticsData()
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
      await tester.pumpWidget(scrollingHost(const MinimalTextField()));
      expect(suggests(), isTrue);
      await tester.pumpWidget(
        scrollingHost(const MinimalTextField(obscureText: true)),
      );
      expect(suggests(), isFalse);
      // A revealed password: shown, still kept from the keyboard.
      await tester.pumpWidget(
        scrollingHost(const MinimalTextField(enableSuggestions: false)),
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
      await tester.pumpWidget(
        scrollingHost(const MinimalTextField(invalid: true)),
      );
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
        scrollingHost(
          const MinimalFormField(
            labelText: 'Issue ID',
            errorText: 'An issue ID ends in its number.',
            child: MinimalTextField(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(rule(), Border.all(color: t.destructive, width: t.hairline));
      await tester.pumpWidget(
        scrollingHost(
          const MinimalFormField(
            labelText: 'Issue ID',
            helperText: 'Shown to your team.',
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
        scrollingHost(
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
}
