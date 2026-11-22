import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_ui/look_ui.dart';
import 'package:look_ui/src/inventory.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core_test/guidelines.dart';
import 'package:ui_core_test/ui_core_test.dart';

/// The fonts the pixel checks read: Roboto for the words and Material's
/// icons for the glyphs, from the Flutter SDK's own cache. A look loads the
/// families its FontManifest.json lists; a family left out is drawn in the
/// test's own font, whose boxes stand on the baseline and read as off-centre.
Future<void> loadLookFonts(WidgetTester tester) async {
  final fonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) =>
      File('$fonts/$name').readAsBytes().then(ByteData.sublistView);
  await tester.runAsync(() async {
    await (FontLoader('Roboto')
          ..addFont(read('Roboto-Regular.ttf'))
          ..addFont(read('Roboto-Medium.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(read('MaterialIcons-Regular.otf'))).load();
  });
}

/// An app on the look: Flutter's MaterialApp, the look's theme in its
/// builder, the look's page transitions in its ThemeData.
Widget lookApp({
  required Widget home,
  Brightness brightness = Brightness.light,
  TextDirection? direction,
  double textScale = 1,
  Locale? locale,
}) => MaterialApp(
  locale: locale,
  // ui_core's built-in words (Close, Cancel, the scrim's name) in the
  // reader's language, beside Flutter's own.
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: lookPageTransitions,
    ),
  ),
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: textScale,
    maxScaleFactor: textScale,
    child: Directionality(
      textDirection: direction ?? Directionality.of(context),
      child: LookTheme(
        data: LookThemeData.of(brightness),
        child: ColoredBox(
          color: LookThemeData.of(brightness).colors.ground,
          child: child!,
        ),
      ),
    ),
  ),
  home: home,
);

/// A screen of the look's parts, as a gallery page holds them.
class PartsScreen extends StatefulWidget {
  const PartsScreen({super.key});

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> {
  bool _email = true;
  bool _wifi = false;
  bool _pinned = false;
  String _plan = 'day';

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A row of actions wraps when it does not fit (a phone, large
        // text), rather than overflowing.
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            LookButton('Save', onPressed: () {}),
            LookButton(
              'Cancel',
              variant: LookButtonVariant.outlined,
              onPressed: () {},
            ),
            const LookButton('Archived', onPressed: null),
          ],
        ),
        const SizedBox(height: 16),
        LookIconButton(
          icon: Icons.favorite_border,
          semanticLabel: 'Favourite',
          isSelected: _pinned,
          onPressed: () => setState(() => _pinned = !_pinned),
        ),
        LookCheckbox(
          value: _email,
          label: 'Email me',
          onChanged: (value) => setState(() => _email = value!),
        ),
        LookSwitch(
          value: _wifi,
          semanticLabel: 'Wi-Fi',
          onChanged: (value) => setState(() => _wifi = value),
        ),
        LookRadioGroup<String>(
          key: const ValueKey('plan'),
          value: _plan,
          onChanged: (value) => setState(() => _plan = value),
          options: const [
            LookRadioOption(value: 'day', label: 'Day'),
            LookRadioOption(value: 'week', label: 'Week'),
            LookRadioOption(value: 'month', label: 'Month'),
          ],
        ),
        const SizedBox(height: 16),
        const LookTextField(
          label: 'Name',
          hint: 'Ada Lovelace',
          helperText: 'As it appears on your card',
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('every part says what it is, and reaches the floor', (
    tester,
  ) async {
    await tester.pumpWidget(lookApp(home: const PartsScreen()));
    final screen = tester.element(find.byType(PartsScreen));
    const DesignCheckableCheck(look: 'Look').check(screen).verify();
    const DesignTextFieldNameCheck(look: 'Look').check(screen).verify();
    const DesignFieldSemanticsCheck(look: 'Look').check(screen).verify();
    const DesignTapTargetCheck(look: 'Look').check(screen).verify();
    const DesignCursorCheck(look: 'Look').check(screen).verify();
    await expectLater(tester, meetsGuideline(checkableRoleGuideline));
    await expectLater(tester, meetsGuideline(textFieldNameGuideline));
    await expectLater(tester, meetsGuideline(fieldSemanticsGuideline));
    await expectLater(tester, meetsGuideline(cursorGuideline));
    // The look's floor is 44 by 44, Apple's; Flutter's iOS guideline holds
    // it. A look on Material's 48 holds androidTapTargetGuideline.
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(tapTargetReachGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('a toggle button is a button that is selected', (tester) async {
    await tester.pumpWidget(lookApp(home: const PartsScreen()));
    await tester.tap(find.bySemanticsLabel('Favourite'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Favourite')),
      matchesSemantics(
        label: 'Favourite',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('the radio group answers the keys as Flutter\'s does', (
    tester,
  ) async {
    final before = FocusNode();
    addTearDown(before.dispose);
    var plan = 'week';
    await tester.pumpWidget(
      lookApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              Focus(
                focusNode: before,
                child: const SizedBox.square(dimension: 1),
              ),
              LookRadioGroup<String>(
                key: const ValueKey('plan'),
                value: plan,
                onChanged: (value) => setState(() => plan = value),
                options: const [
                  LookRadioOption(value: 'day', label: 'Day'),
                  LookRadioOption(value: 'week', label: 'Week'),
                  LookRadioOption(value: 'month', label: 'Month'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final report = await const DesignRadioGroupCheck(look: 'Look').check(
      tester.element(find.byKey(const ValueKey('plan'))),
      before: before,
      sendKeyEvent: tester.sendKeyEvent,
      pump: tester.pump,
    );
    report.verify();
  });

  testWidgets('labels sit on their faces\' middles, by day and by night', (
    tester,
  ) async {
    await loadLookFonts(tester);
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        lookApp(home: const PartsScreen(), brightness: brightness),
      );
      // A theme that springs from day to night is read once it lands.
      await tester.pumpAndSettle();
      final screen = tester.element(find.byType(PartsScreen));
      final labels = await const DesignLabelCheck(
        look: 'Look',
        drawnTolerance: 0.5,
      ).check(screen, runAsync: tester.runAsync);
      labels.verify();
      final shadows = await const DesignShadowClipCheck(look: 'Look')
          .check(screen, runAsync: tester.runAsync);
      shadows.verify();
      const DesignClipCheck(look: 'Look').check(screen).verify();
      const DesignWordBreakCheck(look: 'Look').check(screen).verify();
    }
  });

  testWidgets('every part holds at twice the text size, right to left', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      lookApp(
        home: const PartsScreen(),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    final screen = tester.element(find.byType(PartsScreen));
    const DesignClipCheck(look: 'Look').check(screen).verify();
    const DesignWordBreakCheck(look: 'Look').check(screen).verify();
    // Right to left, a checkbox's words stand to the left of its box.
    expect(
      tester.getCenter(find.text('Email me')).dx,
      lessThan(tester.getCenter(find.byType(LookCheckbox)).dx),
    );
  });

  testWidgets('a press passes through the faces between, on a spring', (
    tester,
  ) async {
    await tester.pumpWidget(lookApp(home: const PartsScreen()));
    final save = find.widgetWithText(LookButton, 'Save');
    Color fill() => tester
        .widget<LookSurface>(
          find.descendant(of: save, matching: find.byType(LookSurface)),
        )
        .face
        .fill;
    final rest = fill();
    // A mouse's press shows at once; a touch's in a scroll view waits
    // kPressTimeout, in case it starts a scroll.
    final gesture = await tester.startGesture(
      tester.getCenter(save),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final midway = fill();
    await tester.pumpAndSettle();
    final pressed = fill();
    expect(midway, isNot(rest));
    expect(midway, isNot(pressed));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fill(), rest);
  });

  testWidgets('under Reduce Motion a state change settles within 150 ms', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: lookApp(home: const PartsScreen()),
      ),
    );
    final save = find.widgetWithText(LookButton, 'Save');
    final gesture = await tester.startGesture(
      tester.getCenter(save),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final face = tester
        .widget<LookSurface>(
          find.descendant(of: save, matching: find.byType(LookSurface)),
        )
        .face;
    await tester.pumpAndSettle();
    expect(
      face,
      tester
          .widget<LookSurface>(
            find.descendant(of: save, matching: find.byType(LookSurface)),
          )
          .face,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the tooltip shows on the keyboard\'s focus', (tester) async {
    await tester.pumpWidget(
      lookApp(
        home: Center(
          child: LookTooltip(
            message: 'Archive the thread',
            child: LookButton('Archive', onPressed: () {}),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Archive the thread'), findsOneWidget);
  });

  testWidgets('a dialog takes focus, closes on Escape and gives focus back', (
    tester,
  ) async {
    bool? answer;
    await tester.pumpWidget(
      lookApp(
        home: Builder(
          builder: (context) => Center(
            child: LookButton(
              'Delete',
              destructive: true,
              onPressed: () async {
                answer = await showLookDialog<bool>(
                  context,
                  title: 'Delete the draft?',
                  content: const Text('It cannot be brought back.'),
                  actions: (context) => [
                    RawDialogAction(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    RawDialogAction(
                      label: 'Delete',
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Delete the draft?'), findsOneWidget);
    // The focus starts on the safe action, never on the destructive one.
    String? focused() {
      final at = FocusManager.instance.primaryFocus?.context;
      if (at == null) return null;
      final words = find.descendant(
        of: find.byElementPredicate((e) => e == at),
        matching: find.byType(Text),
      );
      return words.evaluate().isEmpty
          ? null
          : tester.widget<Text>(words.first).data;
    }

    expect(focused(), 'Cancel');
    final screen = tester.element(find.text('Delete the draft?'));
    const DesignCheckableCheck(look: 'Look').check(screen).verify();
    const DesignTapTargetCheck(look: 'Look').check(screen).verify();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Delete the draft?'), findsNothing);
    expect(answer, isNull);
    // The focus is back on the button that opened it.
    expect(focused(), 'Delete');
  });

  testWidgets('on iOS a swipe from the leading edge pops the page', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: lookPageTransitions,
          ),
        ),
        builder: (context, child) =>
            LookTheme(data: LookThemeData.day(), child: child!),
        home: const Text('Inbox'),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (context) => const Text('Thread')),
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(2, 300));
    await gesture.moveBy(const Offset(500, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Thread'), findsNothing);
    expect(find.text('Inbox'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Android back closes the dialog before it leaves the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      lookApp(
        home: Builder(
          builder: (context) => Center(
            child: LookButton(
              'Share',
              onPressed: () => showLookDialog<void>(
                context,
                title: 'Share the link?',
                isAlert: false,
                actions: (context) => [
                  RawDialogAction(
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Share the link?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Share the link?'), findsNothing);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('three dialog actions stack, one width, the confirming on top, '
      'when they do not fit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      lookApp(
        home: Builder(
          builder: (context) => Center(
            child: LookButton(
              'Close',
              onPressed: () => showLookDialog<void>(
                context,
                title: 'Discard the draft?',
                content: const Text('Your changes will be lost.'),
                actions: (context) => [
                  for (final label in ['Keep editing', 'Discard', 'Save draft'])
                    RawDialogAction(
                      label: label,
                      isDestructiveAction: label == 'Discard',
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    Rect face(String label) => tester.getRect(
      find
          .ancestor(of: find.text(label), matching: find.byType(LookSurface))
          .first,
    );
    final keep = face('Keep editing');
    final discard = face('Discard');
    final save = face('Save draft');
    expect(save.top, lessThan(discard.top));
    expect(discard.top, lessThan(keep.top));
    expect({keep.width, discard.width, save.width}, hasLength(1));
    expect({keep.height, discard.height, save.height}, hasLength(1));
    // The words and the actions keep a gap between them.
    expect(
      save.top - tester.getRect(find.text('Your changes will be lost.')).bottom,
      greaterThanOrEqualTo(16),
    );
  });

  testWidgets('built-in words follow the reader\'s language', (tester) async {
    await tester.pumpWidget(
      lookApp(
        locale: const Locale('de'),
        home: Builder(
          builder: (context) => Center(
            child: LookButton(
              'Teilen',
              onPressed: () => showLookDialog<void>(
                context,
                title: 'Link teilen?',
                isAlert: false,
                actions: (context) => [
                  RawDialogAction(
                    label: RawWidgetsLocalizations.of(context)
                        .cancelButtonLabel,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Teilen'));
    await tester.pumpAndSettle();
    final words = RawWidgetsLocalizations.of(
      tester.element(find.text('Link teilen?')),
    );
    expect(words.cancelButtonLabel, isNot('Cancel'));
    expect(find.text(words.cancelButtonLabel), findsOneWidget);
  });

  testWidgets('a tooltip is read with the control it names', (tester) async {
    await tester.pumpWidget(
      lookApp(
        home: Center(
          child: LookTooltip(
            message: 'Archive the thread',
            child: LookButton('Archive', onPressed: () {}),
          ),
        ),
      ),
    );
    final screen = tester.element(find.byType(LookTooltip));
    const DesignTooltipNodeCheck(look: 'Look').check(screen).verify();
    await expectLater(tester, meetsGuideline(tooltipNodeGuideline));
  });

  testWidgets('a field keeps its semantics nodes as its text changes', (
    tester,
  ) async {
    await tester.pumpWidget(lookApp(home: const PartsScreen()));
    final screen = tester.element(find.byType(PartsScreen));
    const check = DesignFieldNodesCheck(look: 'Look');
    final empty = check.read(screen);
    await tester.enterText(find.byType(EditableText).first, 'A');
    await tester.pumpAndSettle();
    check.check(empty, screen).verify();
  });

  testWidgets('a button, a field, a select and a combobox in a row stand '
      'at one height on one centre line', (tester) async {
    await tester.pumpWidget(
      lookApp(
        home: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 160, child: LookTextField(label: 'Name')),
              const SizedBox(width: 12),
              LookSelect<String>(
                label: 'Plan',
                options: const ['Day', 'Week'],
                value: 'Day',
                onChanged: (_) {},
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 160,
                child: LookCombobox<String>(
                  label: 'Owner',
                  options: ['Ada', 'Grace'],
                ),
              ),
              const SizedBox(width: 12),
              LookButton('Save', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    // The faces, not their tap targets: each part's painted surface.
    Rect face(Finder part) => tester.getRect(
      find.descendant(of: part, matching: find.byType(LookSurface)).first,
    );
    final faces = [
      face(find.byType(LookTextField)),
      face(find.byType(LookSelect<String>)),
      face(find.byType(LookCombobox<String>)),
      face(find.byType(LookButton)),
    ];
    for (final f in faces.skip(1)) {
      expect(f.height, moreOrLessEquals(faces.first.height));
    }
    // The button has no label above it, so its face is compared with the
    // fields' by height only; the fields share their centre line.
    for (final f in faces.skip(1).take(2)) {
      expect(f.center.dy, moreOrLessEquals(faces.first.center.dy));
    }
  });

  testWidgets('from 600 px wide, a select, a combobox and a button keep '
      'their content\'s width', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<double> faceWidth(CrossAxisAlignment align, Widget part) async {
      await tester.pumpWidget(
        lookApp(
          home: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: align, children: [part]),
          ),
        ),
      );
      final face = find.descendant(
        of: find.byWidget(part),
        matching: find.byType(LookSurface),
      );
      return tester.getSize(face.first).width;
    }

    const options = ['Day', 'Week', 'Month'];
    LookSelect<String> select(String value) => LookSelect<String>(
      label: 'Plan',
      options: options,
      value: value,
      onChanged: (_) {},
    );
    const combobox = LookCombobox<String>(label: 'Plan', options: options);
    const start = CrossAxisAlignment.start;
    final day = await faceWidth(start, select('Day'));
    expect(day, lessThan(240));
    // One width whatever is chosen, and the combobox offering the same
    // list is that width too: the two read as one kind of field.
    expect(await faceWidth(start, select('Month')), day);
    expect(await faceWidth(start, combobox), day);
    expect(
      await faceWidth(start, LookButton('Save', onPressed: () {})),
      lessThan(240),
    );
    // A form that sets its fields' width still sets it.
    const stretch = CrossAxisAlignment.stretch;
    expect(await faceWidth(stretch, select('Day')), 1440 - 48);
    expect(await faceWidth(stretch, combobox), 1440 - 48);
  });

  testWidgets('a select and a combobox open their lists below, as one kind '
      'of field', (tester) async {
    String? owner;
    await tester.pumpWidget(
      lookApp(
        home: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LookSelect<String>(
                  label: 'Plan',
                  options: const ['Day', 'Week', 'Month'],
                  value: 'Week',
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                LookCombobox<String>(
                  label: 'Owner',
                  options: const ['Ada', 'Grace', 'Katherine'],
                  value: owner,
                  onSelected: (next) => setState(() => owner = next),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final screen = tester.element(find.byType(StatefulBuilder));
    // Both fields end in the same sign that they open a list.
    expect(
      find.descendant(
        of: find.byType(LookSelect<String>),
        matching: find.byType(LookListSign),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LookCombobox<String>),
        matching: find.byType(LookListSign),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(LookSelect<String>));
    await tester.pumpAndSettle();
    expect(find.text('Month'), findsOneWidget);
    const DesignListSideCheck(look: 'Look').check(screen).verify();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text('Katherine'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Katherine')).dy,
      greaterThan(tester.getBottomLeft(find.byType(EditableText)).dy),
    );
    const DesignListSideCheck(look: 'Look').check(screen).verify();
    await tester.tap(find.text('Grace'));
    await tester.pumpAndSettle();
    expect(owner, 'Grace');
  });

  testWidgets('a destructive menu row takes the danger tone', (tester) async {
    await tester.pumpWidget(
      lookApp(
        home: Center(
          child: LookMenu(
            entries: [
              RawMenuEntry(label: 'Rename', onPressed: () {}),
              RawMenuEntry(
                label: 'Delete',
                isDestructiveAction: true,
                onPressed: () {},
              ),
            ],
            child: const SizedBox(width: 200, height: 80),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LookMenu)),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    final colors = LookThemeData.day().colors;
    Color? ink(String label) =>
        tester.widget<Text>(find.text(label)).style?.color;
    expect(ink('Delete'), colors.danger);
    expect(ink('Rename'), colors.ink);
  });

  test('the inventory answers its rows; what it leaves are missing', () {
    final problems = lookInventory.problems;
    expect(problems, isNotEmpty);
    expect(problems.every((p) => p.contains(': missing (')), isTrue);
  });
}
