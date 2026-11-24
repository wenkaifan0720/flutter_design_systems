import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_ui/look_ui.dart';
import 'package:look_ui/src/inventory.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart'
    show RawCalendarDatePicker, RawPageRoute, TapTargetPadding;
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
        // Toasts over every route, under the look's theme.
        child: LookToaster(
          child: ColoredBox(
            color: LookThemeData.of(brightness).colors.ground,
            child: child!,
          ),
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
          labelText: 'Name',
          hintText: 'Ada Lovelace',
          helperText: 'As it appears on your card',
        ),
      ],
    ),
  );
}

/// The words of the control the keyboard's focus is on, or null.
String? focusedWords(WidgetTester tester) {
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
    const DesignOverflowCheck(look: 'Look').check(screen).verify();
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
    expect(focusedWords(tester), 'Cancel');
    final screen = tester.element(find.text('Delete the draft?'));
    const DesignCheckableCheck(look: 'Look').check(screen).verify();
    const DesignTapTargetCheck(look: 'Look').check(screen).verify();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Delete the draft?'), findsNothing);
    expect(answer, isNull);
    // The focus is back on the button that opened it.
    expect(focusedWords(tester), 'Delete');
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

  testWidgets('dialog actions stand in one row, or one column of one width '
      'with the confirming on top', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const labels = ['Keep editing', 'Discard', 'Save draft'];
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpWidget(
          lookApp(
            textScale: scale,
            home: Builder(
              builder: (context) => Center(
                child: LookButton(
                  'Close',
                  onPressed: () => showLookDialog<void>(
                    context,
                    title: 'Discard the draft?',
                    content: const Text('Your changes will be lost.'),
                    actions: (context) => [
                      for (final label in labels)
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
        final dialog = tester.element(find.text('Discard the draft?'));
        const DesignDialogActionsCheck(
          look: 'Look',
          actions: labels,
        ).check(dialog).verify();
        const DesignOverlayCheck(look: 'Look').check(dialog).verify();
        // The words and the actions keep a gap between them.
        final top = [
          for (final label in labels) tester.getRect(find.text(label)).top,
        ].reduce((a, b) => a < b ? a : b);
        expect(
          top - tester.getRect(find.text('Your changes will be lost.')).bottom,
          greaterThanOrEqualTo(16),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('a sheet lays its own buttons out as a dialog does', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const labels = ['Cancel', 'Copy link', 'Send a copy'];
    for (final width in [320.0, 1024.0]) {
      tester.view.physicalSize = Size(width, 700);
      await tester.pumpWidget(
        lookApp(
          home: Builder(
            builder: (context) => Center(
              child: LookButton(
                'Share',
                onPressed: () => showLookSheet<void>(
                  context,
                  title: 'Share the list',
                  actions: (context) => [
                    for (final label in labels)
                      LookButton(
                        label,
                        variant: label == labels.last
                            ? LookButtonVariant.filled
                            : LookButtonVariant.outlined,
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
      final sheet = tester.element(find.text('Share the list'));
      const DesignDialogActionsCheck(
        look: 'Look',
        actions: labels,
      ).check(sheet).verify();
      // Stacked on a narrow phone, side by side on a desk.
      final copy = tester.getRect(find.text('Copy link'));
      final send = tester.getRect(find.text('Send a copy'));
      expect(send.bottom < copy.top, width < 600);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Share the list'), findsNothing);
    }
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
              const SizedBox(
                width: 160,
                child: LookTextField(labelText: 'Name'),
              ),
              const SizedBox(width: 12),
              LookSelect<String>(
                labelText: 'Plan',
                options: const ['Day', 'Week'],
                value: 'Day',
                onChanged: (_) {},
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 160,
                child: LookCombobox<String>(
                  labelText: 'Owner',
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
      labelText: 'Plan',
      options: options,
      value: value,
      onChanged: (_) {},
    );
    const combobox = LookCombobox<String>(labelText: 'Plan', options: options);
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
                  labelText: 'Plan',
                  options: const ['Day', 'Week', 'Month'],
                  value: 'Week',
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                LookCombobox<String>(
                  labelText: 'Owner',
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

  testWidgets('a panel that is not a dialog says no dialog, keeps Tab '
      'inside, closes on Escape and gives focus back', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      lookApp(
        home: Builder(
          builder: (context) => Center(
            child: LookButton(
              'Search',
              onPressed: () => showLookPanel<void>(
                context,
                title: 'Search the notes',
                builder: (context, close) => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LookButton(
                      'Clear',
                      variant: LookButtonVariant.outlined,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    LookButton('Done', onPressed: close),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Search the notes'), findsOneWidget);
    // No node says dialog; the heading names the route.
    final roles = <SemanticsRole>[];
    void collect(SemanticsNode node) {
      roles.add(node.getSemanticsData().role);
      node.visitChildren((SemanticsNode child) {
        collect(child);
        return true;
      });
    }

    var root = tester.getSemantics(find.text('Search the notes'));
    while (root.parent != null) {
      root = root.parent!;
    }
    collect(root);
    expect(roles, isNot(contains(SemanticsRole.dialog)));
    expect(roles, isNot(contains(SemanticsRole.alertDialog)));
    expect(
      tester.getSemantics(find.text('Search the notes')),
      isSemantics(isHeader: true, namesRoute: true),
    );
    // Tab goes round the panel's controls and never back to the page.
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedWords(tester), isIn(['Clear', 'Done']));
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Search the notes'), findsNothing);
    expect(focusedWords(tester), 'Search');
    semantics.dispose();
  });

  for (final direction in TextDirection.values) {
    testWidgets('${direction.name}: a menu the look places opens over its '
        'button, its end corner on the button\'s', (tester) async {
      final semantics = tester.ensureSemantics();
      String? picked;
      await tester.pumpWidget(
        lookApp(
          direction: direction,
          home: Center(
            child: LookMoreMenu(
              semanticLabel: 'More',
              entries: [
                RawMenuEntry(
                  label: 'Rename',
                  onPressed: () => picked = 'Rename',
                ),
                RawMenuEntry(
                  label: 'Delete',
                  isDestructiveAction: true,
                  onPressed: () => picked = 'Delete',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final button = tester.getRect(
        find.descendant(
          of: find.byType(LookMoreMenu),
          matching: find.byType(TapTargetPadding),
        ),
      );
      final menu = tester.getRect(find.byType(LookListSurface));
      if (direction == TextDirection.ltr) {
        expect(menu.topRight, button.topRight);
      } else {
        expect(menu.topLeft, button.topLeft);
      }
      // Its node is a menu named as its button.
      final node = tester
          .getSemantics(find.byType(LookListSurface))
          .getSemanticsData();
      expect(node.role, SemanticsRole.menu);
      expect(node.label, 'More');
      // The keys start on the first row; Enter picks it, the menu closes
      // and the focus goes back to the button.
      expect(focusedWords(tester), 'Rename');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, 'Rename');
      expect(find.byType(LookListSurface), findsNothing);
      expect(focusedWords(tester), '…');
      semantics.dispose();
    });
  }

  testWidgets('a select opened from the keys starts on its chosen option', (
    tester,
  ) async {
    await tester.pumpWidget(
      lookApp(
        home: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LookSelect<String>(
                labelText: 'Plan',
                options: const ['Day', 'Week', 'Month'],
                value: 'Month',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(focusedWords(tester), 'Month');
  });

  testWidgets('a combobox\'s input says whether its list shows', (
    tester,
  ) async {
    await tester.pumpWidget(
      lookApp(
        home: const Padding(
          padding: EdgeInsets.all(24),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: LookCombobox<String>(
              labelText: 'Owner',
              options: ['Ada', 'Grace'],
            ),
          ),
        ),
      ),
    );
    final input = find.byType(EditableText);
    Matcher expanded(bool open) =>
        isSemantics(hasExpandedState: true, isExpanded: open);
    expect(tester.getSemantics(input), expanded(false));
    await tester.tap(input);
    await tester.pumpAndSettle();
    expect(find.text('Grace'), findsOneWidget);
    expect(tester.getSemantics(input), expanded(true));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(input), expanded(false));
  });

  testWidgets('a field\'s help and error are read with it; required is a '
      'flag', (tester) async {
    for (final error in [null, 'Enter the whole address']) {
      await tester.pumpWidget(
        lookApp(
          home: Padding(
            padding: const EdgeInsets.all(24),
            child: LookTextField(
              labelText: 'Email',
              helperText: 'For receipts only',
              errorText: error,
              required: true,
            ),
          ),
        ),
      );
      final screen = tester.element(find.byType(LookTextField));
      DesignFieldWordsCheck(
        look: 'Look',
        words: [error ?? 'For receipts only'],
      ).check(screen).verify();
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(isRequired: true, isTextField: true),
      );
    }
  });

  testWidgets('a month opens whole where it fits, on its chosen day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DateTime? due = DateTime(2026, 3, 18);
    await tester.pumpWidget(
      lookApp(
        home: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(24),
            // The field at the foot of a phone: too little room below.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LookDateField(
                  labelText: 'Due',
                  value: due,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                  onChanged: (day) => setState(() => due = day),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final screen = tester.element(find.byType(LookDateField));
    // Above the field's face, whole: below it the month would not fit.
    final face = find.descendant(
      of: find.byType(LookDateField),
      matching: find.byType(LookListSign),
    );
    expect(
      tester.getRect(find.byType(RawCalendarDatePicker)).bottom,
      lessThan(tester.getRect(face).top),
    );
    const DesignOverlayCheck(look: 'Look').check(screen).verify();
    const DesignListSideCheck(look: 'Look').check(screen).verify();
    const DesignTapTargetCheck(look: 'Look').check(screen).verify();
    // The keys start on the chosen day: the next one, then Enter.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(due, DateTime(2026, 3, 19));
    expect(find.byType(RawCalendarDatePicker), findsNothing);
  });

  testWidgets('a toast stands clear of the bar at the foot', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      lookApp(
        home: Builder(
          builder: (context) => Column(
            children: [
              const Expanded(child: SizedBox.expand()),
              LookBottomBar(
                child: LookButton(
                  'Save draft',
                  onPressed: () =>
                      LookToaster.of(context)
                          .show(const RawToast(message: 'Draft saved')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save draft'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester.getRect(find.text('Draft saved')).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(LookBottomBar)).top),
    );
    // Its time runs out, and it leaves.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Draft saved'), findsNothing);
  });

  testWidgets('tabs are one tab stop, and the arrows choose', (tester) async {
    final before = FocusNode();
    addTearDown(before.dispose);
    var tab = 'open';
    await tester.pumpWidget(
      lookApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Focus(
                focusNode: before,
                child: const SizedBox.square(dimension: 1),
              ),
              LookTabs<String>(
                value: tab,
                semanticLabel: 'Tasks',
                onChanged: (next) => setState(() => tab = next),
                tabs: const [
                  LookTab(value: 'all', label: 'All'),
                  LookTab(value: 'open', label: 'Open'),
                  LookTab(value: 'done', label: 'Done'),
                ],
              ),
              LookButton('After', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    before.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    // Tab enters on the chosen tab; an arrow moves and chooses.
    expect(focusedWords(tester), 'Open');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(tab, 'done');
    expect(
      tester.getSemantics(find.text('Done')),
      isSemantics(isSelected: true),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedWords(tester), 'After');
    final screen = tester.element(find.byType(LookTabs<String>));
    const DesignTapTargetCheck(look: 'Look').check(screen).verify();
    const DesignCursorCheck(look: 'Look').check(screen).verify();
  });

  testWidgets('a toolbar is one tab stop, and the arrows move along it', (
    tester,
  ) async {
    final before = FocusNode();
    addTearDown(before.dispose);
    await tester.pumpWidget(
      lookApp(
        home: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(
              focusNode: before,
              child: const SizedBox.square(dimension: 1),
            ),
            LookToolbar(
              toggles: [
                for (final (label, icon) in [
                  ('Bold', Icons.format_bold),
                  ('Italic', Icons.format_italic),
                  ('Underline', Icons.format_underline),
                ])
                  LookToolbarToggle(
                    icon: icon,
                    semanticLabel: label,
                    isSelected: label == 'Italic',
                    onPressed: () {},
                  ),
              ],
            ),
            LookButton('After', onPressed: () {}),
          ],
        ),
      ),
    );
    Matcher focused() => isSemantics(isFocused: true);
    before.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.bySemanticsLabel('Bold')), focused());
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.bySemanticsLabel('Italic')), focused());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedWords(tester), 'After');
  });

  testWidgets("tabs laid out in another order: the arrows follow the tabs' "
      'order', (tester) async {
    final before = FocusNode();
    addTearDown(before.dispose);
    var tab = 'all';
    await tester.pumpWidget(
      lookApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Focus(
                focusNode: before,
                child: const SizedBox.square(dimension: 1),
              ),
              LookTabs<String>(
                value: tab,
                semanticLabel: 'Tasks',
                onChanged: (next) => setState(() => tab = next),
                tabs: const [
                  LookTab(value: 'all', label: 'All', order: 0),
                  LookTab(value: 'done', label: 'Done', order: 2),
                  LookTab(value: 'open', label: 'Open', order: 1),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    before.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedWords(tester), 'All');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(tab, 'open', reason: 'Open comes second, though drawn last');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(tab, 'done');
  });

  testWidgets("a reorderable row's grip marks the keyboard's focus, and "
      'Alt with Down moves its row, the focus with it', (tester) async {
    var items = ['Milk', 'Eggs', 'Bread'];
    await tester.pumpWidget(
      lookApp(
        home: StatefulBuilder(
          builder: (context, setState) => LookReorderableList<String>(
            items: items,
            labelOf: (item) => item,
            onReorder: (from, to) => setState(() {
              final next = [...items];
              final item = next.removeAt(from);
              next.insert(to, item);
              items = next;
            }),
            itemBuilder: (context, item) => Text(item),
          ),
        ),
      ),
    );
    Color rule(String item) => tester
        .widget<AnimatedLookSurface>(
          find.descendant(
            of: find.ancestor(of: find.text(item), matching: find.byType(Row)),
            matching: find.byType(AnimatedLookSurface),
          ),
        )
        .face
        .rule;
    const clear = Color(0x00000000);
    expect(rule('Milk'), clear);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(rule('Milk'), isNot(clear), reason: 'the keyboard is on its grip');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(items, ['Eggs', 'Milk', 'Bread']);
    expect(rule('Milk'), isNot(clear));
    expect(rule('Eggs'), clear);
  });

  test('the inventory answers its rows; what it leaves are missing', () {
    final problems = lookInventory.problems;
    expect(problems, isNotEmpty);
    expect(problems.every((p) => p.contains(': missing (')), isTrue);
  });

  testWidgets(
    "a LookPage plays the look's push, and on iOS alone a swipe takes it back",
    (tester) async {
      var pages = <Page<void>>[
        const LookPage<void>(key: ValueKey('inbox'), child: Text('Inbox')),
        const LookPage<void>(key: ValueKey('thread'), child: Text('Thread')),
      ];
      await tester.pumpWidget(
        lookApp(
          home: StatefulBuilder(
            builder: (context, setState) => Navigator(
              pages: pages,
              onDidRemovePage: (page) =>
                  setState(() => pages = [...pages]..remove(page)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thread'), findsOneWidget);
      await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
      await tester.pumpAndSettle();
      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      expect(find.text('Thread'), ios ? findsNothing : findsOneWidget);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    "the dismiss key says back on a pushed page, close on a sheet, nothing on a root",
    (tester) async {
      await tester.pumpWidget(lookApp(home: const LookDismissKey()));
      expect(find.byType(LookIconButton), findsNothing);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          RawPageRoute<void>(
            transitionsBuilder: const LookPageTransitionsBuilder(),
            builder: (context) => const LookDismissKey(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      unawaited(
        navigator.push(
          RawPageRoute<void>(
            transitionsBuilder: const LookPageTransitionsBuilder(),
            fullscreenDialog: true,
            builder: (context) => const LookDismissKey(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
    },
  );

  testWidgets(
    "drawn choices answer as a radio group: arrows choose, a press between a drawing's parts chooses",
    (tester) async {
      var size = 'S';
      LookChoiceDrawing drawing(String text) =>
          (BuildContext context, bool chosen, Set<WidgetState> states) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(chosen ? '[$text' : text),
                    const SizedBox(width: 24),
                    const Text(']'),
                  ],
                ),
              );
      await tester.pumpWidget(
        lookApp(
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) => LookDrawnChoices<String>(
                value: size,
                onChanged: (next) => setState(() => size = next),
                choices: [
                  for (final s in const ['S', 'M', 'L'])
                    LookDrawnChoice(value: s, label: s, drawing: drawing(s)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(size, 'M');
      // Between the words and the bracket of L's drawing: nothing painted.
      final left = tester.getTopRight(find.text('L'));
      await tester.tapAt(left + const Offset(12, 0));
      await tester.pumpAndSettle();
      expect(size, 'L');
      expect(
        tester.getSemantics(find.bySemanticsLabel('L')),
        isSemantics(
          label: 'L',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
        ),
      );
    },
  );
}
