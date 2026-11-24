import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tend/app.dart';
import 'package:tend/design/design.dart';
import 'package:tend/garden.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'fonts.dart';

/// The day every test reads the garden on, so its words never change.
final DateTime today = DateTime(2026, 3, 12);

/// The widths Tend runs at: a phone, and a tablet held either way.
const List<Size> sizes = [Size(390, 844), Size(1024, 768)];

/// Pumps the app at [size], by day or by night, in [locale] (Arabic reads
/// right to left), at [textScale].
Future<Garden> pumpTend(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  tester.platformDispatcher
    ..platformBrightnessTestValue = brightness
    ..localesTestValue = [locale]
    ..textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final garden = Garden.example(today: today);
  addTearDown(garden.dispose);
  // A new app each time: the last one's routes never carry over.
  await tester.pumpWidget(TendApp(key: UniqueKey(), garden: garden));
  await tester.pumpAndSettle();
  return garden;
}

/// What ui_core_test finds wrong on the screen showing now: roles, names,
/// a field's words, tap targets (a finger's on a phone, a pointer's on a
/// tablet's keyboard), cursors, and words cut, broken or overflowing.
List<String> problemsOn(WidgetTester tester, {required bool touch}) {
  final screen = tester.element(find.byType(Navigator).first);
  return [
    for (final report in [
      const DesignCheckableCheck(look: 'Tend').check(screen),
      const DesignTextFieldNameCheck(look: 'Tend').check(screen),
      const DesignFieldSemanticsCheck(look: 'Tend').check(screen),
      DesignTapTargetCheck(
        look: 'Tend',
        input: touch ? RawInput.touch : RawInput.pointer,
      ).check(screen),
      if (!touch) const DesignCursorCheck(look: 'Tend').check(screen),
      const DesignOverflowCheck(look: 'Tend').check(screen),
      const DesignClipCheck(look: 'Tend').check(screen),
      const DesignWordBreakCheck(look: 'Tend').check(screen),
    ])
      ...report.problems,
  ];
}

/// The key a pushed screen's bar shows to leave it, in any language.
final Finder back = find.descendant(
  of: find.byType(TendDismissKey),
  matching: find.byType(RawButton),
);

/// The row of the plant called [name].
Finder rowOf(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(TendListRow));

void main() {
  testWidgets('every screen holds at every width, day and night, both '
      'directions, at 1x and 2x text', (tester) async {
    await loadTendFonts(tester);
    final found = <String>[];
    for (final size in sizes) {
      for (final brightness in Brightness.values) {
        for (final locale in const [Locale('en'), Locale('ar')]) {
          for (final textScale in const [1.0, 2.0]) {
            final at =
                '${size.width.round()} ${brightness.name} '
                '${locale.languageCode} ${textScale}x';
            await pumpTend(
              tester,
              size: size,
              brightness: brightness,
              locale: locale,
              textScale: textScale,
            );
            final touch = size.width < 600;
            found.addAll(
              problemsOn(tester, touch: touch).map((p) => 'Plants $at: $p'),
            );
            await tester.tap(find.text('Monty'));
            await tester.pumpAndSettle();
            found.addAll(
              problemsOn(tester, touch: touch).map((p) => 'Plant $at: $p'),
            );
            await tester.tap(back);
            await tester.pumpAndSettle();
            await tester.tap(find.bySemanticsLabel('Settings'));
            await tester.pumpAndSettle();
            found.addAll(
              problemsOn(tester, touch: touch).map((p) => 'Settings $at: $p'),
            );
            expect(tester.takeException(), isNull, reason: at);
          }
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });

  testWidgets('watering shows a toast above the bar, and Undo takes it back', (
    tester,
  ) async {
    await pumpTend(tester);
    expect(find.text('Living room · Water tomorrow'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Water Monty'));
    await tester.pumpAndSettle();
    expect(find.text('Living room · Water in 7 days'), findsOneWidget);
    final toast = tester.getRect(find.text('Watered Monty'));
    final bar = tester.getRect(find.byType(TendBottomBar));
    expect(toast.bottom, lessThanOrEqualTo(bar.top));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Living room · Water tomorrow'), findsOneWidget);
  });

  testWidgets('deleting asks first, in the danger tone, with focus on Cancel', (
    tester,
  ) async {
    for (final width in const [320.0, 390.0]) {
      for (final textScale in const [1.0, 2.0]) {
        await pumpTend(tester, size: Size(width, 844), textScale: textScale);
        await tester.tap(find.bySemanticsLabel('More for Fig'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        final dialog = tester.element(find.byType(RawAlertDialog));
        const DesignDialogActionsCheck(
          look: 'Tend',
          actions: ['Cancel', 'Delete'],
        ).check(dialog).verify();
        const DesignOverlayCheck(look: 'Tend').check(dialog).verify();
        // Enter on the focused action never confirms a loss.
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Fig'), findsOneWidget);
      }
    }
    await tester.tap(find.bySemanticsLabel('More for Fig'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Fig'), findsNothing);
  });

  testWidgets('leaving with changes asks: keep editing, discard or save', (
    tester,
  ) async {
    await pumpTend(tester, size: const Size(320, 700), textScale: 2);
    await tester.tap(find.text('Monty'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Monstera');
    await tester.pumpAndSettle();
    await tester.tap(back);
    await tester.pumpAndSettle();
    // Three actions do not fit a narrow phone at twice the text size: they
    // stack, one width, the confirming one on top.
    Rect action(String label) => tester.getRect(
      find.ancestor(
        of: find.descendant(
          of: find.byType(RawAlertDialog),
          matching: find.text(label),
        ),
        matching: find.byType(AnimatedTendSurface),
      ),
    );
    final [stay, discard, save] = [
      for (final label in ['Keep editing', 'Discard', 'Save']) action(label),
    ];
    expect(save.bottom, lessThanOrEqualTo(discard.top));
    expect(discard.bottom, lessThanOrEqualTo(stay.top));
    expect({stay.width, discard.width, save.width}, hasLength(1));
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Monty'), findsOneWidget);
    expect(find.text('Monstera'), findsNothing);
  });

  testWidgets('a new plant opens as a sheet, and a missing name is read '
      'with its field', (tester) async {
    await pumpTend(tester);
    await tester.tap(find.text('Add a plant'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final screen = tester.element(find.byType(Navigator).first);
    const DesignFieldWordsCheck(
      look: 'Tend',
      words: ['Give the plant a name'],
    ).check(screen).verify();
  });

  testWidgets("a field keeps its semantics nodes as its text changes", (
    tester,
  ) async {
    await pumpTend(tester);
    await tester.tap(find.text('Monty'));
    await tester.pumpAndSettle();
    final screen = tester.element(find.byType(Navigator).first);
    const check = DesignFieldNodesCheck(look: 'Tend');
    final before = check.read(screen);
    await tester.enterText(find.byType(EditableText).first, 'M');
    await tester.pumpAndSettle();
    check.check(before, screen).verify();
  });

  testWidgets('choosing night in the settings turns the whole app', (
    tester,
  ) async {
    await pumpTend(tester);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Night'));
    await tester.pumpAndSettle();
    final theme = TendTheme.of(tester.element(find.byType(TendScaffold).last));
    expect(theme.colors, TendColors.night);
  });
}
