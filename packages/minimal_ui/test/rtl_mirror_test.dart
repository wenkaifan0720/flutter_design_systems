// Right to left, every everyday part mirrors: what stands at its start edge
// left to right (a glyph, the first segment, a count at the end) stands as
// far from the screen's other edge right to left, through the shared world
// checks. A slider fills from the start side.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'world_checks.dart';

Widget _app(TextDirection direction, Widget part) => MaterialApp(
  builder: (context, navigator) => Directionality(
    textDirection: direction,
    child: MinimalHost(
      light: MinimalThemeData.preset('standard', Brightness.light),
      dark: MinimalThemeData.preset('standard', Brightness.dark),
      brightness: Brightness.light,
      child: navigator!,
    ),
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 360, child: part)),
  ),
);

void _ignore(Object? _) {}

/// A part, and what in it marks a side.
typedef _Case = ({Widget part, Finder Function() mark});

Finder _icon() => find.byType(MinimalIcon).first;

final Map<String, _Case> _cases = {
  'MinimalButton': (
    part: MinimalButton('Save', icon: LucideIcons.plus, onPressed: () {}),
    mark: _icon,
  ),
  'MinimalListTile': (
    part: MinimalListTile(
      title: 'Inbox',
      icon: LucideIcons.inbox,
      onTap: () {},
    ),
    mark: _icon,
  ),
  'MinimalListTile chevron': (
    part: MinimalListTile(title: 'Inbox', chevron: true, onTap: () {}),
    mark: _icon,
  ),
  'MinimalTextField': (
    part: const MinimalTextField(label: 'Name', icon: LucideIcons.user),
    mark: _icon,
  ),
  'MinimalSearchField': (
    part: const MinimalSearchField(hint: 'Search'),
    mark: _icon,
  ),
  'MinimalChip': (
    part: MinimalChip('Open', icon: LucideIcons.circle, onPressed: () {}),
    mark: _icon,
  ),
  'MinimalFilter': (
    part: MinimalFilter('Open', count: 2, onPressed: () {}),
    mark: () => find.text('2'),
  ),
  'MinimalSegmentedButton': (
    part: const MinimalSegmentedButton<int>(
      segments: [
        MinimalButtonSegment(0, 'Day'),
        MinimalButtonSegment(1, 'Week'),
        MinimalButtonSegment(2, 'Month'),
      ],
      value: 0,
      label: 'Range',
      onChanged: _ignore,
    ),
    mark: () => find.text('Day'),
  ),
  'MinimalToggleGroup': (
    part: const MinimalToggleGroup<String>(
      items: [
        MinimalToggleItem('a', label: 'Bold'),
        MinimalToggleItem('b', label: 'Italic'),
        MinimalToggleItem('c', label: 'Underline'),
      ],
      selected: {'a'},
      onChanged: _ignore,
    ),
    mark: () => find.text('Bold'),
  ),
  'MinimalTabBar': (
    part: const MinimalTabBar(
      tabs: ['Overview', 'Activity', 'Notes'],
      selectedIndex: 0,
      onChanged: _ignore,
    ),
    mark: () => find.text('Overview'),
  ),
  'MinimalNavigationBar': (
    part: const MinimalNavigationBar(
      items: [
        MinimalNavItem(LucideIcons.inbox, 'Inbox'),
        MinimalNavItem(LucideIcons.folder, 'Projects'),
        MinimalNavItem(LucideIcons.user, 'You'),
      ],
      selectedIndex: 0,
      onDestinationSelected: _ignore,
    ),
    mark: () => find.text('Inbox'),
  ),
  'MinimalRadioGroup': (
    part: const MinimalRadioGroup<String>(
      value: 'free',
      onChanged: _ignore,
      options: [
        MinimalRadioOption(value: 'free', label: 'Free'),
        MinimalRadioOption(value: 'pro', label: 'Pro'),
      ],
    ),
    mark: () => find.byType(MinimalRadio).first,
  ),
  'MinimalDisclosure': (
    part: const MinimalDisclosure(title: 'Advanced', child: Text('More')),
    mark: _icon,
  ),
  'MinimalAppBar': (
    part: MinimalAppBar(
      title: 'Today',
      actions: [
        MinimalIconButton(LucideIcons.plus, label: 'Add', onPressed: () {}),
      ],
    ),
    mark: () => find.byType(MinimalIconButton).last,
  ),
  'MinimalLinearProgressIndicator': (
    part: const MinimalLinearProgressIndicator(value: 0.25, label: 'Upload'),
    mark: () => find.byType(FractionallySizedBox),
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    testWidgets('$name mirrors right to left', (tester) async {
      await expectMirrorsInRtl(
        tester,
        (direction) => _app(direction, c.part),
        parts: [c.mark()],
      );
    });
  }

  testWidgets('right to left an external link\'s arrow mirrors; a letter '
      'glyph does not', (tester) async {
    await tester.pumpWidget(
      _app(
        TextDirection.rtl,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinimalLink('Terms', external: true, onPressed: () {}),
            const MinimalToggleGroup<String>(
              items: [
                MinimalToggleItem(
                  'bold',
                  icon: LucideIcons.bold,
                  semanticLabel: 'Bold',
                ),
              ],
              selected: {'bold'},
              onChanged: _ignore,
            ),
          ],
        ),
      ),
    );
    IconData glyph(Finder part) => tester
        .widget<Icon>(find.descendant(of: part, matching: find.byType(Icon)))
        .icon!;
    // Icon mirrors a glyph that matches the text direction, and only that.
    expect(glyph(find.byType(MinimalLink)).matchTextDirection, isTrue);
    expect(
      glyph(find.byType(MinimalToggleGroup<String>)).matchTextDirection,
      isFalse,
    );
  });

  testWidgets('a slider fills from the start side right to left', (
    tester,
  ) async {
    double? got;
    await tester.pumpWidget(
      _app(
        TextDirection.rtl,
        StatefulBuilder(
          builder: (context, setState) => MinimalSlider(
            label: 'Volume',
            showLabel: false,
            value: got ?? 0.5,
            onChanged: (v) => setState(() => got = v),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final track = tester.getRect(find.byType(MinimalSlider));
    // Near the right edge is near the start: a small value.
    await tester.tapAt(Offset(track.right - 24, track.center.dy));
    await tester.pumpAndSettle();
    expect(got, isNotNull);
    expect(got!, lessThan(0.5));
  });
}
