// Minimal in the shared inventory (ui_core's DesignInventory): it answers
// every row once, each live specimen is the row's own class
// (`Minimal<Stem>`), and each one builds and lays out on a phone and a
// desktop, light and dark, and at 200% text on a phone, without an error.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _host(
  Widget Function(BuildContext context) builder, {
  Brightness brightness = Brightness.light,
  Size size = const Size(800, 600),
  double textScale = 1,
}) => MaterialApp(
  builder: (context, navigator) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: MinimalHost(
      light: MinimalThemeData.preset('standard', Brightness.light),
      dark: MinimalThemeData.preset('standard', Brightness.dark),
      brightness: brightness,
      child: navigator!,
    ),
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: size,
        child: Builder(builder: builder),
      ),
    ),
  ),
);

void main() {
  testWidgets('every row answered once, each specimen a Minimal part', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      _host((c) {
        context = c;
        return const SizedBox();
      }),
    );
    expect(minimalInventory.problems, isEmpty);
    minimalInventory.verify();
    for (final entry in minimalInventory.entries) {
      final specimen = entry.builder?.call(context);
      if (specimen == null) continue;
      expect(
        specimen.runtimeType.toString(),
        startsWith('Minimal'),
        reason: entry.row,
      );
    }
  });

  testWidgets('the overlay specimens read as working parts', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      _host((c) {
        context = c;
        return const SizedBox();
      }),
    );
    Widget specimen(String row) => minimalInventory.entries
        .firstWhere((e) => e.row == row)
        .builder!(context);
    // Live actions, so the dialog's buttons do not read disabled.
    final dialog = specimen('Dialog') as MinimalDialog;
    expect(dialog.onConfirm, isNotNull);
    expect(dialog.onCancel, isNotNull);
    // An action sheet ends in its quiet Cancel row.
    final sheet = specimen('ActionSheet') as MinimalActionSheet;
    expect(sheet.onCancel, isNotNull);
    // A range prints its ends as figures with their unit.
    final range = specimen('RangeSlider') as MinimalRangeSlider;
    expect(range.format?.call(range.values.start), '\$40');
  });

  testWidgets('the two gaps say why, not "later"', (tester) async {
    final gaps = [
      for (final e in minimalInventory.entries)
        if (e.builder == null) e,
    ];
    expect(gaps.map((e) => e.row), ['FloatingActionButton', 'WheelPicker']);
    expect(gaps.first.absentReason, contains('top bar'));
    expect(gaps.last.absentReason, contains('MinimalTimePicker'));
  });

  for (final brightness in Brightness.values) {
    for (final size in const [Size(390, 640), Size(1000, 640)]) {
      testWidgets('every live specimen lays out: ${brightness.name}, '
          '${size.width.round()} wide', (tester) async {
        tester.view.physicalSize = size * 1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final entry in minimalInventory.entries) {
          final builder = entry.builder;
          if (builder == null) continue;
          await tester.pumpWidget(
            _host(builder, brightness: brightness, size: size),
          );
          await tester.pump(const Duration(milliseconds: 400));
          final error = tester.takeException();
          expect(error, isNull, reason: '${entry.row}: $error');
        }
        // Let a carousel's or a toast's timers run out before the end.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
      });
    }
  }

  testWidgets('every live specimen lays out at 200% text on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final entry in minimalInventory.entries) {
      final builder = entry.builder;
      if (builder == null) continue;
      await tester.pumpWidget(
        _host(builder, size: const Size(390, 844), textScale: 2),
      );
      await tester.pump(const Duration(milliseconds: 400));
      final error = tester.takeException();
      expect(error, isNull, reason: '${entry.row}: $error');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('the inventory page lists every row under its group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        (context) => const MinimalInventoryGallery(),
        size: const Size(1000, 800),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Button (filled/outlined/text/danger)'), findsOneWidget);
    expect(find.textContaining('minified:'), findsNothing);
    // A heading names the part, not its class (a note may mention one).
    expect(find.text('MinimalButton'), findsNothing);
    expect(find.textContaining('ACTIONS'), findsOneWidget);
  });

  testWidgets('right to left, a URL still reads left to right; a lone check '
      'and a lone switch print their words', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        (context) => const Directionality(
          textDirection: TextDirection.rtl,
          child: MinimalInventoryGallery(),
        ),
        size: const Size(1000, 2400),
      ),
    );
    expect(tester.takeException(), isNull);
    // The scheme before the typed text, never `//:https`.
    expect(
      Directionality.of(tester.element(find.text('https://'))),
      TextDirection.ltr,
    );
    // The field's name still stands on the page's start edge: the right.
    final label = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text('Website'),
        matching: find.byType(RichText),
      ),
    );
    final word = label.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 7),
    );
    expect(word.first.left, greaterThan(label.size.width / 2));
    // A check announces its label and the inventory prints it beside it;
    // a switch stands at the end of a row that prints it.
    expect(find.text('Agree to the guidelines'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    // Let any part's timers run out before the end.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
