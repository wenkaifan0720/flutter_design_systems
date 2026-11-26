// Comic on each platform's own terms, by behaviour. Android: the system back closes what is raised (a dialog, a
// bottom sheet, a side sheet, a drawer, a menu) before it pops the page under it. A desk (macOS, Windows, Linux, and
// the web on them): the Tab key reaches every control that takes input and passes over one that is off, the pointer
// turns to a hand over what presses and to a text cursor over a field, and the controls stand on Comic's one floor, a
// finger's and a pointer's alike. (iOS's edge swipe: page_motion_test.dart.)
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

const _desks = TargetPlatformVariant({
  TargetPlatform.macOS,
  TargetPlatform.windows,
  TargetPlatform.linux,
});

Widget _app(GlobalKey<NavigatorState> navigator) => MaterialApp(
  navigatorKey: navigator,
  builder: (context, child) =>
      ComicTheme(data: ComicThemeData.offset(), child: child!),
  home: const ComicScaffold(body: Text('The first page')),
);

Route<void> _second() => MaterialPageRoute<void>(
  builder: (context) => const ComicScaffold(
    topBar: ComicAppBar(title: 'The second page'),
    body: Text('Its words'),
  ),
);

/// Android's back button or gesture, as the platform sends it.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// Each control under a name, so a focus or a pointer can be traced to it.
Widget _controls() => ComicColumn(
  gap: 12,
  children: [
    for (final (name, control) in <(String, Widget)>[
      ('button', ComicButton.filled('Save', onPressed: () {})),
      ('off', const ComicButton.filled('Off', onPressed: null)),
      (
        'icon button',
        ComicIconButton(ComicGlyphs.bell, label: 'Alerts', onPressed: () {}),
      ),
      (
        'checkbox',
        ComicCheckbox(label: 'Keep issue', value: true, onChanged: (_) {}),
      ),
      ('switch', ComicSwitch(value: true, onChanged: (_) {})),
      ('link', ComicLink('Read the issue', onPressed: () {})),
      (
        'field',
        const SizedBox(
          width: 300,
          child: ComicTextField(hintText: 'Your name'),
        ),
      ),
      (
        'select',
        SizedBox(
          width: 300,
          child: ComicSelect<String>(
            labelText: 'Format',
            value: 'print',
            onChanged: (_) {},
            options: const [
              ComicSelectOption('print', 'Print'),
              ComicSelectOption('screen', 'Screen'),
            ],
          ),
        ),
      ),
    ])
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: KeyedSubtree(key: ValueKey(name), child: control),
      ),
  ],
);

/// The name of the control [context] stands in, if any.
String? _nameOf(BuildContext? context) {
  String? name;
  context?.visitAncestorElements((element) {
    final key = element.widget.key;
    if (element.widget is KeyedSubtree && key is ValueKey<String>) {
      name = key.value;
      return false;
    }
    return true;
  });
  return name;
}

void main() {
  setUpAll(loadComicFonts);

  testWidgets(
    'the system back closes what is raised first, then pops the page',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app(navigator));
      navigator.currentState!.push(_second()).ignore();
      await tester.pumpAndSettle();
      final page = tester.element(find.text('Its words'));
      for (final (what, raise) in <(String, void Function())>[
        (
          'a dialog',
          () => showComicDialog<void>(
            page,
            builder: (_) => const Text('Raised'),
          ).ignore(),
        ),
        (
          'a bottom sheet',
          () => showComicBottomSheet<void>(
            page,
            builder: (_) => const Text('Raised'),
          ).ignore(),
        ),
        (
          'a side sheet',
          () => showComicSheet<void>(
            page,
            builder: (_) =>
                const ComicSheet(title: 'Filters', child: Text('Raised')),
          ).ignore(),
        ),
        (
          'a drawer',
          () => showComicNavigationDrawer<void>(
            page,
            builder: (_) => const Text('Raised'),
          ).ignore(),
        ),
        (
          'a menu',
          () => showComicMenu<String>(
            page,
            anchor: const Rect.fromLTWH(20, 120, 160, 40),
            items: const [ComicMenuItem('raised', 'Raised')],
          ).ignore(),
        ),
      ]) {
        raise();
        await tester.pumpAndSettle();
        expect(find.text('Raised'), findsOneWidget, reason: what);
        await _systemBack(tester);
        expect(find.text('Raised'), findsNothing, reason: '$what stayed up');
        expect(
          find.text('Its words'),
          findsOneWidget,
          reason: 'back took the page away with $what',
        );
      }
      await _systemBack(tester);
      expect(find.text('Its words'), findsNothing);
      expect(find.text('The first page'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    "the system back closes an open list or popover first: a list's field keeps the focus, a popover's anchor gets it back",
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app(navigator));
      navigator.currentState!
          .push(
            MaterialPageRoute<void>(
              builder: (context) => ComicScaffold(
                topBar: const ComicAppBar(title: 'The second page'),
                body: ComicColumn(
                  gap: 16,
                  children: [
                    const Text('Its words'),
                    const SizedBox(
                      width: 300,
                      child: ComicCombobox<String>(
                        labelText: 'City',
                        options: ['Paris', 'Porto', 'Lisbon'],
                      ),
                    ),
                    // From 600 wide a button keeps to its words at the start of a stretched column's room.
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ComicPopover(
                        anchorBuilder: (context, a) => ComicButton(
                          'Filter',
                          key: const ValueKey('filter'),
                          onPressed: a.toggle,
                        ),
                        builder: (context, close) => const Text('Only unread'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .ignore();
      await tester.pumpAndSettle();
      final field = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;
      await tester.showKeyboard(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsOneWidget, reason: 'the list is open');
      await _systemBack(tester);
      expect(find.text('Lisbon'), findsNothing, reason: 'the list stayed open');
      expect(field.hasFocus, isTrue);
      expect(find.text('Its words'), findsOneWidget);
      // A popover opened by a finger: back closes it, the page stays. (The label is lettered in capitals: the button is
      // found by its key.)
      await tester.tap(find.byKey(const ValueKey('filter')));
      await tester.pumpAndSettle();
      expect(find.text('Only unread'), findsOneWidget);
      await _systemBack(tester);
      expect(find.text('Only unread'), findsNothing);
      expect(find.text('Its words'), findsOneWidget);
      // Opened from the keyboard (Tab to its anchor, Enter): back closes it and the anchor has the focus.
      Key? focusedButton() => FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<ComicButton>()
          ?.key;
      for (
        var i = 0;
        i < 6 && focusedButton() != const ValueKey('filter');
        i++
      ) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focusedButton(), const ValueKey('filter'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Only unread'), findsOneWidget);
      await _systemBack(tester);
      expect(find.text('Only unread'), findsNothing);
      expect(find.text('Its words'), findsOneWidget);
      expect(
        focusedButton(),
        const ValueKey('filter'),
        reason: "the popover's anchor did not get the focus back",
      );
      await _systemBack(tester);
      expect(find.text('Its words'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'at a desk the Tab key reaches every control that takes input, and passes over one that is off',
    (tester) async {
      await tester.pumpWidget(comicApp(_controls()));
      final reached = <String>[];
      for (var i = 0; i < 16; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final name = _nameOf(FocusManager.instance.primaryFocus?.context);
        if (name != null && !reached.contains(name)) reached.add(name);
      }
      expect(reached, [
        'button',
        'icon button',
        'checkbox',
        'switch',
        'link',
        'field',
        'select',
      ]);
    },
    variant: _desks,
  );

  testWidgets(
    'at a desk the pointer is a hand over what presses, a text cursor over a field, the arrow over a part that is off',
    (tester) async {
      await tester.pumpWidget(comicApp(_controls()));
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      for (final (name, cursor) in [
        ('button', SystemMouseCursors.click),
        ('icon button', SystemMouseCursors.click),
        ('checkbox', SystemMouseCursors.click),
        ('switch', SystemMouseCursors.click),
        ('link', SystemMouseCursors.click),
        ('select', SystemMouseCursors.click),
        ('field', SystemMouseCursors.text),
        ('off', SystemMouseCursors.basic),
      ]) {
        await mouse.moveTo(tester.getCenter(find.byKey(ValueKey(name))));
        await tester.pump();
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          cursor,
          reason: name,
        );
      }
    },
    variant: _desks,
  );

  testWidgets(
    "the controls stand on Comic's one floor, 40, at a desk and on a phone",
    (tester) async {
      await tester.pumpWidget(comicApp(_controls()));
      // One floor for a finger and a pointer alike: ui_core's finger floor, 40.
      final floor = ComicTapTarget.targets.touch.shortestSide;
      expect(floor, 40);
      expect(ComicTapTarget.targets.pointer, ComicTapTarget.targets.touch);
      final icon = tester.getSize(find.byKey(const ValueKey('icon button')));
      expect(icon.shortestSide, floor, reason: 'the icon button');
      for (final name in ['button', 'checkbox', 'switch', 'link', 'select']) {
        expect(
          tester.getSize(find.byKey(ValueKey(name))).height,
          greaterThanOrEqualTo(floor),
          reason: name,
        );
      }
    },
    variant: TargetPlatformVariant.all(),
  );
}
