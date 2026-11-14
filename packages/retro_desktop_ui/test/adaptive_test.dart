import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoApp, CupertinoScrollbar, CupertinoScrollBehavior;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Widget _host(
  Widget child, {
  TargetPlatform? platform,
  double scale = 1,
  bool reduceMotion = false,
  RetroDesktopThemeData? look,
}) => MaterialApp(
  theme: ThemeData(platform: platform),
  home: RetroDesktopTheme(
    data: look ?? RetroDesktopThemeData.classic(),
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduceMotion,
        ),
        child: child,
      ),
    ),
  ),
);

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final app in ['widgets', 'material', 'cupertino']) {
    testWidgets(
      '$app uses themed scrollbars and preserves its scrolling policy',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final theme = RetroDesktopThemeData.classic();
        final list = ListView.builder(
          controller: controller,
          itemExtent: 60,
          itemCount: 30,
          itemBuilder: (_, index) => Text('Line $index'),
        );
        Widget skin(Widget child) =>
            RetroDesktopTheme(data: theme, child: child);
        await tester.pumpWidget(switch (app) {
          'material' => MaterialApp(
            home: list,
            builder: (_, child) => skin(child!),
          ),
          'cupertino' => CupertinoApp(
            home: list,
            builder: (_, child) => skin(child!),
          ),
          _ => WidgetsApp(
            color: const Color(0xff000000),
            builder: (_, _) => skin(list),
          ),
        });
        final desktop = switch (defaultTargetPlatform) {
          TargetPlatform.linux ||
          TargetPlatform.macOS ||
          TargetPlatform.windows => true,
          _ => false,
        };
        expect(find.byType(CupertinoScrollbar), findsNothing);
        expect(find.byType(Scrollbar), findsNothing);
        expect(
          find.byType(RawScrollbar),
          desktop ? findsOneWidget : findsNothing,
        );
        if (desktop) {
          final scrollbar = tester.widget<RawScrollbar>(
            find.byType(RawScrollbar),
          );
          expect(scrollbar.radius, isNull);
          expect(scrollbar.shape, theme.shapes.full);
          expect(scrollbar.thumbColor, theme.colors.highlight);
          expect(scrollbar.fadeDuration, Duration.zero);
        }
        bool contains<T extends ScrollPhysics>(ScrollPhysics? value) =>
            value != null && (value is T || contains<T>(value.parent));
        final bounces =
            app == 'cupertino' ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS;
        expect(
          contains<BouncingScrollPhysics>(controller.position.physics),
          bounces,
        );
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.all(),
    );
  }

  testWidgets('an explicit host scrollbar opt-out is preserved', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        scrollBehavior: const CupertinoScrollBehavior().copyWith(
          scrollbars: false,
        ),
        builder: (_, child) => RetroDesktopTheme(
          data: RetroDesktopThemeData.classic(),
          child: child!,
        ),
        home: ListView(
          controller: controller,
          children: const [SizedBox(height: 2000)],
        ),
      ),
    );
    expect(find.byType(RawScrollbar), findsNothing);
    expect(find.byType(CupertinoScrollbar), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());

  testWidgets('platform command selects all and copies through the editor', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'First second');
    addTearDown(controller.dispose);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        if (call.method == 'Clipboard.hasStrings') return {'value': true};
        if (call.method == 'Clipboard.getData') return {'text': 'Clipboard'};
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
      _host(
        Center(
          child: SizedBox(
            width: 300,
            child: RetroDesktopTextField(
              label: 'Document',
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    final command = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => LogicalKeyboardKey.metaLeft,
      _ => LogicalKeyboardKey.controlLeft,
    };
    await tester.sendKeyDownEvent(command);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(command);
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 12),
    );
    await tester.sendKeyDownEvent(command);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(command);
    await tester.pump();
    expect(copied, 'First second');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());

  testWidgets('touch and secondary click open the look selection menu', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Editable document');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('en', 'GB'),
            child: RetroDesktopTheme(
              data: RetroDesktopThemeData.berry(),
              child: Center(
                child: SizedBox(
                  width: 300,
                  child: RetroDesktopTextField(
                    label: 'Document',
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
        ),
        scale: 2,
        reduceMotion: true,
      ),
    );
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.cursorRadius, Radius.zero);
    expect(editor.cursorOpacityAnimates, isFalse);
    final touch = retroDesktopTouchEditing(defaultTargetPlatform);
    expect(
      editor.selectionControls,
      same(
        touch
            ? RetroDesktopTextSelectionControls.touch
            : RetroDesktopTextSelectionControls.desktop,
      ),
    );
    if (touch) {
      await tester.longPress(find.byType(EditableText));
    } else {
      await tester.tapAt(
        tester.getCenter(find.byType(EditableText)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
    }
    await tester.pumpAndSettle();
    expect(find.byType(RetroDesktopTextContextMenu), findsOneWidget);
    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
    final menuContext = tester.element(
      find.byType(RetroDesktopTextContextMenu),
    );
    expect(RetroDesktopTheme.of(menuContext).id, 'berry');
    expect(Localizations.localeOf(menuContext), const Locale('en', 'GB'));
    expect(MediaQuery.textScalerOf(menuContext).scale(10), 20);
    expect(MediaQuery.disableAnimationsOf(menuContext), isTrue);
    for (final decoration in [
      GlowingOverscrollIndicator,
      StretchingOverscrollIndicator,
    ]) {
      expect(
        find.descendant(
          of: find.byType(RetroDesktopTextContextMenu),
          matching: find.byType(decoration),
        ),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    'installed platform controls menu layout at 2x in a narrow view',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Deliberately differs from each variant's host platform.
      final installed = retroDesktopTouchEditing(defaultTargetPlatform)
          ? TargetPlatform.windows
          : TargetPlatform.android;
      final touch = retroDesktopTouchEditing(installed);
      await tester.pumpWidget(
        _host(
          RetroDesktopTextContextMenu(
            anchors: const TextSelectionToolbarAnchors(
              primaryAnchor: Offset(180, 300),
            ),
            buttonItems: [
              for (final label in [
                'Cut selection',
                'Copy selection',
                'Paste clipboard',
                'Select every word',
              ])
                ContextMenuButtonItem(label: label, onPressed: () {}),
            ],
          ),
          platform: installed,
          scale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      final horizontal = tester
          .widgetList<SingleChildScrollView>(
            find.descendant(
              of: find.byType(RetroDesktopTextContextMenu),
              matching: find.byType(SingleChildScrollView),
            ),
          )
          .where((view) => view.scrollDirection == Axis.horizontal);
      expect(horizontal.length, touch ? 1 : 0);
      for (final target in find.byType(RetroDesktopPressable).evaluate()) {
        final size = tester.getSize(find.byWidget(target.widget));
        expect(size.width, greaterThanOrEqualTo(touch ? 48 : 44));
        expect(size.height, greaterThanOrEqualTo(touch ? 48 : 44));
      }
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    'touch drag shows and removes the owned editing lens',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const Center(
            child: SizedBox(
              width: 300,
              child: RetroDesktopTextField(initial: 'Drag this selection'),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(EditableText)),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(18, 0));
      await tester.pump();
      expect(find.byType(RawMagnifier), findsOneWidget);
      expect(find.byType(TextMagnifier), findsNothing);
      expect(find.byType(Magnifier), findsNothing);
      expect(tester.takeException(), isNull);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(RawMagnifier), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('editing lens owns its frame and stays above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final info = ValueNotifier<MagnifierInfo>(
      const MagnifierInfo(
        globalGesturePosition: Offset(-200, -100),
        caretRect: Rect.fromLTWH(22, 10, 2, 20),
        fieldBounds: Rect.fromLTWH(0, 0, 390, 120),
        currentLineBoundaries: Rect.fromLTWH(20, 10, 340, 20),
      ),
    );
    addTearDown(info.dispose);
    await tester.pumpWidget(
      _host(
        const RetroDesktopTextField(hint: 'Drag words'),
        reduceMotion: true,
        look: RetroDesktopThemeData.classic().copyWith(
          motion: const RetroDesktopMotion(move: Duration(milliseconds: 200)),
        ),
      ),
    );
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    final lens = editor.magnifierConfiguration.magnifierBuilder(
      tester.element(find.byType(EditableText)),
      MagnifierController(),
      info,
    );
    if (!retroDesktopTouchEditing(defaultTargetPlatform)) {
      expect(lens, isNull);
      return;
    }
    expect(lens, isNotNull);
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
              viewInsets: const EdgeInsets.only(bottom: 280),
            ),
            child: Stack(children: [lens!]),
          ),
        ),
      ),
    );
    void check(Offset focalPoint) {
      final raw = tester.widget<RawMagnifier>(find.byType(RawMagnifier));
      final rect = tester.getRect(find.byType(RawMagnifier));
      expect(rect.left, greaterThanOrEqualTo(20));
      expect(rect.top, greaterThanOrEqualTo(32));
      expect(rect.right, lessThanOrEqualTo(370));
      expect(rect.bottom, lessThanOrEqualTo(540));
      expect(rect.center + raw.focalPointOffset, focalPoint);
      expect(raw.decoration.shape, isNot(isA<RoundedRectangleBorder>()));
      expect(raw.clipBehavior, Clip.hardEdge);
      expect(find.byType(TextMagnifier), findsNothing);
      expect(find.byType(Magnifier), findsNothing);
      expect(tester.takeException(), isNull);
    }

    check(const Offset(20, 20));
    info.value = const MagnifierInfo(
      globalGesturePosition: Offset(900, 800),
      caretRect: Rect.fromLTWH(350, 780, 2, 20),
      fieldBounds: Rect.fromLTWH(0, 760, 390, 60),
      currentLineBoundaries: Rect.fromLTWH(20, 780, 340, 20),
    );
    await tester.pump();
    check(const Offset(360, 790));
    info.value = const MagnifierInfo(
      globalGesturePosition: Offset(900, 800),
      caretRect: Rect.fromLTWH(300, 140, 2, 20),
      fieldBounds: Rect.fromLTWH(100, 120, 100, 40),
      currentLineBoundaries: Rect.fromLTWH(0, 130, 390, 20),
    );
    await tester.pump();
    check(const Offset(200, 150));
    expect(tester.hasRunningAnimations, isFalse);
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    'scroll physics follow the platform without Material overscroll',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          ListView.builder(
            controller: controller,
            itemExtent: 60,
            itemCount: 30,
            itemBuilder: (_, index) => Text('Line $index'),
          ),
        ),
      );
      final physics = controller.position.physics;
      bool contains<T extends ScrollPhysics>(ScrollPhysics? value) =>
          value != null && (value is T || contains<T>(value.parent));
      final bounces =
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      expect(contains<BouncingScrollPhysics>(physics), bounces);
      expect(contains<ClampingScrollPhysics>(physics), !bounces);
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.all(),
  );
}
