// The text field's handles and menu are Neumorphism's own on every platform: the rounded handles and the soft strip on a
// phone, the card menu on a desktop, each word from NeumorphicLocalizations; none of Material's toolbars ever shows.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Finder get _handles => find.byWidgetPredicate(
  (w) =>
      w is CustomPaint && w.painter.runtimeType.toString() == '_HandlePainter',
);

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _test(String description, WidgetTesterCallback body) =>
    testWidgets(description, body, variant: TargetPlatformVariant.all());

bool get _touch => const {
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.fuchsia,
}.contains(defaultTargetPlatform);

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final set in const ['look']) {
    for (final (densityName, density) in [
      ('standard', NeumorphicDensity.standard),
      ('comfortable', NeumorphicDensity.comfortable),
      ('compact', NeumorphicDensity.compact),
    ]) {
      for (final width in [120.0, 240.0, 390.0]) {
        for (final scale in [1.0, 1.3]) {
          _test(
            'editing menu $set $densityName contains paint at $width $scale',
            (tester) async {
              tester.view.physicalSize = Size(width, 640);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                neumorphicApp(
                  NeumorphicTheme(
                    data: NeumorphicThemeData.porcelain().copyWith(
                      density: density,
                    ),
                    child: NeumorphicTextContextMenu(
                      anchors: TextSelectionToolbarAnchors(
                        primaryAnchor: Offset(width / 2, 320),
                      ),
                      buttonItems: [
                        ContextMenuButtonItem(
                          type: ContextMenuButtonType.copy,
                          onPressed: () {},
                        ),
                        ContextMenuButtonItem(
                          type: ContextMenuButtonType.paste,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  textScale: scale,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              final plate = find
                  .descendant(
                    of: find.byType(NeumorphicTextContextMenu),
                    matching: find.byWidgetPredicate(
                      (w) =>
                          w is DecoratedBox && w.decoration is ShapeDecoration,
                    ),
                  )
                  .first;
              final render = tester.renderObject<RenderBox>(plate);
              final shape =
                  (tester.widget<DecoratedBox>(plate).decoration
                          as ShapeDecoration)
                      .shape;
              final path = shape.getOuterPath(Offset.zero & render.size);
              for (final text in ['Copy', 'Paste']) {
                final child = tester.renderObject<RenderBox>(find.text(text));
                final bounds = MatrixUtils.transformRect(
                  child.getTransformTo(render),
                  child.paintBounds,
                ).deflate(1);
                for (final point in [
                  bounds.topLeft,
                  bounds.topCenter,
                  bounds.topRight,
                  bounds.centerRight,
                  bounds.bottomRight,
                  bounds.bottomCenter,
                  bounds.bottomLeft,
                  bounds.centerLeft,
                ]) {
                  expect(
                    path.contains(point),
                    isTrue,
                    reason: '$text $point outside ${render.size} $shape',
                  );
                }
              }
            },
          );
        }
      }
    }
  }

  for (final direction in TextDirection.values) {
    _test('long editing actions at 2x ${direction.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var pressed = -1;
      final labels = [for (var i = 0; i < 3; i++) '$i $longLine'];
      await tester.pumpWidget(
        neumorphicApp(
          NeumorphicTextContextMenu(
            anchors: const TextSelectionToolbarAnchors(
              primaryAnchor: Offset(160, 240),
            ),
            buttonItems: [
              for (var i = 0; i < labels.length; i++)
                ContextMenuButtonItem(
                  label: labels[i],
                  onPressed: () => pressed = i,
                ),
            ],
          ),
          textScale: 2,
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < labels.length; i++) {
        final text = find.text(labels[i]);
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.didExceedMaxLines, isFalse);
        await tester.ensureVisible(text);
        await tester.pumpAndSettle();
        await tester.tap(text);
        expect(pressed, i);
      }
      expect(tester.takeException(), isNull);
    });
  }

  _test(
    'platform editing gesture opens the own menu and copies its selection',
    (tester) async {
      final controller = TextEditingController(text: 'Pepper and salt');
      addTearDown(controller.dispose);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') {
            return <String, Object?>{'text': copied};
          }
          if (call.method == 'Clipboard.hasStrings') {
            return <String, bool>{'value': copied?.isNotEmpty ?? false};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        neumorphicApp(
          Padding(
            padding: const EdgeInsets.all(24),
            child: NeumorphicTextField(controller: controller),
          ),
        ),
      );
      final at =
          tester.getTopLeft(find.byType(EditableText)) + const Offset(12, 8);
      if (_touch && defaultTargetPlatform != TargetPlatform.iOS) {
        await tester.longPressAt(at);
      } else {
        final kind = _touch ? PointerDeviceKind.touch : PointerDeviceKind.mouse;
        await tester.tapAt(at, kind: kind);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(at, kind: kind);
      }
      await _frames(tester);
      if (!_touch) {
        await tester.tapAt(
          at,
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await _frames(tester);
      }
      expect(controller.selection.isCollapsed, isFalse);
      final selected = controller.selection.textInside(controller.text);
      expect(find.byType(NeumorphicTextContextMenu), findsOneWidget);
      expect(find.byType(TextSelectionToolbar), findsNothing);
      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
      expect(_handles, _touch ? findsWidgets : findsNothing);
      final day = NeumorphicThemeData.preset('porcelain', Brightness.light);
      final face = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(NeumorphicTextContextMenu),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = face.decoration as ShapeDecoration;
      expect(decoration.color, day.colors.ground);
      // No printed rim: the relief draws the menu's edge.
      expect((decoration.shape as OutlinedBorder).side, BorderSide.none);
      expect(decoration.shadows!.map((shadow) => shadow.color), [
        day.colors.highlight,
        day.colors.shadow,
      ]);
      await tester.tap(find.text('Copy'));
      await _frames(tester);
      expect(copied, selected);
      expect(find.byType(NeumorphicTextContextMenu), findsNothing);
    },
  );

  _test('Cmd or Ctrl editing shortcuts select, copy, cut and paste', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Pepper and salt');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        if (call.method == 'Clipboard.getData') {
          return <String, Object?>{'text': clipboard};
        }
        if (call.method == 'Clipboard.hasStrings') {
          return <String, bool>{'value': clipboard?.isNotEmpty ?? false};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      neumorphicApp(
        NeumorphicTextField(controller: controller, focusNode: focus),
      ),
    );
    focus.requestFocus();
    await _frames(tester);
    final apple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final modifier = apple
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    Future<void> shortcut(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(modifier);
      await _frames(tester);
    }

    await shortcut(LogicalKeyboardKey.keyA);
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 15),
    );
    await shortcut(LogicalKeyboardKey.keyC);
    expect(clipboard, 'Pepper and salt');
    await shortcut(LogicalKeyboardKey.keyX);
    expect(controller.text, isEmpty);
    await shortcut(LogicalKeyboardKey.keyV);
    expect(controller.text, 'Pepper and salt');
    expect(tester.takeException(), isNull);
  });

  _test('every kind of menu item has its word, and no items is no menu', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      neumorphicApp(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    for (final type in ContextMenuButtonType.values) {
      final word = NeumorphicTextContextMenu.labelOf(
        context,
        ContextMenuButtonItem(type: type, onPressed: () {}),
      );
      expect(
        word.isEmpty,
        type == ContextMenuButtonType.custom,
        reason: type.name,
      );
    }
    expect(
      NeumorphicTextContextMenu.labelOf(
        context,
        ContextMenuButtonItem(label: 'Pin', onPressed: () {}),
      ),
      'Pin',
    );
    await tester.pumpWidget(
      neumorphicApp(
        const NeumorphicTextContextMenu(
          anchors: TextSelectionToolbarAnchors(primaryAnchor: Offset(100, 100)),
          buttonItems: [],
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(NeumorphicTextContextMenu),
        matching: find.byType(DesignPressable),
      ),
      findsNothing,
    );
  });

  test('each platform gets touch handles or an empty desktop handle', () {
    for (final platform in TargetPlatform.values) {
      final touch = const {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.fuchsia,
      }.contains(platform);
      final controls = NeumorphicTextSelectionControls.of(platform);
      expect(
        controls,
        same(
          touch
              ? NeumorphicTextSelectionControls.touch
              : NeumorphicTextSelectionControls.desktop,
        ),
      );
      expect(controls.getHandleSize(20), touch ? isNot(Size.zero) : Size.zero);
      expect(
        controls.getHandleAnchor(TextSelectionHandleType.left, 20),
        isA<Offset>(),
      );
    }
  });
}
