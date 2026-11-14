// The package is platform-independent; exercise real editing and scrolling on
// every host platform rather than inferring support from compilation alone.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  testWidgets('pointer hover and keyboard activation respect disabled state', (
    tester,
  ) async {
    final focus = FocusNode();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    var calls = 0;
    var states = <WidgetState>{};
    try {
      Widget press(bool enabled) => ComicPressable(
        label: 'Open issue',
        focusNode: focus,
        onPressed: enabled ? () => calls++ : null,
        builder: (context, next) {
          states = next;
          return const SizedBox(
            width: 100,
            height: 48,
            child: Text('Open issue'),
          );
        },
      );
      await tester.pumpWidget(comicApp(Center(child: press(true))));
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(find.byType(ComicPressable)));
      await tester.pumpAndSettle();
      expect(states, contains(WidgetState.hovered));
      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(calls, 2);
      await tester.pumpWidget(comicApp(Center(child: press(false))));
      await tester.pumpAndSettle();
      expect(states, contains(WidgetState.disabled));
      await tester.tap(find.byType(ComicPressable));
      expect(calls, 2);
    } finally {
      await mouse.removePointer();
      focus.dispose();
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    'platform editing shortcuts and gestures open Comic selection menu',
    (tester) async {
      final controller = TextEditingController(text: 'Read this issue');
      final focus = FocusNode();
      try {
        await tester.pumpWidget(
          comicApp(
            Center(
              child: SizedBox(
                width: 300,
                child: ComicTextField(
                  label: 'Issue title',
                  controller: controller,
                  focusNode: focus,
                ),
              ),
            ),
          ),
        );
        focus.requestFocus();
        await tester.pumpAndSettle();
        final modifier = switch (defaultTargetPlatform) {
          TargetPlatform.macOS ||
          TargetPlatform.iOS => LogicalKeyboardKey.metaLeft,
          _ => LogicalKeyboardKey.controlLeft,
        };
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(modifier);
        await tester.pumpAndSettle();
        expect(
          controller.selection,
          TextSelection(baseOffset: 0, extentOffset: controller.text.length),
        );
        if (comicTouchEditing(defaultTargetPlatform)) {
          await tester.longPressAt(
            tester.getTopLeft(find.byType(EditableText)) + const Offset(15, 12),
          );
        } else {
          await tester.tap(
            find.byType(EditableText),
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
        }
        await tester.pumpAndSettle();
        expect(find.byType(ComicTextContextMenu), findsOneWidget);
        if (controller.selection.isCollapsed) {
          // iOS long-press places the caret; its menu first offers selection.
          expect(find.text('Select all'), findsOneWidget);
          await tester.tap(find.text('Select all'));
          await tester.pumpAndSettle();
          expect(
            controller.selection,
            TextSelection(baseOffset: 0, extentOffset: controller.text.length),
          );
        } else {
          expect(find.text('Copy'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      } finally {
        controller.dispose();
        focus.dispose();
      }
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('scroll physics, bars and overscroll follow the platform', (
    tester,
  ) async {
    final controller = ScrollController();
    try {
      await tester.pumpWidget(
        comicApp(
          ListView.builder(
            controller: controller,
            itemExtent: 80,
            itemCount: 100,
            itemBuilder: (_, index) => Text('Issue $index'),
          ),
        ),
      );
      final context = tester.element(find.byType(ListView));
      final behavior = ScrollConfiguration.of(context);
      expect(behavior, isA<ComicScrollBehavior>());
      final physics = behavior.getScrollPhysics(context);
      final apple =
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      expect(
        physics,
        apple ? isA<BouncingScrollPhysics>() : isA<ClampingScrollPhysics>(),
      );
      final desktop = !comicTouchEditing(defaultTargetPlatform);
      expect(
        find.byType(RawScrollbar),
        desktop ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(StretchingOverscrollIndicator),
        defaultTargetPlatform == TargetPlatform.android
            ? findsOneWidget
            : findsNothing,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      final before = controller.offset;
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(find.byType(ListView)),
          scrollDelta: const Offset(0, 120),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(before));
      expect(tester.takeException(), isNull);
    } finally {
      controller.dispose();
    }
  }, variant: TargetPlatformVariant.all());
}
