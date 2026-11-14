import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

typedef _Button = Widget Function(bool busy, VoidCallback? action);
void main() {
  setUpAll(loadNeumorphicFonts);
  final buttons = <String, _Button>{
    'act': (busy, action) =>
        NeumorphicButton.filled('Save', busy: busy, onPressed: action),
    'line': (busy, action) =>
        NeumorphicButton('Save', busy: busy, onPressed: action),
    'quiet': (busy, action) =>
        NeumorphicButton.text('Save', busy: busy, onPressed: action),
    'danger': (busy, action) => NeumorphicButton(
      'Save',
      isDestructiveAction: true,
      busy: busy,
      onPressed: action,
    ),
    'button': (busy, action) =>
        NeumorphicButton('Save', busy: busy, onPressed: action),
  };
  for (final entry in buttons.entries) {
    testWidgets(
      '${entry.key} busy state keeps width and focus but blocks activation',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          var busy = false;
          var count = 0;
          late StateSetter update;
          await tester.pumpWidget(
            neumorphicApp(
              MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Center(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      update = setState;
                      return entry.value(busy, () => count++);
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          final size = tester.getSize(find.byType(DesignPressable));
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(count, 1);
          update(() => busy = true);
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byType(DesignPressable)), size);
          expect(
            tester
                .state<DesignPressableState>(find.byType(DesignPressable))
                .states,
            contains(WidgetState.focused),
          );
          expect(
            tester.getSemantics(find.bySemanticsLabel('Save')).value,
            isNotEmpty,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(count, 1);
          update(() => busy = false);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          expect(count, 2);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
  final delayedButtons = <Widget Function(bool, bool, FocusNode, VoidCallback)>[
    (busy, shown, node, action) => NeumorphicButton.filled(
      'Continue',
      busy: busy,
      showBusy: shown,
      focusNode: node,
      onPressed: action,
    ),
    (busy, shown, node, action) => NeumorphicButton(
      'Continue',
      busy: busy,
      showBusy: shown,
      focusNode: node,
      onPressed: action,
    ),
    (busy, shown, node, action) => NeumorphicButton.text(
      'Continue',
      busy: busy,
      showBusy: shown,
      focusNode: node,
      onPressed: action,
    ),
    (busy, shown, node, action) => NeumorphicButton(
      'Continue',
      isDestructiveAction: true,
      busy: busy,
      showBusy: shown,
      focusNode: node,
      onPressed: action,
    ),
    (busy, shown, node, action) => NeumorphicButton(
      'Continue',
      busy: busy,
      showBusy: shown,
      focusNode: node,
      onPressed: action,
    ),
  ];
  for (final (index, button) in delayedButtons.indexed) {
    testWidgets(
      'button $index retains its resting face until progress is shown',
      (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);
        var busy = false, shown = false;
        var calls = 0;
        late StateSetter update;
        await tester.pumpWidget(
          neumorphicApp(
            Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return button(busy, shown, node, () => calls++);
                },
              ),
            ),
          ),
        );
        node.requestFocus();
        await tester.pumpAndSettle();
        final resting = tester.getSize(find.byType(DesignPressable));
        update(() => busy = true);
        await tester.pump(const Duration(milliseconds: 200));
        expect(node.hasFocus, isTrue);
        expect(find.byType(NeumorphicCircularProgressIndicator), findsNothing);
        expect(tester.getSize(find.byType(DesignPressable)), resting);
        expect(tester.hasRunningAnimations, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(calls, 0);
        update(() => shown = true);
        await tester.pump();
        expect(
          find.byType(NeumorphicCircularProgressIndicator),
          findsOneWidget,
        );
        expect(node.hasFocus, isTrue);
        update(() => busy = false);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(calls, 1);
      },
    );
  }
  testWidgets('chip deletion is independently labelled and activated', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var presses = 0, deletes = 0;
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicChip(
              'Studio',
              onPressed: () => presses++,
              onDeleted: () => deletes++,
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Delete Studio'));
      await tester.pumpAndSettle();
      expect(deletes, 1);
      expect(presses, 0);
      await tester.tap(find.text('Studio'));
      await tester.pumpAndSettle();
      expect(presses, 1);
      await tester.pumpWidget(
        neumorphicApp(
          NeumorphicChip(
            'Studio',
            enabled: false,
            onPressed: () => presses++,
            onDeleted: () => deletes++,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(presses, 1);
      expect(deletes, 1);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('chip selection stays explicit and keeps keyboard focus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var selected = false;
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: StatefulBuilder(
              builder: (context, update) => NeumorphicChip(
                'Terrace',
                selected: selected,
                onPressed: () => update(() => selected = !selected),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus;
      for (final expected in [false, true, false]) {
        expect(selected, expected);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Terrace'))
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          expected ? Tristate.isTrue : Tristate.isFalse,
        );
        expect(FocusManager.instance.primaryFocus, same(focus));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
      }
    } finally {
      semantics.dispose();
    }
  });
  for (final size in NeumorphicButtonSize.values) {
    check(
      'button size ${size.name}',
      () => Column(
        children: [
          NeumorphicButton.filled(longLine, size: size, onPressed: () {}),
          NeumorphicButton(longLine, size: size, onPressed: () {}),
          NeumorphicButton.text(longLine, size: size, onPressed: () {}),
          NeumorphicButton(
            longLine,
            isDestructiveAction: true,
            size: size,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
  check(
    'removable chip',
    () => NeumorphicChip(
      longLine,
      selected: true,
      onPressed: () {},
      onDeleted: () {},
    ),
  );

  // Held in with its words hidden as well, a busy key with a ring alone read as an empty field: a key with a glyph
  // turns the ring in the glyph's place and keeps its words, at its width.
  final glyphKeys = <String, Widget Function(bool busy)>{
    'act': (busy) => NeumorphicButton.filled(
      'Uploading',
      icon: NeumorphicGlyphs.upload,
      busy: busy,
      onPressed: () {},
    ),
    'line': (busy) => NeumorphicButton(
      'Uploading',
      icon: NeumorphicGlyphs.upload,
      busy: busy,
      onPressed: () {},
    ),
    'quiet': (busy) => NeumorphicButton.text(
      'Uploading',
      icon: NeumorphicGlyphs.upload,
      busy: busy,
      onPressed: () {},
    ),
  };
  for (final entry in glyphKeys.entries) {
    testWidgets('${entry.key} busy key with a glyph keeps its words', (
      tester,
    ) async {
      Future<void> show(bool busy) async {
        await tester.pumpWidget(
          neumorphicApp(
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Center(child: entry.value(busy)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
      }

      await show(false);
      final size = tester.getSize(find.byType(DesignPressable));
      await show(true);
      expect(tester.getSize(find.byType(DesignPressable)), size);
      expect(find.text('Uploading'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Uploading'),
          matching: find.byWidgetPredicate(
            (w) => w is Opacity && w.opacity == 0,
          ),
        ),
        findsNothing,
      );
      expect(find.byIcon(NeumorphicGlyphs.upload), findsNothing);
      expect(find.byType(NeumorphicCircularProgressIndicator), findsOneWidget);
    });
  }
}
