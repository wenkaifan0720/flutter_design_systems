/// Every everyday part through the shared world checks (world_checks.dart,
/// the same file in every look's package): right to left it mirrors (what
/// leads a part left to right, a button's icon, a row's box, a field's
/// leading icon, the first tab, segment or destination, stands as far from
/// the right edge right to left), at twice the text size nothing overflows,
/// and by day and by night it meets Flutter's tap target, label and text
/// contrast guidelines.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'world_checks.dart';

final _preset = ExpressiveThemeData.presets.first;

/// [part] on the theme's surface, 360 wide in the middle of the view, in
/// [direction] (above the navigator, as an app's locale sets it).
Widget _app(
  Widget part, {
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) => KeyedSubtree(
  key: ValueKey<(TextDirection, Brightness)>((direction, brightness)),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, home) => Directionality(
      textDirection: direction,
      child: ExpressiveHost(
        light: ExpressiveThemeData.preset(_preset, Brightness.light),
        dark: ExpressiveThemeData.preset(_preset, Brightness.dark),
        brightness: brightness,
        child: home!,
      ),
    ),
    home: Builder(
      builder: (context) => ColoredBox(
        color: context.expressiveTheme.colors.surface,
        child: Center(child: SizedBox(width: 360, child: part)),
      ),
    ),
  ),
);

/// A part standing at the start of its 360dp, at its own width.
Widget _atStart(Widget part) =>
    Align(alignment: AlignmentDirectional.centerStart, child: part);

const _lead = ValueKey<String>('lead');
const _trail = ValueKey<String>('trail');

/// The everyday parts: a name, the part, and what of it must mirror.
final _parts = <(String, Widget, List<Finder>)>[
  (
    'a filled button with its icon',
    _atStart(
      ExpressiveFilledButton(
        'Save',
        icon: ExpressiveSymbols.add,
        onPressed: () {},
      ),
    ),
    [find.byIcon(ExpressiveSymbols.add), find.text('Save')],
  ),
  (
    'a chip with its icon',
    _atStart(
      ExpressiveChip(
        'Vegetarian',
        icon: ExpressiveSymbols.check,
        onPressed: () {},
      ),
    ),
    [find.byIcon(ExpressiveSymbols.check), find.text('Vegetarian')],
  ),
  (
    'segments',
    ExpressiveSegmentedButton<String>(
      segments: const <ExpressiveButtonSegment<String>>[
        ExpressiveButtonSegment('day', 'Day'),
        ExpressiveButtonSegment('week', 'Week'),
      ],
      value: 'day',
      onChanged: (_) {},
    ),
    [find.text('Day'), find.text('Week')],
  ),
  (
    'a checkbox row',
    ExpressiveCheckboxRow(label: 'Email me', value: true, onChanged: (_) {}),
    [find.byType(ExpressiveCheckbox), find.text('Email me')],
  ),
  (
    'a radio row',
    ExpressiveRadioRow(label: 'Monthly', selected: true, onPressed: () {}),
    [find.byType(ExpressiveRadio), find.text('Monthly')],
  ),
  (
    'a switch row',
    ExpressiveSwitchRow(label: 'Wi-Fi', value: true, onChanged: (_) {}),
    [find.text('Wi-Fi'), find.byType(ExpressiveSwitch)],
  ),
  (
    "a field's leading and trailing icons",
    const ExpressiveTextField(
      label: 'Name',
      leading: SizedBox(key: _lead, width: 24, height: 24),
      trailing: SizedBox(key: _trail, width: 24, height: 24),
    ),
    [find.byKey(_lead), find.byKey(_trail), find.text('Name')],
  ),
  (
    'a list row',
    ExpressiveListTile(
      title: const Text('Title'),
      leading: const SizedBox(key: _lead, width: 24, height: 24),
      trailing: const SizedBox(key: _trail, width: 24, height: 24),
      onTap: () {},
    ),
    [find.byKey(_lead), find.text('Title'), find.byKey(_trail)],
  ),
  (
    'tabs',
    ExpressiveTabBar(
      tabs: const <ExpressiveTab>[
        ExpressiveTab(label: 'One'),
        ExpressiveTab(label: 'Two'),
      ],
      selectedIndex: 0,
      onChanged: (_) {},
    ),
    [find.text('One'), find.text('Two')],
  ),
  (
    'navigation destinations',
    ExpressiveNavigationBar(
      destinations: const <ExpressiveNavItem>[
        ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
        ExpressiveNavItem(ExpressiveSymbols.search, 'Search'),
      ],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
    ),
    [find.text('Home'), find.text('Search')],
  ),
  (
    "a dialog's title and actions",
    const ExpressiveDialog(
      title: 'Delete the trip?',
      actions: <ExpressiveDialogAction>[
        ExpressiveDialogAction('Cancel'),
        ExpressiveDialogAction('Delete'),
      ],
    ),
    [find.text('Delete the trip?'), find.text('Cancel'), find.text('Delete')],
  ),
];

void main() {
  for (final (name, part, mirrored) in _parts) {
    group(name, () {
      testWidgets('mirrors right to left', (tester) async {
        await expectMirrorsInRtl(
          tester,
          (direction) => _app(part, direction: direction),
          parts: mirrored,
        );
      });

      testWidgets('lays out at text scale 2.0', (tester) async {
        await expectNoOverflowAtTextScale(tester, _app(part));
      });

      for (final brightness in Brightness.values) {
        testWidgets('meets the guidelines, ${brightness.name}', (tester) async {
          await tester.pumpWidget(_app(part, brightness: brightness));
          await tester.pumpAndSettle();
          await expectMeetsGuidelines(tester);
          // Text contrast reads the drawn pixels, the rasterizer's as a
          // golden's are: macOS runs it.
        }, tags: const ['goldens']);
      }
    });
  }

  testWidgets("a field's prefix and suffix swap right to left", (tester) async {
    final controller = TextEditingController(text: '12');
    addTearDown(controller.dispose);
    await expectMirrorsInRtl(
      tester,
      (direction) => _app(
        ExpressiveTextField(
          label: 'Weight',
          controller: controller,
          prefix: '~',
          suffix: 'kg',
        ),
        direction: direction,
      ),
      parts: [find.text('~'), find.text('kg')],
    );
  });
}
