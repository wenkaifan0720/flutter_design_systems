// The text fields family (components/text_fields.dart): Compose's
// TextField / OutlinedTextField geometry and label motion, the secure
// field, the text area, the code input and the field error, and the ported
// Cody v2 controls tests for fields (CONTRACT §8.2; RUN 2 F14):
//   'input supports keyboard submission, read-only, and live error'
//     → 'input supports keyboard submission, read-only, and live error'
//   'grouped controls fit narrow phones at large text sizes' (its input row)
//     → 'fields fit narrow phones at large text sizes'
library;

import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// An app around [child]: Material's localizations and overlay (the text
/// handles' and edit menu's), the Expressive host, the text scale and
/// direction asked for, [child] centred and left free.
Widget _app(
  Widget child, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  TargetPlatform platform = TargetPlatform.android,
  bool stretch = false,
}) => MaterialApp(
  theme: ThemeData(platform: platform),
  home: ExpressiveHost(
    light: _theme,
    brightness: Brightness.light,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: stretch
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: child,
                  ),
                )
              : Center(child: child),
        ),
      ),
    ),
  ),
);

Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

Finder get _field => find.byType(ExpressiveTextField);

void main() {
  testWidgets(
    'field styles resolve complete hover/focus states and fall through to the component theme',
    (tester) async {
      final focus = FocusNode();
      final theme = _theme.copyWith(
        textFieldTheme: ExpressiveComponentThemeData(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? Colors.grey
                : states.contains(WidgetState.hovered)
                ? Colors.teal
                : Colors.green,
          ),
        ),
      );
      final style = ExpressiveComponentThemeData(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              !states.contains(WidgetState.disabled) &&
                  states.contains(WidgetState.focused)
              ? Colors.blue
              : null,
        ),
      );
      Widget app({bool enabled = true}) => _app(
        ExpressiveTheme(
          data: theme,
          child: SizedBox(
            width: 240,
            child: ExpressiveTextField(
              focusNode: focus,
              enabled: enabled,
              style: style,
            ),
          ),
        ),
      );
      Color fill() {
        final dynamic field = tester.widget(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_FieldLayout',
          ),
        );
        return field.containerColor as Color;
      }

      await tester.pumpWidget(app());
      expect(fill().toARGB32(), Colors.green.toARGB32());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(ExpressiveTextField)));
      await tester.pumpAndSettle();
      expect(fill().toARGB32(), Colors.teal.toARGB32());
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(fill().toARGB32(), Colors.blue.toARGB32());
      await tester.pumpWidget(app(enabled: false));
      await tester.pumpAndSettle();
      expect(fill().toARGB32(), Colors.grey.toARGB32());
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
    },
  );

  testWidgets('a pointer over a field shows M3\'s hover face: the indicator or '
      'outline in onSurface, a filled container under the hover layer', (
    tester,
  ) async {
    final c = _theme.colors;
    for (final kind in ExpressiveTextFieldKind.values) {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 240,
            child: ExpressiveTextField(kind: kind, label: 'Name'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      dynamic layout() => tester.widget(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_FieldLayout',
        ),
      );
      final idleContainer = layout().containerColor as Color;
      final idleIndicator = layout().indicatorColor as Color;
      expect(
        idleIndicator.toARGB32(),
        isNot(c.onSurface.toARGB32()),
        reason: '$kind idle',
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(_field));
      await tester.pumpAndSettle();
      expect(
        (layout().indicatorColor as Color).toARGB32(),
        c.onSurface.toARGB32(),
        reason: '$kind hovered',
      );
      final filled = kind == ExpressiveTextFieldKind.filled;
      final hoveredContainer = filled
          ? Color.alphaBlend(
              c.onSurface.withValues(alpha: _theme.states.hoverOpacity),
              idleContainer,
            )
          : idleContainer;
      expect(
        (layout().containerColor as Color).toARGB32(),
        hoveredContainer.toARGB32(),
        reason: '$kind container',
      );
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('input supports keyboard submission, read-only, and live error', (
    tester,
  ) async {
    var submitted = '';
    final controller = TextEditingController();
    await tester.pumpWidget(
      _app(
        ExpressiveTextField(
          label: 'Name',
          controller: controller,
          onSubmitted: (v) => submitted = v,
          textInputAction: TextInputAction.done,
          errorText: 'A name is required',
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'Weekend');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'Weekend');
    expect(find.text('A name is required'), findsOneWidget);
    await tester.pumpWidget(
      _app(ExpressiveTextField(controller: controller, readOnly: true)),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      true,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('fields fit narrow phones at large text sizes', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ExpressiveTextField(
              label: 'Trip name',
              hintText: 'Name',
              leading: Icon(ExpressiveSymbols.flight),
              helperText: 'Only invited people can see this trip.',
            ),
            ExpressiveTextField(
              kind: ExpressiveTextFieldKind.outlined,
              label: 'Nightly budget',
              prefix: r'$',
              suffix: 'USD',
              maxLength: 6,
            ),
            ExpressiveTextField(obscureText: true, label: 'Password'),
            ExpressiveTextArea(label: 'Note for the host'),
            ExpressiveInputOtp(),
          ],
        ),
        scale: 2,
        stretch: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('filled', () {
    testWidgets('keeps Compose\'s minimum size, the label centred at rest', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ExpressiveTextField(label: 'City')));
      final field = _rectOf(tester, _field);
      expect(field.size, const Size(280, 56));
      // Expanded label: bodyLarge's 24dp line, centred in the container by
      // its capitals (DesignCapCenter), its line box a pixel or two lower.
      final label = _rectOf(tester, find.text('City'));
      expect(label.top - field.top, closeTo(16, 2));
      expect(label.left - field.left, TextFieldBehavior.padding);
    });

    testWidgets('focus minimizes the label on the spring and keeps 56dp', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ExpressiveTextField(label: 'City')));
      final field = _rectOf(tester, _field);
      final rest = _rectOf(tester, find.text('City')).top - field.top;
      await tester.tap(_field);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final moving = _rectOf(tester, find.text('City')).top - field.top;
      expect(moving, lessThan(rest));
      expect(moving, greaterThan(TextFieldBehavior.labelVerticalPadding));
      await tester.pumpAndSettle();
      final label = _rectOf(tester, find.text('City'));
      // The minimized label too stands by its capitals, its line box a
      // pixel or two lower.
      expect(
        label.top - field.top,
        closeTo(TextFieldBehavior.labelVerticalPadding, 2),
      );
      expect(label.height, 16);
      expect(_rectOf(tester, _field).height, 56);
      // The input sits under the minimized label, 8dp above the bottom.
      final input = _rectOf(tester, find.byType(EditableText));
      expect(input.top - field.top, closeTo(24, 2));
    });

    testWidgets('without a label the input is centred', (tester) async {
      await tester.pumpWidget(
        _app(const ExpressiveTextField(hintText: 'Search')),
      );
      final field = _rectOf(tester, _field);
      expect(field.height, 56);
      // By its capitals: its line box a pixel or two below 16.
      expect(
        _rectOf(tester, find.byType(EditableText)).top - field.top,
        closeTo(16, 2),
      );
    });

    testWidgets('icons sit in 48dp targets, the text 4dp after them', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveTextField(
            label: 'Guest',
            leading: Icon(ExpressiveSymbols.person),
            trailing: Icon(ExpressiveSymbols.close),
          ),
        ),
      );
      final field = _rectOf(tester, _field);
      final leading = _rectOf(tester, find.byIcon(ExpressiveSymbols.person));
      expect(leading.size, const Size(24, 24));
      expect(leading.left - field.left, 12);
      final trailing = _rectOf(tester, find.byIcon(ExpressiveSymbols.close));
      expect(field.right - trailing.right, 12);
      expect(_rectOf(tester, find.text('Guest')).left - field.left, 52);
    });

    testWidgets('supporting text sits 4dp under the 56dp container', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveTextField(
            label: 'City',
            helperText: 'Where you stay',
          ),
        ),
      );
      final field = _rectOf(tester, _field);
      expect(field.height, 56 + 4 + 16);
      final supporting = _rectOf(tester, find.text('Where you stay'));
      expect(supporting.top - field.top, 60);
      expect(supporting.left - field.left, 16);
    });
  });

  group('outlined', () {
    testWidgets('leaves half the minimized label above the outline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveTextField(
            kind: ExpressiveTextFieldKind.outlined,
            label: 'City',
          ),
        ),
      );
      final field = _rectOf(tester, _field);
      expect(field.size, const Size(280, 64));
      // By its capitals: its line box a pixel or two below 8 + 16.
      expect(
        _rectOf(tester, find.text('City')).top - field.top,
        closeTo(8 + 16, 2),
      );
      await tester.tap(_field);
      await tester.pumpAndSettle();
      // The minimized label is centred on the outline's top edge.
      final label = _rectOf(tester, find.text('City'));
      // By its capitals: its line box a pixel or two below the edge.
      expect(label.top - field.top, closeTo(0, 2));
      expect(label.left - field.left, 16);
      expect(_rectOf(tester, _field).height, 64);
    });
  });

  testWidgets('the label keeps its place in right-to-left', (tester) async {
    await tester.pumpWidget(
      _app(
        const ExpressiveTextField(
          label: 'City',
          leading: Icon(ExpressiveSymbols.place),
        ),
        direction: TextDirection.rtl,
      ),
    );
    final field = _rectOf(tester, _field);
    expect(
      field.right - _rectOf(tester, find.byIcon(ExpressiveSymbols.place)).right,
      12,
    );
    expect(field.right - _rectOf(tester, find.text('City')).right, 52);
  });

  testWidgets('placeholder shows only once the label is minimized', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ExpressiveTextField(label: 'City', hintText: 'Lisbon')),
    );
    expect(find.text('Lisbon'), findsNothing);
    await tester.tap(_field);
    await tester.pumpAndSettle();
    expect(find.text('Lisbon'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Porto');
    await tester.pumpAndSettle();
    expect(find.text('Lisbon'), findsNothing);
  });

  testWidgets('prefix and suffix show with the input', (tester) async {
    await tester.pumpWidget(
      _app(
        const ExpressiveTextField(label: 'Budget', prefix: r'$', suffix: 'USD'),
      ),
    );
    expect(find.text(r'$'), findsNothing);
    await tester.tap(_field);
    await tester.pumpAndSettle();
    final prefix = _rectOf(tester, find.text(r'$'));
    final input = _rectOf(tester, find.byType(EditableText));
    expect(input.left - prefix.right, TextFieldBehavior.affixPadding);
    expect(find.text('USD'), findsOneWidget);
  });

  testWidgets('the counter follows the text and the length is enforced', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ExpressiveTextField(label: 'Headline', maxLength: 5)),
    );
    expect(find.text('0/5'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Sea view');
    await tester.pump();
    expect(find.text('5/5'), findsOneWidget);
  });

  testWidgets('a secure field obscures and reveals on its toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ExpressiveTextField(label: 'Password', obscureText: true)),
    );
    EditableText editable() =>
        tester.widget<EditableText>(find.byType(EditableText));
    expect(editable().obscureText, isTrue);
    expect(editable().enableSuggestions, isFalse);
    await tester.tap(find.bySemanticsLabel('Show password'));
    await tester.pumpAndSettle();
    expect(editable().obscureText, isFalse);
    expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
  });

  testWidgets('a disabled field takes no focus', (tester) async {
    await tester.pumpWidget(
      _app(const ExpressiveTextField(label: 'City', enabled: false)),
    );
    await tester.tap(_field);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.hasAnyClients, isFalse);
  });

  testWidgets('the field is named by its label and flags an error', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const ExpressiveTextField(label: 'Email', errorText: 'Invalid')),
    );
    final node = tester
        .getSemantics(find.byType(EditableText))
        .getSemanticsData();
    expect(node.label, 'Email');
    expect(node.flagsCollection.isTextField, isTrue);
    expect(node.validationResult, SemanticsValidationResult.invalid);
    semantics.dispose();
  });

  testWidgets('a text area grows with its lines', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(ExpressiveTextArea(label: 'Note', controller: controller)),
    );
    final three = _rectOf(tester, find.byType(ExpressiveTextArea)).height;
    // 8 + 16 label + three 24dp lines + 8.
    expect(three, 8 + 16 + 3 * 24 + 8);
    controller.text = 'one\ntwo\nthree\nfour\nfive';
    await tester.pumpAndSettle();
    expect(
      _rectOf(tester, find.byType(ExpressiveTextArea)).height,
      8 + 16 + 5 * 24 + 8,
    );
  });

  testWidgets('a text area with an action key reports it, as Compose\'s '
      'keyboard actions do on a multi-line field', (tester) async {
    var submitted = '';
    var completed = 0;
    await tester.pumpWidget(
      _app(
        ExpressiveTextArea(
          label: 'Note',
          textInputAction: TextInputAction.done,
          onEditingComplete: () => completed++,
          onSubmitted: (v) => submitted = v,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'Ring twice');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(completed, 1);
    expect(submitted, 'Ring twice');
  });

  testWidgets('every decoration tap reports onTap, focused or not', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        ExpressiveTextField(
          label: 'Country',
          readOnly: true,
          trailing: const Icon(ExpressiveSymbols.arrowDropDown),
          onTap: () => taps++,
        ),
      ),
    );
    final arrow = find.byIcon(ExpressiveSymbols.arrowDropDown);
    await tester.tap(arrow);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      true,
    );
    await tester.tap(arrow);
    await tester.pump();
    expect(taps, 2);
  });

  group('code input', () {
    testWidgets('a paste fills every cell and completes', (tester) async {
      String? completed;
      await tester.pumpWidget(
        _app(ExpressiveInputOtp(onCompleted: (v) => completed = v)),
      );
      await tester.enterText(find.byType(EditableText), '482913');
      await tester.pump();
      expect(completed, '482913');
      for (final digit in '482913'.split('')) {
        expect(find.text(digit), findsWidgets);
      }
    });

    testWidgets('keeps digits only, at most its length', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(ExpressiveInputOtp(length: 4, controller: controller)),
      );
      await tester.enterText(find.byType(EditableText), '12a3456');
      await tester.pump();
      expect(controller.text, '1234');
    });

    testWidgets('backspace steps back a cell', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(ExpressiveInputOtp(length: 4, controller: controller)),
      );
      await tester.enterText(find.byType(EditableText), '12');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.text, '1');
    });

    testWidgets('a cell tap keeps the caret at the end of the code', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(ExpressiveInputOtp(length: 4, controller: controller)),
      );
      await tester.enterText(find.byType(EditableText), '123');
      await tester.pump();
      final input = find.byType(EditableText);
      await tester.tapAt(tester.getTopLeft(input) + const Offset(4, 4));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.selection, const TextSelection.collapsed(offset: 3));
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.text, '12');
      await tester.tapAt(tester.getTopLeft(input) + const Offset(4, 4));
      await tester.pump(const Duration(milliseconds: 400));
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: '${controller.text}4',
          selection: const TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();
      expect(controller.text, '124');
      // A selection made some other way collapses back to the end too.
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 2,
      );
      await tester.pump();
      expect(controller.selection, const TextSelection.collapsed(offset: 3));
    });

    testWidgets('shows its error under the cells', (tester) async {
      await tester.pumpWidget(
        _app(const ExpressiveInputOtp(errorText: 'That code has expired')),
      );
      expect(find.byType(ExpressiveFieldError), findsOneWidget);
    });

    testWidgets('a form\'s submit, formatters and autofill reach the input', (
      tester,
    ) async {
      final submitted = <String>[];
      final completed = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: ExpressiveInputOtp(
              length: 4,
              controller: controller,
              textInputAction: TextInputAction.send,
              autofillHints: const <String>[AutofillHints.password],
              // Folds a letter to a digit before the code's own filter.
              inputFormatters: <TextInputFormatter>[
                TextInputFormatter.withFunction(
                  (old, value) =>
                      value.copyWith(text: value.text.replaceAll('o', '0')),
                ),
              ],
              onCompleted: completed.add,
              onSubmitted: submitted.add,
            ),
          ),
        ),
      );
      final input = find.byType(EditableText);
      final editable = tester.widget<EditableText>(input);
      expect(editable.textInputAction, TextInputAction.send);
      expect(editable.autofillHints, const <String>[AutofillHints.password]);
      await tester.enterText(input, '1o2');
      await tester.pump();
      expect(controller.text, '102', reason: 'the caller\'s formatter ran');
      await tester.enterText(input, '1o23');
      await tester.pump();
      expect(completed, <String>['1023']);
      expect(submitted, isEmpty, reason: 'the last digit is onCompleted');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      expect(submitted, <String>['1023']);
    });

    testWidgets('on ui_core\'s code field: a long press offers Paste in '
        'Material\'s toolbar; one node carries its name, length and error', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => switch (call.method) {
          'Clipboard.hasStrings' => <String, Object?>{'value': true},
          'Clipboard.getData' => <String, Object?>{'text': '48 29'},
          _ => null,
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: ExpressiveInputOtp(
              length: 4,
              controller: controller,
              errorText: 'That code has expired',
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(EditableText))
          .getSemanticsData();
      expect(data.label, 'Code, 4 characters');
      expect(data.maxValueLength, 4);
      expect(data.validationResult, SemanticsValidationResult.invalid);

      await tester.longPress(find.byType(ExpressiveInputOtp));
      await tester.pumpAndSettle();
      expect(find.text('Paste'), findsOneWidget);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(controller.text, '4829');
      expect(find.text('Paste'), findsNothing);
      semantics.dispose();
    });
  });

  testWidgets('every form lays out on both platforms at 1.3', (tester) async {
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ]) {
      await tester.pumpWidget(
        _app(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final style in ExpressiveTextFieldKind.values)
                for (final rounded in <bool>[false, true])
                  for (final tonal in <bool>[false, true])
                    ExpressiveTextField(
                      kind: style,
                      rounded: rounded,
                      tonal: tonal,
                      label: 'Label',
                      helperText: 'Supporting',
                    ),
              const ExpressiveFieldError('Something is wrong'),
            ],
          ),
          scale: 1.3,
          platform: platform,
          stretch: true,
        ),
      );
      await tester.tap(_field.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
