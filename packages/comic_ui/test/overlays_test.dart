// ui_core's overlays in Comic's parts: the tooltip on Flutter's RawTooltip, a shortcut's keys in words, and a
// combobox's and a multi-select's search that takes time or fails.
import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

const _control = ValueKey('control');

void main() {
  setUpAll(loadComicFonts);

  testWidgets(
    'a tooltip waits 400 ms, stands under its control, centred, and Escape hides it',
    (tester) async {
      await tester.pumpWidget(
        comicApp(
          const Center(
            child: ComicTooltip(
              message: 'Save this issue',
              child: SizedBox(key: _control, width: 48, height: 48),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(_control)).tooltip,
        'Save this issue',
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(_control)));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ComicTooltipFace), findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(ComicTooltipFace), findsOneWidget);
      final control = tester.getRect(find.byKey(_control));
      final tip = tester.getRect(find.byType(ComicTooltipFace));
      expect(tip.top, moreOrLessEquals(control.bottom + 6, epsilon: .5));
      expect(tip.center.dx, moreOrLessEquals(control.center.dx, epsilon: .5));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ComicTooltipFace), findsNothing);
    },
  );

  // The tip joins the tipped key's own node, as the published tooltip made it: a screen reader hears the key's name,
  // its tip and that it is a button together, and no node round it takes the tip.
  for (final (name, label, key) in [
    (
      'ComicIconButton',
      'Save',
      ComicIconButton(Icons.bookmark, label: 'Save', onPressed: () {}),
    ),
    ('ComicButton', 'Save', ComicButton('Save', onPressed: () {})),
  ]) {
    testWidgets(
      "a tipped $name's own node carries its label, its tip and that it is a button",
      (tester) async {
        final semantics = tester.ensureSemantics();
        const tip = 'Save to your collection';
        await tester.pumpWidget(
          comicApp(
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Issue 12'),
                  ComicTooltip(message: tip, child: key),
                ],
              ),
            ),
          ),
        );
        final node = tester.getSemantics(find.byWidget(key));
        expect(
          node,
          isSemantics(
            label: label,
            tooltip: tip,
            isButton: true,
            hasTapAction: true,
          ),
        );
        var root = node;
        while (root.parent != null) {
          root = root.parent!;
        }
        final saying = <SemanticsNode>[];
        void visit(SemanticsNode n) {
          final data = n.getSemanticsData();
          if (data.tooltip.contains(tip) || data.label.contains(tip)) {
            saying.add(n);
          }
          n.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        visit(root);
        expect(saying, [node]);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    "a shortcut's keys come in words, as the platform orders them",
    (tester) async {
      late String label, enter;
      await tester.pumpWidget(
        comicApp(
          Builder(
            builder: (context) {
              label = ComicKbd.labelOf(
                context,
                const SingleActivator(
                  LogicalKeyboardKey.keyN,
                  meta: true,
                  shift: true,
                ),
              );
              enter = ComicKbd.labelOf(
                context,
                const SingleActivator(LogicalKeyboardKey.enter, shift: true),
              );
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ComicKbd.shortcut(
                    SingleActivator(LogicalKeyboardKey.keyK, control: true),
                  ),
                  ComicKbd.shortcut(
                    SingleActivator(LogicalKeyboardKey.enter, shift: true),
                  ),
                ],
              );
            },
          ),
        ),
      );
      final apple = defaultTargetPlatform == TargetPlatform.macOS;
      // Comic's faces draw none of Apple's key symbols, so a Mac reads words too.
      expect(label, apple ? 'Shift+Command+N' : 'Meta+Shift+N');
      // Enter in words everywhere: ui_core's ↵ off Apple's platforms is a glyph Comic's faces lack.
      expect(enter, 'Shift+Enter');
      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(find.bySemanticsLabel('Shift plus Enter'), findsOneWidget);
      expect(find.textContaining(RegExp('[⌃⌥⇧⌘↵]')), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    "a combobox's search says it is looking, then that it failed; Try again asks again, by the pointer or the keys",
    (tester) async {
      final asked = <Completer<Iterable<String>>>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        comicApp(
          Padding(
            padding: const EdgeInsets.all(16),
            child: ComicCombobox<String>(
              label: 'City',
              options: const [],
              focusNode: focus,
              search: (query) {
                asked.add(Completer());
                return asked.last.future;
              },
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Lis');
      await tester.pump();
      expect(find.text('Loading'), findsOneWidget);
      asked.last.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load results"), findsOneWidget);
      expect(focus.hasFocus, isTrue);
      final count = asked.length;
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(asked, hasLength(count + 1));
      asked.last.completeError(StateError('still offline'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(asked, hasLength(count + 2));
      asked.last.complete(const ['Lisbon']);
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text("Couldn't load results"), findsNothing);
    },
  );

  testWidgets("a combobox over its own options never says it is looking", (
    tester,
  ) async {
    await tester.pumpWidget(
      comicApp(
        const Padding(
          padding: EdgeInsets.all(16),
          child: ComicCombobox<String>(
            label: 'City',
            options: ['Lisbon', 'London'],
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'L');
    await tester.pump();
    expect(find.text('Loading'), findsNothing);
    expect(find.text('Lisbon'), findsOneWidget);
  });

  testWidgets(
    "a multi-select's search says it is looking, and that it failed",
    (tester) async {
      final asked = <Completer<Iterable<String>>>[];
      await tester.pumpWidget(
        comicApp(
          Padding(
            padding: const EdgeInsets.all(16),
            child: ComicMultiSelect<String>(
              label: 'Genres',
              values: const [],
              onChanged: (_) {},
              search: (query) {
                asked.add(Completer());
                return asked.last.future;
              },
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'No');
      await tester.pump();
      expect(find.text('Loading'), findsOneWidget);
      asked.last.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load results"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    },
  );
}
