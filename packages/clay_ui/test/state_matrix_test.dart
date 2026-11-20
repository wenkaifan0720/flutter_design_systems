// Each control's interaction states in Clay's own material, by day and by night: idle, hovered, pressed, focused,
// selected, disabled and in error, each where the control has it, as goldens.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

/// Compare against local baselines when they are available.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

const _all = {
  'idle',
  'hovered',
  'pressed',
  'focused',
  'selected',
  'disabled',
  'error',
};

typedef _Build = Widget Function(bool selected, bool disabled, bool error);

class _Part {
  const _Part(
    this.name,
    this.build, {
    this.states = const {'idle', 'hovered', 'pressed', 'focused', 'disabled'},
    this.target,
    this.tabs = 1,
    this.width,
  });

  final String name;
  final _Build build;
  final Set<String> states;

  /// The cell the pointer goes to, else the part's middle.
  final Finder Function()? target;

  /// How many Tabs bring the keyboard to it.
  final int tabs;
  final double? width;
}

void _none() {}

const _noStates = {
  'idle',
  'hovered',
  'pressed',
  'focused',
  'selected',
  'disabled',
};

final _parts = <_Part>[
  _Part(
    'Button',
    (s, d, e) => ClayButton('Share', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, filled',
    (s, d, e) => ClayButton.filled('Add habit', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, text',
    (s, d, e) => ClayButton.text('Later', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, destructive',
    (s, d, e) => ClayButton(
      'Delete habit',
      isDestructiveAction: true,
      onPressed: d ? null : _none,
    ),
  ),
  _Part(
    'Icon button',
    (s, d, e) => ClayIconButton(
      icon: const Icon(LucideIcons.heart),
      tooltip: 'Save',
      selected: s,
      onPressed: d ? null : _none,
    ),
    states: _noStates,
  ),
  _Part(
    'Icon button, filled',
    (s, d, e) => ClayIconButton.filled(
      icon: const Icon(LucideIcons.plus),
      tooltip: 'New habit',
      onPressed: d ? null : _none,
    ),
  ),
  _Part('Link', (s, d, e) => ClayLink('See all', onPressed: d ? null : _none)),
  _Part(
    'Checkbox',
    (s, d, e) => ClayCheckbox(
      value: s,
      isError: e,
      semanticLabel: 'Done',
      onChanged: d ? null : (_) {},
    ),
    states: _all,
  ),
  _Part(
    'Radio',
    (s, d, e) => ClayRadio<int>(
      value: 1,
      groupValue: s ? 1 : 0,
      semanticLabel: 'Morning',
      onChanged: d ? null : (_) {},
    ),
    states: _noStates,
  ),
  _Part(
    'Switch',
    (s, d, e) => ClaySwitch(
      value: s,
      semanticLabel: 'Reminders',
      onChanged: d ? null : (_) {},
    ),
    states: _noStates,
  ),
  _Part(
    'Chip',
    (s, d, e) =>
        ClayChip(label: 'Morning', selected: s, onSelected: d ? null : (_) {}),
    states: _noStates,
  ),
  _Part(
    'Segmented button',
    (s, d, e) => ClaySegmentedButton<String>(
      segments: const [
        ClaySegment(value: 'day', label: 'Day'),
        ClaySegment(value: 'week', label: 'Week'),
        ClaySegment(value: 'month', label: 'Month'),
      ],
      expanded: false,
      selected: s ? 'week' : 'day',
      onChanged: d ? null : (_) {},
    ),
    states: _noStates,
    target: () => find.text('Week'),
    tabs: 2,
  ),
  _Part(
    'Toggle group',
    (s, d, e) => ClayToggleGroup<String>(
      semanticLabel: 'Time of day',
      toggles: [
        ClayToggle(value: 'm', label: 'Morning', enabled: !d),
        ClayToggle(value: 'e', label: 'Evening', enabled: !d),
      ],
      selected: s ? const {'m'} : const {},
      onSelectionChanged: (_) {},
    ),
    states: _noStates,
    target: () => find.text('Morning'),
  ),
  _Part(
    'Tab bar',
    (s, d, e) => ClayTabBar(
      tabs: const ['Week', 'Month'],
      selectedIndex: s ? 1 : 0,
      onSelected: (_) {},
    ),
    states: {'idle', 'hovered', 'pressed', 'focused', 'selected'},
    target: () => find.text('Month'),
    tabs: 2,
    width: 320,
  ),
  _Part(
    'Navigation bar',
    (s, d, e) => ClayNavigationBar(
      destinations: const [
        ClayDestination(icon: LucideIcons.sun, label: 'Today'),
        ClayDestination(icon: LucideIcons.listChecks, label: 'Habits'),
        ClayDestination(icon: LucideIcons.settings, label: 'Settings'),
      ],
      selectedIndex: s ? 1 : 0,
      onSelected: (_) {},
    ),
    states: {'idle', 'hovered', 'pressed', 'focused', 'selected'},
    target: () => find.text('Habits'),
    tabs: 2,
    width: 380,
  ),
  _Part(
    'List row',
    (s, d, e) => ClayGroup(
      children: [
        ClayListTile(
          title: 'Drink water',
          subtitle: '5 of 8 glasses',
          trailingText: '12 days',
          selected: s,
          enabled: !d,
          onTap: _none,
        ),
      ],
    ),
    states: _noStates,
    width: 340,
  ),
  _Part(
    'Card',
    (s, d, e) => ClayCard(
      onTap: d ? null : _none,
      child: const Text('Drink water, 5 of 8'),
    ),
    width: 280,
  ),
  _Part(
    'Disclosure',
    (s, d, e) => ClayDisclosure(
      title: 'Why it matters',
      expanded: s,
      onChanged: d ? null : (_) {},
      child: const Text('A glass before coffee sets the day.'),
    ),
    states: _noStates,
    width: 340,
  ),
  _Part(
    'Text field',
    (s, d, e) => ClayTextField(
      label: 'Habit name',
      hint: 'Drink water',
      error: e ? 'Give the habit a name.' : null,
      enabled: !d,
      onChanged: (_) {},
    ),
    states: {'idle', 'hovered', 'focused', 'disabled', 'error'},
    width: 340,
  ),
  _Part(
    'Search field',
    (s, d, e) =>
        ClaySearchField(hint: 'Search habits', enabled: !d, onChanged: (_) {}),
    states: {'idle', 'hovered', 'focused', 'disabled'},
    width: 340,
  ),
  _Part(
    'Select',
    (s, d, e) => ClaySelect<String>(
      label: 'Repeat',
      value: 'daily',
      error: e ? 'Pick how often.' : null,
      items: const [
        ClaySelectItem(value: 'daily', label: 'Every day'),
        ClaySelectItem(value: 'weekdays', label: 'Weekdays'),
      ],
      onChanged: d ? null : (_) {},
    ),
    states: {'idle', 'hovered', 'focused', 'disabled', 'error'},
    width: 340,
  ),
  _Part(
    'Slider',
    (s, d, e) => ClaySlider(
      value: 0.4,
      semanticLabel: 'Energy',
      onChanged: d ? null : (_) {},
    ),
    width: 340,
  ),
  _Part(
    'Range slider',
    (s, d, e) => ClayRangeSlider(
      values: const ClayRangeValues(6, 9),
      min: 5,
      max: 12,
      startLabel: 'Earliest',
      endLabel: 'Latest',
      onChanged: d ? null : (_) {},
    ),
    width: 340,
  ),
  _Part(
    'Number field',
    (s, d, e) => ClayNumberField(
      value: 4,
      max: 12,
      semanticLabel: 'Glasses',
      onChanged: d ? null : (_) {},
    ),
    target: () => find.byIcon(LucideIcons.plus),
  ),
  _Part(
    'Rating',
    (s, d, e) => ClayRating(
      value: 3,
      semanticLabel: 'How the week felt',
      onChanged: d ? null : (_) {},
    ),
  ),
  _Part(
    'Pagination',
    (s, d, e) =>
        ClayPagination(page: 1, count: 5, onChanged: d ? null : (_) {}),
    target: () => find.text('3'),
    width: 380,
  ),
];

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : clayRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

String _slug(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

const _stage = ValueKey('stage');

void main() {
  setUpAll(_loadFonts);
  for (final part in _parts) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${part.name} by ${brightness.name}: each state matches its golden',
        (tester) async {
          tester.view.devicePixelRatio = 2;
          tester.view.physicalSize = const Size(480 * 2, 260 * 2);
          addTearDown(tester.view.reset);
          for (final state in _all.where(part.states.contains)) {
            final specimen = part.build(
              state == 'selected',
              state == 'disabled',
              state == 'error',
            );
            await tester.pumpWidget(
              kitApp(
                brightness: brightness,
                home: Builder(
                  builder: (context) => ColoredBox(
                    color: context.clayTheme.colors.ground,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: RepaintBoundary(
                        key: _stage,
                        child: ColoredBox(
                          color: context.clayTheme.colors.ground,
                          child: Padding(
                            padding: const EdgeInsets.all(ClaySpacing.large),
                            child: SizedBox(
                              width: part.width,
                              child: Align(
                                alignment: AlignmentDirectional.topStart,
                                widthFactor: part.width == null ? 1 : null,
                                child: KeyedSubtree(
                                  key: ValueKey('${part.name} $state'),
                                  child: specimen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final whole = find.byKey(_stage);
            final at = part.target == null
                ? tester.getCenter(
                    find
                        .descendant(of: whole, matching: find.byType(Padding))
                        .first,
                  )
                : tester.getCenter(
                    find.descendant(of: whole, matching: part.target!()).first,
                  );
            TestGesture? held;
            TestGesture? mouse;
            switch (state) {
              case 'hovered':
                mouse = await tester.createGesture(
                  kind: PointerDeviceKind.mouse,
                );
                await mouse.addPointer(location: Offset.zero);
                await mouse.moveTo(at);
                await tester.pumpAndSettle();
              case 'pressed':
                held = await tester.startGesture(at);
                await tester.pump(const Duration(milliseconds: 400));
              case 'focused':
                for (var i = 0; i < part.tabs; i++) {
                  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
                }
                await tester.pumpAndSettle();
            }
            await expectLater(
              whole,
              matchesGoldenFile(
                'goldens/states/${_slug(part.name)}/${state}_${brightness.name}.png',
              ),
            );
            expect(tester.takeException(), isNull, reason: state);
            if (held != null) {
              // Slid off before letting go: a held press that leaves does
              // not act.
              await held.moveTo(const Offset(470, 250));
              await held.up();
            }
            if (mouse != null) await mouse.removePointer();
            await tester.pumpAndSettle();
          }
          // Leave nothing running: a tooltip's timer.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 3));
        },
        // Pixels recorded on macOS: `flutter test --exclude-tags goldens`
        // leaves them out elsewhere.
        skip: !_recorded,
        tags: const ['goldens'],
      );
    }
  }
}
