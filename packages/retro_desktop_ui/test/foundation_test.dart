import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

// The focus rings a part's highlight painters will draw (claimed fallbacks
// excluded): the ring follows the part's outline, outside it.
// The highlight is a custom paint of its own kind (it hands its painter the
// device's grid), so it is found as any CustomPaint, not by its exact type.
List<RetroDesktopFocusRing> focusRings(WidgetTester tester, Finder part) => [
  for (final paint in tester.widgetList<CustomPaint>(
    find.descendant(
      of: part,
      matching: find.byWidgetPredicate((w) => w is CustomPaint),
    ),
  ))
    if (paint.foregroundPainter?.runtimeType.toString() == '_HighlightPainter')
      if ((paint.foregroundPainter! as dynamic).ring
          case final RetroDesktopFocusRing ring)
        if (!(((paint.foregroundPainter! as dynamic).skip
                    as RetroDesktopHighlightClaim?)
                ?.claimed ??
            false))
          ring,
];

void main() {
  test(
    'theme values copy, compare and interpolate without losing custom slots',
    () {
      final base = RetroDesktopThemeData.classic();
      final changed = base.copyWith(
        colors: base.colors.copyWith(text: const Color(0xff222222)),
        defaultButtonTheme: const RetroDesktopStyle(
          fill: WidgetStatePropertyAll(Color(0xff333333)),
        ),
        motion: const RetroDesktopMotion(state: Duration(milliseconds: 200)),
      );
      final direct = base.copyWith(
        checkboxTheme: const RetroDesktopStyle(
          fill: WidgetStatePropertyAll(Color(0xff123456)),
        ),
      );
      expect(direct.checkboxTheme.fill!.resolve({}), const Color(0xff123456));
      expect(direct.cardTheme, base.cardTheme);
      expect(base, base.copyWith());
      expect(base.hashCode, base.copyWith().hashCode);
      expect(changed, isNot(base));
      expect(
        changed.atWidth(1024).defaultButtonTheme,
        changed.defaultButtonTheme,
      );
      expect(changed.onHighlight.motion, changed.motion);
      expect(base.lerp(changed, 0), base);
      expect(base.lerp(changed, 1), changed);
      final half = base.lerp(changed, .5);
      expect(
        half.colors.text,
        Color.lerp(base.colors.text, changed.colors.text, .5),
      );
      expect(half.motion.state, const Duration(milliseconds: 100));
      expect(base.toString(), contains('RetroDesktopThemeData'));
    },
  );

  test('overshooting theme curves keep timings and focus widths valid', () {
    const zero = RetroDesktopMotion.still;
    const moving = RetroDesktopMotion(
      press: Duration(milliseconds: 100),
      state: Duration(milliseconds: 100),
      move: Duration(milliseconds: 100),
      raise: Duration(milliseconds: 100),
      travel: Duration(milliseconds: 100),
      leave: Duration(milliseconds: 100),
    );
    const thin = RetroDesktopFocusRing(color: Color(0xff111111), width: 0);
    const thick = RetroDesktopFocusRing(color: Color(0xff222222), width: 2);
    for (final (a, b, x, y, t) in [
      (zero, moving, thin, thick, -.5),
      (moving, zero, thick, thin, 1.5),
    ]) {
      final value = RetroDesktopMotion.lerp(a, b, t);
      expect([
        value.press,
        value.state,
        value.move,
        value.raise,
        value.travel,
        value.leave,
      ], everyElement(Duration.zero));
      expect(RetroDesktopFocusRing.lerp(x, y, t).width, 0);
    }
  });

  test('palette lists are copied and immutable, including lerped values', () {
    final base = RetroDesktopThemeData.classic().colors;
    final tones = [const Color(0xff444444)];
    final copy = base.copyWith(
      tones: tones,
      illustration: base.illustration.copyWith(sky: const []),
    );
    tones[0] = const Color(0xff999999);
    expect(copy.tones.single, const Color(0xff444444));
    expect(
      () => copy.tones.add(const Color(0xff111111)),
      throwsUnsupportedError,
    );
    expect(
      RetroDesktopColors.lerp(base, copy, .5).illustration.sky,
      hasLength(base.illustration.sky.length),
    );
  });

  test('window classes have shared boundaries', () {
    expect(
      [
        599.0,
        600.0,
        839.0,
        840.0,
        1199.0,
        1200.0,
      ].map(RetroDesktopWindowSizeClass.ofWidth),
      [
        RetroDesktopWindowSizeClass.compact,
        RetroDesktopWindowSizeClass.medium,
        RetroDesktopWindowSizeClass.medium,
        RetroDesktopWindowSizeClass.expanded,
        RetroDesktopWindowSizeClass.expanded,
        RetroDesktopWindowSizeClass.large,
      ],
    );
  });

  for (final host in ['material', 'cupertino', 'widgets']) {
    testWidgets('theme and editing install under $host with no Material API', (
      tester,
    ) async {
      Widget builder(BuildContext context, Widget? child) => RetroDesktopTheme(
        data: RetroDesktopThemeData.lagoon(),
        child: child!,
      );
      final home = Builder(
        builder: (context) {
          expect(RetroDesktopTheme.of(context).id, 'lagoon');
          expect(RetroDesktopTheme.maybeOf(context), isNotNull);
          return const Center(
            child: SizedBox(
              width: 220,
              child: RetroDesktopTextField(hint: 'Name'),
            ),
          );
        },
      );
      final Widget app = switch (host) {
        'material' => MaterialApp(builder: builder, home: home),
        'cupertino' => CupertinoApp(builder: builder, home: home),
        _ => WidgetsApp(
          color: const Color(0xff000000),
          builder: builder,
          onGenerateRoute: (_) =>
              PageRouteBuilder<void>(pageBuilder: (_, _, _) => home),
        ),
      };
      await tester.pumpWidget(app);
      final state = tester.state<EditableTextState>(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'A name');
      await tester.pump();
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(state),
      );
      expect(find.text('A name'), findsOneWidget);
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(
        editor.selectionControls,
        isA<RetroDesktopTextSelectionControls>(),
      );
      expect(editor.contextMenuBuilder, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'field decorators name only the editable and announce its error',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        const inputKey = Key('input decorator');
        const errorKey = Key('failure decorator');
        var completed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: RetroDesktopTheme(
              data: RetroDesktopThemeData.classic(),
              child: Center(
                child: SizedBox(
                  width: 320,
                  child: RetroDesktopTextField(
                    label: 'Drawn title',
                    hint: 'Drawn placeholder',
                    error: 'Error words',
                    nameOnly: true,
                    decorate: (input) => Semantics(
                      key: inputKey,
                      label: 'Owned name',
                      child: input,
                    ),
                    failureLine: (error) => Semantics(
                      key: errorKey,
                      liveRegion: true,
                      child: error,
                    ),
                    onEditingComplete: () => completed++,
                    trailing: RetroDesktopIconButton(
                      Icons.clear,
                      label: 'Separate action',
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.bySemanticsLabel('Owned name'), findsOneWidget);
        expect(find.bySemanticsLabel('Drawn title'), findsNothing);
        expect(find.bySemanticsLabel('Separate action'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(inputKey),
            matching: find.byType(EditableText),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(inputKey),
            matching: find.byType(RetroDesktopIconButton),
          ),
          findsNothing,
        );
        expect(
          tester
              .getSemantics(find.byKey(errorKey))
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        await tester.enterText(find.byType(EditableText), 'Value');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        expect(completed, 1);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('nested themes survive capture without clamping text scale', (
    tester,
  ) async {
    late CapturedThemes captured;
    final outerKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          key: outerKey,
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: RetroDesktopTheme(
              data: RetroDesktopThemeData.berry(),
              child: Builder(
                builder: (inner) {
                  expect(MediaQuery.textScalerOf(inner).scale(14), 28);
                  captured = InheritedTheme.capture(from: inner, to: context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
    final target = captured.wrap(
      Builder(
        builder: (context) {
          expect(RetroDesktopTheme.of(context).id, 'berry');
          return const Text('Captured');
        },
      ),
    );
    await tester.pumpWidget(MaterialApp(home: target));
    expect(find.text('Captured'), findsOneWidget);
  });

  testWidgets(
    'press handles Enter, Space, focus, busy, disabled and semantic activation',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final focus = FocusNode();
        final states = WidgetStatesController();
        addTearDown(focus.dispose);
        addTearDown(states.dispose);
        var count = 0;
        Widget app({bool enabled = true, bool busy = false}) => MaterialApp(
          home: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic(),
            child: Center(
              child: RetroDesktopPressable(
                label: 'Save',
                focusNode: focus,
                statesController: states,
                busy: busy,
                onPressed: enabled ? () => count++ : null,
                child: const Text('Save'),
              ),
            ),
          ),
        );
        await tester.pumpWidget(app());
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        focus.requestFocus();
        await tester.pump();
        expect(states.value, contains(WidgetState.focused));
        // With no face below to claim it, the press draws the ring itself.
        final rings = focusRings(tester, find.byType(RetroDesktopPressable));
        expect(rings, isNotEmpty);
        expect(rings.first.width, greaterThan(0));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(count, 2);
        await tester.tap(find.byType(RetroDesktopPressable));
        expect(count, 3);
        final size = tester.getSize(find.byType(RetroDesktopPressable));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(find.bySemanticsLabel('Save'), findsOneWidget);
        final node = tester.getSemantics(find.byType(RetroDesktopPressable));
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.tap,
        );
        expect(count, 4);
        await tester.pumpWidget(app(busy: true));
        expect(focus.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.tap(find.byType(RetroDesktopPressable));
        expect(count, 4);
        expect(states.value, isNot(contains(WidgetState.disabled)));
        await tester.pumpWidget(app(enabled: false));
        await tester.pump();
        expect(states.value, contains(WidgetState.disabled));
        await tester.tap(find.byType(RetroDesktopPressable));
        expect(count, 4);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('state builders receive hover, selected, error and pressed', (
    tester,
  ) async {
    final states = WidgetStatesController();
    addTearDown(states.dispose);
    Set<WidgetState> seen = {};
    await tester.pumpWidget(
      MaterialApp(
        home: RetroDesktopTheme(
          data: RetroDesktopThemeData.classic(),
          child: Center(
            child: RetroDesktopPressable(
              onPressed: () {},
              selected: true,
              error: true,
              statesController: states,
              builder: (context, value) {
                seen = value;
                return const Text('State face');
              },
            ),
          ),
        ),
      ),
    );
    expect(seen, containsAll([WidgetState.selected, WidgetState.error]));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(RetroDesktopPressable)));
    await tester.pump();
    expect(seen, contains(WidgetState.hovered));
    await mouse.down(tester.getCenter(find.byType(RetroDesktopPressable)));
    await tester.pump();
    expect(seen, contains(WidgetState.pressed));
    await mouse.up();
    await tester.pump();
    expect(seen, isNot(contains(WidgetState.pressed)));
  });

  testWidgets(
    'reduce motion cuts explicit theme animation and component timings',
    (tester) async {
      Widget app(RetroDesktopThemeData theme) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AnimatedRetroDesktopTheme(
            data: theme,
            duration: const Duration(seconds: 1),
            child: Builder(
              builder: (context) {
                expect(
                  RetroDesktopMotion.of(context),
                  RetroDesktopMotion.still,
                );
                return Text(RetroDesktopTheme.of(context).id);
              },
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(RetroDesktopThemeData.classic()));
      await tester.pumpWidget(
        app(
          RetroDesktopThemeData.berry().copyWith(
            motion: const RetroDesktopMotion(state: Duration(seconds: 1)),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('berry'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );
  testWidgets(
    'editor focus draws the configured outline around its padded target',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      const color = Color(0xffa000a0);
      await tester.pumpWidget(
        MaterialApp(
          home: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic().copyWith(
              focus: const RetroDesktopFocusRing(color: color, width: 3),
            ),
            child: Center(
              child: SizedBox(
                width: 300,
                child: RetroDesktopTextField(label: 'Name', focusNode: focus),
              ),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      final rings = focusRings(tester, find.byType(RetroDesktopTextField));
      expect(
        rings.any((ring) => ring.color == color && ring.width == 3),
        isTrue,
      );
      await tester.enterText(find.byType(EditableText), 'Visible focus');
      expect(focus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reach follows the installed platform, including a simulated phone',
    (tester) async {
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: platform),
            // Apply each platform immediately in this per-platform fixture.
            themeAnimationDuration: Duration.zero,
            home: RetroDesktopTheme(
              data: RetroDesktopThemeData.classic(),
              child: Center(
                child: RetroDesktopPressable(
                  label: 'Small face',
                  onPressed: () {},
                  child: const SizedBox.square(dimension: 8),
                ),
              ),
            ),
          ),
        );
        final target =
            platform == TargetPlatform.android || platform == TargetPlatform.iOS
            ? 48.0
            : 44.0;
        // On a touch screen the reach pads across as well as down; on a desk
        // only down, and the face keeps its own width (RetroDesktopReach).
        expect(
          tester.getSize(find.byType(RetroDesktopPressable)),
          target == 48 ? Size.square(target) : Size(8, target),
        );
      }
    },
  );

  testWidgets('host scroll platform controls targets across theme boundaries', (
    tester,
  ) async {
    for (final platform in TargetPlatform.values) {
      final other = platform == TargetPlatform.android
          ? TargetPlatform.windows
          : TargetPlatform.android;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: other),
          scrollBehavior: const ScrollBehavior().copyWith(platform: platform),
          home: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic(),
            child: Builder(
              builder: (context) {
                expect(Theme.of(context).platform, platform);
                return Center(
                  child: RetroDesktopPressable(
                    label: 'Host platform target',
                    onPressed: () {},
                    child: const SizedBox.square(dimension: 8),
                  ),
                );
              },
            ),
          ),
        ),
      );
      final target = switch (platform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => 48.0,
        _ => 44.0,
      };
      expect(
        tester.getSize(find.byType(RetroDesktopPressable)),
        target == 48 ? Size.square(target) : Size(8, target),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
