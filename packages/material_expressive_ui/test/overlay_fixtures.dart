// The overlays every family and every text check opens: those a call raises
// and those a widget raises itself, with the gesture that raises each.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// Opens one overlay from [context].
typedef OverlayOpener = void Function(BuildContext context);

/// Overlays a call raises, by name.
final overlayRoutes = <String, OverlayOpener>{
  'dialog': (context) => showExpressiveDialog<void>(
    context: context,
    builder: (_) => const ExpressiveDialog(
      title: 'Discard draft?',
      text: 'Your changes will be lost.',
      actions: [
        ExpressiveDialogAction('Cancel'),
        ExpressiveDialogAction('Discard', filled: true),
      ],
    ),
  ),
  'dialog with plain content': (context) => showExpressiveDialog<void>(
    context: context,
    builder: (_) => const ExpressiveDialog(
      title: 'Plain',
      content: Text('Content a caller wrote without a style'),
    ),
  ),
  'bottom sheet': (context) => showExpressiveBottomSheet<void>(
    context,
    builder: (_) => const Padding(
      padding: EdgeInsets.all(24),
      child: Text('A sheet a caller wrote without a style'),
    ),
  ),
  'menu': (context) => showExpressiveMenu(
    context,
    anchor: const Rect.fromLTWH(20, 40, 120, 40),
    entries: const [
      ExpressiveMenuItem('Rename', supportingText: 'Change the name'),
      ExpressiveMenuItem('Duplicate', trailingText: 'Ctrl+D'),
    ],
  ),
  'popover': (context) => showExpressivePopover(
    context,
    anchor: const Rect.fromLTWH(20, 40, 120, 40),
    builder: (_) => const Text('A popover a caller wrote without a style'),
  ),
  'snack bar': (context) => showExpressiveSnackBar(
    context,
    'Message archived',
    actionLabel: 'Undo',
    onAction: () {},
    withDismissAction: true,
  ),
  'date picker': (context) => showExpressiveDatePicker(
    context: context,
    initialDate: DateTime(2026, 11, 8),
    today: DateTime(2026, 11, 8),
  ),
  'date input': (context) => showExpressiveDatePicker(
    context: context,
    initialDate: DateTime(2026, 11, 8),
    today: DateTime(2026, 11, 8),
    initialMode: ExpressiveDatePickerMode.input,
  ),
  'date range picker': (context) => showExpressiveDateRangePicker(
    context: context,
    initialStart: DateTime(2026, 11, 8),
    initialEnd: DateTime(2026, 11, 12),
    today: DateTime(2026, 11, 8),
  ),
  'time picker': (context) => showExpressiveTimePicker(
    context: context,
    initialHour: 9,
    initialMinute: 30,
  ),
  'time input': (context) => showExpressiveTimePicker(
    context: context,
    initialHour: 9,
    initialMinute: 30,
    initialMode: ExpressiveTimePickerMode.input,
  ),
};

/// Overlays a widget raises itself, and the gesture that raises each.
final raisedOverlays = <String, (Widget, Future<void> Function(WidgetTester))>{
  'select': (
    ExpressiveSelect<int>(
      label: 'Size',
      value: 1,
      options: const [
        ExpressiveSelectOption(1, 'Small'),
        ExpressiveSelectOption(2, 'Large'),
      ],
      onChanged: (_) {},
    ),
    (tester) => tester.tap(find.byType(ExpressiveSelect<int>)),
  ),
  'plain tooltip': (
    const ExpressiveTooltip.plain(
      message: 'Add to favourites',
      child: SizedBox.square(dimension: 48),
    ),
    (tester) => tester.longPress(find.byType(ExpressiveTooltip)),
  ),
  'rich tooltip': (
    const ExpressiveTooltip.rich(
      title: 'Favourites',
      text: 'Saved places appear here',
      child: SizedBox.square(dimension: 48),
    ),
    (tester) => tester.longPress(find.byType(ExpressiveTooltip)),
  ),
  'search view': (
    ExpressiveSearchBar(
      hintText: 'Search places',
      results: (context, query) => Text('Results for "$query"'),
    ),
    (tester) => tester.tap(find.byType(ExpressiveSearchBar)),
  ),
  'docked date picker': (
    ExpressiveDockedDatePicker(
      label: 'Starts',
      value: DateTime(2026, 11, 8),
      currentDate: DateTime(2026, 11, 8),
      onChanged: (_) {},
    ),
    (tester) => tester.tap(find.byType(ExpressiveDockedDatePicker)),
  ),
  'split button menu': (
    ExpressiveSplitButton(
      'Save',
      onPressed: () {},
      menu: (context, close) => const Text('Save with a note'),
    ),
    (tester) async {
      final halves = find.descendant(
        of: find.byType(ExpressiveSplitButton),
        matching: find.byType(ExpressivePressable),
      );
      await tester.tap(halves.last);
    },
  ),
  'fab menu': (
    ExpressiveHeroMoment(
      child: ExpressiveFabMenu(
        icon: ExpressiveSymbols.add,
        buttonKey: const ValueKey<String>('fab'),
        items: [
          for (final label in ['Note', 'Photo', 'List'])
            ExpressiveFabMenuItem(
              icon: ExpressiveSymbols.edit,
              label: label,
              onPressed: (_) {},
            ),
        ],
      ),
    ),
    (tester) => tester.tap(find.byKey(const ValueKey<String>('fab'))),
  ),
};

/// A WidgetsApp with only [theme] above it, showing [home].
Widget overlayHost(ExpressiveThemeData theme, WidgetBuilder home) => WidgetsApp(
  color: theme.colors.primary,
  debugShowCheckedModeBanner: false,
  pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
  builder: (context, child) => ExpressiveTheme(data: theme, child: child!),
  home: Builder(builder: home),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 34));
  }
}

/// Opens every overlay under [theme] on a 412 × 915 phone, one at a time,
/// and calls [visit] with each one open.
Future<void> forEachOverlay(
  WidgetTester tester,
  ExpressiveThemeData theme,
  FutureOr<void> Function(String name) visit,
) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  for (final MapEntry(key: name, value: open) in overlayRoutes.entries) {
    await tester.pumpWidget(SizedBox(key: ValueKey('before $name')));
    await tester.pumpWidget(
      overlayHost(
        theme,
        (context) => Center(
          child: GestureDetector(
            key: const ValueKey('open'),
            behavior: HitTestBehavior.opaque,
            onTap: () => open(context),
            child: const SizedBox.square(dimension: 48),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await _settle(tester);
    expect(tester.takeException(), isNull, reason: name);
    await visit(name);
  }
  for (final MapEntry(key: name, value: (widget, raise))
      in raisedOverlays.entries) {
    await tester.pumpWidget(SizedBox(key: ValueKey('before $name')));
    await tester.pumpWidget(
      overlayHost(
        theme,
        (context) => Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: SizedBox(width: 280, child: widget),
          ),
        ),
      ),
    );
    await _settle(tester);
    await raise(tester);
    await _settle(tester);
    expect(tester.takeException(), isNull, reason: name);
    await visit(name);
  }
}
