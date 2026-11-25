// Every doc example of the checks, compiled and run: each fenced dart block
// in their files is written out below, so an example that stops compiling
// fails analysis, and the first test fails when they have an example this
// file lacks. The checks take a tester, so their examples are functions the
// checks' own tests run in their shapes.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

import 'doc_examples.dart';

/// The screen [DesignKeylineCheck]'s example checks.
class SettingsScreen extends StatelessWidget {
  /// A screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// The theme [DesignContrastCheck.sweep]'s example builds.
class GiltThemeData {
  /// The look's own palette.
  const GiltThemeData({required this.brightness, this.accent, this.paper});

  /// A named palette.
  const GiltThemeData.from({
    required Color this.accent,
    this.paper,
    required this.brightness,
  });

  /// Day or night.
  final Brightness brightness;

  /// The accent.
  final Color? accent;

  /// The paper.
  final Color? paper;
}

/// The app [DesignContrastCheck.sweep]'s example pumps.
class GiltApp extends StatelessWidget {
  /// An app showing [home] in [theme].
  const GiltApp({super.key, required this.theme, required this.home});

  /// Its theme.
  final GiltThemeData theme;

  /// Its screen.
  final Widget home;

  @override
  Widget build(BuildContext context) => home;
}

/// The form [DesignListSideCheck]'s example checks.
class TaskForm extends StatelessWidget {
  /// A form.
  const TaskForm({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// The form [DesignFieldWordsCheck]'s example checks.
class SignUpForm extends StatelessWidget {
  /// A form.
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// The list [DesignFieldNodesCheck]'s example types in.
class TaskList extends StatelessWidget {
  /// A list.
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// [DesignTooltipNodeCheck]'s and [DesignListSideCheck]'s examples, run by
/// their own tests' shapes (tooltip_node_check_test.dart and
/// list_side_check_test.dart).
void _nodeAndSideChecks(WidgetTester tester) {
  const DesignTooltipNodeCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
  const DesignListSideCheck(look: 'Comic')
      .check(tester.element(find.byType(TaskForm)))
      .verify();
}

/// [DesignOverlayCheck]'s, [DesignOverflowCheck]'s,
/// [DesignDialogActionsCheck]'s and [DesignFieldWordsCheck]'s examples, run
/// by checks_050_test.dart's shapes.
void _checks050(WidgetTester tester) {
  const DesignOverlayCheck(look: 'Comic')
      .check(tester.element(find.byType(TaskForm)))
      .verify();
  const DesignOverflowCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
  const DesignDialogActionsCheck(
    look: 'Comic',
    actions: ['Cancel', 'Discard', 'Save changes'],
  ).check(tester.element(find.byType(TaskForm))).verify();
  const DesignFieldWordsCheck(
    look: 'Comic',
    words: ['We never share it', 'Enter a valid email'],
  ).check(tester.element(find.byType(SignUpForm))).verify();
}

/// [DesignFieldNodesCheck]'s example: it types, so field_nodes_check_test.dart
/// runs it in its shape.
Future<void> _fieldNodesCheck(WidgetTester tester) async {
  const check = DesignFieldNodesCheck(look: 'Comic');
  final empty = check.read(tester.element(find.byType(TaskList)));
  await tester.enterText(find.byType(EditableText), 'p');
  await tester.pump();
  check.check(empty, tester.element(find.byType(TaskList))).verify();
}

/// [DesignLabelCheck]'s example: it takes a tester, so it is compiled
/// here and run by label_check_test.dart.
Future<void> _labelCheck(WidgetTester tester) async {
  final report = await const DesignLabelCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignContrastCheck]'s examples: they take a tester, so they are
/// compiled here and run by contrast_check_test.dart's shapes.
Future<void> _contrastCheck(WidgetTester tester) async {
  final report = await const DesignContrastCheck(look: 'Gilt').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignContrastCheck.sweep]'s example.
Future<void> _contrastSweep(WidgetTester tester) async {
  final report = await const DesignContrastCheck(look: 'Gilt').sweep(
    show: (palette, brightness) async {
      // The look's own colour API takes the palette.
      final theme = palette == null
          ? GiltThemeData(brightness: brightness)
          : GiltThemeData.from(
              accent: palette.accent,
              paper: palette.neutral,
              brightness: brightness,
            );
      await tester.pumpWidget(
        GiltApp(theme: theme, home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
    },
    screen: () => tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignFaceInsetCheck]'s example: it takes a tester, so it is compiled
/// here and run by face_inset_check_test.dart's shape.
Future<void> _faceInsetCheck(WidgetTester tester) async {
  final report = await const DesignFaceInsetCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignWordBreakCheck]'s and [DesignClipCheck]'s examples, run by
/// fit_check_test.dart's shape.
void _fitChecks(WidgetTester tester) {
  const DesignWordBreakCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
  const DesignClipCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
}

/// [DesignCursorCheck]'s, [DesignTapTargetCheck]'s,
/// [DesignFieldSemanticsCheck]'s, [DesignCheckableCheck]'s and
/// [DesignShadowClipCheck]'s examples, run by their own tests' shapes
/// (cursor_check_test.dart and its neighbours).
Future<void> _screenChecks(WidgetTester tester) async {
  const DesignCursorCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
  const DesignFieldSemanticsCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
  const DesignTapTargetCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
  const DesignCheckableCheck(look: 'Comic')
      .check(tester.element(find.byType(SettingsScreen)))
      .verify();
  const DesignTapTargetCheck(
    look: 'Comic',
    input: RawInput.pointer,
  ).check(tester.element(find.byType(SettingsScreen))).verify();
  final report = await const DesignShadowClipCheck(look: 'Comic').check(
    tester.element(find.byType(SettingsScreen)),
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// [DesignRadioGroupCheck]'s example: it takes the focusable before the
/// group, so radio_group_check_test.dart runs it in its shape.
Future<void> _radioGroupCheck(WidgetTester tester, FocusNode before) async {
  final report = await const DesignRadioGroupCheck(look: 'Comic').check(
    tester.element(find.byKey(const ValueKey('plan'))),
    before: before,
    sendKeyEvent: tester.sendKeyEvent,
    pump: tester.pump,
  );
  report.verify();
}

/// [DesignLabelCheck.checkDensities]'s example, run by
/// label_check_test.dart.
Future<void> _labelDensities(
  WidgetTester tester,
  Map<String, DesignAlignmentTheme> densities,
) async {
  final report = await const DesignLabelCheck(look: 'Comic').checkDensities(
    densities: densities,
    screen: (context) => const SettingsScreen(),
    pump: tester.pumpWidget,
    runAsync: tester.runAsync,
  );
  report.verify();
}

/// The image settling that [DesignLabelCheck]'s docs ask for before a
/// check, run by label_check_test.dart.
Future<void> _settleImages(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.wait([
      for (final e in find.byType(Image).evaluate())
        precacheImage((e.widget as Image).image, e),
    ]),
  );
  await tester.pump();
}

/// The checks' files: ui_core_test's whole lib, and part of the source tree
/// it is made from, whose other files' examples are ui_core's and the
/// review's.
const Set<String> _checksFiles = {
  'alignment.dart',
  'checkable_check.dart',
  'contrast_check.dart',
  'cursor_check.dart',
  'dialog_actions_check.dart',
  'face_inset_check.dart',
  'field_nodes_check.dart',
  'field_words_check.dart',
  'field_semantics_check.dart',
  'list_side_check.dart',
  'overflow_check.dart',
  'overlay_check.dart',
  'radio_group_check.dart',
  'shadow_clip_check.dart',
  'tap_target_check.dart',
  'tooltip_node_check.dart',
  'reading.dart',
  'shape.dart',
  'drawn_pixels.dart',
  'label_line.dart',
};

void main() {
  test('the checks the examples call are compiled here', () {
    expect(_labelCheck, isNotNull);
    expect(_faceInsetCheck, isNotNull);
    expect(_contrastCheck, isNotNull);
    expect(_contrastSweep, isNotNull);
    expect(_labelDensities, isNotNull);
    expect(_settleImages, isNotNull);
    expect(_fitChecks, isNotNull);
    expect(_screenChecks, isNotNull);
    expect(_radioGroupCheck, isNotNull);
    expect(_nodeAndSideChecks, isNotNull);
    expect(_fieldNodesCheck, isNotNull);
    expect(_checks050, isNotNull);
  });

  testDocExamples(
    self: 'test/checks_doc_examples_test.dart',
    examples: const {},
    wrap: (child) => child,
    skip: {
      for (final file in Directory('lib').listSync(recursive: true))
        if (!_checksFiles.contains(file.uri.pathSegments.last))
          file.uri.pathSegments.last,
    },
  );
}
